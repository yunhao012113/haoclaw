import path from "node:path";
import { describe, expect, it } from "vitest";
import { formatCliCommand } from "./command-format.js";
import { applyCliProfileEnv, parseCliProfileArgs } from "./profile.js";

describe("parseCliProfileArgs", () => {
  it("leaves gateway --dev for subcommands", () => {
    const res = parseCliProfileArgs([
      "node",
      "haoclaw",
      "gateway",
      "--dev",
      "--allow-unconfigured",
    ]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBeNull();
    expect(res.argv).toEqual(["node", "haoclaw", "gateway", "--dev", "--allow-unconfigured"]);
  });

  it("still accepts global --dev before subcommand", () => {
    const res = parseCliProfileArgs(["node", "haoclaw", "--dev", "gateway"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("dev");
    expect(res.argv).toEqual(["node", "haoclaw", "gateway"]);
  });

  it("parses --profile value and strips it", () => {
    const res = parseCliProfileArgs(["node", "haoclaw", "--profile", "work", "status"]);
    if (!res.ok) {
      throw new Error(res.error);
    }
    expect(res.profile).toBe("work");
    expect(res.argv).toEqual(["node", "haoclaw", "status"]);
  });

  it("rejects missing profile value", () => {
    const res = parseCliProfileArgs(["node", "haoclaw", "--profile"]);
    expect(res.ok).toBe(false);
  });

  it.each([
    ["--dev first", ["node", "haoclaw", "--dev", "--profile", "work", "status"]],
    ["--profile first", ["node", "haoclaw", "--profile", "work", "--dev", "status"]],
  ])("rejects combining --dev with --profile (%s)", (_name, argv) => {
    const res = parseCliProfileArgs(argv);
    expect(res.ok).toBe(false);
  });
});

describe("applyCliProfileEnv", () => {
  it("fills env defaults for dev profile", () => {
    const env: Record<string, string | undefined> = {};
    applyCliProfileEnv({
      profile: "dev",
      env,
      homedir: () => "/home/peter",
    });
    const expectedStateDir = path.join(path.resolve("/home/peter"), ".haoclaw-dev");
    expect(env.HAOCLAW_PROFILE).toBe("dev");
    expect(env.HAOCLAW_STATE_DIR).toBe(expectedStateDir);
    expect(env.HAOCLAW_CONFIG_PATH).toBe(path.join(expectedStateDir, "haoclaw.json"));
    expect(env.HAOCLAW_GATEWAY_PORT).toBe("19001");
  });

  it("does not override explicit env values", () => {
    const env: Record<string, string | undefined> = {
      HAOCLAW_STATE_DIR: "/custom",
      HAOCLAW_GATEWAY_PORT: "19099",
    };
    applyCliProfileEnv({
      profile: "dev",
      env,
      homedir: () => "/home/peter",
    });
    expect(env.HAOCLAW_STATE_DIR).toBe("/custom");
    expect(env.HAOCLAW_GATEWAY_PORT).toBe("19099");
    expect(env.HAOCLAW_CONFIG_PATH).toBe(path.join("/custom", "haoclaw.json"));
  });

  it("uses HAOCLAW_HOME when deriving profile state dir", () => {
    const env: Record<string, string | undefined> = {
      HAOCLAW_HOME: "/srv/haoclaw-home",
      HOME: "/home/other",
    };
    applyCliProfileEnv({
      profile: "work",
      env,
      homedir: () => "/home/fallback",
    });

    const resolvedHome = path.resolve("/srv/haoclaw-home");
    expect(env.HAOCLAW_STATE_DIR).toBe(path.join(resolvedHome, ".haoclaw-work"));
    expect(env.HAOCLAW_CONFIG_PATH).toBe(
      path.join(resolvedHome, ".haoclaw-work", "haoclaw.json"),
    );
  });
});

describe("formatCliCommand", () => {
  it.each([
    {
      name: "no profile is set",
      cmd: "haoclaw doctor --fix",
      env: {},
      expected: "haoclaw doctor --fix",
    },
    {
      name: "profile is default",
      cmd: "haoclaw doctor --fix",
      env: { HAOCLAW_PROFILE: "default" },
      expected: "haoclaw doctor --fix",
    },
    {
      name: "profile is Default (case-insensitive)",
      cmd: "haoclaw doctor --fix",
      env: { HAOCLAW_PROFILE: "Default" },
      expected: "haoclaw doctor --fix",
    },
    {
      name: "profile is invalid",
      cmd: "haoclaw doctor --fix",
      env: { HAOCLAW_PROFILE: "bad profile" },
      expected: "haoclaw doctor --fix",
    },
    {
      name: "--profile is already present",
      cmd: "haoclaw --profile work doctor --fix",
      env: { HAOCLAW_PROFILE: "work" },
      expected: "haoclaw --profile work doctor --fix",
    },
    {
      name: "--dev is already present",
      cmd: "haoclaw --dev doctor",
      env: { HAOCLAW_PROFILE: "dev" },
      expected: "haoclaw --dev doctor",
    },
  ])("returns command unchanged when $name", ({ cmd, env, expected }) => {
    expect(formatCliCommand(cmd, env)).toBe(expected);
  });

  it("inserts --profile flag when profile is set", () => {
    expect(formatCliCommand("haoclaw doctor --fix", { HAOCLAW_PROFILE: "work" })).toBe(
      "haoclaw --profile work doctor --fix",
    );
  });

  it("trims whitespace from profile", () => {
    expect(formatCliCommand("haoclaw doctor --fix", { HAOCLAW_PROFILE: "  jbhaoclaw  " })).toBe(
      "haoclaw --profile jbhaoclaw doctor --fix",
    );
  });

  it("handles command with no args after haoclaw", () => {
    expect(formatCliCommand("haoclaw", { HAOCLAW_PROFILE: "test" })).toBe(
      "haoclaw --profile test",
    );
  });

  it("handles pnpm wrapper", () => {
    expect(formatCliCommand("pnpm haoclaw doctor", { HAOCLAW_PROFILE: "work" })).toBe(
      "pnpm haoclaw --profile work doctor",
    );
  });
});

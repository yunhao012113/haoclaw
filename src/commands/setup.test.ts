import fs from "node:fs/promises";
import path from "node:path";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { withTempHome } from "../../test/helpers/temp-home.js";
import { setupCommand } from "./setup.js";

const { runNonInteractiveOnboardingMock } = vi.hoisted(() => ({
  runNonInteractiveOnboardingMock: vi.fn(),
}));
const { healthCommandMock, probeGatewayReachableMock, waitForGatewayReachableMock, spawnMock } =
  vi.hoisted(() => ({
    healthCommandMock: vi.fn(),
    probeGatewayReachableMock: vi.fn(),
    waitForGatewayReachableMock: vi.fn(),
    spawnMock: vi.fn(),
  }));

vi.mock("./onboard-non-interactive.js", () => ({
  runNonInteractiveOnboarding: runNonInteractiveOnboardingMock,
}));
vi.mock("./health.js", () => ({
  healthCommand: healthCommandMock,
}));
vi.mock("./onboard-helpers.js", () => ({
  probeGatewayReachable: probeGatewayReachableMock,
  resolveControlUiLinks: () => ({
    httpUrl: "http://127.0.0.1:18789/",
    wsUrl: "ws://127.0.0.1:18789/ws",
  }),
  waitForGatewayReachable: waitForGatewayReachableMock,
}));
vi.mock("node:child_process", async (importOriginal) => {
  const actual = await importOriginal<typeof import("node:child_process")>();
  return {
    ...actual,
    spawn: spawnMock,
  };
});

describe("setupCommand", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    spawnMock.mockReturnValue({ unref: vi.fn() });
    probeGatewayReachableMock.mockResolvedValue({ ok: false });
    waitForGatewayReachableMock.mockResolvedValue({ ok: true });
    healthCommandMock.mockResolvedValue(undefined);
  });

  it("delegates to non-interactive onboarding for simple API-backed setup", async () => {
    const runtime = {
      log: vi.fn(),
      error: vi.fn(),
      exit: vi.fn(),
    };

    await setupCommand(
      {
        provider: "openai-compatible",
        apiKey: "sk-test",
        baseUrl: "https://llm.example.com/v1",
        model: "gpt-4.1-mini",
        installDaemon: true,
        gatewayPort: 19000,
        skipSkills: false,
      },
      runtime,
    );

    expect(runNonInteractiveOnboardingMock).toHaveBeenCalledWith(
      expect.objectContaining({
        nonInteractive: true,
        acceptRisk: true,
        flow: "quickstart",
        mode: "local",
        authChoice: "custom-api-key",
        customBaseUrl: "https://llm.example.com/v1",
        customModelId: "gpt-4.1-mini",
        customApiKey: "sk-test",
        customCompatibility: "openai",
        installDaemon: true,
        gatewayPort: 19000,
        skipSkills: false,
        skipChannels: true,
        skipSearch: true,
        skipUi: true,
        skipHealth: true,
      }),
      runtime,
    );
    expect(spawnMock).toHaveBeenCalled();
    expect(healthCommandMock).toHaveBeenCalledWith(
      { json: false, timeoutMs: 10_000 },
      runtime,
    );
  });

  it("skips gateway auto-start when start is false", async () => {
    const runtime = {
      log: vi.fn(),
      error: vi.fn(),
      exit: vi.fn(),
    };

    await setupCommand(
      {
        provider: "openai",
        apiKey: "sk-test",
        start: false,
      },
      runtime,
    );

    expect(spawnMock).not.toHaveBeenCalled();
    expect(healthCommandMock).not.toHaveBeenCalled();
  });

  it("writes gateway.mode=local on first run", async () => {
    await withTempHome(async (home) => {
      const runtime = {
        log: vi.fn(),
        error: vi.fn(),
        exit: vi.fn(),
      };

      await setupCommand(undefined, runtime);

      const configPath = path.join(home, ".haoclaw", "haoclaw.json");
      const raw = await fs.readFile(configPath, "utf-8");

      expect(raw).toContain('"mode": "local"');
      expect(raw).toContain('"workspace"');
    });
  });

  it("adds gateway.mode=local to an existing config without overwriting workspace", async () => {
    await withTempHome(async (home) => {
      const runtime = {
        log: vi.fn(),
        error: vi.fn(),
        exit: vi.fn(),
      };
      const configDir = path.join(home, ".haoclaw");
      const configPath = path.join(configDir, "haoclaw.json");
      const workspace = path.join(home, "custom-workspace");

      await fs.mkdir(configDir, { recursive: true });
      await fs.writeFile(
        configPath,
        JSON.stringify({
          agents: {
            defaults: {
              workspace,
            },
          },
        }),
      );

      await setupCommand(undefined, runtime);

      const raw = JSON.parse(await fs.readFile(configPath, "utf-8")) as {
        agents?: { defaults?: { workspace?: string } };
        gateway?: { mode?: string };
      };

      expect(raw.agents?.defaults?.workspace).toBe(workspace);
      expect(raw.gateway?.mode).toBe("local");
    });
  });
});

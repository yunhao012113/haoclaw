import { Command } from "commander";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

const setupCommandMock = vi.fn();
const onboardCommandMock = vi.fn();
const runtime = {
  log: vi.fn(),
  error: vi.fn(),
  exit: vi.fn(),
};

vi.mock("../../commands/setup.js", () => ({
  setupCommand: setupCommandMock,
}));

vi.mock("../../commands/onboard.js", () => ({
  onboardCommand: onboardCommandMock,
}));

vi.mock("../../runtime.js", () => ({
  defaultRuntime: runtime,
}));

let registerSetupCommand: typeof import("./register.setup.js").registerSetupCommand;

beforeAll(async () => {
  ({ registerSetupCommand } = await import("./register.setup.js"));
});

describe("registerSetupCommand", () => {
  async function runCli(args: string[]) {
    const program = new Command();
    registerSetupCommand(program);
    await program.parseAsync(args, { from: "user" });
  }

  beforeEach(() => {
    vi.clearAllMocks();
    setupCommandMock.mockResolvedValue(undefined);
    onboardCommandMock.mockResolvedValue(undefined);
  });

  it("runs setup command by default", async () => {
    await runCli(["setup", "--workspace", "/tmp/ws"]);

    expect(setupCommandMock).toHaveBeenCalledWith(
      expect.objectContaining({
        workspace: "/tmp/ws",
      }),
      runtime,
    );
    expect(onboardCommandMock).not.toHaveBeenCalled();
  });

  it("passes simple API setup options through setup command", async () => {
    await runCli([
      "setup",
      "--provider",
      "openai-compatible",
      "--api-key",
      "sk-test",
      "--base-url",
      "https://llm.example.com/v1",
      "--model",
      "gpt-4.1-mini",
      "--install-daemon",
      "--gateway-port",
      "19000",
      "--no-skip-skills",
    ]);

    expect(setupCommandMock).toHaveBeenCalledWith(
      expect.objectContaining({
        provider: "openai-compatible",
        apiKey: "sk-test",
        baseUrl: "https://llm.example.com/v1",
        model: "gpt-4.1-mini",
        installDaemon: true,
        start: true,
        gatewayPort: 19000,
        skipSkills: false,
      }),
      runtime,
    );
    expect(onboardCommandMock).not.toHaveBeenCalled();
  });

  it("forwards --no-start to simple setup", async () => {
    await runCli([
      "setup",
      "--provider",
      "openai",
      "--api-key",
      "sk-test",
      "--no-start",
    ]);

    expect(setupCommandMock).toHaveBeenCalledWith(
      expect.objectContaining({
        provider: "openai",
        apiKey: "sk-test",
        start: false,
      }),
      runtime,
    );
  });

  it("runs onboard command when --wizard is set", async () => {
    await runCli(["setup", "--wizard", "--mode", "remote", "--remote-url", "wss://example"]);

    expect(onboardCommandMock).toHaveBeenCalledWith(
      expect.objectContaining({
        mode: "remote",
        remoteUrl: "wss://example",
      }),
      runtime,
    );
    expect(setupCommandMock).not.toHaveBeenCalled();
  });

  it("runs onboard command when wizard-only flags are passed explicitly", async () => {
    await runCli(["setup", "--mode", "remote", "--non-interactive"]);

    expect(onboardCommandMock).toHaveBeenCalledWith(
      expect.objectContaining({
        mode: "remote",
        nonInteractive: true,
      }),
      runtime,
    );
    expect(setupCommandMock).not.toHaveBeenCalled();
  });

  it("reports setup errors through runtime", async () => {
    setupCommandMock.mockRejectedValueOnce(new Error("setup failed"));

    await runCli(["setup"]);

    expect(runtime.error).toHaveBeenCalledWith("Error: setup failed");
    expect(runtime.exit).toHaveBeenCalledWith(1);
  });
});

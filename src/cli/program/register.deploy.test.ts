import { Command } from "commander";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";

const setupCommandMock = vi.fn();
const runtime = {
  log: vi.fn(),
  error: vi.fn(),
  exit: vi.fn(),
};

vi.mock("../../commands/setup.js", () => ({
  setupCommand: setupCommandMock,
}));

vi.mock("../../runtime.js", () => ({
  defaultRuntime: runtime,
}));

let registerDeployCommand: typeof import("./register.deploy.js").registerDeployCommand;

beforeAll(async () => {
  ({ registerDeployCommand } = await import("./register.deploy.js"));
});

describe("registerDeployCommand", () => {
  async function runCli(args: string[]) {
    const program = new Command();
    registerDeployCommand(program);
    await program.parseAsync(args, { from: "user" });
  }

  beforeEach(() => {
    vi.clearAllMocks();
    setupCommandMock.mockResolvedValue(undefined);
  });

  it("maps deploy flags into setupCommand", async () => {
    await runCli([
      "deploy",
      "--provider",
      "openai-compatible",
      "--base-url",
      "https://llm.example.com/v1",
      "--api-key",
      "sk-test",
      "--gateway-port",
      "19999",
      "--no-skip-skills",
    ]);

    expect(setupCommandMock).toHaveBeenCalledWith(
      expect.objectContaining({
        provider: "openai-compatible",
        baseUrl: "https://llm.example.com/v1",
        apiKey: "sk-test",
        installDaemon: true,
        start: true,
        gatewayPort: 19999,
        skipSkills: false,
      }),
      runtime,
    );
  });

  it("supports disabling daemon and start", async () => {
    await runCli([
      "deploy",
      "--provider",
      "openai",
      "--api-key",
      "sk-test",
      "--no-daemon",
      "--no-start",
    ]);

    expect(setupCommandMock).toHaveBeenCalledWith(
      expect.objectContaining({
        provider: "openai",
        apiKey: "sk-test",
        installDaemon: false,
        start: false,
      }),
      runtime,
    );
  });
});

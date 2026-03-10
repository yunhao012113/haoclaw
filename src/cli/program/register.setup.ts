import type { Command } from "commander";
import { onboardCommand } from "../../commands/onboard.js";
import { setupCommand } from "../../commands/setup.js";
import { defaultRuntime } from "../../runtime.js";
import { formatDocsLink } from "../../terminal/links.js";
import { theme } from "../../terminal/theme.js";
import { runCommandWithRuntime } from "../cli-utils.js";
import { hasExplicitOptions } from "../command-options.js";

export function registerSetupCommand(program: Command) {
  program
    .command("setup")
    .description("Initialize Haoclaw with sane defaults or a simple API-backed setup")
    .addHelpText(
      "after",
      () =>
        `\n${theme.muted("Docs:")} ${formatDocsLink("/cli/setup", "docs.haoclaw.ai/cli/setup")}\n`,
    )
    .option(
      "--workspace <dir>",
      "Agent workspace directory (default: ~/.haoclaw/workspace; stored as agents.defaults.workspace)",
    )
    .option(
      "--provider <name>",
      "Simple provider: openai|anthropic|openrouter|gemini|openai-compatible|anthropic-compatible",
    )
    .option("--api-key <key>", "API key for simple setup")
    .option("--base-url <url>", "Custom provider base URL for simple setup")
    .option(
      "--model <id>",
      "Model id for simple setup (optional for OpenAI-compatible endpoints that expose /models)",
    )
    .option("--install-daemon", "Install the gateway service during simple setup", false)
    .option("--no-start", "Do not start the gateway after simple setup")
    .option("--gateway-port <port>", "Gateway port for simple setup")
    .option("--no-skip-skills", "Keep skills enabled during simple setup")
    .option("--wizard", "Run the interactive onboarding wizard", false)
    .option("--non-interactive", "Run the wizard without prompts", false)
    .option("--mode <mode>", "Wizard mode: local|remote")
    .option("--remote-url <url>", "Remote Gateway WebSocket URL")
    .option("--remote-token <token>", "Remote Gateway token (optional)")
    .action(async (opts, command) => {
      await runCommandWithRuntime(defaultRuntime, async () => {
        const hasWizardFlags = hasExplicitOptions(command, [
          "wizard",
          "nonInteractive",
          "mode",
          "remoteUrl",
          "remoteToken",
        ]);
        const hasSimpleFlags = hasExplicitOptions(command, [
          "provider",
          "apiKey",
          "baseUrl",
          "model",
          "installDaemon",
          "start",
          "gatewayPort",
          "skipSkills",
        ]);
        if (opts.wizard || hasWizardFlags) {
          await onboardCommand(
            {
              workspace: opts.workspace as string | undefined,
              nonInteractive: Boolean(opts.nonInteractive),
              mode: opts.mode as "local" | "remote" | undefined,
              remoteUrl: opts.remoteUrl as string | undefined,
              remoteToken: opts.remoteToken as string | undefined,
            },
            defaultRuntime,
          );
          return;
        }
        await setupCommand(
          {
            workspace: opts.workspace as string | undefined,
            provider: opts.provider as
              | "openai"
              | "anthropic"
              | "openrouter"
              | "gemini"
              | "openai-compatible"
              | "anthropic-compatible"
              | undefined,
            apiKey: opts.apiKey as string | undefined,
            baseUrl: opts.baseUrl as string | undefined,
            model: opts.model as string | undefined,
            installDaemon: hasSimpleFlags ? Boolean(opts.installDaemon) : undefined,
            start: typeof opts.start === "boolean" ? opts.start : undefined,
            gatewayPort:
              typeof opts.gatewayPort === "string"
                ? Number.parseInt(opts.gatewayPort, 10)
                : undefined,
            skipSkills: typeof opts.skipSkills === "boolean" ? opts.skipSkills : undefined,
          },
          defaultRuntime,
        );
      });
    });
}

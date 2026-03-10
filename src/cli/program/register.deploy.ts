import type { Command } from "commander";
import { setupCommand } from "../../commands/setup.js";
import { defaultRuntime } from "../../runtime.js";
import { formatDocsLink } from "../../terminal/links.js";
import { theme } from "../../terminal/theme.js";
import { runCommandWithRuntime } from "../cli-utils.js";

export function registerDeployCommand(program: Command) {
  program
    .command("deploy")
    .description("One-click deployment: configure provider, start gateway, and verify health")
    .addHelpText(
      "after",
      () =>
        `\n${theme.muted("Docs:")} ${formatDocsLink("/cli/setup", "docs.haoclaw.ai/cli/setup")}\n`,
    )
    .requiredOption(
      "--provider <name>",
      "Provider: openai|anthropic|openrouter|gemini|openai-compatible|anthropic-compatible",
    )
    .option("--api-key <key>", "API key for deployment")
    .option("--base-url <url>", "Custom provider base URL")
    .option(
      "--model <id>",
      "Model id (optional for OpenAI-compatible endpoints that expose /models)",
    )
    .option("--workspace <dir>", "Agent workspace directory")
    .option("--gateway-port <port>", "Gateway port")
    .option("--no-skip-skills", "Keep skills enabled during deployment")
    .option("--no-daemon", "Do not install the gateway service")
    .option("--no-start", "Do not start the gateway after deployment")
    .action(async (opts) => {
      await runCommandWithRuntime(defaultRuntime, async () => {
        await setupCommand(
          {
            workspace: opts.workspace as string | undefined,
            provider: opts.provider as
              | "openai"
              | "anthropic"
              | "openrouter"
              | "gemini"
              | "openai-compatible"
              | "anthropic-compatible",
            apiKey: opts.apiKey as string | undefined,
            baseUrl: opts.baseUrl as string | undefined,
            model: opts.model as string | undefined,
            installDaemon: Boolean(opts.daemon),
            start: typeof opts.start === "boolean" ? opts.start : true,
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

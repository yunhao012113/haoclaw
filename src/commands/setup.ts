import { spawn } from "node:child_process";
import fs from "node:fs/promises";
import JSON5 from "json5";
import { DEFAULT_AGENT_WORKSPACE_DIR, ensureAgentWorkspace } from "../agents/workspace.js";
import { type HaoclawConfig, createConfigIO, writeConfigFile } from "../config/config.js";
import { formatConfigPath, logConfigUpdated } from "../config/logging.js";
import { resolveSessionTranscriptsDir } from "../config/sessions.js";
import type { RuntimeEnv } from "../runtime.js";
import { defaultRuntime } from "../runtime.js";
import { shortenHomePath } from "../utils.js";
import { healthCommand } from "./health.js";
import { probeGatewayReachable, resolveControlUiLinks, waitForGatewayReachable } from "./onboard-helpers.js";
import { runNonInteractiveOnboarding } from "./onboard-non-interactive.js";
import type { OnboardOptions } from "./onboard-types.js";

export type SimpleSetupProvider =
  | "openai"
  | "anthropic"
  | "openrouter"
  | "gemini"
  | "openai-compatible"
  | "anthropic-compatible";

export type SetupOptions = {
  workspace?: string;
  provider?: SimpleSetupProvider;
  apiKey?: string;
  baseUrl?: string;
  model?: string;
  installDaemon?: boolean;
  start?: boolean;
  gatewayPort?: number;
  skipSkills?: boolean;
};

async function readConfigFileRaw(configPath: string): Promise<{
  exists: boolean;
  parsed: HaoclawConfig;
}> {
  try {
    const raw = await fs.readFile(configPath, "utf-8");
    const parsed = JSON5.parse(raw);
    if (parsed && typeof parsed === "object") {
      return { exists: true, parsed: parsed as HaoclawConfig };
    }
    return { exists: true, parsed: {} };
  } catch {
    return { exists: false, parsed: {} };
  }
}

function hasSimpleSetupInputs(opts?: SetupOptions) {
  return Boolean(
    opts?.provider ||
      opts?.apiKey ||
      opts?.baseUrl ||
      opts?.model ||
      opts?.installDaemon ||
      opts?.gatewayPort !== undefined,
  );
}

function buildSimpleOnboardOptions(opts?: SetupOptions): OnboardOptions {
  const provider = opts?.provider?.trim() as SimpleSetupProvider | undefined;
  const apiKey = opts?.apiKey?.trim();
  const baseUrl = opts?.baseUrl?.trim();
  const model = opts?.model?.trim();
  const customProviderRequested =
    provider === "openai-compatible" ||
    provider === "anthropic-compatible" ||
    Boolean(baseUrl) ||
    Boolean(model);

  if (customProviderRequested && (!baseUrl || !model)) {
    throw new Error(
      "Simple setup with a custom API endpoint requires both --base-url and --model.",
    );
  }

  const onboardingOpts: OnboardOptions = {
    workspace: opts?.workspace,
    nonInteractive: true,
    acceptRisk: true,
    flow: "quickstart",
    mode: "local",
    skipChannels: true,
    skipSearch: true,
    skipUi: true,
    skipHealth: true,
    skipSkills: opts?.skipSkills ?? true,
    installDaemon: Boolean(opts?.installDaemon),
    gatewayPort: opts?.gatewayPort,
  };

  if (customProviderRequested) {
    onboardingOpts.authChoice = "custom-api-key";
    onboardingOpts.customBaseUrl = baseUrl;
    onboardingOpts.customModelId = model;
    onboardingOpts.customApiKey = apiKey;
    onboardingOpts.customCompatibility =
      provider === "anthropic-compatible" ? "anthropic" : "openai";
    return onboardingOpts;
  }

  switch (provider ?? "openai") {
    case "openai":
      onboardingOpts.authChoice = "openai-api-key";
      onboardingOpts.openaiApiKey = apiKey;
      break;
    case "anthropic":
      onboardingOpts.authChoice = "apiKey";
      onboardingOpts.anthropicApiKey = apiKey;
      break;
    case "openrouter":
      onboardingOpts.authChoice = "openrouter-api-key";
      onboardingOpts.openrouterApiKey = apiKey;
      break;
    case "gemini":
      onboardingOpts.authChoice = "gemini-api-key";
      onboardingOpts.geminiApiKey = apiKey;
      break;
    default:
      throw new Error(`Unsupported simple setup provider: ${provider}`);
  }

  return onboardingOpts;
}

function resolveGatewayAuth(cfg: HaoclawConfig): { token?: string; password?: string } {
  const auth = cfg.gateway?.auth;
  if (!auth || typeof auth !== "object") {
    return {};
  }
  if (auth.mode === "password" && typeof auth.password === "string" && auth.password.trim()) {
    return { password: auth.password.trim() };
  }
  if (auth.mode === "token" && typeof auth.token === "string" && auth.token.trim()) {
    return { token: auth.token.trim() };
  }
  return {};
}

async function ensureGatewayStarted(cfg: HaoclawConfig, runtime: RuntimeEnv) {
  const port =
    typeof cfg.gateway?.port === "number" && Number.isFinite(cfg.gateway.port)
      ? cfg.gateway.port
      : 18789;
  const bind =
    cfg.gateway?.bind === "auto" ||
    cfg.gateway?.bind === "lan" ||
    cfg.gateway?.bind === "loopback" ||
    cfg.gateway?.bind === "custom" ||
    cfg.gateway?.bind === "tailnet"
      ? cfg.gateway.bind
      : "loopback";
  const links = resolveControlUiLinks({
    port,
    bind,
    customBindHost: cfg.gateway?.customBindHost,
    basePath: undefined,
  });
  const auth = resolveGatewayAuth(cfg);
  const probe = await probeGatewayReachable({
    url: links.wsUrl,
    token: auth.token,
    password: auth.password,
    timeoutMs: 1500,
  });
  if (!probe.ok) {
    const entryPath = process.argv[1];
    if (!entryPath) {
      throw new Error("Unable to determine current Haoclaw entry script for gateway startup.");
    }
    const child = spawn(process.execPath, [entryPath, "gateway", "run"], {
      detached: true,
      stdio: "ignore",
      env: {
        ...process.env,
        HAOCLAW_NO_RESPAWN: process.env.HAOCLAW_NO_RESPAWN ?? "1",
      },
    });
    child.unref();
    runtime.log(`Gateway starting in background on port ${port}.`);
  } else {
    runtime.log(`Gateway already running on port ${port}.`);
  }

  const reachable = await waitForGatewayReachable({
    url: links.wsUrl,
    token: auth.token,
    password: auth.password,
    deadlineMs: 15_000,
  });
  if (!reachable.ok) {
    throw new Error(`Gateway did not become reachable: ${reachable.detail ?? "unknown error"}`);
  }
  await healthCommand({ json: false, timeoutMs: 10_000 }, runtime);
}

export async function setupCommand(opts?: SetupOptions, runtime: RuntimeEnv = defaultRuntime) {
  if (hasSimpleSetupInputs(opts)) {
    const onboardingOpts = buildSimpleOnboardOptions(opts);
    await runNonInteractiveOnboarding(onboardingOpts, runtime);
    if (opts?.start !== false) {
      const io = createConfigIO();
      const existingRaw = await readConfigFileRaw(io.configPath);
      await ensureGatewayStarted(existingRaw.parsed, runtime);
    }
    return;
  }

  const desiredWorkspace =
    typeof opts?.workspace === "string" && opts.workspace.trim()
      ? opts.workspace.trim()
      : undefined;

  const io = createConfigIO();
  const configPath = io.configPath;
  const existingRaw = await readConfigFileRaw(configPath);
  const cfg = existingRaw.parsed;
  const defaults = cfg.agents?.defaults ?? {};

  const workspace = desiredWorkspace ?? defaults.workspace ?? DEFAULT_AGENT_WORKSPACE_DIR;

  const next: HaoclawConfig = {
    ...cfg,
    agents: {
      ...cfg.agents,
      defaults: {
        ...defaults,
        workspace,
      },
    },
    gateway: {
      ...cfg.gateway,
      mode: cfg.gateway?.mode ?? "local",
    },
  };

  if (
    !existingRaw.exists ||
    defaults.workspace !== workspace ||
    cfg.gateway?.mode !== next.gateway?.mode
  ) {
    await writeConfigFile(next);
    if (!existingRaw.exists) {
      runtime.log(`Wrote ${formatConfigPath(configPath)}`);
    } else {
      const updates: string[] = [];
      if (defaults.workspace !== workspace) {
        updates.push("set agents.defaults.workspace");
      }
      if (cfg.gateway?.mode !== next.gateway?.mode) {
        updates.push("set gateway.mode");
      }
      const suffix = updates.length > 0 ? `(${updates.join(", ")})` : undefined;
      logConfigUpdated(runtime, { path: configPath, suffix });
    }
  } else {
    runtime.log(`Config OK: ${formatConfigPath(configPath)}`);
  }

  const ws = await ensureAgentWorkspace({
    dir: workspace,
    ensureBootstrapFiles: !next.agents?.defaults?.skipBootstrap,
  });
  runtime.log(`Workspace OK: ${shortenHomePath(ws.dir)}`);

  const sessionsDir = resolveSessionTranscriptsDir();
  await fs.mkdir(sessionsDir, { recursive: true });
  runtime.log(`Sessions OK: ${shortenHomePath(sessionsDir)}`);
}

import type { HaoclawConfig } from "../config/config.js";
import { loadHaoclawPlugins } from "../plugins/loader.js";
import { resolveUserPath } from "../utils.js";

export function ensureRuntimePluginsLoaded(params: {
  config?: HaoclawConfig;
  workspaceDir?: string | null;
}): void {
  const workspaceDir =
    typeof params.workspaceDir === "string" && params.workspaceDir.trim()
      ? resolveUserPath(params.workspaceDir)
      : undefined;

  loadHaoclawPlugins({
    config: params.config,
    workspaceDir,
  });
}

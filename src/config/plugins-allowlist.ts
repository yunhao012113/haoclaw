import type { HaoclawConfig } from "./config.js";

export function ensurePluginAllowlisted(cfg: HaoclawConfig, pluginId: string): HaoclawConfig {
  const allow = cfg.plugins?.allow;
  if (!Array.isArray(allow) || allow.includes(pluginId)) {
    return cfg;
  }
  return {
    ...cfg,
    plugins: {
      ...cfg.plugins,
      allow: [...allow, pluginId],
    },
  };
}

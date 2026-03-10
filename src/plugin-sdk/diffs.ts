// Narrow plugin-sdk surface for the bundled diffs plugin.
// Keep this list additive and scoped to symbols used under extensions/diffs.

export type { HaoclawConfig } from "../config/config.js";
export { resolvePreferredHaoclawTmpDir } from "../infra/tmp-haoclaw-dir.js";
export type {
  AnyAgentTool,
  HaoclawPluginApi,
  HaoclawPluginConfigSchema,
  PluginLogger,
} from "../plugins/types.js";

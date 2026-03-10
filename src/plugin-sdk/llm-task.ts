// Narrow plugin-sdk surface for the bundled llm-task plugin.
// Keep this list additive and scoped to symbols used under extensions/llm-task.

export { resolvePreferredHaoclawTmpDir } from "../infra/tmp-haoclaw-dir.js";
export type { AnyAgentTool, HaoclawPluginApi } from "../plugins/types.js";

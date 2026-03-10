import { createPluginRuntimeStore } from "haoclaw/plugin-sdk/compat";
import type { PluginRuntime } from "haoclaw/plugin-sdk/discord";

const { setRuntime: setDiscordRuntime, getRuntime: getDiscordRuntime } =
  createPluginRuntimeStore<PluginRuntime>("Discord runtime not initialized");
export { getDiscordRuntime, setDiscordRuntime };

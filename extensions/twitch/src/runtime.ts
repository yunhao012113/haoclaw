import { createPluginRuntimeStore } from "haoclaw/plugin-sdk/compat";
import type { PluginRuntime } from "haoclaw/plugin-sdk/twitch";

const { setRuntime: setTwitchRuntime, getRuntime: getTwitchRuntime } =
  createPluginRuntimeStore<PluginRuntime>("Twitch runtime not initialized");
export { getTwitchRuntime, setTwitchRuntime };

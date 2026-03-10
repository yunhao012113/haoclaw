import { createPluginRuntimeStore } from "haoclaw/plugin-sdk/compat";
import type { PluginRuntime } from "haoclaw/plugin-sdk/imessage";

const { setRuntime: setIMessageRuntime, getRuntime: getIMessageRuntime } =
  createPluginRuntimeStore<PluginRuntime>("iMessage runtime not initialized");
export { getIMessageRuntime, setIMessageRuntime };

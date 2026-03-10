import { createPluginRuntimeStore } from "haoclaw/plugin-sdk/compat";
import type { PluginRuntime } from "haoclaw/plugin-sdk/zalo";

const { setRuntime: setZaloRuntime, getRuntime: getZaloRuntime } =
  createPluginRuntimeStore<PluginRuntime>("Zalo runtime not initialized");
export { getZaloRuntime, setZaloRuntime };

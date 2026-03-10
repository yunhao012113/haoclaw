import type { HaoclawPluginApi } from "haoclaw/plugin-sdk/googlechat";
import { emptyPluginConfigSchema } from "haoclaw/plugin-sdk/googlechat";
import { googlechatDock, googlechatPlugin } from "./src/channel.js";
import { setGoogleChatRuntime } from "./src/runtime.js";

const plugin = {
  id: "googlechat",
  name: "Google Chat",
  description: "Haoclaw Google Chat channel plugin",
  configSchema: emptyPluginConfigSchema(),
  register(api: HaoclawPluginApi) {
    setGoogleChatRuntime(api.runtime);
    api.registerChannel({ plugin: googlechatPlugin, dock: googlechatDock });
  },
};

export default plugin;

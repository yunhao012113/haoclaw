import type { HaoclawPluginApi } from "haoclaw/plugin-sdk/synology-chat";
import { emptyPluginConfigSchema } from "haoclaw/plugin-sdk/synology-chat";
import { createSynologyChatPlugin } from "./src/channel.js";
import { setSynologyRuntime } from "./src/runtime.js";

const plugin = {
  id: "synology-chat",
  name: "Synology Chat",
  description: "Native Synology Chat channel plugin for Haoclaw",
  configSchema: emptyPluginConfigSchema(),
  register(api: HaoclawPluginApi) {
    setSynologyRuntime(api.runtime);
    api.registerChannel({ plugin: createSynologyChatPlugin() });
  },
};

export default plugin;

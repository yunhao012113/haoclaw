const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("haoclawDesktop", {
  platform: "windows",
  mode: "desktop",
  defaultLocale: "zh-CN",
  defaultTab: "overview",
  defaultGatewayUrl: "http://127.0.0.1:18789",
  listBundledSkills: () => ipcRenderer.invoke("haoclaw:list-bundled-skills"),
});

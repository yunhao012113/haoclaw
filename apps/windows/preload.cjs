const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("haoclawDesktop", {
  platform: "windows",
  mode: "desktop",
  defaultLocale: "zh-CN",
  defaultTab: "chat",
  defaultGatewayUrl: "http://127.0.0.1:3456",
  listBundledSkills: () => ipcRenderer.invoke("haoclaw:list-bundled-skills"),
});

const { contextBridge } = require("electron");

contextBridge.exposeInMainWorld("haoclawDesktop", {
  platform: "windows",
  mode: "desktop",
  defaultLocale: "zh-CN",
  defaultTab: "overview",
  defaultGatewayUrl: "http://127.0.0.1:18789",
});

const { contextBridge } = require("electron");

contextBridge.exposeInMainWorld("haoclawDesktop", {
  platform: "windows",
  defaultGatewayUrl: "http://127.0.0.1:18789",
});

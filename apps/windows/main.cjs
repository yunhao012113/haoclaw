const path = require("node:path");
const fs = require("node:fs");
const { app, BrowserWindow, shell } = require("electron");

const PRODUCT_NAME = "Haoclaw";

function resolveUiEntry() {
  const candidates = app.isPackaged
    ? [path.join(process.resourcesPath, "control-ui", "index.html")]
    : [
        path.resolve(__dirname, "..", "..", "dist", "control-ui", "index.html"),
        path.resolve(__dirname, "..", "..", "ui", "dist", "index.html"),
      ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  throw new Error(`Missing Control UI build. Looked in: ${candidates.join(", ")}`);
}

function createMainWindow() {
  const window = new BrowserWindow({
    width: 1440,
    height: 920,
    minWidth: 1180,
    minHeight: 760,
    title: PRODUCT_NAME,
    autoHideMenuBar: true,
    backgroundColor: "#f4f1eb",
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      preload: path.join(__dirname, "preload.cjs"),
    },
  });

  window.webContents.setWindowOpenHandler(({ url }) => {
    void shell.openExternal(url);
    return { action: "deny" };
  });

  window.webContents.on("will-navigate", (event, url) => {
    if (url.startsWith("file://")) {
      return;
    }
    event.preventDefault();
    void shell.openExternal(url);
  });

  const uiEntry = resolveUiEntry();
  void window.loadFile(uiEntry);
  return window;
}

app.whenReady().then(() => {
  createMainWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

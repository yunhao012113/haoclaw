const path = require("node:path");
const fs = require("node:fs");
const os = require("node:os");
const { pipeline } = require("node:stream/promises");
const { Readable } = require("node:stream");
const { app, BrowserWindow, Menu, dialog, shell } = require("electron");

const PRODUCT_NAME = "Haoclaw";
const RELEASES_API = "https://api.github.com/repos/yunhao012113/haoclaw/releases/latest";
const RELEASES_PAGE = "https://github.com/yunhao012113/haoclaw/releases/latest";
let updateCheckRunning = false;

function normalizeVersion(raw) {
  return String(raw || "").replace(/^[vV]/, "").trim();
}

function compareVersions(left, right) {
  const leftParts = normalizeVersion(left).split(/[^0-9]+/).filter(Boolean).map(Number);
  const rightParts = normalizeVersion(right).split(/[^0-9]+/).filter(Boolean).map(Number);
  const count = Math.max(leftParts.length, rightParts.length);

  for (let index = 0; index < count; index += 1) {
    const lhs = leftParts[index] ?? 0;
    const rhs = rightParts[index] ?? 0;
    if (lhs > rhs) {return 1;}
    if (lhs < rhs) {return -1;}
  }
  return 0;
}

function currentVersion() {
  return app.getVersion();
}

async function fetchLatestRelease() {
  const response = await fetch(RELEASES_API, {
    headers: {
      Accept: "application/vnd.github+json",
      "User-Agent": `${PRODUCT_NAME}/${currentVersion()}`,
    },
  });
  if (!response.ok) {
    throw new Error(`GitHub API ${response.status}`);
  }

  return response.json();
}

function chooseWindowsInstaller(release) {
  return (release.assets || []).find((asset) => asset.name.endsWith("-setup.exe")) ?? null;
}

async function downloadInstaller(asset) {
  const response = await fetch(asset.browser_download_url, {
    headers: {
      Accept: "application/octet-stream",
      "User-Agent": `${PRODUCT_NAME}/${currentVersion()}`,
    },
  });
  if (!response.ok || !response.body) {
    throw new Error("安装包下载失败");
  }

  const downloadsDir = app.getPath("downloads") || path.join(os.homedir(), "Downloads");
  const destination = path.join(downloadsDir, asset.name);
  const tempPath = `${destination}.download`;

  try {
    fs.rmSync(tempPath, { force: true });
  } catch {}
  try {
    fs.rmSync(destination, { force: true });
  } catch {}

  await pipeline(Readable.fromWeb(response.body), fs.createWriteStream(tempPath));
  fs.renameSync(tempPath, destination);

  const openResult = await shell.openPath(destination);
  if (openResult) {
    throw new Error(openResult);
  }

  return destination;
}

async function checkForUpdates({ manual = false } = {}) {
  if (updateCheckRunning) {
    return;
  }
  updateCheckRunning = true;

  try {
    const release = await fetchLatestRelease();
    const latestVersion = normalizeVersion(release.tag_name);
    const installer = chooseWindowsInstaller(release);

    if (compareVersions(latestVersion, currentVersion()) <= 0 || !installer) {
      if (manual) {
        await dialog.showMessageBox({
          type: "info",
          title: "Haoclaw",
          message: "当前已经是最新版本。",
        });
      }
      return;
    }

    const result = await dialog.showMessageBox({
      type: "info",
      title: "发现新版本",
      message: `发现 Haoclaw ${latestVersion}`,
      detail: "是否立即下载并打开安装包？",
      buttons: ["立即更新", "稍后"],
      cancelId: 1,
      defaultId: 0,
    });

    if (result.response === 0) {
      const installerPath = await downloadInstaller(installer);
      await dialog.showMessageBox({
        type: "info",
        title: "安装包已打开",
        message: "请按安装向导完成更新。",
        detail: installerPath,
      });
    }
  } catch (error) {
    if (manual) {
      await dialog.showMessageBox({
        type: "error",
        title: "检查更新失败",
        message: "无法获取最新版本信息。",
        detail: error instanceof Error ? error.message : String(error),
      });
    }
  } finally {
    updateCheckRunning = false;
  }
}

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

function buildApplicationMenu() {
  const template = [
    {
      label: "Haoclaw",
      submenu: [
        {
          label: "检查更新",
          click: () => {
            void checkForUpdates({ manual: true });
          },
        },
        {
          label: "下载页",
          click: () => {
            void shell.openExternal(RELEASES_PAGE);
          },
        },
        { type: "separator" },
        {
          label: "退出",
          role: "quit",
        },
      ],
    },
    {
      label: "窗口",
      submenu: [
        { role: "reload", label: "重新加载" },
        { role: "toggledevtools", label: "开发者工具" },
        { type: "separator" },
        { role: "minimize", label: "最小化" },
        { role: "close", label: "关闭窗口" },
      ],
    },
  ];

  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

app.whenReady().then(() => {
  buildApplicationMenu();
  createMainWindow();
  void checkForUpdates({ manual: false });

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

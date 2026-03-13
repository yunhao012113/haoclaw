const path = require("node:path");
const fs = require("node:fs");
const os = require("node:os");
const { pipeline } = require("node:stream/promises");
const { Readable } = require("node:stream");
const { spawn } = require("node:child_process");
const { app, BrowserWindow, Menu, dialog, shell, ipcMain } = require("electron");

const PRODUCT_NAME = "Haoclaw";
const RELEASES_API = "https://api.github.com/repos/yunhao012113/haoclaw/releases?per_page=12";
const RELEASES_PAGE = "https://github.com/yunhao012113/haoclaw/releases/latest";
let updateCheckRunning = false;
const FALLBACK_SKILL_KEYS = [
  "1password",
  "agent-browser",
  "apple-notes",
  "apple-reminders",
  "bear-notes",
  "blogwatcher",
  "blucli",
  "bluebubbles",
  "camsnap",
  "canvas",
  "clawhub",
  "coding-agent",
  "discord",
  "eightctl",
  "gemini",
  "gh-issues",
  "gifgrep",
  "github",
  "gog",
  "goplaces",
  "healthcheck",
  "himalaya",
  "imsg",
  "mcporter",
  "model-usage",
  "nano-banana-pro",
  "nano-pdf",
  "notion",
  "obsidian",
  "openai-image-gen",
  "openai-whisper",
  "openai-whisper-api",
  "openhue",
  "oracle",
  "ordercli",
  "peekaboo",
  "sag",
  "session-logs",
  "sherpa-onnx-tts",
  "skill-creator",
  "slack",
  "songsee",
  "sonoscli",
  "spotify-player",
  "summarize",
  "things-mac",
  "tmux",
  "trello",
  "video-frames",
  "voice-call",
  "wacli",
  "weather",
  "xurl",
];

function parseSkillDescription(skillMarkdown) {
  const lines = String(skillMarkdown || "").split(/\r?\n/);
  let inFrontMatter = false;
  let frontMatterSeen = false;
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (line === "---") {
      if (!frontMatterSeen) {
        frontMatterSeen = true;
        inFrontMatter = true;
        continue;
      }
      if (inFrontMatter) {
        inFrontMatter = false;
        continue;
      }
    }
    if (!line || line.startsWith("#") || line.startsWith("-")) {
      continue;
    }
    if (line.toLowerCase().startsWith("description:")) {
      const value = line.slice("description:".length).trim();
      if (value) {
        return value;
      }
      continue;
    }
    return line;
  }
  return "内置技能";
}

function resolveBundledSkillsDirs() {
  const managedSkillsDir = path.join(os.homedir(), ".haoclaw", "skills");
  const dirs = app.isPackaged
    ? [managedSkillsDir, path.join(process.resourcesPath, "skills")]
    : [
        managedSkillsDir,
        path.resolve(__dirname, "..", "..", "skills"),
        path.join(process.resourcesPath, "skills"),
      ];
  return dirs.filter((dir, index) => dirs.indexOf(dir) === index && fs.existsSync(dir));
}

function listBundledSkills() {
  const skills = [];
  const seen = new Set();
  for (const root of resolveBundledSkillsDirs()) {
    const entries = fs.readdirSync(root, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory() || entry.name.startsWith(".")) {
        continue;
      }
      const key = entry.name.trim();
      if (!key || seen.has(key)) {
        continue;
      }
      const skillFile = path.join(root, entry.name, "SKILL.md");
      if (!fs.existsSync(skillFile)) {
        continue;
      }
      const markdown = fs.readFileSync(skillFile, "utf8");
      skills.push({
        name: key,
        skillKey: key,
        description: parseSkillDescription(markdown),
        source: "haoclaw-bundled",
        filePath: skillFile,
        baseDir: root,
      });
      seen.add(key);
    }
  }
  if (skills.length === 0) {
    const managedRoot = path.join(os.homedir(), ".haoclaw", "skills");
    for (const key of FALLBACK_SKILL_KEYS) {
      skills.push({
        name: key,
        skillKey: key,
        description: "Haoclaw 预装技能",
        source: "haoclaw-bundled",
        filePath: path.join(managedRoot, key, "SKILL.md"),
        baseDir: managedRoot,
      });
    }
  }
  skills.sort((a, b) => a.name.localeCompare(b.name));
  return skills;
}

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

function isUnifiedDesktopRelease(release) {
  const assets = release?.assets || [];
  return (
    assets.some((asset) => asset.name.endsWith(".pkg")) &&
    assets.some((asset) => asset.name.endsWith("-setup.exe"))
  );
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

  const releases = await response.json();
  return releases.find(isUnifiedDesktopRelease) ?? null;
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

function launchSilentInstaller(installerPath) {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "haoclaw-update-"));
  const scriptPath = path.join(tempDir, "upgrade.cmd");
  const pid = process.pid;
  const installedExe = path.join(process.env.LOCALAPPDATA || "", "Programs", PRODUCT_NAME, `${PRODUCT_NAME}.exe`);

  const script = [
    "@echo off",
    "setlocal",
    `set PID=${pid}`,
    `set INSTALLER=${JSON.stringify(installerPath)}`,
    `set APP_EXE=${JSON.stringify(installedExe)}`,
    ":waitloop",
    'tasklist /FI "PID eq %PID%" | find "%PID%" >nul',
    "if %ERRORLEVEL%==0 (",
    "  timeout /t 1 /nobreak >nul",
    "  goto waitloop",
    ")",
    'start /wait "" %INSTALLER% /S',
    "if exist %APP_EXE% start \"\" %APP_EXE%",
    "del \"%~f0\"",
  ].join("\r\n");

  fs.writeFileSync(scriptPath, script, "utf8");
  spawn("cmd.exe", ["/c", scriptPath], {
    detached: true,
    stdio: "ignore",
    windowsHide: true,
  }).unref();
}

async function checkForUpdates({ manual = false } = {}) {
  if (updateCheckRunning) {
    return;
  }
  updateCheckRunning = true;

  try {
    const release = await fetchLatestRelease();
    if (!release) {
      return { available: false, reason: "未找到同时包含 mac 和 Windows 安装包的统一版本" };
    }

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
      launchSilentInstaller(installerPath);
      app.quit();
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

  throw new Error(`未找到桌面界面构建产物，已检查路径：${candidates.join(", ")}`);
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

void app.whenReady().then(() => {
  ipcMain.handle("haoclaw:list-bundled-skills", () => listBundledSkills());
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

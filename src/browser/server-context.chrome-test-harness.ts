import { vi } from "vitest";
import { installChromeUserDataDirHooks } from "./chrome-user-data-dir.test-harness.js";

const chromeUserDataDir = { dir: "/tmp/haoclaw" };
installChromeUserDataDirHooks(chromeUserDataDir);

vi.mock("./chrome.js", () => ({
  isChromeCdpReady: vi.fn(async () => true),
  isChromeReachable: vi.fn(async () => true),
  launchHaoclawChrome: vi.fn(async () => {
    throw new Error("unexpected launch");
  }),
  resolveHaoclawUserDataDir: vi.fn(() => chromeUserDataDir.dir),
  stopHaoclawChrome: vi.fn(async () => {}),
}));

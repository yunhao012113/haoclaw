import { describe, expect, it } from "vitest";
import { buildPlatformRuntimeLogHints, buildPlatformServiceStartHints } from "./runtime-hints.js";

describe("buildPlatformRuntimeLogHints", () => {
  it("renders launchd log hints on darwin", () => {
    expect(
      buildPlatformRuntimeLogHints({
        platform: "darwin",
        env: {
          HAOCLAW_STATE_DIR: "/tmp/haoclaw-state",
          HAOCLAW_LOG_PREFIX: "gateway",
        },
        systemdServiceName: "haoclaw-gateway",
        windowsTaskName: "Haoclaw Gateway",
      }),
    ).toEqual([
      "Launchd stdout (if installed): /tmp/haoclaw-state/logs/gateway.log",
      "Launchd stderr (if installed): /tmp/haoclaw-state/logs/gateway.err.log",
    ]);
  });

  it("renders systemd and windows hints by platform", () => {
    expect(
      buildPlatformRuntimeLogHints({
        platform: "linux",
        systemdServiceName: "haoclaw-gateway",
        windowsTaskName: "Haoclaw Gateway",
      }),
    ).toEqual(["Logs: journalctl --user -u haoclaw-gateway.service -n 200 --no-pager"]);
    expect(
      buildPlatformRuntimeLogHints({
        platform: "win32",
        systemdServiceName: "haoclaw-gateway",
        windowsTaskName: "Haoclaw Gateway",
      }),
    ).toEqual(['Logs: schtasks /Query /TN "Haoclaw Gateway" /V /FO LIST']);
  });
});

describe("buildPlatformServiceStartHints", () => {
  it("builds platform-specific service start hints", () => {
    expect(
      buildPlatformServiceStartHints({
        platform: "darwin",
        installCommand: "haoclaw gateway install",
        startCommand: "haoclaw gateway",
        launchAgentPlistPath: "~/Library/LaunchAgents/com.haoclaw.gateway.plist",
        systemdServiceName: "haoclaw-gateway",
        windowsTaskName: "Haoclaw Gateway",
      }),
    ).toEqual([
      "haoclaw gateway install",
      "haoclaw gateway",
      "launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.haoclaw.gateway.plist",
    ]);
    expect(
      buildPlatformServiceStartHints({
        platform: "linux",
        installCommand: "haoclaw gateway install",
        startCommand: "haoclaw gateway",
        launchAgentPlistPath: "~/Library/LaunchAgents/com.haoclaw.gateway.plist",
        systemdServiceName: "haoclaw-gateway",
        windowsTaskName: "Haoclaw Gateway",
      }),
    ).toEqual([
      "haoclaw gateway install",
      "haoclaw gateway",
      "systemctl --user start haoclaw-gateway.service",
    ]);
  });
});

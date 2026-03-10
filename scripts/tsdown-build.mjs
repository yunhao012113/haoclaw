#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const logLevel = process.env.HAOCLAW_BUILD_VERBOSE ? "info" : "warn";
const localTsdownEntry = path.resolve(
  "node_modules",
  "tsdown",
  "dist",
  "run.mjs",
);
const hasLocalTsdown = fs.existsSync(localTsdownEntry);
const command = hasLocalTsdown ? process.execPath : "pnpm";
const args = hasLocalTsdown
  ? [localTsdownEntry, "--config-loader", "unrun", "--logLevel", logLevel]
  : ["exec", "tsdown", "--config-loader", "unrun", "--logLevel", logLevel];
const result = spawnSync(command, args, {
  stdio: "inherit",
  shell: !hasLocalTsdown && process.platform === "win32",
});

if (typeof result.status === "number") {
  process.exit(result.status);
}

process.exit(1);

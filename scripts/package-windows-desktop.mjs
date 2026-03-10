#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(here, "..");
const windowsAppDir = path.join(rootDir, "apps", "windows");

function run(cmd, args, cwd = rootDir) {
  const result = spawnSync(cmd, args, {
    cwd,
    stdio: "inherit",
    shell: process.platform === "win32",
    env: process.env,
  });
  if ((result.status ?? 1) !== 0) {
    process.exit(result.status ?? 1);
  }
}

if (process.platform !== "win32") {
  console.error("Windows desktop packaging must run on Windows.");
  process.exit(1);
}

run(process.execPath, ["scripts/ui.js", "build"]);
run("pnpm", ["install", "--no-frozen-lockfile"], windowsAppDir);
run("pnpm", ["run", "dist"], windowsAppDir);

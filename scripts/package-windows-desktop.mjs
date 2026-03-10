#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(here, "..");
const windowsAppDir = path.join(rootDir, "apps", "windows");
const uiDir = path.join(rootDir, "ui");
const releaseVersion = process.env.HAOCLAW_DESKTOP_VERSION?.trim();

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

if (releaseVersion) {
  const packageJsonPath = path.join(windowsAppDir, "package.json");
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
  if (packageJson.version !== releaseVersion) {
    packageJson.version = releaseVersion;
    fs.writeFileSync(packageJsonPath, `${JSON.stringify(packageJson, null, 2)}\n`);
  }
}

run("pnpm", ["install", "--ignore-workspace", "--no-frozen-lockfile"], uiDir);
run("pnpm", ["run", "build"], uiDir);
run("pnpm", ["install", "--ignore-workspace", "--no-frozen-lockfile"], windowsAppDir);
run("pnpm", ["run", "dist"], windowsAppDir);

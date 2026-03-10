import fs from "node:fs/promises";
import path from "node:path";
import { describe, expect, it } from "vitest";
import { createTempHomeEnv } from "./temp-home.js";

describe("createTempHomeEnv", () => {
  it("sets home env vars and restores them on cleanup", async () => {
    const previousHome = process.env.HOME;
    const previousUserProfile = process.env.USERPROFILE;
    const previousStateDir = process.env.HAOCLAW_STATE_DIR;

    const tempHome = await createTempHomeEnv("haoclaw-temp-home-");
    expect(process.env.HOME).toBe(tempHome.home);
    expect(process.env.USERPROFILE).toBe(tempHome.home);
    expect(process.env.HAOCLAW_STATE_DIR).toBe(path.join(tempHome.home, ".haoclaw"));
    await expect(fs.stat(tempHome.home)).resolves.toMatchObject({
      isDirectory: expect.any(Function),
    });

    await tempHome.restore();

    expect(process.env.HOME).toBe(previousHome);
    expect(process.env.USERPROFILE).toBe(previousUserProfile);
    expect(process.env.HAOCLAW_STATE_DIR).toBe(previousStateDir);
    await expect(fs.stat(tempHome.home)).rejects.toThrow();
  });
});

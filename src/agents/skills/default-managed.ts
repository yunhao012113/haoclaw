import fs from "node:fs";
import path from "node:path";

function copyDir(sourceDir: string, targetDir: string) {
  fs.mkdirSync(targetDir, { recursive: true });
  for (const entry of fs.readdirSync(sourceDir, { withFileTypes: true })) {
    const sourcePath = path.join(sourceDir, entry.name);
    const targetPath = path.join(targetDir, entry.name);
    if (entry.isDirectory()) {
      copyDir(sourcePath, targetPath);
      continue;
    }
    if (entry.isSymbolicLink()) {
      const linkTarget = fs.readlinkSync(sourcePath);
      try {
        fs.unlinkSync(targetPath);
      } catch {}
      fs.symlinkSync(linkTarget, targetPath);
      continue;
    }
    fs.copyFileSync(sourcePath, targetPath);
  }
}

export function ensureDefaultManagedSkills(params: {
  managedSkillsDir: string;
  bundledSkillsDir?: string;
}): string[] {
  const { managedSkillsDir, bundledSkillsDir } = params;
  if (!bundledSkillsDir || !fs.existsSync(bundledSkillsDir)) {
    return [];
  }

  fs.mkdirSync(managedSkillsDir, { recursive: true });

  const skillNames = fs
    .readdirSync(bundledSkillsDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith("."))
    .map((entry) => entry.name)
    .sort((left, right) => left.localeCompare(right));

  const copied: string[] = [];
  for (const skillName of skillNames) {
    const sourceDir = path.join(bundledSkillsDir, skillName);
    const sourceSkill = path.join(sourceDir, "SKILL.md");
    if (!fs.existsSync(sourceSkill)) {
      continue;
    }
    const targetDir = path.join(managedSkillsDir, skillName);
    const targetSkill = path.join(targetDir, "SKILL.md");
    if (fs.existsSync(targetSkill)) {
      continue;
    }
    copyDir(sourceDir, targetDir);
    copied.push(skillName);
  }

  return copied;
}

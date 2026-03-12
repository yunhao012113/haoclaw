import { html, nothing } from "lit";
import type { SkillStatusEntry } from "../types.ts";

export function computeSkillMissing(skill: SkillStatusEntry): string[] {
  return [
    ...skill.missing.bins.map((b) => `bin:${b}`),
    ...skill.missing.env.map((e) => `env:${e}`),
    ...skill.missing.config.map((c) => `config:${c}`),
    ...skill.missing.os.map((o) => `os:${o}`),
  ];
}

export function computeSkillReasons(skill: SkillStatusEntry): string[] {
  const reasons: string[] = [];
  if (skill.disabled) {
    reasons.push("已禁用");
  }
  if (skill.blockedByAllowlist) {
    reasons.push("被白名单限制");
  }
  return reasons;
}

function resolveSkillSourceLabel(source: string): string {
  switch (source) {
    case "haoclaw-bundled":
    case "haoclaw-managed":
      return "后台目录";
    case "haoclaw-workspace":
      return "工作区";
    case "haoclaw-extra":
      return "扩展目录";
    default:
      return source;
  }
}

export function renderSkillStatusChips(params: {
  skill: SkillStatusEntry;
  showBundledBadge?: boolean;
}) {
  const skill = params.skill;
  const showBundledBadge = Boolean(params.showBundledBadge);
  return html`
    <div class="chip-row" style="margin-top: 6px;">
      <span class="chip">${resolveSkillSourceLabel(skill.source)}</span>
      ${
        showBundledBadge
          ? html`
              <span class="chip">后台托管</span>
            `
          : nothing
      }
      <span class="chip ${skill.eligible ? "chip-ok" : "chip-warn"}">
        ${skill.eligible ? "可用" : "受限"}
      </span>
      ${
        skill.disabled
          ? html`
              <span class="chip chip-warn">已禁用</span>
            `
          : nothing
      }
      ${
        skill.source === "haoclaw-bundled" || skill.source === "haoclaw-managed"
          ? html`
              <span class="chip">按需启用</span>
            `
          : nothing
      }
    </div>
  `;
}

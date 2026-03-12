import { html, nothing } from "lit";
import type { SkillMessageMap } from "../controllers/skills.ts";
import { clampText } from "../format.ts";
import type { SkillStatusEntry, SkillStatusReport } from "../types.ts";
import { groupSkills } from "./skills-grouping.ts";
import {
  computeSkillMissing,
  computeSkillReasons,
  renderSkillStatusChips,
} from "./skills-shared.ts";

export type SkillsProps = {
  loading: boolean;
  report: SkillStatusReport | null;
  error: string | null;
  filter: string;
  edits: Record<string, string>;
  busyKey: string | null;
  messages: SkillMessageMap;
  onFilterChange: (next: string) => void;
  onRefresh: () => void;
  onToggle: (skillKey: string, enabled: boolean) => void;
  onEdit: (skillKey: string, value: string) => void;
  onSaveKey: (skillKey: string) => void;
  onInstall: (skillKey: string, name: string, installId: string) => void;
};

const LOCALIZED_SUMMARIES: Record<string, string> = {
  "1password": "用于 1Password CLI 的登录、读取和密钥注入辅助。",
  "agent-browser": "用于浏览器自动化、页面点击、截图和元素读取。",
  "apple-notes": "用于读写 Apple Notes 备忘录内容。",
  "apple-reminders": "用于管理 Apple 提醒事项。",
  "bear-notes": "用于 Bear 笔记的读取、创建和整理。",
  blogwatcher: "用于订阅博客更新并整理新增内容。",
  blucli: "用于蓝牙设备和蓝牙状态操作。",
  bluebubbles: "用于 BlueBubbles / iMessage 相关联动。",
  camsnap: "用于摄像头拍照与图像采集。",
  canvas: "用于桌面画布、截图和可视化产出。",
  clawhub: "用于连接技能市场或技能仓库。",
  "coding-agent": "用于代码任务、补丁编写和工程辅助。",
  discord: "用于 Discord 渠道接入和消息操作。",
  gemini: "用于 Gemini 系列模型与工具联动。",
  github: "用于 GitHub 仓库、PR 和提交管理。",
  notion: "用于 Notion 页面和数据库操作。",
  obsidian: "用于 Obsidian 笔记库读写。",
  slack: "用于 Slack 渠道接入和消息收发。",
  summarize: "用于网页、文档或对话摘要。",
  telegram: "用于 Telegram 渠道接入和消息联动。",
  trello: "用于 Trello 看板操作。",
  weather: "用于天气查询。",
  whatsapp: "用于 WhatsApp 渠道接入和消息操作。",
};

function containsChinese(text: string): boolean {
  return /\p{Script=Han}/u.test(text);
}

function localizedSkillDescription(skill: SkillStatusEntry): string {
  const raw = skill.description.trim();
  if (!raw) {
    return LOCALIZED_SUMMARIES[skill.skillKey] ?? "用于后台技能扩展。";
  }
  if (containsChinese(raw)) {
    return raw;
  }
  const localized = LOCALIZED_SUMMARIES[skill.skillKey] ?? `用于 ${skill.name} 的后台技能扩展。`;
  return `${raw}\n中文：${localized}`;
}

export function renderSkills(props: SkillsProps) {
  const skills = props.report?.skills ?? [];
  const filter = props.filter.trim().toLowerCase();
  const filtered = filter
    ? skills.filter((skill) =>
        [skill.name, skill.description, skill.source].join(" ").toLowerCase().includes(filter),
      )
    : skills;
  const groups = groupSkills(filtered);

  return html`
    <section class="card">
      <div class="row" style="justify-content: space-between;">
        <div>
          <div class="card-title">技能库</div>
          <div class="card-sub">查看后台目录、扩展目录和工作区技能，按需启用即可。</div>
        </div>
        <button class="btn" ?disabled=${props.loading} @click=${props.onRefresh}>
          ${props.loading ? "加载中…" : "刷新"}
        </button>
      </div>

      <div class="filters" style="margin-top: 14px;">
        <label class="field" style="flex: 1;">
          <span>筛选</span>
          <input
            .value=${props.filter}
            @input=${(e: Event) => props.onFilterChange((e.target as HTMLInputElement).value)}
            placeholder="搜索技能"
          />
        </label>
        <div class="muted">显示 ${filtered.length} 个</div>
      </div>

      ${
        props.error
          ? html`<div class="callout danger" style="margin-top: 12px;">${props.error}</div>`
          : nothing
      }

      ${
        filtered.length === 0
          ? html`
              <div class="muted" style="margin-top: 16px">没有找到匹配的技能。</div>
            `
          : html`
            <div class="agent-skills-groups" style="margin-top: 16px;">
              ${groups.map((group) => {
                const collapsedByDefault = group.id === "workspace" || group.id === "built-in";
                return html`
                  <details class="agent-skills-group" ?open=${!collapsedByDefault}>
                    <summary class="agent-skills-header">
                      <span>${group.label}</span>
                      <span class="muted">${group.skills.length}</span>
                    </summary>
                    <div class="list skills-grid">
                      ${group.skills.map((skill) => renderSkill(skill, props))}
                    </div>
                  </details>
                `;
              })}
            </div>
          `
      }
    </section>
  `;
}

function renderSkill(skill: SkillStatusEntry, props: SkillsProps) {
  const busy = props.busyKey === skill.skillKey;
  const apiKey = props.edits[skill.skillKey] ?? "";
  const message = props.messages[skill.skillKey] ?? null;
  const showBundledBadge = Boolean(skill.bundled && skill.source !== "haoclaw-bundled");
  const missing = computeSkillMissing(skill);
  const reasons = computeSkillReasons(skill);
  const description = localizedSkillDescription(skill);
  return html`
    <div class="list-item">
      <div class="list-main">
        <div class="list-title">
          ${skill.emoji ? `${skill.emoji} ` : ""}${skill.name}
        </div>
        <div class="list-sub">${clampText(description, 200)}</div>
        ${renderSkillStatusChips({ skill, showBundledBadge })}
        ${
          missing.length > 0
            ? html`
              <div class="muted" style="margin-top: 6px;">
                缺少项：${missing.join(", ")}
              </div>
            `
            : nothing
        }
        ${
          reasons.length > 0
            ? html`
              <div class="muted" style="margin-top: 6px;">
                原因：${reasons.join(", ")}
              </div>
            `
            : nothing
        }
      </div>
      <div class="list-meta">
        <div class="row" style="justify-content: flex-end; flex-wrap: wrap;">
          <button
            class="btn"
            ?disabled=${busy}
            @click=${() => props.onToggle(skill.skillKey, skill.disabled)}
          >
            ${skill.disabled ? "启用" : "禁用"}
          </button>
          ${
            skill.install.length > 0 && skill.missing.bins.length > 0
              ? html`
                  <span class="chip">需用户自行安装</span>
                  ${
                    skill.homepage
                      ? html`
                          <a
                            class="btn"
                            href=${skill.homepage}
                            target="_blank"
                            rel="noopener noreferrer"
                          >
                            打开安装说明
                          </a>
                        `
                      : nothing
                  }
                `
              : nothing
          }
        </div>
        ${
          message
            ? html`<div
              class="muted"
              style="margin-top: 8px; color: ${
                message.kind === "error"
                  ? "var(--danger-color, #d14343)"
                  : "var(--success-color, #0a7f5a)"
              };"
            >
              ${message.message}
            </div>`
            : nothing
        }
        ${
          skill.primaryEnv
            ? html`
              <div class="field" style="margin-top: 10px;">
                <span>接口密钥</span>
                <input
                  type="password"
                  .value=${apiKey}
                  @input=${(e: Event) =>
                    props.onEdit(skill.skillKey, (e.target as HTMLInputElement).value)}
                />
              </div>
              <button
                class="btn primary"
                style="margin-top: 8px;"
                ?disabled=${busy}
                @click=${() => props.onSaveKey(skill.skillKey)}
              >
                保存密钥
              </button>
            `
            : nothing
        }
      </div>
    </div>
  `;
}

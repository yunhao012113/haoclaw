import { html } from "lit";
import type { ConfigUiHints } from "../types.ts";
import { formatChannelExtraValue, resolveChannelConfigValue } from "./channel-config-extras.ts";
import type { ChannelsProps } from "./channels.types.ts";
import { analyzeConfigSchema, renderNode, schemaType, type JsonSchema } from "./config-form.ts";

type ChannelConfigFormProps = {
  channelId: string;
  configValue: Record<string, unknown> | null;
  schema: unknown;
  uiHints: ConfigUiHints;
  disabled: boolean;
  onPatch: (path: Array<string | number>, value: unknown) => void;
};

type ManualChannelField = {
  path: string[];
  label: string;
  kind: "text" | "secret" | "number" | "textarea" | "select" | "boolean";
  placeholder?: string;
  help?: string;
  options?: Array<{ label: string; value: string }>;
};

function resolveSchemaNode(
  schema: JsonSchema | null,
  path: Array<string | number>,
): JsonSchema | null {
  let current = schema;
  for (const key of path) {
    if (!current) {
      return null;
    }
    const type = schemaType(current);
    if (type === "object") {
      const properties = current.properties ?? {};
      if (typeof key === "string" && properties[key]) {
        current = properties[key];
        continue;
      }
      const additional = current.additionalProperties;
      if (typeof key === "string" && additional && typeof additional === "object") {
        current = additional;
        continue;
      }
      return null;
    }
    if (type === "array") {
      if (typeof key !== "number") {
        return null;
      }
      const items = Array.isArray(current.items) ? current.items[0] : current.items;
      current = items ?? null;
      continue;
    }
    return null;
  }
  return current;
}

function resolveChannelValue(
  config: Record<string, unknown>,
  channelId: string,
): Record<string, unknown> {
  return resolveChannelConfigValue(config, channelId) ?? {};
}

const EXTRA_CHANNEL_FIELDS = ["groupPolicy", "streamMode", "dmPolicy"] as const;

const COMMON_POLICY_OPTIONS = [
  { label: "开放", value: "open" },
  { label: "配对", value: "pairing" },
  { label: "白名单", value: "allowlist" },
  { label: "禁用", value: "disabled" },
];

const COMMON_GROUP_POLICY_OPTIONS = [
  { label: "开放", value: "open" },
  { label: "白名单", value: "allowlist" },
  { label: "禁用", value: "disabled" },
];

const MANUAL_CHANNEL_FIELDS: Record<string, ManualChannelField[]> = {
  feishu: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    { path: ["appId"], label: "应用 App ID", kind: "text", placeholder: "cli_xxx" },
    { path: ["appSecret"], label: "应用 App Secret", kind: "secret" },
    { path: ["encryptKey"], label: "加密 Key", kind: "secret" },
    { path: ["verificationToken"], label: "校验 Token", kind: "secret" },
    {
      path: ["connectionMode"],
      label: "接入方式",
      kind: "select",
      options: [
        { label: "WebSocket", value: "websocket" },
        { label: "Webhook", value: "webhook" },
      ],
    },
    {
      path: ["domain"],
      label: "服务域",
      kind: "select",
      options: [
        { label: "飞书", value: "feishu" },
        { label: "Lark", value: "lark" },
      ],
    },
    { path: ["webhookPath"], label: "Webhook 路径", kind: "text", placeholder: "/webhook/feishu" },
    { path: ["webhookHost"], label: "Webhook 主机", kind: "text", placeholder: "0.0.0.0" },
    { path: ["webhookPort"], label: "Webhook 端口", kind: "number", placeholder: "18789" },
    {
      path: ["allowFrom"],
      label: "允许用户",
      kind: "textarea",
      placeholder: "每行一个 open_id / user_id",
    },
    {
      path: ["dmPolicy"],
      label: "私聊策略",
      kind: "select",
      options: COMMON_POLICY_OPTIONS.filter((option) => option.value !== "disabled"),
    },
    {
      path: ["groupAllowFrom"],
      label: "允许群组",
      kind: "textarea",
      placeholder: "每行一个 chat_id",
    },
    {
      path: ["groupPolicy"],
      label: "群组策略",
      kind: "select",
      options: COMMON_GROUP_POLICY_OPTIONS,
    },
    { path: ["requireMention"], label: "群聊必须 @", kind: "boolean" },
  ],
  telegram: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    { path: ["botToken"], label: "Bot Token", kind: "secret", placeholder: "123456:ABC..." },
    {
      path: ["webhookPath"],
      label: "Webhook 路径",
      kind: "text",
      placeholder: "/webhook/telegram",
    },
    { path: ["webhookSecret"], label: "Webhook Secret", kind: "secret" },
    { path: ["proxy"], label: "代理地址", kind: "text", placeholder: "socks5://127.0.0.1:7890" },
    { path: ["allowFrom"], label: "允许用户", kind: "textarea", placeholder: "每行一个 tg:userId" },
    {
      path: ["dmPolicy"],
      label: "私聊策略",
      kind: "select",
      options: COMMON_POLICY_OPTIONS.filter((option) => option.value !== "disabled"),
    },
    {
      path: ["groupPolicy"],
      label: "群组策略",
      kind: "select",
      options: COMMON_GROUP_POLICY_OPTIONS,
    },
    { path: ["requireMention"], label: "群聊必须 @", kind: "boolean" },
    {
      path: ["defaultTo"],
      label: "默认发送目标",
      kind: "text",
      placeholder: "user:12345678 / group:-100...",
    },
  ],
  slack: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    { path: ["botToken"], label: "Bot Token", kind: "secret", placeholder: "xoxb-..." },
    { path: ["appToken"], label: "App Token", kind: "secret", placeholder: "xapp-..." },
    { path: ["signingSecret"], label: "Signing Secret", kind: "secret" },
    { path: ["webhookPath"], label: "Webhook 路径", kind: "text", placeholder: "/webhook/slack" },
    {
      path: ["allowFrom"],
      label: "允许用户",
      kind: "textarea",
      placeholder: "每行一个 Slack user id",
    },
    {
      path: ["dmPolicy"],
      label: "私聊策略",
      kind: "select",
      options: COMMON_POLICY_OPTIONS.filter((option) => option.value !== "disabled"),
    },
    {
      path: ["groupPolicy"],
      label: "频道策略",
      kind: "select",
      options: COMMON_GROUP_POLICY_OPTIONS,
    },
    { path: ["requireMention"], label: "频道必须 @", kind: "boolean" },
    {
      path: ["defaultTo"],
      label: "默认发送目标",
      kind: "text",
      placeholder: "C12345678 / U12345678",
    },
  ],
  discord: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    { path: ["token"], label: "Bot Token", kind: "secret" },
    {
      path: ["defaultTo"],
      label: "默认发送目标",
      kind: "text",
      placeholder: "channel:123 / user:456",
    },
    {
      path: ["dm", "allowFrom"],
      label: "允许私聊用户",
      kind: "textarea",
      placeholder: "每行一个 Discord user id",
    },
    {
      path: ["dm", "policy"],
      label: "私聊策略",
      kind: "select",
      options: COMMON_POLICY_OPTIONS.filter((option) => option.value !== "disabled"),
    },
    {
      path: ["groupPolicy"],
      label: "频道策略",
      kind: "select",
      options: COMMON_GROUP_POLICY_OPTIONS,
    },
    {
      path: ["replyToMode"],
      label: "回复模式",
      kind: "select",
      options: [
        { label: "关闭", value: "off" },
        { label: "回复原消息", value: "reply" },
        { label: "线程优先", value: "thread" },
      ],
    },
  ],
  googlechat: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    {
      path: ["serviceAccount"],
      label: "服务账号 JSON",
      kind: "textarea",
      placeholder: "{ ... }",
      help: "可直接粘贴 JSON 内容。",
    },
    {
      path: ["serviceAccountFile"],
      label: "服务账号文件",
      kind: "text",
      placeholder: "/path/to/service-account.json",
    },
    {
      path: ["webhookPath"],
      label: "Webhook 路径",
      kind: "text",
      placeholder: "/webhook/googlechat",
    },
    { path: ["webhookUrl"], label: "Webhook URL", kind: "text", placeholder: "https://..." },
    { path: ["botUser"], label: "Bot 用户", kind: "text", placeholder: "users/123456789" },
    {
      path: ["audienceType"],
      label: "Audience 类型",
      kind: "text",
      placeholder: "chat-app / service-account",
    },
    {
      path: ["audience"],
      label: "Audience 值",
      kind: "text",
      placeholder: "https://chat.googleapis.com/",
    },
    {
      path: ["dm", "allowFrom"],
      label: "允许私聊用户",
      kind: "textarea",
      placeholder: "每行一个 users/xxx",
    },
    {
      path: ["dm", "policy"],
      label: "私聊策略",
      kind: "select",
      options: COMMON_POLICY_OPTIONS.filter((option) => option.value !== "disabled"),
    },
    {
      path: ["groupPolicy"],
      label: "空间策略",
      kind: "select",
      options: COMMON_GROUP_POLICY_OPTIONS,
    },
  ],
  signal: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    {
      path: ["baseUrl"],
      label: "Signal 服务地址",
      kind: "text",
      placeholder: "http://127.0.0.1:8080",
    },
    {
      path: ["cliPath"],
      label: "signal-cli 路径",
      kind: "text",
      placeholder: "/usr/local/bin/signal-cli",
    },
    {
      path: ["allowFrom"],
      label: "允许用户",
      kind: "textarea",
      placeholder: "每行一个号码或用户标识",
    },
    { path: ["dmPolicy"], label: "私聊策略", kind: "select", options: COMMON_POLICY_OPTIONS },
    {
      path: ["groupPolicy"],
      label: "群组策略",
      kind: "select",
      options: COMMON_GROUP_POLICY_OPTIONS,
    },
    { path: ["defaultTo"], label: "默认发送目标", kind: "text", placeholder: "+86138..." },
  ],
  imessage: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    {
      path: ["cliPath"],
      label: "命令行路径",
      kind: "text",
      placeholder: "imessage / bluebubbles-cli",
    },
    {
      path: ["dbPath"],
      label: "数据库路径",
      kind: "text",
      placeholder: "~/Library/Messages/chat.db",
    },
    {
      path: ["allowFrom"],
      label: "允许联系人",
      kind: "textarea",
      placeholder: "每行一个手机号或邮箱",
    },
    { path: ["dmPolicy"], label: "私聊策略", kind: "select", options: COMMON_POLICY_OPTIONS },
    {
      path: ["groupPolicy"],
      label: "群组策略",
      kind: "select",
      options: COMMON_GROUP_POLICY_OPTIONS,
    },
    {
      path: ["defaultTo"],
      label: "默认发送目标",
      kind: "text",
      placeholder: "+86138... / someone@example.com",
    },
  ],
  whatsapp: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    { path: ["defaultTo"], label: "默认发送目标", kind: "text", placeholder: "+86138..." },
    {
      path: ["allowFrom"],
      label: "允许联系人",
      kind: "textarea",
      placeholder: "每行一个号码或 jid",
    },
    { path: ["dmPolicy"], label: "私聊策略", kind: "select", options: COMMON_POLICY_OPTIONS },
    {
      path: ["groupPolicy"],
      label: "群组策略",
      kind: "select",
      options: COMMON_GROUP_POLICY_OPTIONS,
    },
  ],
  line: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    { path: ["channelAccessToken"], label: "Channel Access Token", kind: "secret" },
    { path: ["channelSecret"], label: "Channel Secret", kind: "secret" },
    { path: ["webhookPath"], label: "Webhook 路径", kind: "text", placeholder: "/webhook/line" },
    {
      path: ["allowFrom"],
      label: "允许用户",
      kind: "textarea",
      placeholder: "每行一个 LINE user id",
    },
    { path: ["dmPolicy"], label: "私聊策略", kind: "select", options: COMMON_POLICY_OPTIONS },
    {
      path: ["groupPolicy"],
      label: "群组策略",
      kind: "select",
      options: COMMON_GROUP_POLICY_OPTIONS,
    },
  ],
  twitch: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    { path: ["username"], label: "Bot 用户名", kind: "text", placeholder: "your_bot_name" },
    { path: ["accessToken"], label: "OAuth Token", kind: "secret", placeholder: "oauth:..." },
    { path: ["clientId"], label: "Client ID", kind: "text" },
    { path: ["clientSecret"], label: "Client Secret", kind: "secret" },
    { path: ["refreshToken"], label: "Refresh Token", kind: "secret" },
    {
      path: ["allowFrom"],
      label: "允许用户",
      kind: "textarea",
      placeholder: "每行一个 Twitch user id",
    },
  ],
  nostr: [
    { path: ["enabled"], label: "启用渠道", kind: "boolean" },
    { path: ["relays"], label: "Relay 列表", kind: "textarea", placeholder: "每行一个 wss://..." },
    { path: ["privateKey"], label: "私钥", kind: "secret" },
    { path: ["publicKey"], label: "公钥", kind: "text" },
    { path: ["defaultTo"], label: "默认发送目标", kind: "text", placeholder: "npub..." },
  ],
};

function readPathValue(record: Record<string, unknown>, path: string[]): unknown {
  let current: unknown = record;
  for (const segment of path) {
    if (!current || typeof current !== "object") {
      return undefined;
    }
    current = (current as Record<string, unknown>)[segment];
  }
  return current;
}

function normalizeTextAreaValue(raw: unknown): string {
  if (Array.isArray(raw)) {
    return raw.map((entry) => String(entry)).join("\n");
  }
  if (typeof raw === "string") {
    return raw;
  }
  return "";
}

function normalizeScalarValue(raw: unknown): string {
  if (typeof raw === "string" || typeof raw === "number") {
    return String(raw);
  }
  return "";
}

function parseManualFieldValue(field: ManualChannelField, raw: string | boolean): unknown {
  if (field.kind === "boolean") {
    return Boolean(raw);
  }
  if (typeof raw !== "string") {
    return null;
  }
  const trimmed = raw.trim();
  if (!trimmed) {
    return null;
  }
  if (field.kind === "number") {
    const parsed = Number(trimmed);
    return Number.isFinite(parsed) ? parsed : null;
  }
  if (field.kind === "textarea") {
    const items = trimmed
      .split(/\r?\n|,/)
      .map((entry) => entry.trim())
      .filter(Boolean);
    if (field.path[field.path.length - 1] === "serviceAccount") {
      try {
        return JSON.parse(trimmed);
      } catch {
        return trimmed;
      }
    }
    return items.length > 0 ? items : null;
  }
  return trimmed;
}

function renderManualChannelConfigForm(props: ChannelConfigFormProps) {
  const fields = MANUAL_CHANNEL_FIELDS[props.channelId];
  if (!fields?.length) {
    return html`
      <div class="callout danger">当前渠道还没有可用的手动配置模板。</div>
    `;
  }
  const value = resolveChannelValue(props.configValue ?? {}, props.channelId);
  return html`
    <div class="callout" style="margin-bottom: 12px;">
      当前使用渠道手动配置表单。即使后端 schema 没返回，也可以直接填写 API、Token、Webhook 和权限策略。
    </div>
    <div class="config-form">
      ${fields.map((field) => {
        const fieldValue = readPathValue(value, field.path);
        const patchPath = ["channels", props.channelId, ...field.path];
        if (field.kind === "boolean") {
          return html`
            <label style="display:flex; align-items:center; gap:10px; margin: 8px 0;">
              <input
                type="checkbox"
                ?checked=${Boolean(fieldValue)}
                ?disabled=${props.disabled}
                @change=${(event: Event) =>
                  props.onPatch(
                    patchPath,
                    parseManualFieldValue(field, (event.currentTarget as HTMLInputElement).checked),
                  )}
              />
              <span>${field.label}</span>
            </label>
          `;
        }
        return html`
          <label style="display:block; margin: 10px 0;">
            <div style="font-weight:600; margin-bottom:6px;">${field.label}</div>
            ${
              field.help
                ? html`<div class="muted" style="margin-bottom:6px;">${field.help}</div>`
                : null
            }
            ${
              field.kind === "select"
                ? html`
                  <select
                    style="width:100%;"
                    ?disabled=${props.disabled}
                    @change=${(event: Event) =>
                      props.onPatch(
                        patchPath,
                        parseManualFieldValue(
                          field,
                          (event.currentTarget as HTMLSelectElement).value,
                        ),
                      )}
                  >
                    <option value="">请选择</option>
                    ${field.options?.map(
                      (option) => html`
                        <option
                          value=${option.value}
                          ?selected=${normalizeScalarValue(fieldValue) === option.value}
                        >
                          ${option.label}
                        </option>
                      `,
                    )}
                  </select>
                `
                : field.kind === "textarea"
                  ? html`
                    <textarea
                      rows="4"
                      style="width:100%;"
                      .value=${normalizeTextAreaValue(fieldValue)}
                      placeholder=${field.placeholder ?? ""}
                      ?disabled=${props.disabled}
                      @input=${(event: Event) =>
                        props.onPatch(
                          patchPath,
                          parseManualFieldValue(
                            field,
                            (event.currentTarget as HTMLTextAreaElement).value,
                          ),
                        )}
                    ></textarea>
                  `
                  : html`
                    <input
                      type=${field.kind === "secret" ? "password" : "text"}
                      style="width:100%;"
                      .value=${normalizeScalarValue(fieldValue)}
                      placeholder=${field.placeholder ?? ""}
                      ?disabled=${props.disabled}
                      @input=${(event: Event) =>
                        props.onPatch(
                          patchPath,
                          parseManualFieldValue(
                            field,
                            (event.currentTarget as HTMLInputElement).value,
                          ),
                        )}
                    />
                  `
            }
          </label>
        `;
      })}
    </div>
    ${renderExtraChannelFields(value)}
  `;
}

function renderExtraChannelFields(value: Record<string, unknown>) {
  const entries = EXTRA_CHANNEL_FIELDS.flatMap((field) => {
    if (!(field in value)) {
      return [];
    }
    return [[field, value[field]]] as Array<[string, unknown]>;
  });
  if (entries.length === 0) {
    return null;
  }
  return html`
    <div class="status-list" style="margin-top: 12px;">
      ${entries.map(
        ([field, raw]) => html`
          <div>
            <span class="label">${field}</span>
            <span>${formatChannelExtraValue(raw)}</span>
          </div>
        `,
      )}
    </div>
  `;
}

export function renderChannelConfigForm(props: ChannelConfigFormProps) {
  if (MANUAL_CHANNEL_FIELDS[props.channelId]?.length) {
    return renderManualChannelConfigForm(props);
  }
  const analysis = analyzeConfigSchema(props.schema);
  const normalized = analysis.schema;
  if (!normalized) {
    return renderManualChannelConfigForm(props);
  }
  const node = resolveSchemaNode(normalized, ["channels", props.channelId]);
  if (!node) {
    return renderManualChannelConfigForm(props);
  }
  const configValue = props.configValue ?? {};
  const value = resolveChannelValue(configValue, props.channelId);
  return html`
    <div class="config-form">
      ${renderNode({
        schema: node,
        value,
        path: ["channels", props.channelId],
        hints: props.uiHints,
        unsupported: new Set(analysis.unsupportedPaths),
        disabled: props.disabled,
        showLabel: false,
        onPatch: props.onPatch,
      })}
    </div>
    ${renderExtraChannelFields(value)}
  `;
}

export function renderChannelConfigSection(params: { channelId: string; props: ChannelsProps }) {
  const { channelId, props } = params;
  const disabled = props.configSaving || props.configSchemaLoading;
  return html`
    <div style="margin-top: 16px;">
      ${
        props.configSchemaLoading
          ? html`
              <div class="muted">正在加载配置结构…</div>
            `
          : renderChannelConfigForm({
              channelId,
              configValue: props.configForm,
              schema: props.configSchema,
              uiHints: props.configUiHints,
              disabled,
              onPatch: props.onConfigPatch,
            })
      }
      <div class="row" style="margin-top: 12px;">
        <button
          class="btn primary"
          ?disabled=${disabled || !props.configFormDirty}
          @click=${() => props.onConfigSave()}
        >
          ${props.configSaving ? "保存中…" : "保存"}
        </button>
        <button
          class="btn"
          ?disabled=${disabled}
          @click=${() => props.onConfigReload()}
        >
          重新加载
        </button>
      </div>
    </div>
  `;
}

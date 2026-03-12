import type { GatewayBrowserClient } from "../gateway.ts";
import type { SkillStatusEntry, SkillStatusReport } from "../types.ts";

export type SkillsState = {
  client: GatewayBrowserClient | null;
  connected: boolean;
  skillsLoading: boolean;
  skillsReport: SkillStatusReport | null;
  skillsError: string | null;
  skillsBusyKey: string | null;
  skillEdits: Record<string, string>;
  skillMessages: SkillMessageMap;
};

export type SkillMessage = {
  kind: "success" | "error";
  message: string;
};

export type SkillMessageMap = Record<string, SkillMessage>;

type LoadSkillsOptions = {
  clearMessages?: boolean;
};

function setSkillMessage(state: SkillsState, key: string, message?: SkillMessage) {
  if (!key.trim()) {
    return;
  }
  const next = { ...state.skillMessages };
  if (message) {
    next[key] = message;
  } else {
    delete next[key];
  }
  state.skillMessages = next;
}

function getErrorMessage(err: unknown) {
  if (err instanceof Error) {
    return err.message;
  }
  return String(err);
}

function fallbackSkillEntry(entry: {
  name: string;
  skillKey: string;
  description: string;
  source: string;
  filePath: string;
  baseDir: string;
}): SkillStatusEntry {
  return {
    name: entry.name,
    description: entry.description || "内置技能",
    source: entry.source || "haoclaw-bundled",
    filePath: entry.filePath,
    baseDir: entry.baseDir,
    skillKey: entry.skillKey || entry.name,
    bundled: true,
    always: false,
    disabled: false,
    blockedByAllowlist: false,
    eligible: true,
    requirements: { bins: [], env: [], config: [], os: [] },
    missing: { bins: [], env: [], config: [], os: [] },
    configChecks: [],
    install: [],
  };
}

async function loadDesktopFallbackSkills(): Promise<SkillStatusReport | null> {
  const loader = window.haoclawDesktop?.listBundledSkills;
  if (typeof loader !== "function") {
    return null;
  }
  try {
    const list = await loader();
    if (!Array.isArray(list) || list.length === 0) {
      return null;
    }
    const skills = list.map((entry) => fallbackSkillEntry(entry));
    return {
      workspaceDir: "",
      managedSkillsDir: "",
      skills,
    };
  } catch {
    return null;
  }
}

export async function loadSkills(state: SkillsState, options?: LoadSkillsOptions) {
  if (options?.clearMessages && Object.keys(state.skillMessages).length > 0) {
    state.skillMessages = {};
  }
  if (!state.client || !state.connected) {
    const fallback = await loadDesktopFallbackSkills();
    if (fallback) {
      state.skillsReport = fallback;
      state.skillsError = null;
    }
    return;
  }
  if (state.skillsLoading) {
    return;
  }
  state.skillsLoading = true;
  state.skillsError = null;
  try {
    const res = await state.client.request<SkillStatusReport | undefined>("skills.status", {});
    if (res && Array.isArray(res.skills) && res.skills.length > 0) {
      state.skillsReport = res;
      state.skillsError = null;
    } else {
      const fallback = await loadDesktopFallbackSkills();
      if (fallback) {
        state.skillsReport = fallback;
        state.skillsError = null;
      } else if (res) {
        state.skillsReport = res;
      }
    }
  } catch (err) {
    const fallback = await loadDesktopFallbackSkills();
    if (fallback) {
      state.skillsReport = fallback;
      state.skillsError = null;
    } else {
      state.skillsError = getErrorMessage(err);
    }
  } finally {
    state.skillsLoading = false;
  }
}

export function updateSkillEdit(state: SkillsState, skillKey: string, value: string) {
  state.skillEdits = { ...state.skillEdits, [skillKey]: value };
}

export async function updateSkillEnabled(state: SkillsState, skillKey: string, enabled: boolean) {
  if (!state.client || !state.connected) {
    return;
  }
  state.skillsBusyKey = skillKey;
  state.skillsError = null;
  try {
    await state.client.request("skills.update", { skillKey, enabled });
    await loadSkills(state);
    setSkillMessage(state, skillKey, {
      kind: "success",
      message: enabled ? "技能已启用" : "技能已禁用",
    });
  } catch (err) {
    const message = getErrorMessage(err);
    state.skillsError = message;
    setSkillMessage(state, skillKey, {
      kind: "error",
      message,
    });
  } finally {
    state.skillsBusyKey = null;
  }
}

export async function saveSkillApiKey(state: SkillsState, skillKey: string) {
  if (!state.client || !state.connected) {
    return;
  }
  state.skillsBusyKey = skillKey;
  state.skillsError = null;
  try {
    const apiKey = state.skillEdits[skillKey] ?? "";
    await state.client.request("skills.update", { skillKey, apiKey });
    await loadSkills(state);
    setSkillMessage(state, skillKey, {
      kind: "success",
      message: "API Key 已保存",
    });
  } catch (err) {
    const message = getErrorMessage(err);
    state.skillsError = message;
    setSkillMessage(state, skillKey, {
      kind: "error",
      message,
    });
  } finally {
    state.skillsBusyKey = null;
  }
}

export async function installSkill(
  state: SkillsState,
  skillKey: string,
  name: string,
  installId: string,
) {
  if (!state.client || !state.connected) {
    return;
  }
  state.skillsBusyKey = skillKey;
  state.skillsError = null;
  try {
    const result = await state.client.request<{ message?: string }>("skills.install", {
      name,
      installId,
      timeoutMs: 120000,
    });
    await loadSkills(state);
    setSkillMessage(state, skillKey, {
      kind: "success",
      message: result?.message ?? "已安装",
    });
  } catch (err) {
    const message = getErrorMessage(err);
    state.skillsError = message;
    setSkillMessage(state, skillKey, {
      kind: "error",
      message,
    });
  } finally {
    state.skillsBusyKey = null;
  }
}

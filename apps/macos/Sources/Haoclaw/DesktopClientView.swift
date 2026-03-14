import Foundation
import HaoclawChatUI
import HaoclawProtocol
import Observation
import SwiftUI

enum DesktopSidebarSection: String, CaseIterable, Identifiable {
    case conversations
    case channels
    case cron

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .conversations: "会话"
        case .channels: "IM 渠道"
        case .cron: "定时任务"
        }
    }
}

enum DesktopControlSection: String, CaseIterable, Identifiable {
    case general
    case models
    case tools
    case skills
    case channels
    case automation
    case workspace
    case updates

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .general: "运行台"
        case .models: "模型中心"
        case .tools: "工具接入"
        case .skills: "技能库"
        case .channels: "渠道接入"
        case .automation: "自动任务"
        case .workspace: "工作区"
        case .updates: "更新中心"
        }
    }

    var symbol: String {
        switch self {
        case .general: "switch.2"
        case .models: "cpu"
        case .tools: "shippingbox"
        case .skills: "sparkles"
        case .channels: "message"
        case .automation: "calendar.badge.clock"
        case .workspace: "folder"
        case .updates: "arrow.down.circle"
        }
    }

    var summary: String {
        switch self {
        case .general: "连接方式、显示策略和桌面行为"
        case .models: "统一配置 Provider、模型和会话默认项"
        case .tools: "接入命令型工具与 HTTP 工具"
        case .skills: "查看技能状态并进行启停"
        case .channels: "把 Haoclaw 接入外部消息渠道"
        case .automation: "管理定时任务和自动流程"
        case .workspace: "项目目录、监听和上下文保留"
        case .updates: "检查版本、发布记录和一键升级"
        }
    }
}

enum DesktopProviderPreset: String, CaseIterable, Identifiable {
    case custom
    case openai
    case openrouter
    case anthropic
    case gemini
    case mistral
    case minimax
    case qwenPortal
    case qianfan
    case nvidia
    case zhipu
    case deepseek
    case moonshot
    case siliconFlow
    case groq
    case together
    case cerebras
    case xai
    case ollama
    case openAICompatible
    case anthropicCompatible

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .custom: "自定义接口"
        case .openai: "OpenAI"
        case .openrouter: "OpenRouter"
        case .anthropic: "Anthropic"
        case .gemini: "Gemini"
        case .mistral: "Mistral"
        case .minimax: "MiniMax"
        case .qwenPortal: "Qwen Portal"
        case .qianfan: "百度千帆"
        case .nvidia: "NVIDIA"
        case .zhipu: "智谱 GLM"
        case .deepseek: "DeepSeek"
        case .moonshot: "Moonshot"
        case .siliconFlow: "SiliconFlow"
        case .groq: "Groq"
        case .together: "Together AI"
        case .cerebras: "Cerebras"
        case .xai: "xAI"
        case .ollama: "Ollama"
        case .openAICompatible: "OpenAI 兼容"
        case .anthropicCompatible: "Anthropic 兼容"
        }
    }

    var defaultProviderID: String {
        switch self {
        case .custom: "custom"
        case .openai: "openai"
        case .openrouter: "openrouter"
        case .anthropic: "anthropic"
        case .gemini: "google"
        case .mistral: "mistral"
        case .minimax: "minimax"
        case .qwenPortal: "qwen-portal"
        case .qianfan: "qianfan"
        case .nvidia: "nvidia"
        case .zhipu: "zhipu"
        case .deepseek: "deepseek"
        case .moonshot: "moonshot"
        case .siliconFlow: "siliconflow"
        case .groq: "groq"
        case .together: "together"
        case .cerebras: "cerebras"
        case .xai: "xai"
        case .ollama: "ollama"
        case .openAICompatible: "custom-openai"
        case .anthropicCompatible: "custom-anthropic"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .custom: ""
        case .openai: "https://api.openai.com/v1"
        case .openrouter: "https://openrouter.ai/api/v1"
        case .anthropic: "https://api.anthropic.com"
        case .gemini: "https://generativelanguage.googleapis.com"
        case .mistral: "https://api.mistral.ai/v1"
        case .minimax: "https://api.minimax.io/anthropic"
        case .qwenPortal: "https://portal.qwen.ai/v1"
        case .qianfan: "https://qianfan.baidubce.com/v2"
        case .nvidia: "https://integrate.api.nvidia.com/v1"
        case .zhipu: "https://open.bigmodel.cn/api/paas/v4"
        case .deepseek: "https://api.deepseek.com/v1"
        case .moonshot: "https://api.moonshot.cn/v1"
        case .siliconFlow: "https://api.siliconflow.cn/v1"
        case .groq: "https://api.groq.com/openai/v1"
        case .together: "https://api.together.xyz/v1"
        case .cerebras: "https://api.cerebras.ai/v1"
        case .xai: "https://api.x.ai/v1"
        case .ollama: "http://127.0.0.1:11434/v1"
        case .openAICompatible, .anthropicCompatible: ""
        }
    }

    var defaultModelID: String {
        switch self {
        case .custom: ""
        case .openai: "gpt-5"
        case .openrouter: "anthropic/claude-sonnet-4-5"
        case .anthropic: "claude-sonnet-4-5"
        case .gemini: "gemini-2.5-pro"
        case .mistral: "mistral-large-latest"
        case .minimax: "MiniMax-M2.5"
        case .qwenPortal: "coder-model"
        case .qianfan: "deepseek-v3.2"
        case .nvidia: "nvidia/llama-3.1-nemotron-70b-instruct"
        case .zhipu: "glm-4.5"
        case .deepseek: "deepseek-chat"
        case .moonshot: "kimi-k2-0905-preview"
        case .siliconFlow: "Qwen/Qwen3-Coder-480B-A35B-Instruct"
        case .groq: "llama-3.3-70b-versatile"
        case .together: "deepseek-ai/DeepSeek-V3"
        case .cerebras: "llama-4-scout-17b-16e-instruct"
        case .xai: "grok-3-beta"
        case .ollama: "qwen2.5-coder"
        case .openAICompatible: "qwen2.5-coder"
        case .anthropicCompatible: "claude-sonnet-4-5"
        }
    }

    var apiAdapter: String {
        switch self {
        case .custom: "openai-completions"
        case .anthropic, .anthropicCompatible, .minimax: "anthropic-messages"
        case .gemini: "google-generative-ai"
        case .openai: "openai-responses"
        case .openrouter, .mistral, .qwenPortal, .qianfan, .nvidia, .zhipu, .deepseek, .moonshot, .siliconFlow, .groq, .together, .cerebras, .xai,
             .ollama, .openAICompatible:
            "openai-completions"
        }
    }

    var authHeader: Bool {
        switch self {
        case .minimax:
            true
        default:
            false
        }
    }

    var helpText: String {
        switch self {
        case .custom:
            "适合任何没有预设的自定义接口。你可以自己填写 Provider ID、Base URL、API Key 和模型 ID。"
        case .openai:
            "官方 OpenAI 接口，默认使用 Responses API。"
        case .openrouter:
            "适合直接接 OpenRouter，多模型聚合。"
        case .anthropic:
            "官方 Anthropic Messages 接口。"
        case .gemini:
            "官方 Gemini 接口。"
        case .mistral:
            "Mistral 官方接口，已预填官方地址和默认模型。"
        case .minimax:
            "MiniMax 官方接口，已预填 Anthropic 兼容地址，并自动启用 Authorization Header。"
        case .qwenPortal:
            "Qwen Portal 官方接口，适合直接填写 Qwen Portal 的访问凭据。"
        case .qianfan:
            "百度千帆统一接口，适合用一套 API 接多个模型。"
        case .nvidia:
            "NVIDIA NIM 官方接口，已预填官方地址和常用默认模型。"
        case .zhipu:
            "智谱 GLM 接口，适合直接填智谱 API Key。"
        case .deepseek:
            "DeepSeek 官方接口。"
        case .moonshot:
            "Moonshot Kimi 官方接口。"
        case .siliconFlow:
            "SiliconFlow 聚合接口。"
        case .groq:
            "Groq 低延迟 OpenAI 兼容接口。"
        case .together:
            "Together AI OpenAI 兼容接口。"
        case .cerebras:
            "Cerebras OpenAI 兼容接口。"
        case .xai:
            "xAI Grok OpenAI 兼容接口。"
        case .ollama:
            "本地 Ollama，默认地址是 127.0.0.1:11434。"
        case .openAICompatible:
            "适合 Ollama、vLLM、LiteLLM、自建代理等 OpenAI 兼容接口。这个预设需要你手动填写 API 接口地址。"
        case .anthropicCompatible:
            "适合兼容 Anthropic Messages 协议的代理或网关。这个预设需要你手动填写 API 接口地址。"
        }
    }

    var missingBaseURLMessage: String {
        switch self {
        case .openAICompatible:
            "请先填写 API 接口地址。OpenAI 兼容接口不会自动生成地址；如果你要接 NVIDIA，请直接选择 NVIDIA 预设。"
        case .anthropicCompatible:
            "请先填写 API 接口地址。Anthropic 兼容接口需要手动提供网关地址。"
        case .custom:
            "请先填写 API 接口地址。"
        default:
            "请先填写 API 接口地址，或重新选择一个带默认地址的服务商预设。"
        }
    }

    static func infer(providerID: String, baseURL: String, apiAdapter: String) -> DesktopProviderPreset {
        let normalizedProvider = providerID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedAdapter = apiAdapter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalizedProvider == "openrouter" || normalizedBaseURL.contains("openrouter.ai") {
            return .openrouter
        }
        if normalizedProvider == "mistral" || normalizedBaseURL.contains("api.mistral.ai") {
            return .mistral
        }
        if normalizedProvider == "minimax" || normalizedBaseURL.contains("api.minimax.io/anthropic") {
            return .minimax
        }
        if normalizedProvider == "qwen-portal" || normalizedBaseURL.contains("portal.qwen.ai") {
            return .qwenPortal
        }
        if normalizedProvider == "qianfan" || normalizedBaseURL.contains("qianfan.baidubce.com") {
            return .qianfan
        }
        if normalizedProvider == "nvidia" || normalizedBaseURL.contains("integrate.api.nvidia.com") {
            return .nvidia
        }
        if normalizedProvider == "zhipu" || normalizedBaseURL.contains("bigmodel.cn") {
            return .zhipu
        }
        if normalizedProvider == "deepseek" || normalizedBaseURL.contains("api.deepseek.com") {
            return .deepseek
        }
        if normalizedProvider == "moonshot" || normalizedBaseURL.contains("api.moonshot.cn") {
            return .moonshot
        }
        if normalizedProvider == "siliconflow" || normalizedBaseURL.contains("siliconflow.cn") {
            return .siliconFlow
        }
        if normalizedProvider == "groq" || normalizedBaseURL.contains("api.groq.com") {
            return .groq
        }
        if normalizedProvider == "together" || normalizedBaseURL.contains("api.together.xyz") {
            return .together
        }
        if normalizedProvider == "cerebras" || normalizedBaseURL.contains("api.cerebras.ai") {
            return .cerebras
        }
        if normalizedProvider == "xai" || normalizedBaseURL.contains("api.x.ai") {
            return .xai
        }
        if normalizedProvider == "ollama" || normalizedBaseURL.contains("127.0.0.1:11434") ||
            normalizedBaseURL.contains("localhost:11434")
        {
            return .ollama
        }
        if normalizedProvider == "anthropic" || normalizedBaseURL.contains("api.anthropic.com") {
            return .anthropic
        }
        if normalizedProvider == "google" || normalizedProvider == "gemini" ||
            normalizedBaseURL.contains("generativelanguage.googleapis.com")
        {
            return .gemini
        }
        if normalizedProvider == "openai" || normalizedBaseURL.contains("api.openai.com") {
            return .openai
        }
        if normalizedAdapter == "anthropic-messages" {
            return .anthropicCompatible
        }
        return .openAICompatible
    }
}

struct DesktopModelSettingsDraft: Equatable {
    var connectionMode: AppState.ConnectionMode = .local
    var remoteTransport: AppState.RemoteTransport = .direct
    var remoteURL = ""
    var remoteToken = ""
    var remoteTarget = ""
    var remoteIdentity = ""
    var providerPreset: DesktopProviderPreset = .openAICompatible
    var providerId = "haoclaw-desktop"
    var apiAdapter = "openai-completions"
    var baseURL = ""
    var apiKey = ""
    var modelID = ""
}

@MainActor
@Observable
final class DesktopClientModel {
    let appState: AppState
    let chatViewModel: HaoclawChatViewModel

    var sidebarSection: DesktopSidebarSection = .conversations
    var isShowingModelSettings = false
    var isSavingModelSettings = false
    var isRefreshing = false
    var statusMessage: String?
    var runtimeModels: [ModelChoice] = []
    var configuredModels: [ModelChoice] = []
    var currentModelRef = "未配置"
    var gatewayURL = "未连接"
    var gatewayStatus = "连接中"
    var isGatewayReady = false
    var stateDirectory = "未发现"
    var configPath = "未发现"
    var connectionHint: String?
    var isRepairingConnection = false
    var settingsDraft = DesktopModelSettingsDraft()
    var appliedModelSettings = DesktopModelSettingsDraft()
    var isShowingControlCenter = false
    var controlSection: DesktopControlSection = .general

    @ObservationIgnored private var endpointTask: Task<Void, Never>?

    var availableModels: [ModelChoice] {
        Self.mergeModelChoices(self.configuredModels, self.runtimeModels, currentModelRef: self.selectedSessionModelRef)
    }

    var preferredProviderID: String {
        let sessionProvider = Self.providerID(from: self.selectedSessionModelRef)
        if !sessionProvider.isEmpty {
            return sessionProvider
        }
        let currentProvider = Self.providerID(from: self.currentModelRef)
        if !currentProvider.isEmpty {
            return currentProvider
        }
        let configured = self.settingsDraft.providerId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !configured.isEmpty {
            return configured
        }
        return self.settingsDraft.providerPreset.defaultProviderID
    }

    var pickerModels: [ModelChoice] {
        let providerID = self.preferredProviderID.lowercased()
        guard !providerID.isEmpty else { return self.availableModels }
        let filtered = self.availableModels.filter { $0.provider.lowercased() == providerID }
        return filtered.isEmpty ? self.availableModels : filtered
    }

    var settingsSuggestedModels: [ModelChoice] {
        let providerID = self.settingsDraft.providerId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !providerID.isEmpty else { return self.availableModels }
        let filtered = self.availableModels.filter { $0.provider.lowercased() == providerID }
        return filtered.isEmpty ? self.availableModels : filtered
    }

    var settingsResolvedProviderID: String {
        let trimmed = self.settingsDraft.providerId.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? self.settingsDraft.providerPreset.defaultProviderID : trimmed
    }

    var settingsResolvedApiAdapter: String {
        let trimmed = self.settingsDraft.apiAdapter.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? self.settingsDraft.providerPreset.apiAdapter : trimmed
    }

    var settingsResolvedModelChoices: [ModelChoice] {
        let providerID = self.settingsResolvedProviderID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !providerID.isEmpty else { return [] }
        return self.availableModels.filter { $0.provider.lowercased() == providerID }
    }

    var firstResolvedDiscoveredModelID: String? {
        self.settingsResolvedModelChoices
            .lazy
            .map { $0.id.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
    }

    var canApplyDraftModelSelection: Bool {
        let providerID = self.settingsResolvedProviderID.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelID = self.settingsDraft.modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        return !providerID.isEmpty && !modelID.isEmpty
    }

    init(appState: AppState, chatViewModel: HaoclawChatViewModel) {
        self.appState = appState
        self.chatViewModel = chatViewModel
    }

    func start() {
        self.chatViewModel.load()
        self.chatViewModel.refreshSessions(limit: 50)
        self.startEndpointObserverIfNeeded()
        Task { await self.refreshSupportData() }
    }

    func refreshSupportData() async {
        self.isRefreshing = true
        defer { self.isRefreshing = false }

        await self.loadCurrentConfig()
        let environment = await self.refreshConnectionHint()
        await self.ensureLocalGatewayIfPossible(environment)
        await self.loadModelCatalog()
        await self.refreshEndpoint()
        self.chatViewModel.refreshSessions(limit: 50)
    }

    func repairConnection() async {
        guard !self.isRepairingConnection else { return }
        self.isRepairingConnection = true
        defer { self.isRepairingConnection = false }

        self.statusMessage = "正在修复本地连接…"
        self.ensureLocalStateLayout()

        let environment = await Task.detached(priority: .utility) {
            GatewayEnvironment.check()
        }.value

        switch environment.kind {
        case .missingNode, .missingGateway, .incompatible:
            let installed = await CLIInstaller.install { message in
                self.statusMessage = message
            }
            guard installed else {
                await self.refreshSupportData()
                return
            }
        case .ok, .checking, .error:
            break
        }

        if !FileManager.default.fileExists(atPath: HaoclawPaths.configURL.path) {
            HaoclawConfigFile.saveDict(HaoclawConfigFile.loadDict())
        }

        if self.appState.connectionMode != .local {
            self.appState.connectionMode = .local
        }

        GatewayProcessManager.shared.refreshEnvironmentStatus(force: true)
        GatewayProcessManager.shared.setActive(true)
        let ready = await GatewayProcessManager.shared.waitForGatewayReady(timeout: 10)
        await self.refreshSupportData()

        if ready {
            if self.currentModelRef == "未配置" {
                self.statusMessage = "网关已启动。下一步在“模型与 API”里填入 Base URL、API Key 和模型 ID。"
            } else {
                self.statusMessage = "本地连接已恢复。"
            }
        } else {
            self.statusMessage = "本地运行时已安装，但网关还没有启动成功。请再点一次“重新连接”。"
        }
    }

    func createConversation() {
        let next = "desktop-\(UUID().uuidString.prefix(8))"
        self.chatViewModel.switchSession(to: next)
    }

    func selectSession(_ key: String) {
        self.chatViewModel.switchSession(to: key)
    }

    func openModelSettings() {
        self.restoreSettingsDraftFromApplied()
        self.refreshSettingsDraftFromState()
        self.controlSection = .models
        self.isShowingControlCenter = true
    }

    func openControlCenter(_ section: DesktopControlSection = .general) {
        if section == .models {
            self.restoreSettingsDraftFromApplied()
            self.refreshSettingsDraftFromState()
        }
        self.controlSection = section
        self.isShowingControlCenter = true
    }

    func selectSessionModel(_ modelRef: String) async {
        let trimmedModelRef = modelRef.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModelRef.isEmpty else { return }
        guard trimmedModelRef != self.selectedSessionModelRef else { return }

        do {
            try await GatewayConnection.shared.patchSessionModel(
                sessionKey: self.chatViewModel.sessionKey,
                modelRef: trimmedModelRef)
            self.currentModelRef = trimmedModelRef
            self.statusMessage = "当前会话已切换到 \(trimmedModelRef)。"
            self.chatViewModel.refreshSessions(limit: 50)
            self.chatViewModel.refresh()
        } catch {
            self.statusMessage = "切换模型失败：\(error.localizedDescription)"
        }
    }

    func saveModelSettings() async {
        let selectedPreset = self.settingsDraft.providerPreset
        let connectionMode = self.settingsDraft.connectionMode
        let remoteTransport = self.settingsDraft.remoteTransport
        let trimmedRemoteURL = self.settingsDraft.remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRemoteToken = self.settingsDraft.remoteToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRemoteTarget = self.settingsDraft.remoteTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRemoteIdentity = self.settingsDraft.remoteIdentity.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBaseURL = self.settingsDraft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedApiKey = self.settingsDraft.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModelID = self.settingsDraft.modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProviderID = self.settingsDraft.providerId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedApiAdapter = self.settingsDraft.apiAdapter.trimmingCharacters(in: .whitespacesAndNewlines)

        if connectionMode == .remote, remoteTransport == .direct, trimmedRemoteURL.isEmpty {
            self.statusMessage = "远程直连模式需要填写 Gateway URL。"
            return
        }
        if connectionMode == .remote, remoteTransport == .ssh, trimmedRemoteTarget.isEmpty {
            self.statusMessage = "SSH 模式需要填写 SSH Target。"
            return
        }

        let resolvedProviderID = trimmedProviderID.isEmpty ? selectedPreset.defaultProviderID : trimmedProviderID
        let resolvedApiAdapter = trimmedApiAdapter.isEmpty ? selectedPreset.apiAdapter : trimmedApiAdapter
        let resolvedModelID = self.resolveModelIDForSave(
            explicitModelID: trimmedModelID,
            providerID: resolvedProviderID,
            preset: selectedPreset)

        guard !trimmedBaseURL.isEmpty else {
            self.statusMessage = selectedPreset.missingBaseURLMessage
            return
        }

        self.isSavingModelSettings = true
        defer { self.isSavingModelSettings = false }

        var root = HaoclawConfigFile.loadDict()
        var modelsRoot = root["models"] as? [String: Any] ?? [:]
        var providers = modelsRoot["providers"] as? [String: Any] ?? [:]

        var providerEntry = providers[resolvedProviderID] as? [String: Any] ?? [:]
        providerEntry["baseUrl"] = trimmedBaseURL
        providerEntry["api"] = resolvedApiAdapter
        if selectedPreset.authHeader {
            providerEntry["authHeader"] = true
        } else {
            providerEntry.removeValue(forKey: "authHeader")
        }
        if !trimmedApiKey.isEmpty {
            providerEntry["apiKey"] = trimmedApiKey
        } else {
            providerEntry.removeValue(forKey: "apiKey")
        }

        if !resolvedModelID.isEmpty {
            var providerModels = Self.extractProviderModels(from: providerEntry)
            let nextModelEntry: [String: Any] = [
                "id": resolvedModelID,
                "name": resolvedModelID,
                "api": resolvedApiAdapter,
            ]
            if let existingIndex = providerModels.firstIndex(where: {
                (($0["id"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == resolvedModelID
            }) {
                providerModels[existingIndex] = nextModelEntry
            } else {
                providerModels.append(nextModelEntry)
            }
            providerEntry["models"] = providerModels
        } else {
            providerEntry.removeValue(forKey: "models")
        }
        providers[resolvedProviderID] = providerEntry
        modelsRoot["mode"] = "merge"
        modelsRoot["providers"] = providers
        root["models"] = modelsRoot
        Self.persistLastSavedProviderSelection(
            in: &root,
            providerID: resolvedProviderID,
            modelID: resolvedModelID)

        if !resolvedModelID.isEmpty {
            let primaryRef = "\(resolvedProviderID)/\(resolvedModelID)"
            if var agentsRoot = root["agents"] as? [String: Any] {
                var defaults = agentsRoot["defaults"] as? [String: Any] ?? [:]
                defaults["model"] = ["primary": primaryRef]
                agentsRoot["defaults"] = defaults
                root["agents"] = agentsRoot
            } else {
                var agentRoot = root["agent"] as? [String: Any] ?? [:]
                agentRoot["model"] = ["primary": primaryRef]
                root["agent"] = agentRoot
            }
        } else {
            if var agentsRoot = root["agents"] as? [String: Any] {
                var defaults = agentsRoot["defaults"] as? [String: Any] ?? [:]
                defaults.removeValue(forKey: "model")
                agentsRoot["defaults"] = defaults
                root["agents"] = agentsRoot
            }
            if var agentRoot = root["agent"] as? [String: Any] {
                agentRoot.removeValue(forKey: "model")
                root["agent"] = agentRoot
            }
        }

        do {
            HaoclawConfigFile.saveDict(root)
            self.configuredModels = Self.extractConfiguredModels(from: root)
            self.settingsDraft.providerPreset = selectedPreset
            self.settingsDraft.providerId = resolvedProviderID
            self.settingsDraft.apiAdapter = resolvedApiAdapter
            self.settingsDraft.baseURL = trimmedBaseURL
            self.settingsDraft.apiKey = trimmedApiKey
            self.settingsDraft.modelID = resolvedModelID
            self.appliedModelSettings = self.settingsDraft
            self.appState.connectionMode = connectionMode
            self.appState.remoteTransport = remoteTransport
            self.appState.remoteUrl = trimmedRemoteURL
            self.appState.remoteToken = trimmedRemoteToken
            self.appState.remoteTarget = trimmedRemoteTarget
            self.appState.remoteIdentity = trimmedRemoteIdentity
            self.statusMessage = "接口已保存，正在验证连接并读取模型…"
            await self.refreshSupportData()

            var effectiveModelID = resolvedModelID
            if effectiveModelID.isEmpty, let discoveredModelID = self.firstResolvedDiscoveredModelID {
                effectiveModelID = discoveredModelID
            }

            if !effectiveModelID.isEmpty {
                let primaryRef = await self.applyPrimaryModelSelection(
                    providerID: resolvedProviderID,
                    modelID: effectiveModelID,
                    apiAdapter: resolvedApiAdapter)
                self.statusMessage = resolvedModelID.isEmpty
                    ? "接口已连接，已自动选用 \(primaryRef) 作为默认模型。"
                    : (selectedPreset == .openAICompatible || selectedPreset == .anthropicCompatible
                        ? "连接与模型配置已保存。"
                        : "\(selectedPreset.title) 连接已保存。")
                await self.refreshSupportData()
            } else {
                self.controlSection = .models
                self.statusMessage = self.isGatewayReady
                    ? "接口已保存，但当前没有发现模型列表。请手动填写默认模型 ID 后再保存。"
                    : "接口已保存，但网关暂时还没准备好读取模型。请稍后重试，或手动填写默认模型 ID。"
            }
        }
    }

    func applyDraftModelSelection() async {
        let providerID = self.settingsResolvedProviderID.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiAdapter = self.settingsResolvedApiAdapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelID = self.settingsDraft.modelID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !providerID.isEmpty else {
            self.statusMessage = "请先填写接口名称。"
            return
        }
        guard !modelID.isEmpty else {
            self.statusMessage = "请先选择或填写默认模型 ID。"
            return
        }

        self.statusMessage = "正在应用默认模型…"
        let primaryRef = await self.applyPrimaryModelSelection(
            providerID: providerID,
            modelID: modelID,
            apiAdapter: apiAdapter)
        self.statusMessage = "已将 \(primaryRef) 设为默认模型，并同步到当前会话。"
        await self.refreshSupportData()
    }

    var currentSessionTitle: String {
        let key = self.chatViewModel.sessionKey
        let match = self.chatViewModel.sessionChoices.first { $0.key == key }
        let display = match?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return display.isEmpty ? key : display
    }

    var currentSessionSummary: String {
        guard let match = self.chatViewModel.sessionChoices.first(where: { $0.key == self.chatViewModel.sessionKey }) else {
            return "本地会话"
        }
        let model = match.model?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !model.isEmpty {
            return model
        }
        return "等待首条消息"
    }

    private func startEndpointObserverIfNeeded() {
        guard self.endpointTask == nil else { return }
        self.endpointTask = Task { [weak self] in
            guard let self else { return }
            let stream = await GatewayEndpointStore.shared.subscribe(bufferingNewest: 1)
            for await state in stream {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.applyEndpointState(state)
                }
            }
        }
    }

    private func applyEndpointState(_ state: GatewayEndpointState) {
        switch state {
        case let .ready(_, url, _, _):
            self.gatewayURL = url.absoluteString
            self.gatewayStatus = "已连接"
            self.isGatewayReady = true
        case let .connecting(_, detail):
            self.gatewayURL = "等待网关"
            self.gatewayStatus = detail
            self.isGatewayReady = false
        case let .unavailable(_, reason):
            self.gatewayURL = "不可用"
            self.gatewayStatus = reason
            self.isGatewayReady = false
        }
    }

    private func refreshEndpoint() async {
        await GatewayEndpointStore.shared.refresh()
        do {
            let config = try await GatewayEndpointStore.shared.requireConfig()
            self.gatewayURL = config.url.absoluteString
            self.isGatewayReady = (try? await GatewayConnection.shared.healthOK(timeoutMs: 4000)) ?? false
            self.gatewayStatus = self.isGatewayReady ? "已连接" : "网关未就绪"
        } catch {
            self.gatewayStatus = self.connectionHint ?? "无法连接本地网关"
            self.isGatewayReady = false
        }
    }

    private func loadCurrentConfig() async {
        let root = HaoclawConfigFile.loadDict()
        self.configuredModels = Self.extractConfiguredModels(from: root)
        let modelRef = Self.extractPrimaryModelRef(from: root)
        if let modelRef, !modelRef.isEmpty {
            self.currentModelRef = modelRef
            let parts = modelRef.split(separator: "/", maxSplits: 1).map(String.init)
            let providerID = parts.first ?? "haoclaw-desktop"
            let providerEntry = ((root["models"] as? [String: Any])?["providers"] as? [String: Any])?[providerID] as? [String: Any]
            let baseURL = providerEntry?["baseUrl"] as? String ?? ""
            let apiKey = providerEntry?["apiKey"] as? String ?? ""
            let apiAdapter = providerEntry?["api"] as? String ?? "openai-completions"
            let preset = DesktopProviderPreset.infer(
                providerID: providerID,
                baseURL: baseURL,
                apiAdapter: apiAdapter)

            self.settingsDraft.providerPreset = preset
            self.settingsDraft.providerId = providerID
            self.settingsDraft.apiAdapter = apiAdapter
            self.settingsDraft.baseURL = baseURL
            self.settingsDraft.apiKey = apiKey
            if parts.count == 2 {
                self.settingsDraft.modelID = parts[1]
            }
        } else {
            self.currentModelRef = "未配置"
            if let savedProvider = Self.extractSavedProviderDraft(from: root) {
                let preset = DesktopProviderPreset.infer(
                    providerID: savedProvider.providerID,
                    baseURL: savedProvider.baseURL,
                    apiAdapter: savedProvider.apiAdapter)
                self.settingsDraft.providerPreset = preset
                self.settingsDraft.providerId = savedProvider.providerID
                self.settingsDraft.apiAdapter = savedProvider.apiAdapter
                self.settingsDraft.baseURL = savedProvider.baseURL
                self.settingsDraft.apiKey = savedProvider.apiKey
                self.settingsDraft.modelID = savedProvider.modelID
                if !savedProvider.modelID.isEmpty {
                    self.currentModelRef = "\(savedProvider.providerID)/\(savedProvider.modelID)"
                }
            }
        }

        self.refreshSettingsDraftFromState()
        self.appliedModelSettings = self.settingsDraft
        self.ensureLocalStateLayout()
        self.stateDirectory = HaoclawPaths.stateDirURL.path
        self.configPath = HaoclawPaths.configURL.path

        let paths = await GatewayConnection.shared.snapshotPaths()
        self.stateDirectory = paths.stateDir ?? self.stateDirectory
        self.configPath = paths.configPath ?? self.configPath
    }

    func applyProviderPreset() {
        let preset = self.settingsDraft.providerPreset
        self.settingsDraft.providerId = preset.defaultProviderID
        self.settingsDraft.apiAdapter = preset.apiAdapter
        self.settingsDraft.baseURL = preset.defaultBaseURL
        self.settingsDraft.modelID = preset.defaultModelID
    }

    func restoreSettingsDraftFromApplied() {
        self.settingsDraft.providerPreset = self.appliedModelSettings.providerPreset
        self.settingsDraft.providerId = self.appliedModelSettings.providerId
        self.settingsDraft.apiAdapter = self.appliedModelSettings.apiAdapter
        self.settingsDraft.baseURL = self.appliedModelSettings.baseURL
        self.settingsDraft.apiKey = self.appliedModelSettings.apiKey
        self.settingsDraft.modelID = self.appliedModelSettings.modelID
    }

    private func refreshSettingsDraftFromState() {
        self.settingsDraft.connectionMode = self.appState.connectionMode
        self.settingsDraft.remoteTransport = self.appState.remoteTransport
        self.settingsDraft.remoteURL = self.appState.remoteUrl
        self.settingsDraft.remoteToken = self.appState.remoteToken
        self.settingsDraft.remoteTarget = self.appState.remoteTarget
        self.settingsDraft.remoteIdentity = self.appState.remoteIdentity

        if self.settingsDraft.providerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.settingsDraft.providerId = self.settingsDraft.providerPreset.defaultProviderID
        }
        if self.settingsDraft.apiAdapter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.settingsDraft.apiAdapter = self.settingsDraft.providerPreset.apiAdapter
        }

        let inferredPreset = DesktopProviderPreset.infer(
            providerID: self.settingsDraft.providerId,
            baseURL: self.settingsDraft.baseURL,
            apiAdapter: self.settingsDraft.apiAdapter)
        self.settingsDraft.providerPreset = inferredPreset
    }

    private func resolveModelIDForSave(
        explicitModelID: String,
        providerID: String,
        preset: DesktopProviderPreset) -> String
    {
        if !explicitModelID.isEmpty {
            return explicitModelID
        }
        if let current = Self.modelID(from: self.selectedSessionModelRef, providerID: providerID), !current.isEmpty {
            return current
        }
        if let current = Self.modelID(from: self.currentModelRef, providerID: providerID), !current.isEmpty {
            return current
        }
        if let existing = self.availableModels.first(where: { $0.provider.caseInsensitiveCompare(providerID) == .orderedSame })?.id,
           !existing.isEmpty
        {
            return existing
        }
        return ""
    }

    private static func extractSavedProviderDraft(from root: [String: Any]) -> (
        providerID: String,
        baseURL: String,
        apiKey: String,
        apiAdapter: String,
        modelID: String
    )? {
        guard let modelsRoot = root["models"] as? [String: Any],
              let providers = modelsRoot["providers"] as? [String: Any]
        else {
            return nil
        }

        if let preferred = self.extractLastSavedProviderSelection(from: root),
           let preferredDraft = self.extractSavedProviderDraft(
               providers: providers,
               providerID: preferred.providerID,
               preferredModelID: preferred.modelID)
        {
            return preferredDraft
        }

        for (providerID, rawEntry) in providers {
            guard let providerEntry = rawEntry as? [String: Any] else { continue }
            let baseURL = (providerEntry["baseUrl"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let apiKey = (providerEntry["apiKey"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let apiAdapter = (providerEntry["api"] as? String ?? "openai-completions").trimmingCharacters(in: .whitespacesAndNewlines)
            let models = Self.extractProviderModels(from: providerEntry)
            let modelID = ((models.first?["id"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !baseURL.isEmpty || !apiKey.isEmpty || !modelID.isEmpty {
                return (providerID, baseURL, apiKey, apiAdapter.isEmpty ? "openai-completions" : apiAdapter, modelID)
            }
        }
        return nil
    }

    private static func extractSavedProviderDraft(
        providers: [String: Any],
        providerID: String,
        preferredModelID: String) -> (
        providerID: String,
        baseURL: String,
        apiKey: String,
        apiAdapter: String,
        modelID: String
    )? {
        guard let providerEntry = providers[providerID] as? [String: Any] else { return nil }
        let baseURL = (providerEntry["baseUrl"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = (providerEntry["apiKey"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let apiAdapter = (providerEntry["api"] as? String ?? "openai-completions").trimmingCharacters(in: .whitespacesAndNewlines)
        let models = Self.extractProviderModels(from: providerEntry)
        let fallbackModelID = ((models.first?["id"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPreferredModelID = preferredModelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelID = trimmedPreferredModelID.isEmpty ? fallbackModelID : trimmedPreferredModelID
        if !baseURL.isEmpty || !apiKey.isEmpty || !modelID.isEmpty {
            return (providerID, baseURL, apiKey, apiAdapter.isEmpty ? "openai-completions" : apiAdapter, modelID)
        }
        return nil
    }

    private static func persistLastSavedProviderSelection(
        in root: inout [String: Any],
        providerID: String,
        modelID: String)
    {
        var desktop = root["desktop"] as? [String: Any] ?? [:]
        var modelSettings = desktop["modelSettings"] as? [String: Any] ?? [:]
        modelSettings["selectedProviderId"] = providerID
        let trimmedModelID = modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedModelID.isEmpty {
            modelSettings.removeValue(forKey: "selectedModelId")
        } else {
            modelSettings["selectedModelId"] = trimmedModelID
        }
        desktop["modelSettings"] = modelSettings
        root["desktop"] = desktop
    }

    private static func extractLastSavedProviderSelection(
        from root: [String: Any]) -> (providerID: String, modelID: String)?
    {
        guard let desktop = root["desktop"] as? [String: Any],
              let modelSettings = desktop["modelSettings"] as? [String: Any]
        else {
            return nil
        }

        let providerID = (modelSettings["selectedProviderId"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !providerID.isEmpty else { return nil }
        let modelID = (modelSettings["selectedModelId"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (providerID, modelID)
    }

    private func loadModelCatalog() async {
        do {
            let result: ModelsListResult = try await GatewayConnection.shared.requestDecoded(
                method: .modelsList,
                params: nil,
                timeoutMs: 6000)
            self.runtimeModels = result.models.map {
                ModelChoice(
                    id: $0.id,
                    name: $0.name,
                    provider: $0.provider,
                    contextWindow: $0.contextwindow)
            }
        } catch {
            do {
                self.runtimeModels = try await ModelCatalogLoader.load(from: ModelCatalogLoader.defaultPath)
            } catch {
                self.runtimeModels = []
            }
        }
    }

    private func refreshConnectionHint() async -> GatewayEnvironmentStatus {
        let status = await Task.detached(priority: .utility) {
            GatewayEnvironment.check()
        }.value
        self.connectionHint = Self.connectionHint(for: status, mode: self.appState.connectionMode)
        return status
    }

    private func ensureLocalGatewayIfPossible(_ environment: GatewayEnvironmentStatus) async {
        guard self.appState.connectionMode == .local else { return }
        guard case .ok = environment.kind else { return }
        GatewayProcessManager.shared.setActive(true)
        _ = await GatewayProcessManager.shared.waitForGatewayReady(timeout: 6)
    }

    private func ensureLocalStateLayout() {
        try? FileManager.default.createDirectory(
            at: HaoclawPaths.stateDirURL,
            withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(
            at: HaoclawPaths.workspaceURL,
            withIntermediateDirectories: true)
    }

    @discardableResult
    private func applyPrimaryModelSelection(
        providerID: String,
        modelID: String,
        apiAdapter: String) async -> String
    {
        let trimmedProviderID = providerID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModelID = modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedApiAdapter = apiAdapter.trimmingCharacters(in: .whitespacesAndNewlines)
        let primaryRef = "\(trimmedProviderID)/\(trimmedModelID)"

        guard !trimmedProviderID.isEmpty, !trimmedModelID.isEmpty else {
            return primaryRef
        }

        var root = HaoclawConfigFile.loadDict()
        var modelsRoot = root["models"] as? [String: Any] ?? [:]
        var providers = modelsRoot["providers"] as? [String: Any] ?? [:]
        var providerEntry = providers[trimmedProviderID] as? [String: Any] ?? [:]
        var providerModels = Self.extractProviderModels(from: providerEntry)
        let nextModelEntry: [String: Any] = [
            "id": trimmedModelID,
            "name": trimmedModelID,
            "api": trimmedApiAdapter.isEmpty ? self.settingsDraft.providerPreset.apiAdapter : trimmedApiAdapter,
        ]
        if let existingIndex = providerModels.firstIndex(where: {
            (($0["id"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == trimmedModelID
        }) {
            providerModels[existingIndex] = nextModelEntry
        } else {
            providerModels.append(nextModelEntry)
        }
        providerEntry["models"] = providerModels
        providers[trimmedProviderID] = providerEntry
        modelsRoot["mode"] = "merge"
        modelsRoot["providers"] = providers
        root["models"] = modelsRoot

        if var agentsRoot = root["agents"] as? [String: Any] {
            var defaults = agentsRoot["defaults"] as? [String: Any] ?? [:]
            defaults["model"] = ["primary": primaryRef]
            agentsRoot["defaults"] = defaults
            root["agents"] = agentsRoot
        } else {
            var agentRoot = root["agent"] as? [String: Any] ?? [:]
            agentRoot["model"] = ["primary": primaryRef]
            root["agent"] = agentRoot
        }

        HaoclawConfigFile.saveDict(root)
        self.configuredModels = Self.extractConfiguredModels(from: root)
        self.currentModelRef = primaryRef
        self.settingsDraft.providerId = trimmedProviderID
        self.settingsDraft.apiAdapter = trimmedApiAdapter
        self.settingsDraft.modelID = trimmedModelID
        try? await GatewayConnection.shared.patchSessionModel(
            sessionKey: self.chatViewModel.sessionKey,
            modelRef: primaryRef)
        return primaryRef
    }

    private static func extractPrimaryModelRef(from root: [String: Any]) -> String? {
        if let agents = root["agents"] as? [String: Any],
           let defaults = agents["defaults"] as? [String: Any],
           let model = defaults["model"] as? [String: Any],
           let primary = model["primary"] as? String
        {
            return primary.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let agent = root["agent"] as? [String: Any],
           let model = agent["model"] as? [String: Any],
           let primary = model["primary"] as? String
        {
            return primary.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    private static func modelID(from modelRef: String, providerID: String) -> String? {
        let parts = modelRef.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        guard parts[0].caseInsensitiveCompare(providerID) == .orderedSame else { return nil }
        return parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractConfiguredModels(from root: [String: Any]) -> [ModelChoice] {
        guard let modelsRoot = root["models"] as? [String: Any],
              let providers = modelsRoot["providers"] as? [String: Any]
        else {
            return []
        }

        var extracted: [ModelChoice] = []
        for (providerID, rawEntry) in providers {
            guard let providerEntry = rawEntry as? [String: Any] else { continue }
            let providerModels = self.extractProviderModels(from: providerEntry)
            for item in providerModels {
                let modelID = ((item["id"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !modelID.isEmpty else { continue }
                let displayName = ((item["name"] as? String) ?? modelID)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                extracted.append(
                    ModelChoice(
                        id: modelID,
                        name: displayName.isEmpty ? modelID : displayName,
                        provider: providerID,
                        contextWindow: item["contextWindow"] as? Int))
            }
        }
        return self.mergeModelChoices(extracted)
    }

    private static func extractProviderModels(from providerEntry: [String: Any]) -> [[String: Any]] {
        guard let rawModels = providerEntry["models"] as? [Any] else { return [] }
        return rawModels.compactMap { $0 as? [String: Any] }
    }

    private static func mergeModelChoices(
        _ groups: [ModelChoice]...,
        currentModelRef: String? = nil) -> [ModelChoice]
    {
        var ordered: [ModelChoice] = []
        var seen = Set<String>()

        for group in groups {
            for choice in group {
                let key = choice.providerAndID
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                ordered.append(choice)
            }
        }

        let trimmedCurrent = currentModelRef?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedCurrent.isEmpty, trimmedCurrent != "未配置" {
            let parts = trimmedCurrent.split(separator: "/", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let provider = parts[0]
                let model = parts[1]
                let key = "\(provider)/\(model)"
                if !seen.contains(key) {
                    ordered.insert(
                        ModelChoice(id: model, name: model, provider: provider, contextWindow: nil),
                        at: 0)
                }
            }
        }

        return ordered
    }

    private static func connectionHint(
        for status: GatewayEnvironmentStatus,
        mode: AppState.ConnectionMode) -> String?
    {
        guard mode == .local else { return nil }
        switch status.kind {
        case .checking:
            return "正在检查本地运行环境…"
        case .ok:
            return nil
        case .missingNode:
            return "缺少本地运行时。点“一键修复”会自动安装 Node.js 22 和 Haoclaw CLI。"
        case .missingGateway:
            return "缺少 Haoclaw CLI。点“一键修复”后，桌面端会自动把本地 Gateway 拉起来。"
        case let .incompatible(found, required):
            return "本地 CLI 版本过旧：当前 \(found)，需要 \(required)。点“一键修复”即可更新。"
        case let .error(message):
            return "本地连接检查失败：\(message)"
        }
    }

    var selectedSessionModelRef: String {
        let sessionModel = self.chatViewModel.sessionChoices
            .first(where: { $0.key == self.chatViewModel.sessionKey })?
            .model?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !sessionModel.isEmpty {
            return sessionModel
        }
        return self.currentModelRef
    }
}

struct DesktopClientRootView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var state: AppState
    let updater: UpdaterProviding?
    @State private var chatViewModel: HaoclawChatViewModel
    @State private var model: DesktopClientModel
    @State private var visibility: NavigationSplitViewVisibility = .all

    init(state: AppState, updater: UpdaterProviding? = nil, sessionKey: String = "main") {
        self._state = Bindable(wrappedValue: state)
        self.updater = updater
        let chatViewModel = HaoclawChatViewModel(sessionKey: sessionKey, transport: MacGatewayChatTransport())
        self._chatViewModel = State(initialValue: chatViewModel)
        self._model = State(initialValue: DesktopClientModel(appState: state, chatViewModel: chatViewModel))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: self.$visibility) {
            DesktopConversationSidebar(model: self.model, chatViewModel: self.chatViewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
        } content: {
            DesktopConversationCenter(model: self.model, chatViewModel: self.chatViewModel)
                .navigationSplitViewColumnWidth(min: 700, ideal: 840)
        } detail: {
            DesktopAgentInspector(model: self.model, chatViewModel: self.chatViewModel, updater: self.updater)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 360)
        }
        .frame(minWidth: 1280, minHeight: 820)
        .sheet(isPresented: self.$model.isShowingControlCenter) {
            DesktopControlCenterSheet(state: self.state, model: self.model, updater: self.updater)
        }
        .onAppear {
            DesktopWindowOpener.shared.register(openWindow: self.openWindow)
            self.model.start()
        }
    }
}

private struct DesktopConversationSidebar: View {
    @Bindable var model: DesktopClientModel
    @Bindable var chatViewModel: HaoclawChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("栏目", selection: self.$model.sidebarSection) {
                ForEach(DesktopSidebarSection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)

            if self.model.sidebarSection == .conversations {
                Button {
                    self.model.createConversation()
                } label: {
                    Label("新建会话", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(self.chatViewModel.sessionChoices, id: \.key) { session in
                            Button {
                                self.model.selectSession(session.key)
                            } label: {
                                DesktopSessionRow(
                                    session: session,
                                    isSelected: session.key == self.chatViewModel.sessionKey)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                Spacer()
                DesktopPlaceholderCard(
                    title: self.model.sidebarSection == .channels ? "渠道面板待接入" : "定时任务待接入",
                    description: self.model.sidebarSection == .channels
                        ? "先把桌面聊天主链路做通，下一步再把飞书、Telegram、Slack 接进来。"
                        : "Cron 任务已有底层能力，下一版会把桌面端管理页补上。")
                Spacer()
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Haoclaw")
                        .font(.headline)
                    Text(self.model.gatewayStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    self.model.openControlCenter(.general)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct DesktopConversationCenter: View {
    @Bindable var model: DesktopClientModel
    @Bindable var chatViewModel: HaoclawChatViewModel

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(self.model.currentSessionTitle)
                        .font(.title2.weight(.semibold))
                    Text(self.model.currentSessionSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("文件") {}
                    .buttonStyle(.bordered)
                    .disabled(true)
                Button("助手") {}
                    .buttonStyle(.bordered)
                    .disabled(true)
            }

            if self.chatViewModel.messages.isEmpty && self.chatViewModel.pendingRunCount == 0 {
                VStack(spacing: 16) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.9), Color.pink.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                        .frame(width: 76, height: 76)
                        .overlay(Text("🐙").font(.system(size: 30)))

                    Text("Haoclaw")
                        .font(.system(size: 34, weight: .semibold))

                    Text("直接连接你的模型 API，本地运行，保留桌面客户端体验。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 14) {
                        DesktopActionCard(
                            title: "可视化配置",
                            description: "直接在桌面端设置连接方式、Gateway、API Key 和模型，无需手改配置文件。",
                            action: { self.model.openModelSettings() })

                        DesktopActionCard(
                            title: self.model.connectionHint == nil ? "刷新连接" : "一键修复",
                            description: self.model.connectionHint ?? "重新检查 Gateway 状态、模型列表和当前配置。",
                            action: {
                                Task {
                                    if self.model.connectionHint == nil {
                                        await self.model.refreshSupportData()
                                    } else {
                                        await self.model.repairConnection()
                                    }
                                }
                            })
                    }
                }
                .padding(.top, 36)
            }

            HaoclawChatView(
                viewModel: self.chatViewModel,
                showsSessionSwitcher: false,
                style: .standard,
                userAccent: Color(nsColor: .controlAccentColor),
                composerAccessory: AnyView(DesktopComposerModelPicker(model: self.model)))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.05), lineWidth: 1))
        }
        .padding(22)
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}

private struct DesktopAgentInspector: View {
    @Bindable var model: DesktopClientModel
    @Bindable var chatViewModel: HaoclawChatViewModel
    let updater: UpdaterProviding?

    private var currentSession: HaoclawChatSessionEntry? {
        self.chatViewModel.sessionChoices.first { $0.key == self.chatViewModel.sessionKey }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.85), Color.pink.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Haoclaw")
                            .font(.title3.weight(.semibold))
                        Text("AI 助手")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                DesktopInfoSection(
                    title: "当前状态",
                    rows: [
                        ("连接", self.model.gatewayStatus),
                        ("模型", self.model.selectedSessionModelRef),
                        ("会话", self.chatViewModel.sessionKey),
                        ("更新", self.updater == nil ? "当前版本" : "可检查更新"),
                    ])

                DesktopInfoSection(
                    title: "会话信息",
                    rows: [
                        ("标题", self.model.currentSessionTitle),
                        ("来源", self.currentSession?.surface ?? "webchat"),
                        ("最近更新", Self.formatTimestamp(self.currentSession?.updatedAt)),
                    ])

                DesktopInfoSection(
                    title: "本地信息",
                    rows: [
                        ("Gateway URL", self.model.gatewayURL),
                        ("配置文件", self.model.configPath),
                        ("状态目录", self.model.stateDirectory),
                    ])

                VStack(alignment: .leading, spacing: 10) {
                    Text("快速操作")
                        .font(.headline)
                    Button("模型与 API") {
                        self.model.openControlCenter(.models)
                    }
                    .buttonStyle(.bordered)

                    if let updater, updater.isAvailable {
                        Button("检查更新 / 立即升级") {
                            self.model.openControlCenter(.updates)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if self.model.appState.connectionMode == .local {
                        Button(self.model.isRepairingConnection ? "修复中…" : "一键修复") {
                            Task { await self.model.repairConnection() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(self.model.isRepairingConnection)
                    }

                    Button("重新连接") {
                        Task { await self.model.refreshSupportData() }
                    }
                    .buttonStyle(.bordered)

                    Button("打开运行台") {
                        self.model.openControlCenter(.general)
                    }
                    .buttonStyle(.bordered)
                }

                if let hint = self.model.connectionHint, !hint.isEmpty {
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if let status = self.model.statusMessage, !status.isEmpty {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private static func formatTimestamp(_ raw: Double?) -> String {
        guard let raw else { return "刚创建" }
        let date = Date(timeIntervalSince1970: raw / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }

}

private struct DesktopModelSettingsSheet: View {
    @Bindable var model: DesktopClientModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("模型与 API")
                        .font(.title2.weight(.semibold))
                    Text("这一页会直接保存连接方式、Gateway 和模型接入信息。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("关闭") {
                    self.model.isShowingModelSettings = false
                }
            }

            DesktopInfoSection(
                title: "网关",
                rows: [
                    ("状态", self.model.gatewayStatus),
                    ("URL", self.model.gatewayURL),
                ])

            VStack(alignment: .leading, spacing: 12) {
                Text("连接方式")
                    .font(.headline)

                Picker("连接方式", selection: self.$model.settingsDraft.connectionMode) {
                    ForEach(AppState.ConnectionMode.allCases, id: \.rawValue) { mode in
                        Text(self.connectionModeTitle(mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if self.model.settingsDraft.connectionMode == .remote {
                    Picker("远程连接方式", selection: self.$model.settingsDraft.remoteTransport) {
                        ForEach(AppState.RemoteTransport.allCases, id: \.rawValue) { transport in
                            Text(self.remoteTransportTitle(transport)).tag(transport)
                        }
                    }
                    .pickerStyle(.segmented)

                    if self.model.settingsDraft.remoteTransport == .direct {
                        TextField("网关地址", text: self.$model.settingsDraft.remoteURL)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        TextField("SSH 目标", text: self.$model.settingsDraft.remoteTarget)
                            .textFieldStyle(.roundedBorder)

                        TextField("SSH 密钥路径", text: self.$model.settingsDraft.remoteIdentity)
                            .textFieldStyle(.roundedBorder)

                        TextField("网关地址", text: self.$model.settingsDraft.remoteURL)
                            .textFieldStyle(.roundedBorder)
                    }

                    SecureField("网关令牌", text: self.$model.settingsDraft.remoteToken)
                        .textFieldStyle(.roundedBorder)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("模型与 API")
                    .font(.headline)

                Picker("服务商预设", selection: self.$model.settingsDraft.providerPreset) {
                    ForEach(DesktopProviderPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: self.model.settingsDraft.providerPreset) { _, _ in
                    self.model.applyProviderPreset()
                }

                Text(self.model.settingsDraft.providerPreset.helpText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                TextField("接口名称", text: self.$model.settingsDraft.providerId)
                    .textFieldStyle(.roundedBorder)

                TextField("API 接口地址", text: self.$model.settingsDraft.baseURL)
                    .textFieldStyle(.roundedBorder)

                SecureField("API 密钥", text: self.$model.settingsDraft.apiKey)
                    .textFieldStyle(.roundedBorder)

                Text("这里不再强制你先填模型 ID。保存后程序会自动扫描当前接口的可用模型。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("重新加载") {
                    Task { await self.model.refreshSupportData() }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("保存并应用") {
                    Task { await self.model.saveModelSettings() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.model.isSavingModelSettings)
            }
        }
        .padding(24)
        .frame(width: 680)
    }
}

private extension DesktopModelSettingsSheet {
    func connectionModeTitle(_ mode: AppState.ConnectionMode) -> String {
        switch mode {
        case .local: "本地"
        case .remote: "远程"
        case .unconfigured: "未配置"
        }
    }

    func remoteTransportTitle(_ transport: AppState.RemoteTransport) -> String {
        switch transport {
        case .direct: "直连"
        case .ssh: "SSH"
        }
    }
}

private struct DesktopComposerModelPicker: View {
    @Bindable var model: DesktopClientModel

    var body: some View {
        Group {
            if self.model.pickerModels.isEmpty {
                HStack(spacing: 6) {
                    Button("添加模型") {
                        self.model.openModelSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("自定义") {
                        self.model.openModelSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } else {
                HStack(spacing: 6) {
                    Picker(
                        "",
                        selection: Binding(
                            get: { self.model.selectedSessionModelRef },
                            set: { next in
                                Task { await self.model.selectSessionModel(next) }
                            }))
                    {
                        ForEach(self.model.pickerModels, id: \.providerAndID) { choice in
                            Text(choice.id).tag(choice.providerAndID)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(maxWidth: 220, alignment: .leading)
                    .help("切换当前会话使用的模型")

                    Button("自定义") {
                        self.model.openModelSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
}

private extension DesktopClientModel {
    static func providerID(from modelRef: String) -> String {
        let trimmed = modelRef.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "未配置" else { return "" }
        let parts = trimmed.split(separator: "/", maxSplits: 1).map(String.init)
        guard let provider = parts.first else { return "" }
        return provider
    }
}

private struct DesktopSessionRow: View {
    let session: HaoclawChatSessionEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(self.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(self.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(self.timeText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(self.isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var displayName: String {
        let trimmed = self.session.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? self.session.key : trimmed
    }

    private var subtitle: String {
        let parts = [
            self.session.surface,
            self.session.model,
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        return parts.isEmpty ? "本地会话" : parts.joined(separator: " · ")
    }

    private var timeText: String {
        guard let raw = self.session.updatedAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: raw / 1000))
    }
}

private struct DesktopActionCard: View {
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(self.title)
                    .font(.headline)
                Text(self.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 300)
    }
}

private struct DesktopPlaceholderCard: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(self.title)
                .font(.headline)
            Text(self.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DesktopInfoSection: View {
    let title: String
    let rows: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(self.title)
                .font(.headline)
            VStack(spacing: 0) {
                ForEach(Array(self.rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .top, spacing: 12) {
                        Text(row.0)
                            .foregroundStyle(.secondary)
                            .frame(width: 76, alignment: .leading)
                        Text(row.1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)

                    if index < self.rows.count - 1 {
                        Divider()
                    }
                }
            }
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

extension ModelChoice {
    var providerAndID: String {
        "\(self.provider)/\(self.id)"
    }
}

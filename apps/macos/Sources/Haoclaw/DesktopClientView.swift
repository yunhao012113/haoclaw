import Foundation
import HaoclawChatUI
import HaoclawProtocol
import Observation
import SwiftUI

private enum DesktopSidebarSection: String, CaseIterable, Identifiable {
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

private struct DesktopModelSettingsDraft: Equatable {
    var providerId = "haoclaw-desktop"
    var gatewayURL = ""
    var baseURL = ""
    var apiKey = ""
    var modelID = ""
}

@MainActor
@Observable
final class DesktopClientModel {
    let chatViewModel: HaoclawChatViewModel

    var sidebarSection: DesktopSidebarSection = .conversations
    var isShowingModelSettings = false
    var isSavingModelSettings = false
    var isRefreshing = false
    var statusMessage: String?
    var models: [ModelChoice] = []
    var currentModelRef = "未配置"
    var gatewayURL = "未连接"
    var gatewayStatus = "连接中"
    var isGatewayReady = false
    var stateDirectory = "未发现"
    var configPath = "未发现"
    var settingsDraft = DesktopModelSettingsDraft()

    @ObservationIgnored private var endpointTask: Task<Void, Never>?

    init(chatViewModel: HaoclawChatViewModel) {
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

        await self.loadModelCatalog()
        await self.loadCurrentConfig()
        await self.refreshEndpoint()
        self.chatViewModel.refreshSessions(limit: 50)
    }

    func createConversation() {
        let next = "desktop-\(UUID().uuidString.prefix(8))"
        self.chatViewModel.switchSession(to: next)
    }

    func selectSession(_ key: String) {
        self.chatViewModel.switchSession(to: key)
    }

    func openModelSettings() {
        self.settingsDraft.providerId = "haoclaw-desktop"
        self.settingsDraft.gatewayURL = self.gatewayURL

        let parts = self.currentModelRef.split(separator: "/", maxSplits: 1).map(String.init)
        if parts.count == 2 {
            self.settingsDraft.modelID = parts[1]
        }

        self.isShowingModelSettings = true
    }

    func saveModelSettings() async {
        let trimmedBaseURL = self.settingsDraft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedApiKey = self.settingsDraft.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedModelID = self.settingsDraft.modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProviderID = self.settingsDraft.providerId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedBaseURL.isEmpty, !trimmedModelID.isEmpty else {
            self.statusMessage = "请先填写 Base URL 和模型 ID。"
            return
        }

        self.isSavingModelSettings = true
        defer { self.isSavingModelSettings = false }

        var root = await ConfigStore.load()
        var modelsRoot = root["models"] as? [String: Any] ?? [:]
        var providers = modelsRoot["providers"] as? [String: Any] ?? [:]

        var providerEntry: [String: Any] = [
            "baseUrl": trimmedBaseURL,
            "api": "openai-completions",
            "models": [[
                "id": trimmedModelID,
                "name": trimmedModelID,
                "api": "openai-completions",
            ]],
        ]
        if !trimmedApiKey.isEmpty {
            providerEntry["apiKey"] = trimmedApiKey
        }
        providers[trimmedProviderID] = providerEntry
        modelsRoot["mode"] = "merge"
        modelsRoot["providers"] = providers
        root["models"] = modelsRoot

        let primaryRef = "\(trimmedProviderID)/\(trimmedModelID)"
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

        do {
            try await ConfigStore.save(root)
            self.currentModelRef = primaryRef
            self.statusMessage = "模型与 API 已保存。"
            self.isShowingModelSettings = false
            await self.refreshSupportData()
        } catch {
            self.statusMessage = error.localizedDescription
        }
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
            self.gatewayStatus = error.localizedDescription
            self.isGatewayReady = false
        }
    }

    private func loadCurrentConfig() async {
        let root = await ConfigStore.load()
        let modelRef = Self.extractPrimaryModelRef(from: root)
        if let modelRef, !modelRef.isEmpty {
            self.currentModelRef = modelRef
            let parts = modelRef.split(separator: "/", maxSplits: 1).map(String.init)
            let providerID = parts.first ?? "haoclaw-desktop"
            let providerEntry = ((root["models"] as? [String: Any])?["providers"] as? [String: Any])?[providerID] as? [String: Any]
            self.settingsDraft.providerId = providerID
            self.settingsDraft.baseURL = providerEntry?["baseUrl"] as? String ?? ""
            self.settingsDraft.apiKey = providerEntry?["apiKey"] as? String ?? ""
            if parts.count == 2 {
                self.settingsDraft.modelID = parts[1]
            }
        } else {
            self.currentModelRef = "未配置"
        }

        let paths = await GatewayConnection.shared.snapshotPaths()
        self.stateDirectory = paths.stateDir ?? "未发现"
        self.configPath = paths.configPath ?? "未发现"
    }

    private func loadModelCatalog() async {
        do {
            let result: ModelsListResult = try await GatewayConnection.shared.requestDecoded(
                method: .modelsList,
                params: nil,
                timeoutMs: 6000)
            self.models = result.models
        } catch {
            do {
                self.models = try await ModelCatalogLoader.load(from: ModelCatalogLoader.defaultPath)
            } catch {
                self.models = []
            }
        }
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
}

struct DesktopClientRootView: View {
    @Bindable var state: AppState
    @State private var chatViewModel: HaoclawChatViewModel
    @State private var model: DesktopClientModel
    @State private var visibility: NavigationSplitViewVisibility = .all

    init(state: AppState, sessionKey: String = "main") {
        self._state = Bindable(wrappedValue: state)
        let chatViewModel = HaoclawChatViewModel(sessionKey: sessionKey, transport: MacGatewayChatTransport())
        self._chatViewModel = State(initialValue: chatViewModel)
        self._model = State(initialValue: DesktopClientModel(chatViewModel: chatViewModel))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: self.$visibility) {
            DesktopConversationSidebar(model: self.model, chatViewModel: self.chatViewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 280, max: 320)
        } content: {
            DesktopConversationCenter(model: self.model, chatViewModel: self.chatViewModel)
                .navigationSplitViewColumnWidth(min: 700, ideal: 840)
        } detail: {
            DesktopAgentInspector(model: self.model, chatViewModel: self.chatViewModel)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 360)
        }
        .frame(minWidth: 1280, minHeight: 820)
        .sheet(isPresented: self.$model.isShowingModelSettings) {
            DesktopModelSettingsSheet(model: self.model)
        }
        .onAppear {
            self.model.start()
        }
    }
}

private struct DesktopConversationSidebar: View {
    @Bindable var model: DesktopClientModel
    @Bindable var chatViewModel: HaoclawChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Section", selection: self.$model.sidebarSection) {
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
                    self.model.openModelSettings()
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
                Button("Agent") {}
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
                            title: "快速配置",
                            description: "填写 Base URL、API Key、模型 ID，保存后即可开始聊天。",
                            action: { self.model.openModelSettings() })

                        DesktopActionCard(
                            title: "刷新连接",
                            description: "重新检查 Gateway 状态、模型列表和当前配置。",
                            action: { Task { await self.model.refreshSupportData() } })
                    }
                }
                .padding(.top, 36)
            }

            HaoclawChatView(
                viewModel: self.chatViewModel,
                showsSessionSwitcher: false,
                style: .standard,
                userAccent: Color(nsColor: .controlAccentColor))
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
                        Text("AI coworker")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                DesktopInfoSection(
                    title: "当前状态",
                    rows: [
                        ("连接", self.model.gatewayStatus),
                        ("模型", self.model.currentModelRef),
                        ("会话", self.chatViewModel.sessionKey),
                    ])

                DesktopInfoSection(
                    title: "会话信息",
                    rows: [
                        ("标题", self.model.currentSessionTitle),
                        ("来源", self.currentSession?.surface ?? "webchat"),
                        ("最近更新", Self.formatTimestamp(self.currentSession?.updatedAt)),
                    ])

                DesktopInfoSection(
                    title: "记忆区",
                    rows: [
                        ("Gateway URL", self.model.gatewayURL),
                        ("配置文件", self.model.configPath),
                        ("状态目录", self.model.stateDirectory),
                    ])

                VStack(alignment: .leading, spacing: 10) {
                    Text("快速操作")
                        .font(.headline)
                    Button("模型与 API") {
                        self.model.openModelSettings()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("重新连接") {
                        Task { await self.model.refreshSupportData() }
                    }
                    .buttonStyle(.bordered)
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
                    Text("第一版只保留最常用的自定义模型接入。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("关闭") {
                    self.model.isShowingModelSettings = false
                }
            }

            DesktopInfoSection(
                title: "Gateway",
                rows: [
                    ("状态", self.model.gatewayStatus),
                    ("URL", self.model.gatewayURL),
                ])

            VStack(alignment: .leading, spacing: 12) {
                Text("自定义模型")
                    .font(.headline)

                TextField("Provider ID", text: self.$model.settingsDraft.providerId)
                    .textFieldStyle(.roundedBorder)

                TextField("Base URL", text: self.$model.settingsDraft.baseURL)
                    .textFieldStyle(.roundedBorder)

                SecureField("API Key", text: self.$model.settingsDraft.apiKey)
                    .textFieldStyle(.roundedBorder)

                TextField("Model ID", text: self.$model.settingsDraft.modelID)
                    .textFieldStyle(.roundedBorder)

                if !self.model.models.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(self.model.models.prefix(10)), id: \.providerAndID) { choice in
                                Button("\(choice.provider)/\(choice.id)") {
                                    self.model.settingsDraft.modelID = choice.id
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }
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

private extension ModelChoice {
    var providerAndID: String {
        "\(self.provider)/\(self.id)"
    }
}

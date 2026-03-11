import AppKit
import Foundation
import Observation
import SwiftUI

struct DesktopControlCenterSheet: View {
    @Bindable var state: AppState
    @Bindable var model: DesktopClientModel
    let updater: UpdaterProviding?

    @AppStorage("desktop.workspace.scopeLimited") private var scopeLimited = true
    @AppStorage("desktop.workspace.autoArchive") private var autoArchive = true
    @AppStorage("desktop.workspace.watchFiles") private var watchFiles = true
    @AppStorage("desktop.showToolDetails") private var showToolDetails = true

    @State private var workspacePath = ""
    @State private var toolDeck = DesktopToolDeckStore()

    var body: some View {
        NavigationSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(DesktopControlSection.allCases) { section in
                        Button {
                            self.model.controlSection = section
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: section.symbol)
                                    .frame(width: 18)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(section.title)
                                        .font(.body.weight(.semibold))
                                    Text(section.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(self.model.controlSection == section ? Color.accentColor.opacity(0.12) : Color.clear))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
            }
            .navigationTitle("Haoclaw 运行台")
            .frame(minWidth: 280, idealWidth: 320)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    self.hero

                    switch self.model.controlSection {
                    case .general:
                        DesktopControlGeneralPane(state: self.state, model: self.model, showToolDetails: self.$showToolDetails)
                    case .models:
                        DesktopControlModelsPane(model: self.model)
                    case .tools:
                        DesktopControlToolsPane(store: self.toolDeck)
                    case .skills:
                        DesktopControlSectionShell(
                            title: "技能库",
                            description: "按运行状态查看技能，直接在桌面端启停、补环境变量和刷新能力目录。")
                        {
                            SkillsSettings(state: self.state)
                        }
                    case .channels:
                        DesktopControlSectionShell(
                            title: "渠道接入",
                            description: "集中管理 IM 接入与消息渠道。这里保留 Haoclaw 自己的入口语义，不复刻外部产品的配置版式。")
                        {
                            ChannelsSettings()
                        }
                    case .automation:
                        DesktopControlSectionShell(
                            title: "自动任务",
                            description: "管理周期任务、批量巡检和后台流程。")
                        {
                            CronSettings()
                        }
                    case .workspace:
                        DesktopControlWorkspacePane(
                            workspacePath: self.$workspacePath,
                            scopeLimited: self.$scopeLimited,
                            autoArchive: self.$autoArchive,
                            watchFiles: self.$watchFiles)
                    case .updates:
                        DesktopControlUpdatesPane(updater: self.updater)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .underPageBackgroundColor))
        }
        .frame(minWidth: 1220, minHeight: 860)
        .onAppear {
            self.workspacePath = HaoclawConfigFile.agentWorkspace() ?? HaoclawConfigFile.defaultWorkspaceURL().path
            self.toolDeck.load()
        }
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(self.model.controlSection.title)
                    .font(.system(size: 28, weight: .bold))
                Text(self.model.controlSection.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    DesktopStatusChip(title: self.model.gatewayStatus, tint: self.model.isGatewayReady ? .green : .orange)
                    DesktopStatusChip(title: self.state.connectionMode == .local ? "本地运行" : "远程接入", tint: .blue)
                    DesktopStatusChip(title: self.model.selectedSessionModelRef, tint: .purple)
                }
            }
            Spacer()
            Button("关闭运行台") {
                self.model.isShowingControlCenter = false
            }
            .buttonStyle(.bordered)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.12), Color.pink.opacity(0.08), Color.white.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)))
    }
}

private struct DesktopControlGeneralPane: View {
    @Bindable var state: AppState
    @Bindable var model: DesktopClientModel
    @Binding var showToolDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DesktopControlCard(title: "运行与显示", subtitle: "把常用开关收在一个地方，打开应用就能改。") {
                VStack(alignment: .leading, spacing: 14) {
                    SettingsToggleRow(title: "开机自动启动", subtitle: "登录后自动启动 Haoclaw。", binding: self.$state.launchAtLogin)
                    SettingsToggleRow(title: "在 Dock 中显示", subtitle: "保持桌面应用形态，不切回纯菜单栏模式。", binding: self.$state.showDockIcon)
                    SettingsToggleRow(title: "启用图标动效", subtitle: "状态图标保留呼吸感和轻微动画。", binding: self.$state.iconAnimationsEnabled)
                    SettingsToggleRow(title: "显示工具过程", subtitle: "在对话中显示工具调用过程与执行详情。", binding: self.$showToolDetails)
                }
            }

            DesktopControlCard(title: "连接策略", subtitle: "统一调整本地 / 远程模式，并在这里直接做健康检查。") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("运行模式", selection: self.$state.connectionMode) {
                        Text("未配置").tag(AppState.ConnectionMode.unconfigured)
                        Text("本机").tag(AppState.ConnectionMode.local)
                        Text("远程").tag(AppState.ConnectionMode.remote)
                    }
                    .pickerStyle(.segmented)

                    DesktopInfoSection(
                        title: "当前链路",
                        rows: [
                            ("Gateway", self.model.gatewayURL),
                            ("状态", self.model.gatewayStatus),
                            ("提示", self.model.connectionHint ?? "当前链路可用"),
                        ])

                    HStack(spacing: 10) {
                        Button("刷新状态") {
                            Task { await self.model.refreshSupportData() }
                        }
                        .buttonStyle(.bordered)

                        if self.state.connectionMode == .local {
                            Button(self.model.isRepairingConnection ? "修复中…" : "一键修复") {
                                Task { await self.model.repairConnection() }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(self.model.isRepairingConnection)
                        }
                    }
                }
            }
        }
    }
}

private struct DesktopControlModelsPane: View {
    @Bindable var model: DesktopClientModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DesktopControlCard(title: "Provider 与接入", subtitle: "这里是 Haoclaw 自己的模型中心，不按外部平台的表单版式照搬。") {
                VStack(alignment: .leading, spacing: 12) {
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

                    TextField("服务商 ID", text: self.$model.settingsDraft.providerId)
                        .textFieldStyle(.roundedBorder)
                    TextField("接口地址", text: self.$model.settingsDraft.baseURL)
                        .textFieldStyle(.roundedBorder)
                    SecureField("API Key", text: self.$model.settingsDraft.apiKey)
                        .textFieldStyle(.roundedBorder)
                    TextField("模型 ID", text: self.$model.settingsDraft.modelID)
                        .textFieldStyle(.roundedBorder)
                    TextField("适配器", text: self.$model.settingsDraft.apiAdapter)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 10) {
                        Button("保存并应用") {
                            Task { await self.model.saveModelSettings() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(self.model.isSavingModelSettings)

                        Button("重新扫描") {
                            Task { await self.model.refreshSupportData() }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            DesktopControlCard(title: "已接入模型", subtitle: "会话下拉会优先显示当前 Provider 下面的模型，这里列出你已经挂进来的项。") {
                VStack(alignment: .leading, spacing: 12) {
                    if self.model.availableModels.isEmpty {
                        Text("当前还没有可用模型。先填入接口和 API Key，再保存。")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                            ForEach(self.model.availableModels, id: \.providerAndID) { choice in
                                DesktopModelChoiceCard(
                                    choice: choice,
                                    isCurrent: choice.providerAndID == self.model.selectedSessionModelRef,
                                    action: {
                                        Task { await self.model.selectSessionModel(choice.providerAndID) }
                                    })
                            }
                        }
                    }

                    if !self.model.settingsSuggestedModels.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(self.model.settingsSuggestedModels, id: \.providerAndID) { choice in
                                    Button("\(choice.provider)/\(choice.id)") {
                                        self.model.settingsDraft.providerId = choice.provider
                                        self.model.settingsDraft.modelID = choice.id
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct DesktopControlToolsPane: View {
    @Bindable var store: DesktopToolDeckStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DesktopControlCard(title: "工具接入", subtitle: "这里不是直接照搬 MCP 页面，而是做成 Haoclaw 的“工具甲板”。本地命令工具和 HTTP 工具都能收进来。") {
                VStack(alignment: .leading, spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button("添加本地命令") {
                                self.store.startAdding(type: .localCommand)
                            }
                            .buttonStyle(.borderedProminent)
                            Button("添加 HTTP 工具") {
                                self.store.startAdding(type: .httpEndpoint)
                            }
                            .buttonStyle(.bordered)
                            Button("文件浏览模板") {
                                self.store.addTemplate(.filesystem)
                            }
                            .buttonStyle(.bordered)
                            Button("网页抓取模板") {
                                self.store.addTemplate(.webFetch)
                            }
                            .buttonStyle(.bordered)
                            Button("SQLite 模板") {
                                self.store.addTemplate(.sqlite)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if self.store.connectors.isEmpty {
                        Text("还没有工具接入项。你可以把本地命令、HTTP 网关或常用工具模板收进来。")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(self.store.connectors) { connector in
                                DesktopToolConnectorRow(connector: connector) { updated in
                                    self.store.update(updated)
                                } onDelete: {
                                    self.store.remove(connector.id)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: self.$store.editingConnector) { connector in
            DesktopToolConnectorEditor(connector: connector) { result in
                self.store.finishEditing(result)
            }
        }
    }
}

private struct DesktopControlWorkspacePane: View {
    @Binding var workspacePath: String
    @Binding var scopeLimited: Bool
    @Binding var autoArchive: Bool
    @Binding var watchFiles: Bool
    @State private var statusMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DesktopControlCard(title: "默认工作区", subtitle: "把项目目录、上下文文件和技能扩展都统一收在这个工作区下。") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        TextField("工作区路径", text: self.$workspacePath)
                            .textFieldStyle(.roundedBorder)
                        Button("浏览") {
                            self.pickFolder()
                        }
                        .buttonStyle(.bordered)
                        Button("打开") {
                            let url = URL(fileURLWithPath: self.workspacePath)
                            NSWorkspace.shared.open(url)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("保存工作区") {
                        let trimmed = self.workspacePath.trimmingCharacters(in: .whitespacesAndNewlines)
                        HaoclawConfigFile.setAgentWorkspace(trimmed.isEmpty ? nil : trimmed)
                        self.statusMessage = "工作区已保存。"
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            DesktopControlCard(title: "上下文策略", subtitle: "这些开关是 Haoclaw 自己的桌面工作区策略，用来控制本地内容如何被持续利用。") {
                VStack(alignment: .leading, spacing: 14) {
                    SettingsToggleRow(title: "限制工作目录范围", subtitle: "将工具访问收束到当前工作区，降低误操作外部目录的风险。", binding: self.$scopeLimited)
                    SettingsToggleRow(title: "自动归档上下文", subtitle: "把关键对话、产出和草稿自动归档到工作区。", binding: self.$autoArchive)
                    SettingsToggleRow(title: "监听文件变化", subtitle: "监控工作区变动，给后续会话提供更及时的上下文。", binding: self.$watchFiles)
                }
            }

            if let statusMessage, !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "选择工作区"
        if panel.runModal() == .OK, let url = panel.url {
            self.workspacePath = url.path
        }
    }
}

private struct DesktopControlUpdatesPane: View {
    let updater: UpdaterProviding?
    @AppStorage("autoUpdateEnabled") private var autoUpdateEnabled = true

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
        return version
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            DesktopControlCard(title: "版本与升级", subtitle: "以后从这版开始，后续更新尽量走应用内一键升级，不再每次手动去下载。") {
                VStack(alignment: .leading, spacing: 12) {
                    DesktopInfoSection(
                        title: "当前安装",
                        rows: [
                            ("版本", self.versionString),
                            ("升级器", self.updater == nil ? "不可用" : "已接入"),
                            ("下载页", "yunhao012113.github.io/haoclaw"),
                        ])

                    if let updater, updater.isAvailable {
                        SettingsToggleRow(title: "自动检查更新", subtitle: "后台检测新版本，并在应用内给出升级入口。", binding: self.$autoUpdateEnabled)
                            .onChange(of: self.autoUpdateEnabled) { _, newValue in
                                updater.automaticallyChecksForUpdates = newValue
                                updater.automaticallyDownloadsUpdates = newValue
                            }

                        HStack(spacing: 10) {
                            Button(updater.updateStatus.isUpdateReady ? "立即升级" : "检查更新") {
                                updater.checkForUpdates(nil)
                            }
                            .buttonStyle(.borderedProminent)

                            Button("打开发布记录") {
                                if let url = URL(string: "https://github.com/yunhao012113/haoclaw/releases/latest") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text("当前构建没有接入升级器，请使用 GitHub Release 安装正式版本。")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            self.updater?.automaticallyChecksForUpdates = self.autoUpdateEnabled
            self.updater?.automaticallyDownloadsUpdates = self.autoUpdateEnabled
        }
    }
}

private struct DesktopControlSectionShell<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        DesktopControlCard(title: self.title, subtitle: self.description) {
            self.content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DesktopControlCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.title3.weight(.semibold))
                Text(self.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            self.content()
        }
        .padding(22)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1))
    }
}

private struct DesktopStatusChip: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(self.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(self.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(self.tint.opacity(0.10))
            .clipShape(Capsule())
    }
}

private struct DesktopModelChoiceCard: View {
    let choice: ModelChoice
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(choice.id)
                .font(.headline)
            Text(choice.provider)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let contextWindow = choice.contextWindow {
                Text("上下文 \(contextWindow)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button(self.isCurrent ? "当前会话正在使用" : "切到这个模型") {
                self.action()
            }
            .buttonStyle(self.isCurrent ? .bordered : .borderedProminent)
            .disabled(self.isCurrent)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(self.isCurrent ? Color.orange.opacity(0.10) : Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private enum DesktopToolConnectorType: String, Codable, CaseIterable, Identifiable {
    case localCommand
    case httpEndpoint

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .localCommand: "本地命令"
        case .httpEndpoint: "HTTP 工具"
        }
    }
}

private enum DesktopToolTemplate {
    case filesystem
    case webFetch
    case sqlite
}

private struct DesktopToolConnector: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: DesktopToolConnectorType
    var target: String
    var arguments: String
    var environment: String
    var enabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        type: DesktopToolConnectorType,
        target: String,
        arguments: String = "",
        environment: String = "",
        enabled: Bool = true)
    {
        self.id = id
        self.name = name
        self.type = type
        self.target = target
        self.arguments = arguments
        self.environment = environment
        self.enabled = enabled
    }
}

@MainActor
@Observable
private final class DesktopToolDeckStore {
    private static let storageKey = "desktop.toolDeck.connectors"

    var connectors: [DesktopToolConnector] = []
    var editingConnector: DesktopToolConnector?

    func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([DesktopToolConnector].self, from: data)
        else {
            return
        }
        self.connectors = decoded
    }

    func startAdding(type: DesktopToolConnectorType) {
        self.editingConnector = DesktopToolConnector(name: "", type: type, target: "")
    }

    func addTemplate(_ template: DesktopToolTemplate) {
        let connector: DesktopToolConnector
        switch template {
        case .filesystem:
            connector = DesktopToolConnector(
                name: "文件浏览器",
                type: .localCommand,
                target: "npx",
                arguments: "-y @modelcontextprotocol/server-filesystem ~/Desktop",
                environment: "")
        case .webFetch:
            connector = DesktopToolConnector(
                name: "网页抓取",
                type: .httpEndpoint,
                target: "https://example.com/mcp/web-fetch",
                arguments: "",
                environment: "AUTH_TOKEN=your-token")
        case .sqlite:
            connector = DesktopToolConnector(
                name: "SQLite 查询",
                type: .localCommand,
                target: "npx",
                arguments: "-y @modelcontextprotocol/server-sqlite ~/Desktop/data.db",
                environment: "")
        }
        self.connectors.append(connector)
        self.persist()
    }

    func finishEditing(_ connector: DesktopToolConnector?) {
        guard let connector else {
            self.editingConnector = nil
            return
        }
        if let index = self.connectors.firstIndex(where: { $0.id == connector.id }) {
            self.connectors[index] = connector
        } else {
            self.connectors.append(connector)
        }
        self.editingConnector = nil
        self.persist()
    }

    func update(_ connector: DesktopToolConnector) {
        guard let index = self.connectors.firstIndex(where: { $0.id == connector.id }) else { return }
        self.connectors[index] = connector
        self.persist()
    }

    func remove(_ id: UUID) {
        self.connectors.removeAll { $0.id == id }
        self.persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(self.connectors) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

private struct DesktopToolConnectorRow: View {
    let connector: DesktopToolConnector
    let onUpdate: (DesktopToolConnector) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(self.connector.name)
                        .font(.headline)
                    DesktopStatusChip(title: self.connector.type.title, tint: .blue)
                }
                Text(self.connector.target)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                if !self.connector.arguments.isEmpty {
                    Text(self.connector.arguments)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle(
                "",
                isOn: Binding(
                    get: { self.connector.enabled },
                    set: { next in
                        var updated = self.connector
                        updated.enabled = next
                        self.onUpdate(updated)
                    }))
            .labelsHidden()
            Button("删除", role: .destructive) {
                self.onDelete()
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DesktopToolConnectorEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var connector: DesktopToolConnector
    let onSave: (DesktopToolConnector?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(self.connector.name.isEmpty ? "添加工具" : "编辑工具")
                .font(.title3.weight(.semibold))

            Picker("类型", selection: self.$connector.type) {
                ForEach(DesktopToolConnectorType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)

            TextField("显示名称", text: self.$connector.name)
                .textFieldStyle(.roundedBorder)
            TextField(self.connector.type == .localCommand ? "命令 / 可执行文件" : "HTTP 地址", text: self.$connector.target)
                .textFieldStyle(.roundedBorder)
            TextField("参数", text: self.$connector.arguments)
                .textFieldStyle(.roundedBorder)
            TextField("环境变量（每行 KEY=VALUE）", text: self.$connector.environment, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(4, reservesSpace: true)

            HStack {
                Button("取消") {
                    self.onSave(nil)
                    self.dismiss()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("保存") {
                    self.onSave(self.connector)
                    self.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.connector.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    self.connector.target.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}

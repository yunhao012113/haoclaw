import Observation
import HaoclawProtocol
import SwiftUI

struct SkillsSettings: View {
    @Bindable var state: AppState
    @State private var model = SkillsSettingsModel()
    @State private var envEditor: EnvEditorState?
    @State private var filter: SkillsFilter = .all

    init(state: AppState = AppStateStore.shared, model: SkillsSettingsModel = SkillsSettingsModel()) {
        self.state = state
        self._model = State(initialValue: model)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            self.header
            self.statusBanner
            self.skillsList
            Spacer(minLength: 0)
        }
        .task { await self.model.refresh() }
        .sheet(item: self.$envEditor) { editor in
            EnvEditorView(editor: editor) { value in
                Task {
                    await self.model.updateEnv(
                        skillKey: editor.skillKey,
                        envKey: editor.envKey,
                        value: value,
                        isPrimary: editor.isPrimary)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("技能库")
                    .font(.headline)
                Text("满足命令、环境变量和配置要求后，技能才会进入可用状态。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if self.model.isLoading {
                ProgressView()
            } else {
                Button {
                    Task { await self.model.refresh() }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .help("刷新技能列表")
            }
            self.headerFilter
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        if let error = self.model.error {
            Text(error)
                .font(.footnote)
                .foregroundStyle(.orange)
        } else if let message = self.model.statusMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var skillsList: some View {
        if self.model.skills.isEmpty {
            Text("当前还没有读取到技能。")
                .foregroundStyle(.secondary)
        } else {
            List {
                ForEach(self.filteredSkills) { skill in
                    SkillRow(
                        skill: skill,
                        isBusy: self.model.isBusy(skill: skill),
                        connectionMode: self.state.connectionMode,
                        onToggleEnabled: { enabled in
                            Task { await self.model.setEnabled(skillKey: skill.skillKey, enabled: enabled) }
                        },
                        onInstall: { option, target in
                            Task { await self.model.install(skill: skill, option: option, target: target) }
                        },
                        onSetEnv: { envKey, isPrimary in
                            self.envEditor = EnvEditorState(
                                skillKey: skill.skillKey,
                                skillName: skill.name,
                                envKey: envKey,
                                isPrimary: isPrimary)
                        })
                }
                if !self.model.skills.isEmpty, self.filteredSkills.isEmpty {
                    Text("当前筛选条件下没有匹配的技能。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.inset)
        }
    }

    private var headerFilter: some View {
        Picker("筛选", selection: self.$filter) {
            ForEach(SkillsFilter.allCases) { filter in
                Text(filter.title)
                    .tag(filter)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .frame(width: 160, alignment: .trailing)
    }

    private var filteredSkills: [SkillStatus] {
        self.model.skills.filter { skill in
            switch self.filter {
            case .all:
                true
            case .ready:
                !skill.disabled && skill.eligible
            case .needsSetup:
                !skill.disabled && !skill.eligible
            case .disabled:
                skill.disabled
            }
        }
    }
}

private enum SkillsFilter: String, CaseIterable, Identifiable {
    case all
    case ready
    case needsSetup
    case disabled

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .all:
            "全部"
        case .ready:
            "可用"
        case .needsSetup:
            "待配置"
        case .disabled:
            "已禁用"
        }
    }
}

enum SkillsInstallTarget: String, CaseIterable {
    case gateway
    case local
}

private struct SkillRow: View {
    let skill: SkillStatus
    let isBusy: Bool
    let connectionMode: AppState.ConnectionMode
    let onToggleEnabled: (Bool) -> Void
    let onInstall: (SkillInstallOption, SkillsInstallTarget) -> Void
    let onSetEnv: (String, Bool) -> Void

    private var missingBins: [String] {
        self.skill.missing.bins
    }

    private var missingEnv: [String] {
        self.skill.missing.env
    }

    private var missingConfig: [String] {
        self.skill.missing.config
    }

    private static let localizedSummaries: [String: String] = [
        "1password": "用于 1Password CLI 的登录、读取和密钥注入辅助。",
        "agent-browser": "用于浏览器自动化、页面点击、截图和元素读取。",
        "apple-notes": "用于读写 Apple Notes 备忘录内容。",
        "apple-reminders": "用于管理 Apple 提醒事项。",
        "bear-notes": "用于 Bear 笔记的读取、创建和整理。",
        "blogwatcher": "用于订阅博客更新并整理新增内容。",
        "blucli": "用于蓝牙设备和蓝牙状态操作。",
        "bluebubbles": "用于 BlueBubbles / iMessage 相关联动。",
        "camsnap": "用于摄像头拍照与图像采集。",
        "canvas": "用于桌面画布、截图和可视化产出。",
        "clawhub": "用于连接 ClawHub 技能市场或技能仓库。",
        "coding-agent": "用于代码任务、补丁编写和工程辅助。",
        "discord": "用于 Discord 渠道接入和消息操作。",
        "eightctl": "用于 eightctl 命令集成。",
        "gemini": "用于 Gemini 系列模型与工具联动。",
        "gh-issues": "用于 GitHub Issue 查询和处理。",
        "gifgrep": "用于 GIF / 动图搜索与筛选。",
        "github": "用于 GitHub 仓库、PR 和提交管理。",
        "gog": "用于命令行工作流和任务操作。",
        "goplaces": "用于地点搜索和地理信息读取。",
        "healthcheck": "用于运行状态检查和健康巡检。",
        "himalaya": "用于邮件客户端和邮箱操作。",
        "imsg": "用于 iMessage / 消息数据库相关功能。",
        "mcporter": "用于 MCP 服务搬运和封装。",
        "model-usage": "用于模型调用量、成本和上下文统计。",
        "nano-banana-pro": "用于图像理解和 Nano Banana 系列能力。",
        "nano-pdf": "用于 PDF 读取、提取和总结。",
        "notion": "用于 Notion 页面和数据库操作。",
        "obsidian": "用于 Obsidian 笔记库读写。",
        "openai-image-gen": "用于 OpenAI 图像生成。",
        "openai-whisper": "用于 Whisper 本地语音转写。",
        "openai-whisper-api": "用于 Whisper API 语音转写。",
        "openhue": "用于 Hue 灯光与家庭设备控制。",
        "oracle": "用于数据库或 Oracle 相关操作。",
        "ordercli": "用于命令行订单或流程管理。",
        "peekaboo": "用于桌面 UI 自动化和可视化交互。",
        "sag": "用于命令行检索与摘要。",
        "session-logs": "用于会话日志查看和归档。",
        "sherpa-onnx-tts": "用于本地语音合成。",
        "skill-creator": "用于创建和维护自定义技能。",
        "slack": "用于 Slack 渠道接入和消息收发。",
        "songsee": "用于音乐内容查询。",
        "sonoscli": "用于 Sonos 播放器控制。",
        "spotify-player": "用于 Spotify 播放控制。",
        "summarize": "用于网页、文档或对话摘要。",
        "things-mac": "用于 Things 任务管理。",
        "tmux": "用于 tmux 会话和终端管理。",
        "trello": "用于 Trello 看板操作。",
        "video-frames": "用于视频抽帧和画面分析。",
        "voice-call": "用于语音通话和电话型交互。",
        "wacli": "用于 WhatsApp CLI 或相关工具联动。",
        "weather": "用于天气查询。",
        "xurl": "用于网络请求和 URL 调试。",
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(self.skill.emoji ?? "✨")
                .font(.title2)

            VStack(alignment: .leading, spacing: 6) {
                Text(self.skill.name)
                    .font(.headline)
                Text(self.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                self.metaRow

                if self.skill.disabled {
                    Text("已在配置中禁用")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !self.requirementsMet, self.shouldShowMissingSummary {
                    self.missingSummary
                }

                if !self.skill.configChecks.isEmpty {
                    self.configChecksView
                }

                if !self.missingEnv.isEmpty {
                    self.envActionRow
                }
            }

            Spacer(minLength: 0)

            self.trailingActions
        }
        .padding(.vertical, 6)
    }

    private var sourceLabel: String {
        switch self.skill.source {
        case "haoclaw-bundled":
            "后台目录"
        case "haoclaw-managed":
            "后台目录"
        case "haoclaw-workspace":
            "工作区"
        case "haoclaw-extra":
            "额外目录"
        case "haoclaw-plugin":
            "插件"
        default:
            self.skill.source
        }
    }

    private var metaRow: some View {
        HStack(spacing: 10) {
            SkillTag(text: self.sourceLabel)
            if self.skill.source == "haoclaw-bundled" || self.skill.source == "haoclaw-managed" {
                SkillTag(text: "按需启用")
            }
            if let url = self.homepageUrl {
                Link(destination: url) {
                    Label("说明页", systemImage: "link")
                        .font(.caption2.weight(.semibold))
                }
                .buttonStyle(.link)
            }
            Spacer(minLength: 0)
        }
    }

    private var homepageUrl: URL? {
        guard let raw = self.skill.homepage?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        guard !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { !self.skill.disabled },
            set: { self.onToggleEnabled($0) })
    }

    private var missingSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            if self.shouldShowMissingBins {
                Text("缺少命令或可执行文件：\(self.missingBins.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !self.missingEnv.isEmpty {
                Text("缺少环境变量：\(self.missingEnv.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !self.missingConfig.isEmpty {
                Text("缺少配置项：\(self.missingConfig.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var configChecksView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(self.skill.configChecks) { check in
                HStack(spacing: 6) {
                    Image(systemName: check.satisfied ? "checkmark.circle" : "xmark.circle")
                        .foregroundStyle(check.satisfied ? .green : .secondary)
                    Text(check.path)
                        .font(.caption)
                    Text(self.formatConfigValue(check.value))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var envActionRow: some View {
        HStack(spacing: 8) {
            ForEach(self.missingEnv, id: \.self) { envKey in
                let isPrimary = envKey == self.skill.primaryEnv
                Button(isPrimary ? "填写 API Key" : "填写 \(envKey)") {
                    self.onSetEnv(envKey, isPrimary)
                }
                .buttonStyle(.bordered)
                .disabled(self.isBusy)
            }
            Spacer(minLength: 0)
        }
    }

    private var trailingActions: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if !self.installOptions.isEmpty {
                VStack(alignment: .trailing, spacing: 6) {
                    SkillTag(text: "需用户自行安装")
                    if let url = self.homepageUrl {
                        Link("打开安装说明", destination: url)
                            .font(.caption.weight(.semibold))
                    }
                }
            } else {
                Toggle("", isOn: self.enabledBinding)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .disabled(self.isBusy || !self.requirementsMet)
            }

            if self.isBusy {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var installOptions: [SkillInstallOption] {
        guard !self.missingBins.isEmpty else { return [] }
        let missing = Set(self.missingBins)
        return self.skill.install.filter { option in
            if option.bins.isEmpty { return true }
            return !missing.isDisjoint(with: option.bins)
        }
    }

    private var requirementsMet: Bool {
        self.missingBins.isEmpty && self.missingEnv.isEmpty && self.missingConfig.isEmpty
    }

    private var shouldShowMissingBins: Bool {
        !self.missingBins.isEmpty && self.installOptions.isEmpty
    }

    private var shouldShowMissingSummary: Bool {
        self.shouldShowMissingBins ||
            !self.missingEnv.isEmpty ||
            !self.missingConfig.isEmpty
    }

    private var localizedDescription: String {
        let raw = self.skill.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            return Self.localizedSummaries[self.skill.skillKey] ?? "用于后台技能调用。"
        }
        guard !Self.containsChinese(raw) else { return raw }
        let localized = Self.localizedSummaries[self.skill.skillKey] ?? "用于 \(self.skill.name) 的后台技能扩展。"
        return "\(raw)\n中文：\(localized)"
    }

    private static func containsChinese(_ text: String) -> Bool {
        text.range(of: #"\p{Han}"#, options: .regularExpression) != nil
    }

    private func formatConfigValue(_ value: AnyCodable?) -> String {
        guard let value else { return "" }
        switch value.value {
        case let bool as Bool:
            return bool ? "是" : "否"
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        case let string as String:
            return string
        default:
            return ""
        }
    }
}

private struct SkillTag: View {
    let text: String

    var body: some View {
        Text(self.text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct EnvEditorState: Identifiable {
    let skillKey: String
    let skillName: String
    let envKey: String
    let isPrimary: Bool

    var id: String {
        "\(self.skillKey)::\(self.envKey)"
    }
}

private struct EnvEditorView: View {
    let editor: EnvEditorState
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(self.title)
                .font(.headline)
            Text(self.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            SecureField(self.editor.envKey, text: self.$value)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("取消") { self.dismiss() }
                Spacer()
                Button("保存") {
                    self.onSave(self.value)
                    self.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private var title: String {
        self.editor.isPrimary ? "填写 API Key" : "填写环境变量"
    }

    private var subtitle: String {
        "技能：\(self.editor.skillName)"
    }
}

@MainActor
@Observable
final class SkillsSettingsModel {
    private static let bundledSkillKeys = [
        "1password",
        "agent-browser",
        "apple-notes",
        "apple-reminders",
        "bear-notes",
        "blogwatcher",
        "blucli",
        "bluebubbles",
        "camsnap",
        "canvas",
        "clawhub",
        "coding-agent",
        "discord",
        "eightctl",
        "gemini",
        "gh-issues",
        "gifgrep",
        "github",
        "gog",
        "goplaces",
        "healthcheck",
        "himalaya",
        "imsg",
        "mcporter",
        "model-usage",
        "nano-banana-pro",
        "nano-pdf",
        "notion",
        "obsidian",
        "openai-image-gen",
        "openai-whisper",
        "openai-whisper-api",
        "openhue",
        "oracle",
        "ordercli",
        "peekaboo",
        "sag",
        "session-logs",
        "sherpa-onnx-tts",
        "skill-creator",
        "slack",
        "songsee",
        "sonoscli",
        "spotify-player",
        "summarize",
        "things-mac",
        "tmux",
        "trello",
        "video-frames",
        "voice-call",
        "wacli",
        "weather",
        "xurl",
    ]

    var skills: [SkillStatus] = []
    var isLoading = false
    var error: String?
    var statusMessage: String?
    private var busySkills: Set<String> = []
    private var hasRetriedAfterEmpty = false

    func isBusy(skill: SkillStatus) -> Bool {
        self.busySkills.contains(skill.skillKey)
    }

    func refresh() async {
        guard !self.isLoading else { return }
        self.isLoading = true
        self.error = nil
        self.seedManagedSkillsFromBundleIfNeeded()
        do {
            let report = try await GatewayConnection.shared.skillsStatus()
            self.skills = report.skills.sorted { $0.name < $1.name }
            if self.skills.isEmpty {
                let fallback = self.loadLocalFallbackSkills()
                if !fallback.isEmpty {
                    self.skills = fallback
                    self.statusMessage = "网关尚未返回技能，已显示本地预装 \(fallback.count) 个技能。"
                    self.hasRetriedAfterEmpty = false
                    self.isLoading = false
                    return
                }
            }
            if self.skills.isEmpty, !self.hasRetriedAfterEmpty {
                self.hasRetriedAfterEmpty = true
                self.statusMessage = "正在初始化预装技能，请稍后刷新。"
                self.isLoading = false
                try? await Task.sleep(nanoseconds: 900_000_000)
                await self.refresh()
                return
            }
            self.hasRetriedAfterEmpty = false
            if self.skills.isEmpty {
                self.statusMessage = "还没有读取到技能，请先确认网关已经在本地模式启动。"
            } else {
                self.statusMessage = "已加载 \(self.skills.count) 个技能。"
            }
        } catch {
            let fallback = self.loadLocalFallbackSkills()
            if !fallback.isEmpty {
                self.skills = fallback
                self.error = nil
                self.statusMessage = "网关未连接，已展示本地预装 \(fallback.count) 个技能。"
            } else {
                self.error = error.localizedDescription
            }
        }
        self.isLoading = false
    }

    fileprivate func install(skill: SkillStatus, option: SkillInstallOption, target: SkillsInstallTarget) async {
        await self.withBusy(skill.skillKey) {
            do {
                if target == .local, AppStateStore.shared.connectionMode != .local {
                    AppStateStore.shared.connectionMode = .local
                    self.statusMessage = "已切换到本地模式，准备安装到当前电脑。"
                }
                let result = try await GatewayConnection.shared.skillsInstall(
                    name: skill.name,
                    installId: option.id,
                    timeoutMs: 300_000)
                self.statusMessage = result.message
            } catch {
                self.statusMessage = error.localizedDescription
            }
            await self.refresh()
        }
    }

    func setEnabled(skillKey: String, enabled: Bool) async {
        await self.withBusy(skillKey) {
            do {
                _ = try await GatewayConnection.shared.skillsUpdate(
                    skillKey: skillKey,
                    enabled: enabled)
                self.statusMessage = enabled ? "技能已启用" : "技能已禁用"
            } catch {
                self.statusMessage = error.localizedDescription
            }
            await self.refresh()
        }
    }

    func updateEnv(skillKey: String, envKey: String, value: String, isPrimary: Bool) async {
        await self.withBusy(skillKey) {
            do {
                if isPrimary {
                    _ = try await GatewayConnection.shared.skillsUpdate(
                        skillKey: skillKey,
                        apiKey: value)
                    self.statusMessage = "API Key 已保存"
                } else {
                    _ = try await GatewayConnection.shared.skillsUpdate(
                        skillKey: skillKey,
                        env: [envKey: value])
                    self.statusMessage = "\(envKey) 已保存"
                }
            } catch {
                self.statusMessage = error.localizedDescription
            }
            await self.refresh()
        }
    }

    private func withBusy(_ id: String, _ work: @escaping () async -> Void) async {
        self.busySkills.insert(id)
        defer { self.busySkills.remove(id) }
        await work()
    }

    private func seedManagedSkillsFromBundleIfNeeded() {
        let fileManager = FileManager.default
        let managedDir = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".haoclaw/skills", isDirectory: true)
        try? fileManager.createDirectory(at: managedDir, withIntermediateDirectories: true)

        guard let bundledDir = self.resolveBundledSkillsDirectory() else { return }
        guard let entries = try? fileManager.contentsOfDirectory(
            at: bundledDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]) else
        {
            return
        }

        for source in entries {
            let values = try? source.resourceValues(forKeys: [.isDirectoryKey])
            guard values?.isDirectory == true else { continue }
            let sourceSkill = source.appendingPathComponent("SKILL.md")
            guard fileManager.fileExists(atPath: sourceSkill.path) else { continue }
            let target = managedDir.appendingPathComponent(source.lastPathComponent, isDirectory: true)
            let targetSkill = target.appendingPathComponent("SKILL.md")
            guard !fileManager.fileExists(atPath: targetSkill.path) else { continue }
            do {
                try self.copyDirectory(from: source, to: target)
            } catch {
                continue
            }
        }
    }

    private func loadLocalFallbackSkills() -> [SkillStatus] {
        var byKey: [String: SkillStatus] = [:]
        for source in self.skillRoots() {
            let entries = self.scanSkills(root: source.url, source: source.kind)
            for item in entries where byKey[item.skillKey] == nil {
                byKey[item.skillKey] = item
            }
        }
        if byKey.isEmpty {
            return self.builtInFallbackSkills()
        }
        return byKey.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func builtInFallbackSkills() -> [SkillStatus] {
        let managedDir = self.managedSkillsDirectory()
        return Self.bundledSkillKeys.map { key in
            let skillDir = managedDir.appendingPathComponent(key, isDirectory: true)
            let skillFile = skillDir.appendingPathComponent("SKILL.md")
            return SkillStatus(
                name: key,
                description: "Haoclaw 后台技能",
                source: "haoclaw-bundled",
                filePath: skillFile.path,
                baseDir: managedDir.path,
                skillKey: key,
                primaryEnv: nil,
                emoji: nil,
                homepage: nil,
                always: false,
                disabled: false,
                eligible: true,
                requirements: SkillRequirements(bins: [], env: [], config: []),
                missing: SkillMissing(bins: [], env: [], config: []),
                configChecks: [],
                install: [])
        }
    }

    private func skillRoots() -> [(url: URL, kind: String)] {
        let fileManager = FileManager.default
        var roots: [(URL, String)] = []

        let managed = self.managedSkillsDirectory()
        roots.append((managed, "haoclaw-managed"))

        if let bundled = self.resolveBundledSkillsDirectory() {
            roots.append((bundled, "haoclaw-bundled"))
        }

        let execDir = URL(fileURLWithPath: Bundle.main.executablePath ?? "")
            .deletingLastPathComponent()
        let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        let devCandidates = [
            execDir.appendingPathComponent("skills", isDirectory: true),
            execDir.appendingPathComponent("../skills", isDirectory: true).standardizedFileURL,
            execDir.appendingPathComponent("../../skills", isDirectory: true).standardizedFileURL,
            execDir.appendingPathComponent("../../../skills", isDirectory: true).standardizedFileURL,
            cwd.appendingPathComponent("skills", isDirectory: true),
        ]
        for candidate in devCandidates where fileManager.fileExists(atPath: candidate.path) {
            roots.append((candidate, "haoclaw-bundled"))
        }

        var unique: [(URL, String)] = []
        var seen = Set<String>()
        for root in roots {
            let key = root.0.standardizedFileURL.path
            if seen.contains(key) {
                continue
            }
            seen.insert(key)
            unique.append(root)
        }
        return unique
    }

    private func managedSkillsDirectory() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".haoclaw/skills", isDirectory: true)
    }

    private func resolveBundledSkillsDirectory() -> URL? {
        let fileManager = FileManager.default
        if let resources = Bundle.main.resourceURL {
            let candidate = resources.appendingPathComponent("skills", isDirectory: true)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        let bundleResources = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Resources", isDirectory: true)
            .standardizedFileURL
        let bundledCandidate = bundleResources.appendingPathComponent("skills", isDirectory: true)
        if fileManager.fileExists(atPath: bundledCandidate.path) {
            return bundledCandidate
        }

        let execDir = URL(fileURLWithPath: Bundle.main.executablePath ?? "")
            .deletingLastPathComponent()
        let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        let candidates = [
            execDir.appendingPathComponent("skills", isDirectory: true),
            execDir.appendingPathComponent("../Resources/skills", isDirectory: true).standardizedFileURL,
            execDir.appendingPathComponent("../../Resources/skills", isDirectory: true).standardizedFileURL,
            execDir.appendingPathComponent("../../../skills", isDirectory: true).standardizedFileURL,
            cwd.appendingPathComponent("skills", isDirectory: true),
        ]
        for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
            return candidate
        }
        return nil
    }

    private func copyDirectory(from source: URL, to target: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: target, withIntermediateDirectories: true)
        let entries = try fileManager.contentsOfDirectory(
            at: source,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles])
        for entry in entries {
            let destination = target.appendingPathComponent(entry.lastPathComponent, isDirectory: false)
            let values = try entry.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            if values.isDirectory == true {
                try self.copyDirectory(from: entry, to: destination)
                continue
            }
            if values.isSymbolicLink == true {
                let linkTarget = try fileManager.destinationOfSymbolicLink(atPath: entry.path)
                if fileManager.fileExists(atPath: destination.path) {
                    try? fileManager.removeItem(at: destination)
                }
                try fileManager.createSymbolicLink(atPath: destination.path, withDestinationPath: linkTarget)
                continue
            }
            if fileManager.fileExists(atPath: destination.path) {
                try? fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: entry, to: destination)
        }
    }

    private func scanSkills(root: URL, source: String) -> [SkillStatus] {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]) else
        {
            return []
        }

        var result: [SkillStatus] = []
        for entry in entries {
            let values = try? entry.resourceValues(forKeys: [.isDirectoryKey])
            guard values?.isDirectory == true else { continue }
            let skillFile = entry.appendingPathComponent("SKILL.md")
            guard fileManager.fileExists(atPath: skillFile.path) else { continue }
            let key = entry.lastPathComponent
            let description = self.skillDescription(from: skillFile) ?? "内置技能"
            let emoji = self.skillEmoji(from: skillFile)
            result.append(
                SkillStatus(
                    name: key,
                    description: description,
                    source: source,
                    filePath: skillFile.path,
                    baseDir: root.path,
                    skillKey: key,
                    primaryEnv: nil,
                    emoji: emoji,
                    homepage: nil,
                    always: false,
                    disabled: false,
                    eligible: true,
                    requirements: SkillRequirements(bins: [], env: [], config: []),
                    missing: SkillMissing(bins: [], env: [], config: []),
                    configChecks: [],
                    install: []))
        }
        return result
    }

    private func skillDescription(from skillFile: URL) -> String? {
        guard let text = try? String(contentsOf: skillFile, encoding: .utf8) else { return nil }
        let lines = text.components(separatedBy: .newlines)
        var insideFrontMatter = false
        var frontMatterSeen = false
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line == "---" {
                if !frontMatterSeen {
                    frontMatterSeen = true
                    insideFrontMatter = true
                    continue
                }
                if insideFrontMatter {
                    insideFrontMatter = false
                    continue
                }
            }
            if insideFrontMatter || line.isEmpty || line.hasPrefix("#") || line.hasPrefix("-") {
                continue
            }
            if line.lowercased().hasPrefix("description:") {
                let value = line.dropFirst("description:".count).trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    return value
                }
                continue
            }
            return line
        }
        return nil
    }

    private func skillEmoji(from skillFile: URL) -> String? {
        guard let text = try? String(contentsOf: skillFile, encoding: .utf8) else { return nil }
        let lines = text.components(separatedBy: .newlines)
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.lowercased().hasPrefix("emoji:") {
                let value = line.dropFirst("emoji:".count).trimmingCharacters(in: .whitespaces)
                return value.isEmpty ? nil : value
            }
        }
        return nil
    }
}

#if DEBUG
struct SkillsSettings_Previews: PreviewProvider {
    static var previews: some View {
        SkillsSettings(state: .preview)
            .frame(width: SettingsTab.windowWidth, height: SettingsTab.windowHeight)
    }
}

extension SkillsSettings {
    static func exerciseForTesting() {
        let skill = SkillStatus(
            name: "Test Skill",
            description: "Test description",
            source: "haoclaw-bundled",
            filePath: "/tmp/skills/test",
            baseDir: "/tmp/skills",
            skillKey: "test",
            primaryEnv: "API_KEY",
            emoji: "🧪",
            homepage: "https://example.com",
            always: false,
            disabled: false,
            eligible: false,
            requirements: SkillRequirements(bins: ["python3"], env: ["API_KEY"], config: ["skills.test"]),
            missing: SkillMissing(bins: ["python3"], env: ["API_KEY"], config: ["skills.test"]),
            configChecks: [
                SkillStatusConfigCheck(path: "skills.test", value: AnyCodable(false), satisfied: false),
            ],
            install: [
                SkillInstallOption(id: "brew", kind: "brew", label: "brew install python", bins: ["python3"]),
            ])

        let row = SkillRow(
            skill: skill,
            isBusy: false,
            connectionMode: .remote,
            onToggleEnabled: { _ in },
            onInstall: { _, _ in },
            onSetEnv: { _, _ in })
        _ = row.body

        _ = SkillTag(text: "Bundled").body

        let editor = EnvEditorView(
            editor: EnvEditorState(
                skillKey: "test",
                skillName: "Test Skill",
                envKey: "API_KEY",
                isPrimary: true),
            onSave: { _ in })
        _ = editor.body
    }

    mutating func setFilterForTesting(_ rawValue: String) {
        guard let filter = SkillsFilter(rawValue: rawValue) else { return }
        self.filter = filter
    }
}
#endif

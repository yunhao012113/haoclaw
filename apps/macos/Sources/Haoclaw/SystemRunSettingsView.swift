import Foundation
import Observation
import SwiftUI

struct SystemRunSettingsView: View {
    @State private var model = ExecApprovalsSettingsModel()
    @State private var tab: ExecApprovalsSettingsTab = .policy
    @State private var newPattern: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Text("命令执行授权")
                    .font(.body)
                Spacer(minLength: 0)
                Picker("智能体", selection: Binding(
                    get: { self.model.selectedAgentId },
                    set: { self.model.selectAgent($0) }))
                {
                    ForEach(self.model.agentPickerIds, id: \.self) { id in
                        Text(self.model.label(for: id)).tag(id)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180, alignment: .trailing)
            }

            Picker("", selection: self.$tab) {
                ForEach(ExecApprovalsSettingsTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 320)

            if self.tab == .policy {
                self.policyView
            } else {
                self.allowlistView
            }
        }
        .task { await self.model.refresh() }
        .onChange(of: self.tab) { _, _ in
            Task { await self.model.refreshSkillBins() }
        }
    }

    private var policyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: Binding(
                get: { self.model.security },
                set: { self.model.setSecurity($0) }))
            {
                ForEach(ExecSecurity.allCases) { security in
                    Text(security.title).tag(security)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Picker("", selection: Binding(
                get: { self.model.ask },
                set: { self.model.setAsk($0) }))
            {
                ForEach(ExecAsk.allCases) { ask in
                    Text(ask.title).tag(ask)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Picker("", selection: Binding(
                get: { self.model.askFallback },
                set: { self.model.setAskFallback($0) }))
            {
                ForEach(ExecSecurity.allCases) { mode in
                    Text("兜底策略：\(mode.title)").tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Text(self.scopeMessage)
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var allowlistView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("自动放行技能 CLI", isOn: Binding(
                get: { self.model.autoAllowSkills },
                set: { self.model.setAutoAllowSkills($0) }))

            if self.model.autoAllowSkills, !self.model.skillBins.isEmpty {
                Text("技能 CLI：\(self.model.skillBins.joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if self.model.isDefaultsScope {
                Text("允许名单按智能体分别保存。请选择一个智能体后再编辑它的允许名单。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    TextField("新增允许名单路径规则（不区分大小写，支持通配）", text: self.$newPattern)
                        .textFieldStyle(.roundedBorder)
                    Button("添加") {
                        if self.model.addEntry(self.newPattern) == nil {
                            self.newPattern = ""
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!self.model.isPathPattern(self.newPattern))
                }

                Text("这里只支持路径规则，像“echo”这种仅文件名的写法会被忽略。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let validationMessage = self.model.allowlistValidationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                if self.model.entries.isEmpty {
                    Text("当前还没有允许的命令规则。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(self.model.entries, id: \.id) { entry in
                            ExecAllowlistRow(
                                entry: Binding(
                                    get: { self.model.entry(for: entry.id) ?? entry },
                                    set: { self.model.updateEntry($0, id: entry.id) }),
                                onRemove: { self.model.removeEntry(id: entry.id) })
                        }
                    }
                }
            }
        }
    }

    private var scopeMessage: String {
        if self.model.isDefaultsScope {
            return "当智能体没有单独覆盖设置时，会使用这里的默认策略。" +
                "询问模式决定是否弹窗确认；没有可用配套界面时会走兜底策略。"
        }
        return "安全级别决定配对为节点后，system.run 是否可以在这台 Mac 上执行。" +
            "询问模式决定是否弹窗确认；没有可用配套界面时会走兜底策略。"
    }
}

private enum ExecApprovalsSettingsTab: String, CaseIterable, Identifiable {
    case policy
    case allowlist

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .policy: "访问策略"
        case .allowlist: "允许名单"
        }
    }
}

struct ExecAllowlistRow: View {
    @Binding var entry: ExecAllowlistEntry
    let onRemove: () -> Void
    @State private var draftPattern: String = ""

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField("规则", text: self.patternBinding)
                    .textFieldStyle(.roundedBorder)

                Button(role: .destructive) {
                    self.onRemove()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            if let lastUsedAt = self.entry.lastUsedAt {
                let date = Date(timeIntervalSince1970: lastUsedAt / 1000.0)
                Text("最近使用：\(Self.relativeFormatter.localizedString(for: date, relativeTo: Date()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let lastUsedCommand = self.entry.lastUsedCommand, !lastUsedCommand.isEmpty {
                Text("最近命令：\(lastUsedCommand)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let lastResolvedPath = self.entry.lastResolvedPath, !lastResolvedPath.isEmpty {
                Text("解析路径：\(lastResolvedPath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            self.draftPattern = self.entry.pattern
        }
    }

    private var patternBinding: Binding<String> {
        Binding(
            get: { self.draftPattern.isEmpty ? self.entry.pattern : self.draftPattern },
            set: { newValue in
                self.draftPattern = newValue
                self.entry.pattern = newValue
            })
    }
}

@MainActor
@Observable
final class ExecApprovalsSettingsModel {
    private static let defaultsScopeId = "__defaults__"
    var agentIds: [String] = []
    var selectedAgentId: String = "main"
    var defaultAgentId: String = "main"
    var security: ExecSecurity = .deny
    var ask: ExecAsk = .onMiss
    var askFallback: ExecSecurity = .deny
    var autoAllowSkills = false
    var entries: [ExecAllowlistEntry] = []
    var skillBins: [String] = []
    var allowlistValidationMessage: String?

    var agentPickerIds: [String] {
        [Self.defaultsScopeId] + self.agentIds
    }

    var isDefaultsScope: Bool {
        self.selectedAgentId == Self.defaultsScopeId
    }

    func label(for id: String) -> String {
        if id == Self.defaultsScopeId { return "默认值" }
        return id
    }

    func refresh() async {
        await self.refreshAgents()
        self.loadSettings(for: self.selectedAgentId)
        await self.refreshSkillBins()
    }

    func refreshAgents() async {
        let root = await ConfigStore.load()
        let agents = root["agents"] as? [String: Any]
        let list = agents?["list"] as? [[String: Any]] ?? []
        var ids: [String] = []
        var seen = Set<String>()
        var defaultId: String?
        for entry in list {
            guard let raw = entry["id"] as? String else { continue }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !seen.insert(trimmed).inserted { continue }
            ids.append(trimmed)
            if (entry["default"] as? Bool) == true, defaultId == nil {
                defaultId = trimmed
            }
        }
        if ids.isEmpty {
            ids = ["main"]
            defaultId = "main"
        } else if defaultId == nil {
            defaultId = ids.first
        }
        self.agentIds = ids
        self.defaultAgentId = defaultId ?? "main"
        if self.selectedAgentId == Self.defaultsScopeId {
            return
        }
        if !self.agentIds.contains(self.selectedAgentId) {
            self.selectedAgentId = self.defaultAgentId
        }
    }

    func selectAgent(_ id: String) {
        self.selectedAgentId = id
        self.allowlistValidationMessage = nil
        self.loadSettings(for: id)
        Task { await self.refreshSkillBins() }
    }

    func loadSettings(for agentId: String) {
        if agentId == Self.defaultsScopeId {
            let defaults = ExecApprovalsStore.resolveDefaults()
            self.security = defaults.security
            self.ask = defaults.ask
            self.askFallback = defaults.askFallback
            self.autoAllowSkills = defaults.autoAllowSkills
            self.entries = []
            self.allowlistValidationMessage = nil
            return
        }
        let resolved = ExecApprovalsStore.resolve(agentId: agentId)
        self.security = resolved.agent.security
        self.ask = resolved.agent.ask
        self.askFallback = resolved.agent.askFallback
        self.autoAllowSkills = resolved.agent.autoAllowSkills
        self.entries = resolved.allowlist
            .sorted { $0.pattern.localizedCaseInsensitiveCompare($1.pattern) == .orderedAscending }
        self.allowlistValidationMessage = nil
    }

    func setSecurity(_ security: ExecSecurity) {
        self.security = security
        if self.isDefaultsScope {
            ExecApprovalsStore.updateDefaults { defaults in
                defaults.security = security
            }
        } else {
            ExecApprovalsStore.updateAgentSettings(agentId: self.selectedAgentId) { entry in
                entry.security = security
            }
        }
        self.syncQuickMode()
    }

    func setAsk(_ ask: ExecAsk) {
        self.ask = ask
        if self.isDefaultsScope {
            ExecApprovalsStore.updateDefaults { defaults in
                defaults.ask = ask
            }
        } else {
            ExecApprovalsStore.updateAgentSettings(agentId: self.selectedAgentId) { entry in
                entry.ask = ask
            }
        }
        self.syncQuickMode()
    }

    func setAskFallback(_ mode: ExecSecurity) {
        self.askFallback = mode
        if self.isDefaultsScope {
            ExecApprovalsStore.updateDefaults { defaults in
                defaults.askFallback = mode
            }
        } else {
            ExecApprovalsStore.updateAgentSettings(agentId: self.selectedAgentId) { entry in
                entry.askFallback = mode
            }
        }
    }

    func setAutoAllowSkills(_ enabled: Bool) {
        self.autoAllowSkills = enabled
        if self.isDefaultsScope {
            ExecApprovalsStore.updateDefaults { defaults in
                defaults.autoAllowSkills = enabled
            }
        } else {
            ExecApprovalsStore.updateAgentSettings(agentId: self.selectedAgentId) { entry in
                entry.autoAllowSkills = enabled
            }
        }
        Task { await self.refreshSkillBins(force: enabled) }
    }

    @discardableResult
    func addEntry(_ pattern: String) -> ExecAllowlistPatternValidationReason? {
        guard !self.isDefaultsScope else { return nil }
        switch ExecApprovalHelpers.validateAllowlistPattern(pattern) {
        case let .valid(normalizedPattern):
            self.entries.append(ExecAllowlistEntry(pattern: normalizedPattern, lastUsedAt: nil))
            let rejected = ExecApprovalsStore.updateAllowlist(agentId: self.selectedAgentId, allowlist: self.entries)
            self.allowlistValidationMessage = rejected.first?.reason.message
            return rejected.first?.reason
        case let .invalid(reason):
            self.allowlistValidationMessage = reason.message
            return reason
        }
    }

    @discardableResult
    func updateEntry(_ entry: ExecAllowlistEntry, id: UUID) -> ExecAllowlistPatternValidationReason? {
        guard !self.isDefaultsScope else { return nil }
        guard let index = self.entries.firstIndex(where: { $0.id == id }) else { return nil }
        var next = entry
        switch ExecApprovalHelpers.validateAllowlistPattern(next.pattern) {
        case let .valid(normalizedPattern):
            next.pattern = normalizedPattern
        case let .invalid(reason):
            self.allowlistValidationMessage = reason.message
            return reason
        }
        self.entries[index] = next
        let rejected = ExecApprovalsStore.updateAllowlist(agentId: self.selectedAgentId, allowlist: self.entries)
        self.allowlistValidationMessage = rejected.first?.reason.message
        return rejected.first?.reason
    }

    func removeEntry(id: UUID) {
        guard !self.isDefaultsScope else { return }
        guard let index = self.entries.firstIndex(where: { $0.id == id }) else { return }
        self.entries.remove(at: index)
        let rejected = ExecApprovalsStore.updateAllowlist(agentId: self.selectedAgentId, allowlist: self.entries)
        self.allowlistValidationMessage = rejected.first?.reason.message
    }

    func entry(for id: UUID) -> ExecAllowlistEntry? {
        self.entries.first(where: { $0.id == id })
    }

    func isPathPattern(_ pattern: String) -> Bool {
        ExecApprovalHelpers.isPathPattern(pattern)
    }

    func refreshSkillBins(force: Bool = false) async {
        guard self.autoAllowSkills else {
            self.skillBins = []
            return
        }
        let bins = await SkillBinsCache.shared.currentBins(force: force)
        self.skillBins = bins.sorted()
    }

    private func syncQuickMode() {
        if self.isDefaultsScope {
            AppStateStore.shared.execApprovalMode = ExecApprovalQuickMode.from(security: self.security, ask: self.ask)
            return
        }
        if self.selectedAgentId == self.defaultAgentId || self.agentIds.count <= 1 {
            AppStateStore.shared.execApprovalMode = ExecApprovalQuickMode.from(security: self.security, ask: self.ask)
        }
    }
}

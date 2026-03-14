import AppKit
import HaoclawChatUI
import HaoclawDiscovery
import HaoclawIPC
import SwiftUI

extension OnboardingView {
    @ViewBuilder
    func pageView(for pageIndex: Int) -> some View {
        switch pageIndex {
        case 0:
            self.welcomePage()
        case 1:
            self.connectionPage()
        case 3:
            self.wizardPage()
        case 5:
            self.permissionsPage()
        case 6:
            self.cliPage()
        case 8:
            self.onboardingChatPage()
        case 9:
            self.readyPage()
        default:
            EmptyView()
        }
    }

    func welcomePage() -> some View {
        self.onboardingPage {
            VStack(spacing: 22) {
                Text("欢迎使用 Haoclaw")
                    .font(.largeTitle.weight(.semibold))
                Text("Haoclaw 是一个强大的个人 AI 助手，可以接入 WhatsApp、Telegram 等消息渠道。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 560)
                    .fixedSize(horizontal: false, vertical: true)

                self.onboardingCard(spacing: 10, padding: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color(nsColor: .systemOrange))
                            .frame(width: 22)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("安全提示")
                                .font(.headline)
                            Text(
                                "接入后的 AI 代理（例如 Claude）在你授权后，可以在这台 Mac 上执行较强的操作，" +
                                    "包括运行命令、读写文件、截取屏幕等。\n\n" +
                                    "请只在你理解相关风险，并且信任自己使用的提示词、工具和集成时再启用 Haoclaw。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: 520)
            }
            .padding(.top, 16)
        }
    }

    func connectionPage() -> some View {
        self.onboardingPage {
            Text("选择你的 Gateway")
                .font(.largeTitle.weight(.semibold))
            Text(
                "Haoclaw 依赖一个持续运行的 Gateway。你可以选择当前这台 Mac、连接附近发现到的 Gateway，" +
                    "或者稍后再配置。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 520)
                .fixedSize(horizontal: false, vertical: true)

            self.onboardingCard(spacing: 12, padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    self.connectionChoiceButton(
                        title: "当前这台 Mac",
                        subtitle: self.localGatewaySubtitle,
                        selected: self.state.connectionMode == .local)
                    {
                        self.selectLocalGateway()
                    }

                    Divider().padding(.vertical, 4)

                    self.gatewayDiscoverySection()

                    self.connectionChoiceButton(
                        title: "稍后再配置",
                        subtitle: "暂时先不启动 Gateway。",
                        selected: self.state.connectionMode == .unconfigured)
                    {
                        self.selectUnconfiguredGateway()
                    }

                    self.advancedConnectionSection()
                }
            }
        }
    }

    private var localGatewaySubtitle: String {
        guard let probe = self.localGatewayProbe else {
            return "Gateway 会在这台 Mac 上自动启动。"
        }
        let base = probe.expected
            ? "已检测到现有 Gateway"
            : "端口 \(probe.port) 已被占用"
        let command = probe.command.isEmpty ? "" : " (\(probe.command) pid \(probe.pid))"
        return "\(base)\(command)，将直接接入。"
    }

    @ViewBuilder
    private func gatewayDiscoverySection() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(self.gatewayDiscovery.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
            if self.gatewayDiscovery.gateways.isEmpty {
                ProgressView().controlSize(.small)
                Button("刷新") {
                    self.gatewayDiscovery.refreshRemoteFallbackNow(timeoutSeconds: 5.0)
                }
                .buttonStyle(.link)
                .help("重新尝试远程发现（Tailscale DNS-SD + Serve 探测）。")
            }
            Spacer(minLength: 0)
        }

        if self.gatewayDiscovery.gateways.isEmpty {
            Text("正在搜索附近可用的 Gateway…")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("附近发现的 Gateway")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                ForEach(self.gatewayDiscovery.gateways.prefix(6)) { gateway in
                    self.connectionChoiceButton(
                        title: gateway.displayName,
                        subtitle: self.gatewaySubtitle(for: gateway),
                        selected: self.isSelectedGateway(gateway))
                    {
                        self.selectRemoteGateway(gateway)
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    @ViewBuilder
    private func advancedConnectionSection() -> some View {
        Button(self.showAdvancedConnection ? "收起高级设置" : "高级设置…") {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                self.showAdvancedConnection.toggle()
            }
            if self.showAdvancedConnection, self.state.connectionMode != .remote {
                self.state.connectionMode = .remote
            }
        }
        .buttonStyle(.link)

        if self.showAdvancedConnection {
            let labelWidth: CGFloat = 110
            let fieldWidth: CGFloat = 320

            VStack(alignment: .leading, spacing: 10) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("连接方式")
                            .font(.callout.weight(.semibold))
                            .frame(width: labelWidth, alignment: .leading)
                        Picker("连接方式", selection: self.$state.remoteTransport) {
                            Text("SSH 隧道").tag(AppState.RemoteTransport.ssh)
                            Text("直连（ws/wss）").tag(AppState.RemoteTransport.direct)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: fieldWidth)
                    }
                    GridRow {
                        Text("Gateway 令牌")
                            .font(.callout.weight(.semibold))
                            .frame(width: labelWidth, alignment: .leading)
                        SecureField("填写远程 Gateway 的认证令牌（gateway.remote.token）", text: self.$state.remoteToken)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: fieldWidth)
                    }
                    if self.state.remoteTokenUnsupported {
                        GridRow {
                            Text("")
                                .frame(width: labelWidth, alignment: .leading)
                            Text(
                                "当前 gateway.remote.token 不是明文值。macOS 客户端无法直接使用它，请在这里填入明文令牌进行替换。")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .frame(width: fieldWidth, alignment: .leading)
                        }
                    }
                    if self.state.remoteTransport == .direct {
                        GridRow {
                            Text("Gateway 地址")
                                .font(.callout.weight(.semibold))
                                .frame(width: labelWidth, alignment: .leading)
                            TextField("wss://gateway.example.ts.net", text: self.$state.remoteUrl)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: fieldWidth)
                        }
                    }
                    if self.state.remoteTransport == .ssh {
                        GridRow {
                            Text("SSH 目标")
                                .font(.callout.weight(.semibold))
                                .frame(width: labelWidth, alignment: .leading)
                            TextField("user@host[:port]", text: self.$state.remoteTarget)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: fieldWidth)
                        }
                        if let message = CommandResolver
                            .sshTargetValidationMessage(self.state.remoteTarget)
                        {
                            GridRow {
                                Text("")
                                    .frame(width: labelWidth, alignment: .leading)
                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .frame(width: fieldWidth, alignment: .leading)
                            }
                        }
                        GridRow {
                            Text("密钥文件")
                                .font(.callout.weight(.semibold))
                                .frame(width: labelWidth, alignment: .leading)
                            TextField("/Users/you/.ssh/id_ed25519", text: self.$state.remoteIdentity)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: fieldWidth)
                        }
                        GridRow {
                            Text("项目根目录")
                                .font(.callout.weight(.semibold))
                                .frame(width: labelWidth, alignment: .leading)
                            TextField("/home/you/Projects/haoclaw", text: self.$state.remoteProjectRoot)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: fieldWidth)
                        }
                        GridRow {
                            Text("CLI 路径")
                                .font(.callout.weight(.semibold))
                                .frame(width: labelWidth, alignment: .leading)
                            TextField(
                                "/Applications/Haoclaw.app/.../haoclaw",
                                text: self.$state.remoteCliPath)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: fieldWidth)
                        }
                    }
                }

                Text(self.state.remoteTransport == .direct
                    ? "提示：建议使用 Tailscale Serve，这样 Gateway 会带上有效的 HTTPS 证书。"
                    : "提示：建议保持 Tailscale 在线，确保 Gateway 始终可达。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    func gatewaySubtitle(for gateway: GatewayDiscoveryModel.DiscoveredGateway) -> String? {
        if self.state.remoteTransport == .direct {
            return GatewayDiscoveryHelpers.directUrl(for: gateway) ?? "仅支持配对"
        }
        if let target = GatewayDiscoveryHelpers.sshTarget(for: gateway),
           let parsed = CommandResolver.parseSSHTarget(target)
        {
            let portSuffix = parsed.port != 22 ? " · ssh \(parsed.port)" : ""
            return "\(parsed.host)\(portSuffix)"
        }
        return "仅支持配对"
    }

    func isSelectedGateway(_ gateway: GatewayDiscoveryModel.DiscoveredGateway) -> Bool {
        guard self.state.connectionMode == .remote else { return false }
        let preferred = self.preferredGatewayID ?? GatewayDiscoveryPreferences.preferredStableID()
        return preferred == gateway.stableID
    }

    func connectionChoiceButton(
        title: String,
        subtitle: String?,
        selected: Bool,
        action: @escaping () -> Void) -> some View
    {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                action()
            }
        } label: {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 0)
                SelectionStateIndicator(selected: selected)
            }
            .openClawSelectableRowChrome(selected: selected)
        }
        .buttonStyle(.plain)
    }

    func permissionsPage() -> some View {
        self.onboardingPage {
            Text("授予权限")
                .font(.largeTitle.weight(.semibold))
            Text("这些 macOS 权限会让 Haoclaw 能在这台 Mac 上执行自动化操作，并读取必要上下文。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
                .fixedSize(horizontal: false, vertical: true)

            self.onboardingCard(spacing: 8, padding: 12) {
                ForEach(Capability.allCases, id: \.self) { cap in
                    PermissionRow(
                        capability: cap,
                        status: self.permissionMonitor.status[cap] ?? false,
                        compact: true)
                    {
                        Task { await self.request(cap) }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await self.refreshPerms() }
                    } label: {
                        Label("刷新状态", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("刷新权限状态")
                    if self.isRequesting {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    func cliPage() -> some View {
        self.onboardingPage {
            Text("安装 CLI")
                .font(.largeTitle.weight(.semibold))
            Text("本地模式需要安装 `haoclaw` CLI，这样 launchd 才能拉起本地 Gateway。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
                .fixedSize(horizontal: false, vertical: true)

            self.onboardingCard(spacing: 10) {
                HStack(spacing: 12) {
                    Button {
                        Task { await self.installCLI() }
                    } label: {
                        let title = self.cliInstalled ? "重新安装 CLI" : "安装 CLI"
                        ZStack {
                            Text(title)
                                .opacity(self.installingCLI ? 0 : 1)
                            if self.installingCLI {
                                ProgressView()
                                    .controlSize(.mini)
                            }
                        }
                        .frame(minWidth: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(self.installingCLI)

                    Button(self.copied ? "已复制" : "复制安装命令") {
                        self.copyToPasteboard(self.devLinkCommand)
                    }
                    .disabled(self.installingCLI)

                    if self.cliInstalled, let loc = self.cliInstallLocation {
                        Label("已安装到 \(loc)", systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }
                }

                if let cliStatus {
                    Text(cliStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !self.cliInstalled, self.cliInstallLocation == nil {
                    Text(
                        """
                        会安装用户目录下的 Node 22+ 运行时和 CLI（不依赖 Homebrew）。
                        后续你随时都可以重新执行，用于重装或更新。
                        """)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    func workspacePage() -> some View {
        self.onboardingPage {
            Text("Agent 工作区")
                .font(.largeTitle.weight(.semibold))
            Text(
                "Haoclaw 会在一个独立工作区中运行代理，这样它可以读取 `AGENTS.md`、写入文件，" +
                    "同时不影响你其他项目。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)
                .fixedSize(horizontal: false, vertical: true)

            self.onboardingCard(spacing: 10) {
                if self.state.connectionMode == .remote {
                    Text("已检测到远程 Gateway")
                        .font(.headline)
                    Text(
                        "请先在远程主机上创建工作区（先通过 SSH 登录过去）。" +
                            "当前 macOS 客户端还不能通过 SSH 直接在远程 Gateway 上写文件。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button(self.copied ? "已复制" : "复制初始化命令") {
                        self.copyToPasteboard(self.workspaceBootstrapCommand)
                    }
                    .buttonStyle(.bordered)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("工作区目录")
                            .font(.headline)
                        TextField(
                            AgentWorkspace.displayPath(for: HaoclawConfigFile.defaultWorkspaceURL()),
                            text: self.$workspacePath)
                            .textFieldStyle(.roundedBorder)

                        HStack(spacing: 12) {
                            Button {
                                Task { await self.applyWorkspace() }
                            } label: {
                                if self.workspaceApplying {
                                    ProgressView()
                                } else {
                                    Text("创建工作区")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(self.workspaceApplying)

                            Button("打开目录") {
                                let url = AgentWorkspace.resolveWorkspaceURL(from: self.workspacePath)
                                NSWorkspace.shared.open(url)
                            }
                            .buttonStyle(.bordered)
                            .disabled(self.workspaceApplying)

                            Button("写入配置") {
                                Task {
                                    let url = AgentWorkspace.resolveWorkspaceURL(from: self.workspacePath)
                                    let saved = await self.saveAgentWorkspace(AgentWorkspace.displayPath(for: url))
                                    if saved {
                                        self.workspaceStatus =
                                            "已写入 ~/.haoclaw/haoclaw.json（agents.defaults.workspace）"
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(self.workspaceApplying)
                        }
                    }

                    if let workspaceStatus {
                        Text(workspaceStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else {
                        Text(
                            "提示：你可以编辑这个目录里的 AGENTS.md 来约束助手行为。" +
                                "如果要做备份，建议把工作区建成私有 git 仓库，方便把代理“记忆”版本化。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    func onboardingChatPage() -> some View {
        VStack(spacing: 16) {
            Text("认识一下你的 Agent")
                .font(.largeTitle.weight(.semibold))
            Text(
                "这里是专门用于引导配置的对话窗口。你的 Agent 会先做自我介绍，了解你的背景，" +
                    "并在你需要时帮助接入 WhatsApp 或 Telegram。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
                .fixedSize(horizontal: false, vertical: true)

            self.onboardingGlassCard(padding: 8) {
                HaoclawChatView(viewModel: self.onboardingChatModel, style: .onboarding)
                    .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 28)
        .frame(width: self.pageWidth, height: self.contentHeight, alignment: .top)
    }

    func readyPage() -> some View {
        self.onboardingPage {
            Text("配置完成")
                .font(.largeTitle.weight(.semibold))
            self.onboardingCard {
                if self.state.connectionMode == .unconfigured {
                    self.featureRow(
                        title: "稍后再配置",
                        subtitle: "等你准备好之后，可以随时去“设置 → 通用”里选择本地或远程模式。",
                        systemImage: "gearshape")
                    Divider()
                        .padding(.vertical, 6)
                }
                if self.state.connectionMode == .remote {
                    self.featureRow(
                        title: "远程 Gateway 检查清单",
                        subtitle: """
                        请在 Gateway 所在主机上安装或更新 `haoclaw`，并确认凭据文件已经就绪
                        （通常是 `~/.haoclaw/credentials/oauth.json`）。准备好后如有需要请重新连接。
                        """,
                        systemImage: "network")
                    Divider()
                        .padding(.vertical, 6)
                }
                self.featureRow(
                    title: "打开菜单栏面板",
                    subtitle: "点击 Haoclaw 菜单栏图标，可以快速聊天并查看状态。",
                    systemImage: "bubble.left.and.bubble.right")
                self.featureActionRow(
                    title: "接入 WhatsApp 或 Telegram",
                    subtitle: "打开“设置 → 渠道”即可完成渠道绑定并查看运行状态。",
                    systemImage: "link",
                    buttonTitle: "打开“设置 → 渠道”")
                {
                    self.openSettings(tab: .channels)
                }
                self.featureRow(
                    title: "试试语音唤醒",
                    subtitle: "在设置里启用语音唤醒后，你可以免手动发指令，并看到实时转写浮层。",
                    systemImage: "waveform.circle")
                self.featureRow(
                    title: "使用面板和 Canvas",
                    subtitle: "菜单栏面板适合快速对话；需要更丰富的预览和可视化内容时可以使用 Canvas。",
                    systemImage: "rectangle.inset.filled.and.person.filled")
                self.featureActionRow(
                    title: "给 Agent 更多能力",
                    subtitle: "你可以在“设置 → 技能”里启用 Peekaboo、oracle、camsnap 等可选技能。",
                    systemImage: "sparkles",
                    buttonTitle: "打开“设置 → 技能”")
                {
                    self.openSettings(tab: .skills)
                }
                self.skillsOverview
                Toggle("登录时自动启动", isOn: self.$state.launchAtLogin)
                    .onChange(of: self.state.launchAtLogin) { _, newValue in
                        AppStateStore.updateLaunchAtLogin(enabled: newValue)
                    }
            }
        }
        .task { await self.maybeLoadOnboardingSkills() }
    }

    private func maybeLoadOnboardingSkills() async {
        guard !self.didLoadOnboardingSkills else { return }
        self.didLoadOnboardingSkills = true
        await self.onboardingSkillsModel.refresh()
    }

    private var skillsOverview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.vertical, 6)

            HStack(spacing: 10) {
                Text("已包含的技能")
                    .font(.headline)
                Spacer(minLength: 0)
                if self.onboardingSkillsModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("刷新") {
                        Task { await self.onboardingSkillsModel.refresh() }
                    }
                    .buttonStyle(.link)
                }
            }

            if let error = self.onboardingSkillsModel.error {
                VStack(alignment: .leading, spacing: 4) {
                    Text("暂时无法从 Gateway 读取技能列表。")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text(
                        "请先确认 Gateway 已启动并连通，然后再点一次“刷新”（或直接打开“设置 → 技能”）。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("详细信息：\(error)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if self.onboardingSkillsModel.skills.isEmpty {
                Text("当前还没有读取到技能列表。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(self.onboardingSkillsModel.skills) { skill in
                            HStack(alignment: .top, spacing: 10) {
                                Text(skill.emoji ?? "✨")
                                    .font(.callout)
                                    .frame(width: 22, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(skill.name)
                                        .font(.callout.weight(.semibold))
                                    Text(skill.description)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(NSColor.windowBackgroundColor)))
                }
                .frame(maxHeight: 160)
            }
        }
    }
}

import SwiftUI

private enum GatewayTailscaleMode: String, CaseIterable, Identifiable {
    case off
    case serve
    case funnel

    var id: String {
        self.rawValue
    }

    var label: String {
        switch self {
        case .off: "关闭"
        case .serve: "Tailnet 内网（Serve）"
        case .funnel: "公网访问（Funnel）"
        }
    }

    var description: String {
        switch self {
        case .off:
            "不自动配置 Tailscale。"
        case .serve:
            "通过 Tailscale Serve 提供仅 Tailnet 可访问的 HTTPS。"
        case .funnel:
            "通过 Tailscale Funnel 提供公网 HTTPS（需要认证）。"
        }
    }
}

struct TailscaleIntegrationSection: View {
    let connectionMode: AppState.ConnectionMode
    let isPaused: Bool

    @Environment(TailscaleService.self) private var tailscaleService
    #if DEBUG
    private var testingService: TailscaleService?
    #endif

    @State private var hasLoaded = false
    @State private var tailscaleMode: GatewayTailscaleMode = .serve
    @State private var requireCredentialsForServe = false
    @State private var password: String = ""
    @State private var statusMessage: String?
    @State private var validationMessage: String?
    @State private var statusTimer: Timer?

    init(connectionMode: AppState.ConnectionMode, isPaused: Bool) {
        self.connectionMode = connectionMode
        self.isPaused = isPaused
        #if DEBUG
        self.testingService = nil
        #endif
    }

    private var effectiveService: TailscaleService {
        #if DEBUG
        return self.testingService ?? self.tailscaleService
        #else
        return self.tailscaleService
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tailscale（面板访问）")
                .font(.callout.weight(.semibold))

            self.statusRow

            if !self.effectiveService.isInstalled {
                self.installButtons
            } else {
                self.modePicker
                if self.tailscaleMode != .off {
                    self.accessURLRow
                }
                if self.tailscaleMode == .serve {
                    self.serveAuthSection
                }
                if self.tailscaleMode == .funnel {
                    self.funnelAuthSection
                }
            }

            if self.connectionMode != .local {
                Text("这里只支持本地模式，请到网关所在设备上修改。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(10)
        .disabled(self.connectionMode != .local)
        .task {
            guard !self.hasLoaded else { return }
            await self.loadConfig()
            self.hasLoaded = true
            await self.effectiveService.checkTailscaleStatus()
            self.startStatusTimer()
        }
        .onDisappear {
            self.stopStatusTimer()
        }
        .onChange(of: self.tailscaleMode) { _, _ in
            Task { await self.applySettings() }
        }
        .onChange(of: self.requireCredentialsForServe) { _, _ in
            Task { await self.applySettings() }
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(self.statusColor)
                .frame(width: 10, height: 10)
            Text(self.statusText)
                .font(.callout)
            Spacer()
            Button("刷新") {
                Task { await self.effectiveService.checkTailscaleStatus() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var statusColor: Color {
        if !self.effectiveService.isInstalled { return .yellow }
        if self.effectiveService.isRunning { return .green }
        return .orange
    }

    private var statusText: String {
        if !self.effectiveService.isInstalled { return "Tailscale 未安装" }
        if self.effectiveService.isRunning { return "Tailscale 已安装并正在运行" }
        return "Tailscale 已安装，但当前未运行"
    }

    private var installButtons: some View {
        HStack(spacing: 12) {
            Button("App Store 安装") { self.effectiveService.openAppStore() }
                .buttonStyle(.link)
            Button("直接下载") { self.effectiveService.openDownloadPage() }
                .buttonStyle(.link)
            Button("安装说明") { self.effectiveService.openSetupGuide() }
                .buttonStyle(.link)
        }
        .controlSize(.small)
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("暴露方式")
                .font(.callout.weight(.semibold))
            Picker("暴露方式", selection: self.$tailscaleMode) {
                ForEach(GatewayTailscaleMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            Text(self.tailscaleMode.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var accessURLRow: some View {
        if let host = self.effectiveService.tailscaleHostname {
            let url = "https://\(host)/ui/"
            HStack(spacing: 8) {
                Text("面板地址：")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let link = URL(string: url) {
                    Link(url, destination: link)
                        .font(.system(.caption, design: .monospaced))
                } else {
                    Text(url)
                        .font(.system(.caption, design: .monospaced))
                }
            }
        } else if !self.effectiveService.isRunning {
            Text("先启动 Tailscale，才能拿到你的 tailnet 主机名。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if self.effectiveService.isInstalled, !self.effectiveService.isRunning {
            Button("启动 Tailscale") { self.effectiveService.openTailscaleApp() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
    }

    private var serveAuthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("需要认证", isOn: self.$requireCredentialsForServe)
                .toggleStyle(.checkbox)
            if self.requireCredentialsForServe {
                self.authFields
            } else {
                Text("Serve 会直接使用 Tailscale 身份头，不需要额外密码。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var funnelAuthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Funnel 必须开启认证。")
                .font(.caption)
                .foregroundStyle(.secondary)
            self.authFields
        }
    }

    @ViewBuilder
    private var authFields: some View {
        SecureField("访问密码", text: self.$password)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 240)
            .onSubmit { Task { await self.applySettings() } }
        Text("密码会写入 ~/.haoclaw/haoclaw.json。生产环境更建议使用 HAOCLAW_GATEWAY_PASSWORD。")
            .font(.caption)
            .foregroundStyle(.secondary)
        Button("更新密码") { Task { await self.applySettings() } }
            .buttonStyle(.bordered)
            .controlSize(.small)
    }

    private func loadConfig() async {
        let root = await ConfigStore.load()
        let gateway = root["gateway"] as? [String: Any] ?? [:]
        let tailscale = gateway["tailscale"] as? [String: Any] ?? [:]
        let modeRaw = (tailscale["mode"] as? String) ?? "serve"
        self.tailscaleMode = GatewayTailscaleMode(rawValue: modeRaw) ?? .off

        let auth = gateway["auth"] as? [String: Any] ?? [:]
        let authModeRaw = auth["mode"] as? String
        let allowTailscale = auth["allowTailscale"] as? Bool

        self.password = auth["password"] as? String ?? ""

        if self.tailscaleMode == .serve {
            let usesExplicitAuth = authModeRaw == "password"
            if let allowTailscale, allowTailscale == false {
                self.requireCredentialsForServe = true
            } else {
                self.requireCredentialsForServe = usesExplicitAuth
            }
        } else {
            self.requireCredentialsForServe = false
        }
    }

    private func applySettings() async {
        guard self.hasLoaded else { return }
        self.validationMessage = nil
        self.statusMessage = nil

        let trimmedPassword = self.password.trimmingCharacters(in: .whitespacesAndNewlines)
        let requiresPassword = self.tailscaleMode == .funnel
            || (self.tailscaleMode == .serve && self.requireCredentialsForServe)
        if requiresPassword, trimmedPassword.isEmpty {
            self.validationMessage = "Password required for this mode."
            return
        }

        let (success, errorMessage) = await TailscaleIntegrationSection.buildAndSaveTailscaleConfig(
            tailscaleMode: self.tailscaleMode,
            requireCredentialsForServe: self.requireCredentialsForServe,
            password: trimmedPassword,
            connectionMode: self.connectionMode,
            isPaused: self.isPaused)

        if !success, let errorMessage {
            self.statusMessage = errorMessage
            return
        }

        if self.connectionMode == .local, !self.isPaused {
            self.statusMessage = "Saved to ~/.haoclaw/haoclaw.json. Restarting gateway…"
        } else {
            self.statusMessage = "Saved to ~/.haoclaw/haoclaw.json. Restart the gateway to apply."
        }
        self.restartGatewayIfNeeded()
    }

    @MainActor
    private static func buildAndSaveTailscaleConfig(
        tailscaleMode: GatewayTailscaleMode,
        requireCredentialsForServe: Bool,
        password: String,
        connectionMode: AppState.ConnectionMode,
        isPaused: Bool) async -> (Bool, String?)
    {
        var root = await ConfigStore.load()
        var gateway = root["gateway"] as? [String: Any] ?? [:]
        var tailscale = gateway["tailscale"] as? [String: Any] ?? [:]
        tailscale["mode"] = tailscaleMode.rawValue
        gateway["tailscale"] = tailscale

        if tailscaleMode != .off {
            gateway["bind"] = "loopback"
        }

        if tailscaleMode == .off {
            gateway.removeValue(forKey: "auth")
        } else {
            var auth = gateway["auth"] as? [String: Any] ?? [:]
            if tailscaleMode == .serve, !requireCredentialsForServe {
                auth["allowTailscale"] = true
                auth.removeValue(forKey: "mode")
                auth.removeValue(forKey: "password")
            } else {
                auth["allowTailscale"] = false
                auth["mode"] = "password"
                auth["password"] = password
            }

            if auth.isEmpty {
                gateway.removeValue(forKey: "auth")
            } else {
                gateway["auth"] = auth
            }
        }

        if gateway.isEmpty {
            root.removeValue(forKey: "gateway")
        } else {
            root["gateway"] = gateway
        }

        do {
            try await ConfigStore.save(root)
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func restartGatewayIfNeeded() {
        guard self.connectionMode == .local, !self.isPaused else { return }
        Task { await GatewayLaunchAgentManager.kickstart() }
    }

    private func startStatusTimer() {
        self.stopStatusTimer()
        if ProcessInfo.processInfo.isRunningTests {
            return
        }
        self.statusTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task { await self.effectiveService.checkTailscaleStatus() }
        }
    }

    private func stopStatusTimer() {
        self.statusTimer?.invalidate()
        self.statusTimer = nil
    }
}

#if DEBUG
extension TailscaleIntegrationSection {
    mutating func setTestingState(
        mode: String,
        requireCredentials: Bool,
        password: String = "secret",
        statusMessage: String? = nil,
        validationMessage: String? = nil)
    {
        if let mode = GatewayTailscaleMode(rawValue: mode) {
            self.tailscaleMode = mode
        }
        self.requireCredentialsForServe = requireCredentials
        self.password = password
        self.statusMessage = statusMessage
        self.validationMessage = validationMessage
    }

    mutating func setTestingService(_ service: TailscaleService?) {
        self.testingService = service
    }
}
#endif

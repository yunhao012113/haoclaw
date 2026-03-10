import AppKit
import Foundation
import OSLog

@MainActor
final class CLIInstallPrompter {
    static let shared = CLIInstallPrompter()
    private let logger = Logger(subsystem: "ai.haoclaw", category: "cli.prompt")
    private var isPrompting = false

    func checkAndPromptIfNeeded(reason: String) {
        guard self.shouldPrompt() else { return }
        guard let version = Self.appVersion() else { return }
        self.isPrompting = true
        UserDefaults.standard.set(version, forKey: cliInstallPromptedVersionKey)

        let alert = NSAlert()
        alert.messageText = "安装本地运行时？"
        alert.informativeText = "本地模式需要安装 Haoclaw CLI，桌面端才能自动拉起 Gateway。"
        alert.addButton(withTitle: "立即安装")
        alert.addButton(withTitle: "稍后再说")
        alert.addButton(withTitle: "打开设置")
        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            Task { await self.installCLI() }
        case .alertThirdButtonReturn:
            self.openSettings(tab: .general)
        default:
            break
        }

        self.logger.debug("cli install prompt handled reason=\(reason, privacy: .public)")
        self.isPrompting = false
    }

    private func shouldPrompt() -> Bool {
        guard !self.isPrompting else { return false }
        guard AppStateStore.shared.onboardingSeen else { return false }
        guard AppStateStore.shared.connectionMode == .local else { return false }
        guard CLIInstaller.installedLocation() == nil else { return false }
        guard let version = Self.appVersion() else { return false }
        let lastPrompt = UserDefaults.standard.string(forKey: cliInstallPromptedVersionKey)
        return lastPrompt != version
    }

    private func installCLI() async {
        let status = StatusBox()
        let success = await CLIInstaller.install { message in
            await status.set(message)
        }
        if success {
            GatewayProcessManager.shared.refreshEnvironmentStatus(force: true)
            GatewayProcessManager.shared.setActive(true)
        }
        if let message = await status.get() {
            let alert = NSAlert()
            alert.messageText = success ? "安装完成" : "安装失败"
            alert.informativeText = message
            alert.runModal()
        }
    }

    private func openSettings(tab: SettingsTab) {
        SettingsTabRouter.request(tab)
        SettingsWindowOpener.shared.open()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .haoclawSelectSettingsTab, object: tab)
        }
    }

    private static func appVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

private actor StatusBox {
    private var value: String?

    func set(_ value: String) {
        self.value = value
    }

    func get() -> String? {
        self.value
    }
}

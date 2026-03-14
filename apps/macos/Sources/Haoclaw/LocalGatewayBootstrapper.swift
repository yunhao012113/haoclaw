import Foundation
import OSLog

@MainActor
final class LocalGatewayBootstrapper {
    static let shared = LocalGatewayBootstrapper()

    struct Result: Equatable {
        let isReady: Bool
        let message: String?

        static let ready = Result(isReady: true, message: nil)
    }

    private let logger = Logger(subsystem: "ai.haoclaw", category: "gateway.bootstrap")
    private var inFlightTask: Task<Result, Never>?

    func ensureReady() async -> Result {
        if let inFlightTask {
            return await inFlightTask.value
        }

        let task = Task { @MainActor [weak self] in
            await self?.runEnsureReady() ?? .ready
        }
        self.inFlightTask = task
        let result = await task.value
        self.inFlightTask = nil
        return result
    }

    private func runEnsureReady() async -> Result {
        let synced = Self.syncedLocalBootstrapRoot(currentRoot: HaoclawConfigFile.loadDict())
        if synced.changed {
            HaoclawConfigFile.saveDict(synced.root)
            self.logger.info("wrote local bootstrap config")
        }

        let workspace = AgentWorkspace.resolveWorkspaceURL(from: AgentWorkspaceConfig.workspace(from: synced.root))
        if let reason = AgentWorkspace.bootstrapSafety(for: workspace).unsafeReason {
            self.logger.warning("workspace bootstrap skipped: \(reason, privacy: .public)")
        } else {
            do {
                _ = try AgentWorkspace.bootstrap(workspaceURL: workspace)
            } catch {
                self.logger.error("workspace bootstrap failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        if CLIInstaller.isInstalled() {
            return .ready
        }

        self.logger.info("haoclaw CLI missing; attempting auto-install")
        let installed = await CLIInstaller.install { _ in }
        guard installed else {
            let message = "本地运行时未安装完成，暂时无法自动启动网关。请检查网络后重试。"
            self.logger.error("cli auto-install failed")
            return Result(isReady: false, message: message)
        }

        return Result(isReady: true, message: "已自动安装本地运行时，正在启动网关。")
    }

    static func syncedLocalBootstrapRoot(currentRoot: [String: Any]) -> (root: [String: Any], changed: Bool) {
        var root = currentRoot
        var gateway = root["gateway"] as? [String: Any] ?? [:]
        var changed = false

        let currentMode = (gateway["mode"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentMode != "local" {
            gateway["mode"] = "local"
            changed = true
        }

        if gateway.isEmpty {
            root.removeValue(forKey: "gateway")
        } else {
            root["gateway"] = gateway
        }

        let currentWorkspace = AgentWorkspaceConfig.workspace(from: root)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if currentWorkspace.isEmpty {
            AgentWorkspaceConfig.setWorkspace(
                in: &root,
                workspace: AgentWorkspace.displayPath(for: HaoclawConfigFile.defaultWorkspaceURL()))
            changed = true
        }

        return (root, changed)
    }
}

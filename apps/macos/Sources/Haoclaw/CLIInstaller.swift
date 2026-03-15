import AppKit
import Foundation

@MainActor
enum CLIInstaller {
    enum Platform: Equatable {
        case macOS
        case other

        static var current: Self {
            #if os(macOS)
            .macOS
            #else
            .other
            #endif
        }
    }

    enum InstallPlan: Equatable {
        case globalPackage(version: String)
        case desktopDownload(message: String)
        case installScript(version: String)
    }

    private static let installScriptURL =
        "https://raw.githubusercontent.com/yunhao012113/haoclaw/main/scripts/install.sh"
    private static let localPrefix = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".haoclaw", isDirectory: true)

    static func installedLocation() -> String? {
        self.installedLocation(
            searchPaths: CommandResolver.preferredPaths(),
            fileManager: .default)
    }

    static func installedLocation(
        searchPaths: [String],
        fileManager: FileManager) -> String?
    {
        for basePath in searchPaths {
            let candidate = URL(fileURLWithPath: basePath).appendingPathComponent("haoclaw").path
            var isDirectory: ObjCBool = false

            guard fileManager.fileExists(atPath: candidate, isDirectory: &isDirectory),
                  !isDirectory.boolValue
            else {
                continue
            }

            guard fileManager.isExecutableFile(atPath: candidate) else { continue }

            return candidate
        }

        return nil
    }

    static func isInstalled() -> Bool {
        self.installedLocation() != nil
    }

    @discardableResult
    static func install(statusHandler: @escaping @MainActor @Sendable (String) async -> Void) async -> Bool {
        let expected = GatewayEnvironment.expectedGatewayVersionString() ?? "latest"
        let environment = GatewayEnvironment.check()
        if case .ok = environment.kind, self.isInstalled() {
            await statusHandler("本地 CLI 已安装。")
            return true
        }

        let searchPaths = CommandResolver.preferredPaths()
        switch self.installPlan(version: expected, searchPaths: searchPaths, platform: .current) {
        case let .globalPackage(version):
            let isUpdate: Bool
            switch environment.kind {
            case .incompatible:
                isUpdate = true
            default:
                isUpdate = false
            }
            await statusHandler(isUpdate ? "正在更新 Haoclaw CLI…" : "正在安装 Haoclaw CLI…")
            let response = await self.installGlobalPackage(version: version, searchPaths: searchPaths)
            if response.success, self.isInstalled() {
                await statusHandler(isUpdate ? "Haoclaw CLI 已更新。" : "Haoclaw CLI 安装完成。")
                return true
            }

            if response.success {
                await statusHandler("安装已完成，但没有检测到 haoclaw 命令。请稍后重试。")
                return false
            }

            let detail = self.summarizeFailure(stderr: response.stderr, stdout: response.stdout)
            let fallback = response.errorMessage ?? "install failed"
            await statusHandler("安装失败：\(detail ?? fallback)")
            return false
        case let .desktopDownload(message):
            self.openDesktopDownloadsPage()
            await statusHandler(message)
            return false
        case let .installScript(version):
            await statusHandler("正在安装本地运行时和 Haoclaw CLI…")
            let cmd = self.installScriptCommand(version: version)
            let response = await ShellExecutor.runDetailed(command: cmd, cwd: nil, env: nil, timeout: 900)

            if response.success, self.isInstalled() {
                await statusHandler("本地运行时安装完成。")
                return true
            }

            if response.success {
                await statusHandler("安装脚本执行完成，但没有检测到 haoclaw 命令。请稍后重试。")
                return false
            }

            let detail = self.summarizeFailure(stderr: response.stderr, stdout: response.stdout)
            let fallback = response.errorMessage ?? "install failed"
            await statusHandler("安装失败：\(detail ?? fallback)")
            return false
        }
    }

    static func installPlan(version: String, searchPaths: [String], platform: Platform) -> InstallPlan {
        let npm = CommandResolver.findExecutable(named: "npm", searchPaths: searchPaths)
        switch RuntimeLocator.resolve(searchPaths: searchPaths) {
        case .success:
            if npm != nil {
                return .globalPackage(version: version)
            }
            if platform == .macOS {
                return .desktopDownload(message: self.manualRepairMessage(
                    detail: "检测到本地 Node.js，但没有找到 npm，桌面端无法继续静默修复。"))
            }
            return .installScript(version: version)
        case let .failure(error):
            if platform == .macOS {
                return .desktopDownload(message: self.manualRepairMessage(detail: RuntimeLocator.describeFailure(error)))
            }
            return .installScript(version: version)
        }
    }

    private static func installScriptCommand(version: String) -> [String] {
        let escapedVersion = self.shellEscape(version)
        let script = """
        set -euo pipefail
        tmp="$(mktemp)"
        trap 'rm -f "$tmp"' EXIT
        curl -fsSL \(self.shellEscape(self.installScriptURL)) -o "$tmp"
        HAOCLAW_NO_PROMPT=1 HAOCLAW_NO_ONBOARD=1 HAOCLAW_INSTALL_METHOD=npm HAOCLAW_VERSION=\(escapedVersion) /bin/bash "$tmp" --no-prompt --no-onboard --npm --version \(escapedVersion)
        """
        return ["/bin/bash", "-lc", script]
    }

    private static func installGlobalPackage(version: String, searchPaths: [String]) async -> ShellExecutor.ShellResult {
        let prefix = self.localPrefix
        let binDir = prefix.appendingPathComponent("bin", isDirectory: true)
        try? FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)

        guard let npm = CommandResolver.findExecutable(named: "npm", searchPaths: searchPaths) else {
            return ShellExecutor.ShellResult(
                stdout: "",
                stderr: "",
                exitCode: nil,
                timedOut: false,
                success: false,
                errorMessage: "npm not found")
        }

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = ([binDir.path] + searchPaths).joined(separator: ":")
        env["NPM_CONFIG_PREFIX"] = prefix.path
        env["npm_config_prefix"] = prefix.path

        let cmd = [npm, "install", "-g", "haoclaw@\(version)"]
        return await ShellExecutor.runDetailed(command: cmd, cwd: nil, env: env, timeout: 900)
    }

    private static func manualRepairMessage(detail: String) -> String {
        """
        当前设备缺少可直接用于本地模式的运行时，桌面端在无终端模式下无法静默申请管理员权限。
        已为你打开统一下载页，请安装最新版 PKG 后再点“一键修复”。

        \(detail)
        """
    }

    private static func openDesktopDownloadsPage() {
        guard let url = URL(string: desktopDownloadsURL) else { return }
        NSWorkspace.shared.open(url)
    }

    private static func summarizeFailure(stderr: String, stdout: String) -> String? {
        let text = stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? stdout : stderr
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let last = lines.last else { return nil }
        let normalized = last.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return normalized.count > 220 ? String(normalized.prefix(219)) + "…" : normalized
    }

    private static func shellEscape(_ raw: String) -> String {
        "'" + raw.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}

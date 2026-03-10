import Foundation

@MainActor
enum CLIInstaller {
    private static let installScriptURL =
        "https://raw.githubusercontent.com/yunhao012113/haoclaw/main/scripts/install.sh"

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
        if self.isInstalled() {
            await statusHandler("本地 CLI 已安装。")
            return true
        }

        let expected = GatewayEnvironment.expectedGatewayVersionString() ?? "latest"
        await statusHandler("正在安装本地运行时和 Haoclaw CLI…")
        let cmd = self.installScriptCommand(version: expected)
        let response = await ShellExecutor.runDetailed(command: cmd, cwd: nil, env: nil, timeout: 900)

        if response.success, self.isInstalled() {
            await statusHandler("本地运行时安装完成。")
            return true
        }

        if response.success {
            await statusHandler("安装脚本执行完成，但没有检测到 haoclaw 命令。请稍后重试。")
            return false
        }

        let detail = response.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = response.errorMessage ?? "install failed"
        await statusHandler("安装失败：\(detail.isEmpty ? fallback : detail)")
        return false
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

    private static func shellEscape(_ raw: String) -> String {
        "'" + raw.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}

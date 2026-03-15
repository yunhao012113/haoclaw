import AppKit
import Foundation

@MainActor
final class GitHubReleaseUpdaterController: NSObject, UpdaterProviding {
    struct ReleaseAsset: Decodable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    struct ReleasePayload: Decodable {
        let tagName: String
        let htmlURL: URL
        let assets: [ReleaseAsset]
        let draft: Bool
        let prerelease: Bool

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
            case assets
            case draft
            case prerelease
        }
    }

    struct AvailableUpdate {
        let version: String
        let asset: ReleaseAsset?
        let releaseURL: URL
    }

    var automaticallyChecksForUpdates: Bool {
        didSet {
            UserDefaults.standard.set(self.automaticallyChecksForUpdates, forKey: autoUpdateKey)
            self.configureBackgroundChecks()
            if self.automaticallyChecksForUpdates {
                Task { await self.checkForUpdatesInteractive(manual: false) }
            }
        }
    }

    var automaticallyDownloadsUpdates: Bool {
        didSet {
            if self.automaticallyDownloadsUpdates != self.automaticallyChecksForUpdates {
                self.automaticallyChecksForUpdates = self.automaticallyDownloadsUpdates
            }
        }
    }

    let isAvailable: Bool = true
    let updateStatus = UpdateStatus()

    private let latestReleaseEndpoint = URL(string: "https://api.github.com/repos/yunhao012113/haoclaw/releases?per_page=12")!
    private let session: URLSession = .shared
    private let autoUpdateKey = "autoUpdateEnabled"
    private var cachedUpdate: AvailableUpdate?
    private var isChecking = false
    private var isInstalling = false
    private var backgroundCheckTask: Task<Void, Never>?
    private var lastAutoInstallAttemptedVersion: String?

    init(savedAutoUpdate: Bool) {
        self.automaticallyChecksForUpdates = savedAutoUpdate
        self.automaticallyDownloadsUpdates = savedAutoUpdate
        super.init()
        self.configureBackgroundChecks()

        if savedAutoUpdate {
            Task { await self.checkForUpdatesInteractive(manual: false) }
        }
    }

    deinit {
        self.backgroundCheckTask?.cancel()
    }

    func checkForUpdates(_: Any?) {
        if let cachedUpdate = self.cachedUpdate, self.updateStatus.isUpdateReady {
            Task { await self.promptAndInstall(update: cachedUpdate) }
            return
        }
        Task { await self.checkForUpdatesInteractive(manual: true) }
    }

    private func checkForUpdatesInteractive(manual: Bool) async {
        guard !self.isChecking else { return }
        self.isChecking = true
        self.updateStatus.isChecking = true
        if manual {
            self.updateStatus.detail = "正在检查最新版本…"
        }
        defer {
            self.isChecking = false
            self.updateStatus.isChecking = false
        }

        do {
            let update = try await self.fetchLatestUpdate()
            self.cachedUpdate = update
            self.updateStatus.isUpdateReady = update != nil
            self.updateStatus.availableVersion = update?.version

            guard let update else {
                self.updateStatus.detail = manual ? "当前桌面客户端已经是最新版本。" : "当前已经是最新版本。"
                if manual {
                    self.presentMessage(
                        title: "已经是最新版本",
                        text: "当前桌面客户端已经是最新版本。",
                        style: .informational)
                }
                return
            }

            self.updateStatus.detail = "发现新版本 \(update.version)。"
            if !manual, self.automaticallyDownloadsUpdates {
                await self.installAutomaticallyIfPossible(update: update)
                return
            }

            if manual {
                await self.promptAndInstall(update: update)
            }
        } catch {
            self.updateStatus.isUpdateReady = self.cachedUpdate != nil
            self.updateStatus.detail = manual ? error.localizedDescription : "后台检查更新失败，可稍后重试。"
            if manual {
                self.presentMessage(
                    title: "检查更新失败",
                    text: error.localizedDescription,
                    style: .warning)
            }
        }
    }

    private func fetchLatestUpdate() async throws -> AvailableUpdate? {
        var request = URLRequest(url: self.latestReleaseEndpoint)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("HaoclawDesktop/\(self.currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await self.session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw NSError(
                domain: "HaoclawUpdater",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "GitHub 返回了无效响应。"])
        }

        let releases = try JSONDecoder().decode([ReleasePayload].self, from: data)
        guard let release = Self.preferredRelease(from: releases, currentVersion: self.currentVersion) else {
            return nil
        }
        let latestVersion = Self.normalizedVersion(release.tagName)
        let preferredAsset = Self.preferredMacAsset(in: release.assets)

        return AvailableUpdate(version: latestVersion, asset: preferredAsset, releaseURL: release.htmlURL)
    }

    static func preferredRelease(from releases: [ReleasePayload], currentVersion: String) -> ReleasePayload? {
        releases.first { release in
            guard !release.draft, !release.prerelease else { return false }
            guard Self.preferredMacAsset(in: release.assets) != nil else { return false }
            let latestVersion = Self.normalizedVersion(release.tagName)
            return Self.compareVersion(latestVersion, to: currentVersion) == .orderedDescending
        }
    }

    static func preferredMacAsset(in assets: [ReleaseAsset]) -> ReleaseAsset? {
        assets.first(where: { $0.name.hasSuffix(".pkg") }) ??
            assets.first(where: { $0.name.hasSuffix(".dmg") }) ??
            assets.first(where: { $0.name.hasSuffix(".zip") })
    }

    private func promptAndInstall(update: AvailableUpdate) async {
        let alert = NSAlert()
        alert.messageText = "发现新版本 \(update.version)"
        alert.informativeText = "是否立即一键升级？桌面端会自动下载安装并重新打开。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "立即升级")
        alert.addButton(withTitle: "稍后")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        do {
            if let asset = update.asset {
                try await self.downloadAndInstall(asset: asset, announcedVersion: update.version, showCompletionAlert: true)
            } else {
                self.updateStatus.detail = "未找到可安装的更新包，已为你打开统一下载页。"
                if let url = URL(string: desktopDownloadsURL) {
                    NSWorkspace.shared.open(url)
                } else {
                    NSWorkspace.shared.open(update.releaseURL)
                }
            }
        } catch {
            self.updateStatus.detail = "升级失败：\(error.localizedDescription)"
            self.presentMessage(
                title: "更新下载失败",
                text: error.localizedDescription,
                style: .warning)
        }
    }

    private func installAutomaticallyIfPossible(update: AvailableUpdate) async {
        guard self.lastAutoInstallAttemptedVersion != update.version else { return }
        self.lastAutoInstallAttemptedVersion = update.version

        guard let asset = update.asset else {
            self.updateStatus.detail = "发现新版本 \(update.version)，但未找到可自动安装的安装包。"
            return
        }

        do {
            try await self.downloadAndInstall(asset: asset, announcedVersion: update.version, showCompletionAlert: false)
        } catch {
            self.updateStatus.detail = "自动升级失败，可点“立即升级”重试。原因：\(error.localizedDescription)"
        }
    }

    private func downloadAndInstall(
        asset: ReleaseAsset,
        announcedVersion: String,
        showCompletionAlert: Bool) async throws
    {
        guard !self.isInstalling else { return }
        self.isInstalling = true
        self.updateStatus.isInstalling = true
        self.updateStatus.detail = "正在下载并安装 \(announcedVersion)…"
        defer {
            self.isInstalling = false
            self.updateStatus.isInstalling = false
        }

        let updatesDir = HaoclawPaths.stateDirURL
            .appendingPathComponent("updates", isDirectory: true)
        try FileManager.default.createDirectory(at: updatesDir, withIntermediateDirectories: true)
        let destination = updatesDir.appendingPathComponent(asset.name)
        let tempDestination = updatesDir.appendingPathComponent(".\(asset.name).download")

        try? FileManager.default.removeItem(at: tempDestination)
        let (tmpURL, response) = try await self.session.download(from: asset.browserDownloadURL)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw NSError(
                domain: "HaoclawUpdater",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "安装包下载失败。"])
        }

        try? FileManager.default.removeItem(at: tempDestination)
        try FileManager.default.moveItem(at: tmpURL, to: tempDestination)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempDestination, to: destination)

        let fileName = asset.name.lowercased()
        if fileName.hasSuffix(".pkg") {
            try self.installPackage(at: destination)
            self.updateStatus.isUpdateReady = false
            self.updateStatus.detail = "Haoclaw 已升级到 \(announcedVersion)，正在重新打开应用。"
            if showCompletionAlert {
                self.presentMessage(
                    title: "升级完成",
                    text: "Haoclaw 已完成升级，正在重新打开应用。",
                    style: .informational)
            }
            self.relaunchInstalledApp()
            return
        }

        guard NSWorkspace.shared.open(destination) else {
            throw NSError(
                domain: "HaoclawUpdater",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "安装包已下载，但无法自动打开。"])
        }

        self.presentMessage(
            title: "安装包已打开",
            text: "当前版本不支持静默安装此格式，请按向导完成更新。安装包位置：\(destination.path)",
            style: .informational)
        self.updateStatus.detail = "安装包已下载并打开，请按安装向导完成升级。"
    }

    private func configureBackgroundChecks() {
        self.backgroundCheckTask?.cancel()
        self.backgroundCheckTask = nil
        guard self.automaticallyChecksForUpdates else { return }

        self.backgroundCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 6 * 60 * 60 * 1_000_000_000)
                guard let self else { return }
                await self.checkForUpdatesInteractive(manual: false)
            }
        }
    }

    private func installPackage(at packageURL: URL) throws {
        let packagePath = packageURL.path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let reopenPath = "/Applications/Haoclaw.app".replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let appleScript = """
        set pkgPath to "\(packagePath)"
        set appPath to "\(reopenPath)"
        do shell script "/usr/sbin/installer -pkg " & quoted form of pkgPath & " -target / && open " & quoted form of appPath with administrator privileges
        """

        var executionError: NSDictionary?
        let script = NSAppleScript(source: appleScript)
        script?.executeAndReturnError(&executionError)
        if let executionError {
            let rawMessage = executionError[NSAppleScript.errorMessage] as? String ?? "安装器执行失败。"
            let message: String
            if rawMessage.contains("A real number can't go after this real number") {
                message = "升级器执行失败。请先安装最新安装包，再继续使用应用内升级。"
            } else {
                message = rawMessage
            }
            throw NSError(
                domain: "HaoclawUpdater",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private func relaunchInstalledApp() {
        let appURL = URL(fileURLWithPath: "/Applications/Haoclaw.app")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
                NSApp.terminate(nil)
            }
        }
    }

    private func presentMessage(title: String, text: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = style
        alert.runModal()
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static func normalizedVersion(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") {
            return String(trimmed.dropFirst())
        }
        return trimmed
    }

    static func compareVersion(_ lhs: String, to rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        let rhsParts = rhs.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        let count = max(lhsParts.count, rhsParts.count)

        for index in 0 ..< count {
            let left = index < lhsParts.count ? lhsParts[index] : 0
            let right = index < rhsParts.count ? rhsParts[index] : 0
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
        }
        return .orderedSame
    }
}

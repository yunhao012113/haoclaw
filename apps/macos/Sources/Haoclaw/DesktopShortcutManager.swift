import Foundation

enum DesktopShortcutManager {
    private static let launcherName = "打开 Haoclaw.command"

    static func ensureDesktopShortcutIfNeeded() {
        let appURL = Bundle.main.bundleURL.standardizedFileURL
        guard appURL.pathExtension == "app" else { return }

        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let applicationsURL = homeDirectory.appendingPathComponent("Applications", isDirectory: true)
        let desktopURL = homeDirectory.appendingPathComponent("Desktop", isDirectory: true)
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: applicationsURL.path) {
            try? fileManager.createDirectory(at: applicationsURL, withIntermediateDirectories: true)
        }

        let userApplicationsShortcutURL = applicationsURL.appendingPathComponent("Haoclaw.app", isDirectory: false)
        ensureShortcut(at: userApplicationsShortcutURL, pointingTo: appURL)

        guard fileManager.fileExists(atPath: desktopURL.path) else { return }

        let shortcutURL = desktopURL.appendingPathComponent("Haoclaw.app", isDirectory: false)
        ensureShortcut(at: shortcutURL, pointingTo: appURL)
        ensureLauncherScript(at: desktopURL, pointingTo: appURL)
    }

    private static func ensureShortcut(at shortcutURL: URL, pointingTo appURL: URL) {
        let fileManager = FileManager.default

        do {
            if fileManager.fileExists(atPath: shortcutURL.path) {
                let currentDestination = try? fileManager.destinationOfSymbolicLink(atPath: shortcutURL.path)
                if currentDestination == appURL.path {
                    return
                }
                try? fileManager.removeItem(at: shortcutURL)
            }

            if fileManager.fileExists(atPath: shortcutURL.path) {
                try fileManager.removeItem(at: shortcutURL)
            }

            try fileManager.createSymbolicLink(at: shortcutURL, withDestinationURL: appURL)
        } catch {
            // Convenience only; the app should still launch even if a shortcut cannot be repaired.
        }
    }

    private static func ensureLauncherScript(at directoryURL: URL, pointingTo appURL: URL) {
        let fileManager = FileManager.default
        let scriptURL = directoryURL.appendingPathComponent(Self.launcherName, isDirectory: false)
        let scriptBody = "#!/bin/bash\nopen \"\(appURL.path)\"\n"

        do {
            try scriptBody.write(to: scriptURL, atomically: true, encoding: .utf8)
            try fileManager.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: scriptURL.path)
        } catch {
            // Convenience only; startup should continue even if the launcher cannot be written.
        }
    }
}

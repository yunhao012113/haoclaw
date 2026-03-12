import Foundation

enum DesktopShortcutManager {
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
    }

    private static func ensureShortcut(at shortcutURL: URL, pointingTo appURL: URL) {
        let fileManager = FileManager.default

        do {
            if fileManager.fileExists(atPath: shortcutURL.path) {
                let currentDestination = try? fileManager.destinationOfSymbolicLink(atPath: shortcutURL.path)
                if currentDestination == appURL.path {
                    return
                }
                try fileManager.removeItem(at: shortcutURL)
            }

            try fileManager.createSymbolicLink(at: shortcutURL, withDestinationURL: appURL)
        } catch {
            // Convenience only; the app should still launch even if a shortcut cannot be repaired.
        }
    }
}

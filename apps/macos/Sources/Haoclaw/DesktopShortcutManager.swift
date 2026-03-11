import Foundation

enum DesktopShortcutManager {
    static func ensureDesktopShortcutIfNeeded() {
        let appURL = Bundle.main.bundleURL.standardizedFileURL
        guard appURL.pathExtension == "app" else { return }

        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let desktopURL = homeDirectory.appendingPathComponent("Desktop", isDirectory: true)
        guard FileManager.default.fileExists(atPath: desktopURL.path) else { return }

        let shortcutURL = desktopURL.appendingPathComponent("Haoclaw.app", isDirectory: false)

        do {
            if FileManager.default.fileExists(atPath: shortcutURL.path) {
                let currentDestination = try? FileManager.default.destinationOfSymbolicLink(atPath: shortcutURL.path)
                if currentDestination == appURL.path {
                    return
                }
                try FileManager.default.removeItem(at: shortcutURL)
            }

            try FileManager.default.createSymbolicLink(at: shortcutURL, withDestinationURL: appURL)
        } catch {
            // Installing the shortcut is a convenience task; startup should continue even if it fails.
        }
    }
}

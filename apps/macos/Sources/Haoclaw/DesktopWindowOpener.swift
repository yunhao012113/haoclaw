import AppKit
import SwiftUI

@MainActor
final class DesktopWindowOpener {
    static let shared = DesktopWindowOpener()

    private var openWindowAction: OpenWindowAction?

    func register(openWindow: OpenWindowAction) {
        self.openWindowAction = openWindow
    }

    func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        self.openWindowAction?(id: "desktop-client")
    }
}


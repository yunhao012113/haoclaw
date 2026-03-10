import AppKit
import SwiftUI

@MainActor
final class DesktopWindowOpener {
    static let shared = DesktopWindowOpener()

    private var openWindowAction: OpenWindowAction?

    func register(openWindow: OpenWindowAction) {
        self.openWindowAction = openWindow
    }

    func openDesktopClient() {
        NSApp.activate(ignoringOtherApps: true)
        if let openWindowAction {
            openWindowAction(id: "desktop-client")
            return
        }
    }
}

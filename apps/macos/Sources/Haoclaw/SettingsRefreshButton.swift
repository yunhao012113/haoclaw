import SwiftUI

struct SettingsRefreshButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        if self.isLoading {
            ProgressView()
        } else {
            Button(action: self.action) {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .help("刷新")
        }
    }
}

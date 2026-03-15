import SwiftUI

struct MenuSessionsHeaderView: View {
    let count: Int
    let statusText: String?

    var body: some View {
        MenuHeaderCard(
            title: "上下文",
            subtitle: self.subtitle,
            statusText: self.statusText)
    }

    private var subtitle: String {
        if self.count == 1 { return "1 个会话 · 24 小时" }
        return "\(self.count) 个会话 · 24 小时"
    }
}

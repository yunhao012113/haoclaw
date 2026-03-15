import SwiftUI

struct MenuUsageHeaderView: View {
    let count: Int

    var body: some View {
        MenuHeaderCard(
            title: "用量",
            subtitle: self.subtitle)
    }

    private var subtitle: String {
        if self.count == 1 { return "1 个提供商" }
        return "\(self.count) 个提供商"
    }
}

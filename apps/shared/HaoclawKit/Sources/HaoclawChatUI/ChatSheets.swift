import Observation
import SwiftUI

@MainActor
struct ChatSessionsSheet: View {
    @Bindable var viewModel: HaoclawChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var sessionToDelete: HaoclawChatSessionEntry?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List(self.viewModel.sessions) { session in
                HStack {
                    Button {
                        self.viewModel.switchSession(to: session.key)
                        self.dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.displayName ?? session.key)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                            if let updatedAt = session.updatedAt, updatedAt > 0 {
                                Text(Date(timeIntervalSince1970: updatedAt / 1000).formatted(
                                    date: .abbreviated,
                                    time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Button(role: .destructive) {
                        self.sessionToDelete = session
                        self.showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("会话列表")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button {
                        self.viewModel.refreshSessions(limit: 200)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                #else
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.viewModel.refreshSessions(limit: 200)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                #endif
            }
            .onAppear {
                self.viewModel.refreshSessions(limit: 200)
            }
        }
        .alert("删除会话", isPresented: self.$showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let session = self.sessionToDelete {
                    self.viewModel.deleteSession(key: session.key)
                }
            }
        } message: {
            if let session = self.sessionToDelete {
                Text("确定要删除会话 \"\(session.displayName ?? session.key)\" 吗？此操作无法撤销。")
            }
        }
    }
}

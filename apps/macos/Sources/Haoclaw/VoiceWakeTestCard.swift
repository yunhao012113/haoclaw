import SwiftUI

struct VoiceWakeTestCard: View {
    @Binding var testState: VoiceWakeTestState
    @Binding var isTesting: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("测试语音唤醒")
                    .font(.callout.weight(.semibold))
                Spacer()
                Button(action: self.onToggle) {
                    Label(
                        self.isTesting ? "停止" : "开始测试",
                        systemImage: self.isTesting ? "stop.circle.fill" : "play.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(self.isTesting ? .red : .accentColor)
            }

            HStack(spacing: 8) {
                self.statusIcon
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.statusText)
                        .font(.subheadline)
                        .frame(maxHeight: 22, alignment: .center)
                    if case let .detected(text) = testState {
                        Text("识别到：\(text)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding(10)
            .background(.quaternary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(minHeight: 54)
        }
        .padding(.vertical, 2)
    }

    private var statusIcon: some View {
        switch self.testState {
        case .idle:
            AnyView(Image(systemName: "waveform").foregroundStyle(.secondary))

        case .requesting:
            AnyView(ProgressView().controlSize(.small))

        case .listening, .hearing:
            AnyView(
                Image(systemName: "ear.and.waveform")
                    .symbolEffect(.pulse)
                    .foregroundStyle(Color.accentColor))

        case .finalizing:
            AnyView(ProgressView().controlSize(.small))

        case .detected:
            AnyView(Image(systemName: "checkmark.circle.fill").foregroundStyle(.green))

        case .failed:
            AnyView(Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow))
        }
    }

    private var statusText: String {
        switch self.testState {
        case .idle:
            "点击开始后说出触发词，等待系统识别。"

        case .requesting:
            "正在请求麦克风和语音识别权限…"

        case .listening:
            "正在监听… 请说出你的触发词。"

        case let .hearing(text):
            "识别到：\(text)"

        case .finalizing:
            "正在收尾处理中…"

        case .detected:
            "已识别到语音唤醒。"

        case let .failed(reason):
            reason
        }
    }
}

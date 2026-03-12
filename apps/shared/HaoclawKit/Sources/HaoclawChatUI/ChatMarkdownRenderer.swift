import SwiftUI
import Foundation

public enum ChatMarkdownVariant: String, CaseIterable, Sendable {
    case standard
    case compact
}

@MainActor
struct ChatMarkdownRenderer: View {
    enum Context {
        case user
        case assistant
    }

    let text: String
    let context: Context
    let variant: ChatMarkdownVariant
    let font: Font
    let textColor: Color

    var body: some View {
        let processed = ChatMarkdownPreprocessor.preprocess(markdown: self.text)
        VStack(alignment: .leading, spacing: 10) {
            MarkdownTextBlock(
                markdown: processed.cleaned,
                font: self.font,
                textColor: self.textColor)

            if !processed.images.isEmpty {
                InlineImageList(images: processed.images)
            }
        }
    }
}

@MainActor
private struct MarkdownTextBlock: View {
    let markdown: String
    let font: Font
    let textColor: Color

    var body: some View {
        if let attributed = self.attributed {
            Text(attributed)
                .font(self.font)
                .foregroundStyle(self.textColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(self.markdown)
                .font(self.font)
                .foregroundStyle(self.textColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var attributed: AttributedString? {
        try? AttributedString(
            markdown: self.markdown,
            options: AttributedString.MarkdownParsingOptions(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible))
    }
}

@MainActor
private struct InlineImageList: View {
    let images: [ChatMarkdownPreprocessor.InlineImage]

    var body: some View {
        ForEach(images, id: \.id) { item in
            if let img = item.image {
                HaoclawPlatformImageFactory.image(img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            } else {
                Text(item.label.isEmpty ? "Image" : item.label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

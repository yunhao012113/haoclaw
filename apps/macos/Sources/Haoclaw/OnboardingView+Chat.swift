import Foundation

extension OnboardingView {
    func maybeKickoffOnboardingChat(for pageIndex: Int) {
        guard pageIndex == self.onboardingChatPageIndex else { return }
        guard self.showOnboardingChat else { return }
        guard !self.didAutoKickoff else { return }
        self.didAutoKickoff = true

        Task { @MainActor in
            for _ in 0..<20 {
                if !self.onboardingChatModel.isLoading { break }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            guard self.onboardingChatModel.messages.isEmpty else { return }
            let kickoff =
                "你好，我刚安装 Haoclaw。请直接使用默认工作区身份，不要再发首次初始化问答或 bootstrap 提问。"
                + "如果需要，只帮我确认 SOUL.md 的语气是否合适，然后直接引导我选择沟通方式：网页、WhatsApp 或 Telegram。"
            self.onboardingChatModel.input = kickoff
            self.onboardingChatModel.send()
        }
    }
}

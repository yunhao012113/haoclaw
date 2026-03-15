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
                "Hi! I just installed Haoclaw and you’re my brand‑new agent. " +
                "Skip any first-run ritual or bootstrap questionnaire. " +
                "Use the default workspace identity, help me confirm the tone in SOUL.md if needed, " +
                "and then guide me straight to choosing how we should talk (web-only, WhatsApp, or Telegram)."
            self.onboardingChatModel.input = kickoff
            self.onboardingChatModel.send()
        }
    }
}

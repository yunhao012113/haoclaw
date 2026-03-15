import Foundation
import HaoclawChatUI
import Testing
@testable import Haoclaw

@Suite(.serialized)
@MainActor
struct DesktopControlCenterSmokeTests {
    private struct TestTransport: HaoclawChatTransport {
        func requestHistory(sessionKey: String) async throws -> HaoclawChatHistoryPayload {
            let json = """
            {"sessionKey":"\(sessionKey)","sessionId":null,"messages":[],"thinkingLevel":"off"}
            """
            return try JSONDecoder().decode(HaoclawChatHistoryPayload.self, from: Data(json.utf8))
        }

        func sendMessage(
            sessionKey _: String,
            message _: String,
            thinking _: String,
            idempotencyKey _: String,
            attachments _: [HaoclawChatAttachmentPayload]) async throws -> HaoclawChatSendResponse
        {
            let json = """
            {"runId":"\(UUID().uuidString)","status":"ok"}
            """
            return try JSONDecoder().decode(HaoclawChatSendResponse.self, from: Data(json.utf8))
        }

        func requestHealth(timeoutMs _: Int) async throws -> Bool {
            true
        }

        func events() -> AsyncStream<HaoclawChatTransportEvent> {
            AsyncStream { continuation in
                continuation.finish()
            }
        }

        func setActiveSessionKey(_: String) async throws {}
    }

    @Test func `desktop control center models page builds body`() {
        let state = AppState(preview: true)
        let chatViewModel = HaoclawChatViewModel(sessionKey: "main", transport: TestTransport())
        let model = DesktopClientModel(appState: state, chatViewModel: chatViewModel)
        model.controlSection = .models
        model.gatewayStatus = "已连接"
        model.gatewayURL = "ws://127.0.0.1:18789"
        model.currentModelRef = "openai/gpt-5"
        model.statusMessage = "接口已连接，已自动选择默认模型。"
        model.runtimeModels = [
            ModelChoice(id: "gpt-5", name: "gpt-5", provider: "openai", contextWindow: 400_000),
            ModelChoice(id: "gpt-5-mini", name: "gpt-5-mini", provider: "openai", contextWindow: 400_000),
        ]
        model.settingsDraft.providerPreset = .openai
        model.settingsDraft.providerId = "openai"
        model.settingsDraft.baseURL = "https://api.openai.com/v1"

        let view = DesktopControlCenterSheet(state: state, model: model, updater: nil)
        _ = view.body

        #expect(model.firstResolvedDiscoveredModelID == "gpt-5")
        #expect(model.canApplyDraftModelSelection == false)

        model.settingsDraft.modelID = "gpt-5-mini"
        #expect(model.canApplyDraftModelSelection)

        model.openModelSettings()
        #expect(model.controlSection == .models)
        #expect(model.isShowingControlCenter)
    }

    @Test func `nvidia preset applies official defaults`() {
        let state = AppState(preview: true)
        let chatViewModel = HaoclawChatViewModel(sessionKey: "main", transport: TestTransport())
        let model = DesktopClientModel(appState: state, chatViewModel: chatViewModel)

        model.settingsDraft.providerPreset = .nvidia
        model.applyProviderPreset()

        #expect(model.settingsDraft.providerId == "nvidia")
        #expect(model.settingsDraft.baseURL == "https://integrate.api.nvidia.com/v1")
        #expect(model.settingsDraft.modelID == "meta/llama-3.3-70b-instruct")
        #expect(model.settingsDraft.apiAdapter == "openai-completions")
        #expect(
            DesktopProviderPreset.infer(
                providerID: "nvidia",
                baseURL: "https://integrate.api.nvidia.com/v1",
                apiAdapter: "openai-completions") == .nvidia)
    }

    @Test func `additional presets apply expected defaults`() {
        let state = AppState(preview: true)
        let chatViewModel = HaoclawChatViewModel(sessionKey: "main", transport: TestTransport())
        let model = DesktopClientModel(appState: state, chatViewModel: chatViewModel)

        model.settingsDraft.providerPreset = .mistral
        model.applyProviderPreset()
        #expect(model.settingsDraft.providerId == "mistral")
        #expect(model.settingsDraft.baseURL == "https://api.mistral.ai/v1")
        #expect(model.settingsDraft.modelID == "mistral-large-latest")

        model.settingsDraft.providerPreset = .minimax
        model.applyProviderPreset()
        #expect(model.settingsDraft.providerId == "minimax")
        #expect(model.settingsDraft.baseURL == "https://api.minimax.io/anthropic")
        #expect(model.settingsDraft.modelID == "MiniMax-M2.5")
        #expect(model.settingsDraft.apiAdapter == "anthropic-messages")
        #expect(model.settingsDraft.providerPreset.authHeader)

        model.settingsDraft.providerPreset = .qianfan
        model.applyProviderPreset()
        #expect(model.settingsDraft.providerId == "qianfan")
        #expect(model.settingsDraft.baseURL == "https://qianfan.baidubce.com/v2")
        #expect(model.settingsDraft.modelID == "deepseek-v3.2")
    }

    @Test func `opening model settings restores applied config instead of stale draft`() {
        let state = AppState(preview: true)
        let chatViewModel = HaoclawChatViewModel(sessionKey: "main", transport: TestTransport())
        let model = DesktopClientModel(appState: state, chatViewModel: chatViewModel)

        model.appliedModelSettings.providerPreset = .nvidia
        model.appliedModelSettings.providerId = "nvidia"
        model.appliedModelSettings.apiAdapter = "openai-completions"
        model.appliedModelSettings.baseURL = "https://integrate.api.nvidia.com/v1"
        model.appliedModelSettings.apiKey = "saved-key"
        model.appliedModelSettings.modelID = "meta/llama-3.3-70b-instruct"

        model.settingsDraft.providerPreset = .openAICompatible
        model.settingsDraft.providerId = "custom-openai"
        model.settingsDraft.baseURL = ""
        model.settingsDraft.apiKey = ""
        model.settingsDraft.modelID = ""

        model.openModelSettings()

        #expect(model.settingsDraft.providerPreset == .nvidia)
        #expect(model.settingsDraft.providerId == "nvidia")
        #expect(model.settingsDraft.baseURL == "https://integrate.api.nvidia.com/v1")
        #expect(model.settingsDraft.apiKey == "saved-key")
        #expect(model.settingsDraft.modelID == "meta/llama-3.3-70b-instruct")
    }

    @Test func `conversation only layout toggle flips state`() {
        let state = AppState(preview: true)
        let chatViewModel = HaoclawChatViewModel(sessionKey: "main", transport: TestTransport())
        let model = DesktopClientModel(appState: state, chatViewModel: chatViewModel)

        #expect(model.isConversationOnlyLayout == false)
        model.toggleConversationOnlyLayout()
        #expect(model.isConversationOnlyLayout == true)
        model.toggleConversationOnlyLayout()
        #expect(model.isConversationOnlyLayout == false)
    }

    @Test func `startup guide advances step by step and then dismisses`() {
        let state = AppState(preview: true)
        let chatViewModel = HaoclawChatViewModel(sessionKey: "main", transport: TestTransport())
        let model = DesktopClientModel(appState: state, chatViewModel: chatViewModel)

        model.presentStartupGuideIfNeeded(force: true)
        #expect(model.shouldShowStartupGuideOverlay)
        #expect(model.startupGuideOverlayStepIndex == 0)

        model.advanceStartupGuideOverlay()
        #expect(model.shouldShowStartupGuideOverlay)
        #expect(model.startupGuideOverlayStepIndex == 1)

        model.advanceStartupGuideOverlay()
        #expect(model.shouldShowStartupGuideOverlay)
        #expect(model.startupGuideOverlayStepIndex == 2)

        model.advanceStartupGuideOverlay()
        #expect(model.shouldShowStartupGuideOverlay == false)
    }

    @Test func `openai compatible preset shows actionable base url guidance`() async {
        let state = AppState(preview: true)
        let chatViewModel = HaoclawChatViewModel(sessionKey: "main", transport: TestTransport())
        let model = DesktopClientModel(appState: state, chatViewModel: chatViewModel)

        model.settingsDraft.providerPreset = .openAICompatible
        model.applyProviderPreset()
        model.settingsDraft.apiKey = "test-key"

        await model.saveModelSettings()

        #expect(model.statusMessage?.contains("不会自动生成地址") == true)
        #expect(model.statusMessage?.contains("NVIDIA") == true)
    }
}

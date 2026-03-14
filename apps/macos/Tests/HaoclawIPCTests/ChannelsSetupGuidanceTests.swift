import HaoclawProtocol
import Testing
@testable import Haoclaw

private typealias GuidanceAnyCodable = Haoclaw.AnyCodable

@MainActor
private func makeGuidanceStore(channels: [String: GuidanceAnyCodable] = [:]) -> ChannelsStore {
    let store = ChannelsStore(isPreview: true)
    store.snapshot = ChannelsStatusSnapshot(
        ts: 1_700_000_000_000,
        channelOrder: Array(channels.keys),
        channelLabels: [:],
        channelDetailLabels: nil,
        channelSystemImages: nil,
        channelMeta: nil,
        channels: channels,
        channelAccounts: [:],
        channelDefaultAccountId: [:])
    return store
}

@Suite(.serialized)
@MainActor
struct ChannelsSetupGuidanceTests {
    @Test func `telegram summary requires token before validation`() {
        let store = makeGuidanceStore()

        let summary = store.channelSetupSummary(for: "telegram")

        #expect(summary.state == .incomplete)
        #expect(summary.detail.contains("Bot Token"))
    }

    @Test func `telegram summary reports successful probe`() {
        let store = makeGuidanceStore(
            channels: [
                "telegram": GuidanceAnyCodable([
                    "configured": true,
                    "running": true,
                    "probe": [
                        "ok": true,
                        "status": 200,
                        "elapsedMs": 120,
                        "bot": ["username": "haoclawbot"],
                    ],
                    "lastProbeAt": 1_700_000_050_000,
                ]),
            ])
        store.updateConfigValue(path: [.key("channels"), .key("telegram"), .key("botToken")], value: "123456:ABC")

        let summary = store.channelSetupSummary(for: "telegram")

        #expect(summary.state == .verified)
        #expect(summary.title == "验证通过")
        #expect(summary.detail.contains("@haoclawbot"))
    }

    @Test func `whatsapp summary guides user to pair after save`() {
        let store = makeGuidanceStore(
            channels: [
                "whatsapp": GuidanceAnyCodable([
                    "configured": true,
                    "running": true,
                    "connected": false,
                    "lastEventAt": 1_700_000_060_000,
                ]),
            ])

        let summary = store.channelSetupSummary(for: "whatsapp")

        #expect(summary.state == .ready)
        #expect(summary.title == "等待扫码配对")
        #expect(summary.detail.contains("二维码"))
    }

    @Test func `slack http mode requires signing secret`() {
        let store = makeGuidanceStore()
        store.updateConfigValue(path: [.key("channels"), .key("slack"), .key("mode")], value: "http")
        store.updateConfigValue(path: [.key("channels"), .key("slack"), .key("botToken")], value: "xoxb-123")

        let summary = store.channelSetupSummary(for: "slack")

        #expect(summary.state == .incomplete)
        #expect(summary.detail.contains("Signing Secret"))
    }

    @Test func `line summary reports verified bot identity`() {
        let store = makeGuidanceStore(
            channels: [
                "line": GuidanceAnyCodable([
                    "configured": true,
                    "running": true,
                    "probe": [
                        "ok": true,
                        "bot": [
                            "displayName": "Haoclaw Line",
                            "basicId": "@haoclaw",
                        ],
                    ],
                    "lastProbeAt": 1_700_000_090_000,
                ]),
            ])
        store.updateConfigValue(path: [.key("channels"), .key("line"), .key("channelAccessToken")], value: "token")
        store.updateConfigValue(path: [.key("channels"), .key("line"), .key("channelSecret")], value: "secret")

        let summary = store.channelSetupSummary(for: "line")

        #expect(summary.state == .verified)
        #expect(summary.detail.contains("Haoclaw Line"))
        #expect(summary.detail.contains("@haoclaw"))
    }

    @Test func `discord summary warns when message content intent is unavailable`() {
        let store = makeGuidanceStore(
            channels: [
                "discord": GuidanceAnyCodable([
                    "configured": true,
                    "running": true,
                    "probe": [
                        "ok": true,
                        "bot": ["username": "haoclawbot"],
                        "application": [
                            "id": "app-123",
                            "intents": [
                                "messageContent": "disabled",
                            ],
                        ],
                    ],
                    "lastProbeAt": 1_700_000_100_000,
                ]),
            ])
        store.updateConfigValue(path: [.key("channels"), .key("discord"), .key("token")], value: "bot-token")

        let summary = store.channelSetupSummary(for: "discord")

        #expect(summary.state == .attention)
        #expect(summary.title == "验证通过，但还需补权限")
        #expect(summary.detail.contains("Message Content Intent"))
    }

    @Test func `slack socket mode next steps mention app token`() {
        let store = makeGuidanceStore()
        store.updateConfigValue(path: [.key("channels"), .key("slack"), .key("mode")], value: "socket")

        let steps = store.channelNextSteps(for: "slack")

        #expect(steps.contains(where: { $0.contains("App Token") }))
    }
}

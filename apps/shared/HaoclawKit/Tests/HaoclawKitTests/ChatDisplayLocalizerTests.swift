import Testing
@testable import HaoclawChatUI

@Suite("ChatDisplayLocalizer")
struct ChatDisplayLocalizerTests {
    @Test func localizesSystemTimelineAndSessionStatus() {
        let raw = """
        System: [2026-03-15 10:29:37 GMT+8] Node: yunhao's MacBook Pro · app 2026.3.67 · mode local · reason launch
        """

        let localized = ChatDisplayLocalizer.localize(raw)

        #expect(localized.contains("系统："))
        #expect(localized.contains("设备："))
        #expect(localized.contains("应用 2026.3.67"))
        #expect(localized.contains("本地模式"))
        #expect(localized.contains("原因：启动"))
    }

    @Test func localizesAuthErrors() {
        let raw = """
        Agent failed before reply: No API key found for provider "anthropic". Auth store: /tmp/auth-profiles.json (agentDir: /tmp/agent). Configure auth for this agent (haoclaw agents add <id>) or copy auth-profiles.json from the main agentDir. Logs: haoclaw logs --follow
        """

        let localized = ChatDisplayLocalizer.localize(raw)

        #expect(localized.contains("助手在回复前失败"))
        #expect(localized.contains("未找到提供商“anthropic”的 API Key"))
        #expect(localized.contains("认证配置"))
        #expect(localized.contains("请为这个助手配置认证"))
        #expect(localized.contains("排查日志：haoclaw logs --follow"))
    }
}

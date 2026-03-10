import Foundation

public enum HaoclawChatTransportEvent: Sendable {
    case health(ok: Bool)
    case tick
    case chat(HaoclawChatEventPayload)
    case agent(HaoclawAgentEventPayload)
    case seqGap
}

public protocol HaoclawChatTransport: Sendable {
    func requestHistory(sessionKey: String) async throws -> HaoclawChatHistoryPayload
    func sendMessage(
        sessionKey: String,
        message: String,
        thinking: String,
        idempotencyKey: String,
        attachments: [HaoclawChatAttachmentPayload]) async throws -> HaoclawChatSendResponse

    func abortRun(sessionKey: String, runId: String) async throws
    func listSessions(limit: Int?) async throws -> HaoclawChatSessionsListResponse

    func requestHealth(timeoutMs: Int) async throws -> Bool
    func events() -> AsyncStream<HaoclawChatTransportEvent>

    func setActiveSessionKey(_ sessionKey: String) async throws
}

extension HaoclawChatTransport {
    public func setActiveSessionKey(_: String) async throws {}

    public func abortRun(sessionKey _: String, runId _: String) async throws {
        throw NSError(
            domain: "HaoclawChatTransport",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "chat.abort not supported by this transport"])
    }

    public func listSessions(limit _: Int?) async throws -> HaoclawChatSessionsListResponse {
        throw NSError(
            domain: "HaoclawChatTransport",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "sessions.list not supported by this transport"])
    }
}

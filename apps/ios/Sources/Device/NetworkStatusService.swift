import Foundation
import Network
import HaoclawKit

final class NetworkStatusService: @unchecked Sendable {
    func currentStatus(timeoutMs: Int = 1500) async -> HaoclawNetworkStatusPayload {
        await withCheckedContinuation { cont in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "ai.haoclaw.ios.network-status")
            let state = NetworkStatusState()

            monitor.pathUpdateHandler = { path in
                guard state.markCompleted() else { return }
                monitor.cancel()
                cont.resume(returning: Self.payload(from: path))
            }

            monitor.start(queue: queue)

            queue.asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
                guard state.markCompleted() else { return }
                monitor.cancel()
                cont.resume(returning: Self.fallbackPayload())
            }
        }
    }

    private static func payload(from path: NWPath) -> HaoclawNetworkStatusPayload {
        let status: HaoclawNetworkPathStatus = switch path.status {
        case .satisfied: .satisfied
        case .requiresConnection: .requiresConnection
        case .unsatisfied: .unsatisfied
        @unknown default: .unsatisfied
        }

        var interfaces: [HaoclawNetworkInterfaceType] = []
        if path.usesInterfaceType(.wifi) { interfaces.append(.wifi) }
        if path.usesInterfaceType(.cellular) { interfaces.append(.cellular) }
        if path.usesInterfaceType(.wiredEthernet) { interfaces.append(.wired) }
        if interfaces.isEmpty { interfaces.append(.other) }

        return HaoclawNetworkStatusPayload(
            status: status,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained,
            interfaces: interfaces)
    }

    private static func fallbackPayload() -> HaoclawNetworkStatusPayload {
        HaoclawNetworkStatusPayload(
            status: .unsatisfied,
            isExpensive: false,
            isConstrained: false,
            interfaces: [.other])
    }
}

private final class NetworkStatusState: @unchecked Sendable {
    private let lock = NSLock()
    private var completed = false

    func markCompleted() -> Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        if self.completed { return false }
        self.completed = true
        return true
    }
}

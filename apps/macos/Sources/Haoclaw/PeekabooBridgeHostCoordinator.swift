import Foundation

@MainActor
final class PeekabooBridgeHostCoordinator {
    static let shared = PeekabooBridgeHostCoordinator()

    func setEnabled(_ enabled: Bool) async {
        _ = enabled
    }

    func stop() async {}
}

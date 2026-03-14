import Foundation
import Testing
@testable import Haoclaw

@Suite(.serialized)
@MainActor
struct LocalGatewayBootstrapperTests {
    @Test func `local bootstrap root writes local mode and workspace`() {
        let synced = LocalGatewayBootstrapper.syncedLocalBootstrapRoot(currentRoot: [:])
        let gateway = synced.root["gateway"] as? [String: Any]

        #expect(synced.changed)
        #expect(gateway?["mode"] as? String == "local")
        #expect(AgentWorkspaceConfig.workspace(from: synced.root) == "~/.haoclaw/workspace")
    }

    @Test func `local bootstrap preserves existing workspace`() {
        let synced = LocalGatewayBootstrapper.syncedLocalBootstrapRoot(currentRoot: [
            "agents": [
                "defaults": [
                    "workspace": "~/custom-workspace",
                ],
            ],
        ])

        #expect(synced.changed)
        #expect(AgentWorkspaceConfig.workspace(from: synced.root) == "~/custom-workspace")
    }
}

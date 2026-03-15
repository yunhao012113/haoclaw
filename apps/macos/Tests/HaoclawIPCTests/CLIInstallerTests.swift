import Foundation
import Testing
@testable import Haoclaw

@Suite(.serialized)
@MainActor
struct CLIInstallerTests {
    private func makeTempExecutable(named name: String = "node", contents: String) throws -> URL {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager().createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent(name)
        try contents.write(to: path, atomically: true, encoding: .utf8)
        try FileManager().setAttributes([.posixPermissions: 0o755], ofItemAtPath: path.path)
        return path
    }

    @Test func `installed location finds executable`() throws {
        let fm = FileManager()
        let root = fm.temporaryDirectory.appendingPathComponent(
            "haoclaw-cli-installer-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: root) }

        let binDir = root.appendingPathComponent("bin")
        try fm.createDirectory(at: binDir, withIntermediateDirectories: true)
        let cli = binDir.appendingPathComponent("haoclaw")
        fm.createFile(atPath: cli.path, contents: Data())
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: cli.path)

        let found = CLIInstaller.installedLocation(
            searchPaths: [binDir.path],
            fileManager: fm)
        #expect(found == cli.path)

        try fm.removeItem(at: cli)
        fm.createFile(atPath: cli.path, contents: Data())
        try fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: cli.path)

        let missing = CLIInstaller.installedLocation(
            searchPaths: [binDir.path],
            fileManager: fm)
        #expect(missing == nil)
    }

    @Test func `install plan prefers local npm install when node is available`() throws {
        let node = try self.makeTempExecutable(contents: """
        #!/bin/sh
        echo v22.12.0
        """)
        let npm = try self.makeTempExecutable(named: "npm", contents: """
        #!/bin/sh
        echo npm-ok
        """)

        let plan = CLIInstaller.installPlan(
            version: "2026.3.67",
            searchPaths: [node.deletingLastPathComponent().path, npm.deletingLastPathComponent().path],
            platform: .macOS)

        #expect(plan == .globalPackage(version: "2026.3.67"))
    }

    @Test func `install plan opens download guidance on mac when runtime is missing`() {
        let plan = CLIInstaller.installPlan(
            version: "2026.3.67",
            searchPaths: ["/tmp/haoclaw-no-runtime"],
            platform: .macOS)

        guard case let .desktopDownload(message) = plan else {
            Issue.record("Expected desktopDownload plan, got \(plan)")
            return
        }
        #expect(message.contains("统一下载页"))
        #expect(message.contains("PKG"))
    }

    @Test func `install plan keeps shell script fallback off mac when runtime is missing`() {
        let plan = CLIInstaller.installPlan(
            version: "2026.3.67",
            searchPaths: ["/tmp/haoclaw-no-runtime"],
            platform: .other)

        #expect(plan == .installScript(version: "2026.3.67"))
    }
}

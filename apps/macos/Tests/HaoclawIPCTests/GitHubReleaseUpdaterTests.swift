import Foundation
import Testing
@testable import Haoclaw

@Suite(.serialized)
struct GitHubReleaseUpdaterTests {
    @Test
    func `preferred mac asset prioritizes pkg over dmg and zip`() {
        let assets = [
            GitHubReleaseUpdaterController.ReleaseAsset(
                name: "Haoclaw-2026.3.16.zip",
                browserDownloadURL: URL(string: "https://example.com/Haoclaw-2026.3.16.zip")!),
            GitHubReleaseUpdaterController.ReleaseAsset(
                name: "Haoclaw-2026.3.16.dmg",
                browserDownloadURL: URL(string: "https://example.com/Haoclaw-2026.3.16.dmg")!),
            GitHubReleaseUpdaterController.ReleaseAsset(
                name: "Haoclaw-2026.3.16.pkg",
                browserDownloadURL: URL(string: "https://example.com/Haoclaw-2026.3.16.pkg")!),
        ]

        #expect(GitHubReleaseUpdaterController.preferredMacAsset(in: assets)?.name == "Haoclaw-2026.3.16.pkg")
    }

    @Test
    func `preferred release ignores prerelease and windows only assets`() {
        let releases = [
            GitHubReleaseUpdaterController.ReleasePayload(
                tagName: "v2026.3.20-beta.1",
                htmlURL: URL(string: "https://example.com/beta")!,
                assets: [
                    .init(
                        name: "Haoclaw-2026.3.20-beta.1.pkg",
                        browserDownloadURL: URL(string: "https://example.com/beta.pkg")!),
                ],
                draft: false,
                prerelease: true),
            GitHubReleaseUpdaterController.ReleasePayload(
                tagName: "v2026.3.19",
                htmlURL: URL(string: "https://example.com/windows-only")!,
                assets: [
                    .init(
                        name: "Haoclaw-2026.3.19-setup.exe",
                        browserDownloadURL: URL(string: "https://example.com/setup.exe")!),
                ],
                draft: false,
                prerelease: false),
            GitHubReleaseUpdaterController.ReleasePayload(
                tagName: "v2026.3.18",
                htmlURL: URL(string: "https://example.com/stable")!,
                assets: [
                    .init(
                        name: "Haoclaw-2026.3.18.pkg",
                        browserDownloadURL: URL(string: "https://example.com/stable.pkg")!),
                ],
                draft: false,
                prerelease: false),
        ]

        let preferred = GitHubReleaseUpdaterController.preferredRelease(from: releases, currentVersion: "2026.3.17")
        #expect(preferred?.tagName == "v2026.3.18")
    }

    @Test
    func `preferred release does not require windows installer to upgrade mac app`() {
        let releases = [
            GitHubReleaseUpdaterController.ReleasePayload(
                tagName: "v2026.3.16",
                htmlURL: URL(string: "https://example.com/release")!,
                assets: [
                    .init(
                        name: "Haoclaw-2026.3.16.pkg",
                        browserDownloadURL: URL(string: "https://example.com/release.pkg")!),
                ],
                draft: false,
                prerelease: false),
        ]

        let preferred = GitHubReleaseUpdaterController.preferredRelease(from: releases, currentVersion: "2026.3.15")
        #expect(preferred?.tagName == "v2026.3.16")
    }

    @Test
    func `latest newer stable release can be newer even before mac asset is uploaded`() {
        let releases = [
            GitHubReleaseUpdaterController.ReleasePayload(
                tagName: "v2026.3.74",
                htmlURL: URL(string: "https://example.com/pending")!,
                assets: [
                    .init(
                        name: "Haoclaw-2026.3.74-setup.exe",
                        browserDownloadURL: URL(string: "https://example.com/setup.exe")!),
                ],
                draft: false,
                prerelease: false),
            GitHubReleaseUpdaterController.ReleasePayload(
                tagName: "v2026.3.73",
                htmlURL: URL(string: "https://example.com/stable")!,
                assets: [
                    .init(
                        name: "Haoclaw-2026.3.73.pkg",
                        browserDownloadURL: URL(string: "https://example.com/stable.pkg")!),
                ],
                draft: false,
                prerelease: false),
        ]

        let newest = GitHubReleaseUpdaterController.latestNewerStableRelease(from: releases, currentVersion: "2026.3.73")
        let installable = GitHubReleaseUpdaterController.preferredRelease(from: releases, currentVersion: "2026.3.73")
        #expect(newest?.tagName == "v2026.3.74")
        #expect(installable == nil)
    }

    @Test
    func `latest newer stable release ignores newer draft duplicate`() {
        let releases = [
            GitHubReleaseUpdaterController.ReleasePayload(
                tagName: "v2026.3.74",
                htmlURL: URL(string: "https://example.com/draft")!,
                assets: [],
                draft: true,
                prerelease: false),
            GitHubReleaseUpdaterController.ReleasePayload(
                tagName: "v2026.3.74",
                htmlURL: URL(string: "https://example.com/release")!,
                assets: [
                    .init(
                        name: "Haoclaw-2026.3.74.pkg",
                        browserDownloadURL: URL(string: "https://example.com/release.pkg")!),
                ],
                draft: false,
                prerelease: false),
        ]

        let newest = GitHubReleaseUpdaterController.latestNewerStableRelease(from: releases, currentVersion: "2026.3.73")
        let installable = GitHubReleaseUpdaterController.preferredRelease(from: releases, currentVersion: "2026.3.73")
        #expect(newest?.htmlURL.absoluteString == "https://example.com/release")
        #expect(installable?.htmlURL.absoluteString == "https://example.com/release")
    }
}

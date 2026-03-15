import Foundation
import Testing
@testable import Haoclaw

@Suite(.serialized)
struct HaoclawConfigFileTests {
    private func makeConfigOverridePath() -> String {
        FileManager().temporaryDirectory
            .appendingPathComponent("haoclaw-config-\(UUID().uuidString)")
            .appendingPathComponent("haoclaw.json")
            .path
    }

    @Test
    func `config path respects env override`() async {
        let override = self.makeConfigOverridePath()

        await TestIsolation.withEnvValues(["HAOCLAW_CONFIG_PATH": override]) {
            #expect(HaoclawConfigFile.url().path == override)
        }
    }

    @MainActor
    @Test
    func `remote gateway port parses and matches host`() async {
        let override = self.makeConfigOverridePath()

        await TestIsolation.withEnvValues(["HAOCLAW_CONFIG_PATH": override]) {
            HaoclawConfigFile.saveDict([
                "gateway": [
                    "remote": [
                        "url": "ws://gateway.ts.net:19999",
                    ],
                ],
            ])
            #expect(HaoclawConfigFile.remoteGatewayPort() == 19999)
            #expect(HaoclawConfigFile.remoteGatewayPort(matchingHost: "gateway.ts.net") == 19999)
            #expect(HaoclawConfigFile.remoteGatewayPort(matchingHost: "gateway") == 19999)
            #expect(HaoclawConfigFile.remoteGatewayPort(matchingHost: "other.ts.net") == nil)
        }
    }

    @MainActor
    @Test
    func `set remote gateway url preserves scheme`() async {
        let override = self.makeConfigOverridePath()

        await TestIsolation.withEnvValues(["HAOCLAW_CONFIG_PATH": override]) {
            HaoclawConfigFile.saveDict([
                "gateway": [
                    "remote": [
                        "url": "wss://old-host:111",
                    ],
                ],
            ])
            HaoclawConfigFile.setRemoteGatewayUrl(host: "new-host", port: 2222)
            let root = HaoclawConfigFile.loadDict()
            let url = ((root["gateway"] as? [String: Any])?["remote"] as? [String: Any])?["url"] as? String
            #expect(url == "wss://new-host:2222")
        }
    }

    @MainActor
    @Test
    func `clear remote gateway url removes only url field`() async {
        let override = self.makeConfigOverridePath()

        await TestIsolation.withEnvValues(["HAOCLAW_CONFIG_PATH": override]) {
            HaoclawConfigFile.saveDict([
                "gateway": [
                    "remote": [
                        "url": "wss://old-host:111",
                        "token": "tok",
                    ],
                ],
            ])
            HaoclawConfigFile.clearRemoteGatewayUrl()
            let root = HaoclawConfigFile.loadDict()
            let remote = ((root["gateway"] as? [String: Any])?["remote"] as? [String: Any]) ?? [:]
            #expect((remote["url"] as? String) == nil)
            #expect((remote["token"] as? String) == "tok")
        }
    }

    @Test
    func `state dir override sets config path`() async {
        let dir = FileManager().temporaryDirectory
            .appendingPathComponent("haoclaw-state-\(UUID().uuidString)", isDirectory: true)
            .path

        await TestIsolation.withEnvValues([
            "HAOCLAW_CONFIG_PATH": nil,
            "HAOCLAW_STATE_DIR": dir,
        ]) {
            #expect(HaoclawConfigFile.stateDirURL().path == dir)
            #expect(HaoclawConfigFile.url().path == "\(dir)/haoclaw.json")
        }
    }

    @MainActor
    @Test
    func `save dict appends config audit log`() async throws {
        let stateDir = FileManager().temporaryDirectory
            .appendingPathComponent("haoclaw-state-\(UUID().uuidString)", isDirectory: true)
        let configPath = stateDir.appendingPathComponent("haoclaw.json")
        let auditPath = stateDir.appendingPathComponent("logs/config-audit.jsonl")

        defer { try? FileManager().removeItem(at: stateDir) }

        try await TestIsolation.withEnvValues([
            "HAOCLAW_STATE_DIR": stateDir.path,
            "HAOCLAW_CONFIG_PATH": configPath.path,
        ]) {
            HaoclawConfigFile.saveDict([
                "gateway": ["mode": "local"],
            ])

            let configData = try Data(contentsOf: configPath)
            let configRoot = try JSONSerialization.jsonObject(with: configData) as? [String: Any]
            #expect((configRoot?["meta"] as? [String: Any]) != nil)

            let rawAudit = try String(contentsOf: auditPath, encoding: .utf8)
            let lines = rawAudit
                .split(whereSeparator: \.isNewline)
                .map(String.init)
            #expect(!lines.isEmpty)
            guard let last = lines.last else {
                Issue.record("Missing config audit line")
                return
            }
            let auditRoot = try JSONSerialization.jsonObject(with: Data(last.utf8)) as? [String: Any]
            #expect(auditRoot?["source"] as? String == "macos-haoclaw-config-file")
            #expect(auditRoot?["event"] as? String == "config.write")
            #expect(auditRoot?["result"] as? String == "success")
            #expect(auditRoot?["configPath"] as? String == configPath.path)
        }
    }

    @MainActor
    @Test
    func `load dict repairs legacy desktop block and duplicate provider keys`() async throws {
        let override = self.makeConfigOverridePath()
        let configURL = URL(fileURLWithPath: override)
        try FileManager.default.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)

        let legacy = """
        {
          "desktop": {
            "modelSettings": {
              "selectedProviderId": "NVIDIA"
            }
          },
          "models": {
            "providers": {
              "nvidia": {
                "api": "openai-completions",
                "baseUrl": "https://integrate.api.nvidia.com/v1",
                "models": [
                  {
                    "id": "nvidia/llama-3.1-nemotron-70b-instruct",
                    "name": "nvidia/llama-3.1-nemotron-70b-instruct"
                  }
                ]
              },
              "NVIDIA": {
                "apiKey": "test-key"
              }
            }
          }
        }
        """
        try Data(legacy.utf8).write(to: configURL)

        await TestIsolation.withEnvValues(["HAOCLAW_CONFIG_PATH": override]) {
            let root = HaoclawConfigFile.loadDict()
            #expect(root["desktop"] == nil)

            let providers = ((root["models"] as? [String: Any])?["providers"] as? [String: Any]) ?? [:]
            #expect(providers["NVIDIA"] == nil)
            let nvidia = providers["nvidia"] as? [String: Any]
            #expect(nvidia?["apiKey"] as? String == "test-key")
            let models = nvidia?["models"] as? [[String: Any]]
            #expect(models?.count == 1)

            let repaired = HaoclawConfigFile.loadDict()
            let repairedProviders = ((repaired["models"] as? [String: Any])?["providers"] as? [String: Any]) ?? [:]
            #expect(repaired["desktop"] == nil)
            #expect(repairedProviders["nvidia"] is [String: Any])
        }
    }

    @MainActor
    @Test
    func `load dict migrates legacy nvidia default model`() async throws {
        let override = self.makeConfigOverridePath()
        let configURL = URL(fileURLWithPath: override)
        try FileManager.default.createDirectory(
            at: configURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)

        let legacy = """
        {
          "agents": {
            "defaults": {
              "model": {
                "primary": "nvidia/nvidia/llama-3.1-nemotron-70b-instruct"
              }
            }
          },
          "models": {
            "providers": {
              "nvidia": {
                "api": "openai-completions",
                "baseUrl": "https://integrate.api.nvidia.com/v1",
                "models": [
                  {
                    "id": "nvidia/llama-3.1-nemotron-70b-instruct",
                    "name": "nvidia/llama-3.1-nemotron-70b-instruct"
                  }
                ]
              }
            }
          }
        }
        """
        try Data(legacy.utf8).write(to: configURL)

        await TestIsolation.withEnvValues(["HAOCLAW_CONFIG_PATH": override]) {
            let root = HaoclawConfigFile.loadDict()
            let primary = ((((root["agents"] as? [String: Any])?["defaults"] as? [String: Any])?["model"] as? [String: Any])?["primary"] as? String)
            #expect(primary == "nvidia/meta/llama-3.3-70b-instruct")

            let providers = ((root["models"] as? [String: Any])?["providers"] as? [String: Any]) ?? [:]
            let nvidia = providers["nvidia"] as? [String: Any]
            let models = (nvidia?["models"] as? [[String: Any]]) ?? []
            #expect(models.first?["id"] as? String == "meta/llama-3.3-70b-instruct")
        }
    }

    @MainActor
    @Test
    func `save dict fills missing provider models array for configured provider`() async {
        let override = self.makeConfigOverridePath()

        await TestIsolation.withEnvValues(["HAOCLAW_CONFIG_PATH": override]) {
            HaoclawConfigFile.saveDict([
                "models": [
                    "providers": [
                        "NVIDIA": [
                            "api": "openai-completions",
                            "apiKey": "test-key",
                            "baseUrl": "https://integrate.api.nvidia.com/v1",
                        ],
                    ],
                ],
            ])

            let root = HaoclawConfigFile.loadDict()
            let providers = ((root["models"] as? [String: Any])?["providers"] as? [String: Any]) ?? [:]
            #expect(providers["NVIDIA"] == nil)
            let nvidia = providers["nvidia"] as? [String: Any]
            #expect((nvidia?["models"] as? [Any]) != nil)
        }
    }
}

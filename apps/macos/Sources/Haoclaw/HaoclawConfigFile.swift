import Foundation
import HaoclawProtocol

enum HaoclawConfigFile {
    private static let logger = Logger(subsystem: "ai.haoclaw", category: "config")
    private static let configAuditFileName = "config-audit.jsonl"

    static func url() -> URL {
        HaoclawPaths.configURL
    }

    static func stateDirURL() -> URL {
        HaoclawPaths.stateDirURL
    }

    static func defaultWorkspaceURL() -> URL {
        HaoclawPaths.workspaceURL
    }

    static func loadDict() -> [String: Any] {
        let url = self.url()
        guard FileManager().fileExists(atPath: url.path) else { return [:] }
        do {
            let data = try Data(contentsOf: url)
            guard let root = self.parseConfigData(data) else {
                self.logger.warning("config JSON root invalid")
                return [:]
            }
            let sanitized = self.sanitizeRoot(root)
            if sanitized.changed {
                self.logger.notice("config sanitized during load")
                self.persistSanitizedRootIfNeeded(sanitized.root, originalData: data, to: url)
            }
            return sanitized.root
        } catch {
            self.logger.warning("config read failed: \(error.localizedDescription)")
            return [:]
        }
    }

    static func saveDict(_ dict: [String: Any]) {
        // Nix mode disables config writes in production, but tests rely on saving temp configs.
        if ProcessInfo.processInfo.isNixMode, !ProcessInfo.processInfo.isRunningTests { return }
        let url = self.url()
        let previousData = try? Data(contentsOf: url)
        let previousRoot = previousData.flatMap { self.parseConfigData($0) }
        let previousBytes = previousData?.count
        let hadMetaBefore = self.hasMeta(previousRoot)
        let gatewayModeBefore = self.gatewayMode(previousRoot)

        var output = self.sanitizeRoot(dict).root
        self.stampMeta(&output)

        do {
            let data = try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys])
            try FileManager().createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic])
            let nextBytes = data.count
            let gatewayModeAfter = self.gatewayMode(output)
            let suspicious = self.configWriteSuspiciousReasons(
                existsBefore: previousData != nil,
                previousBytes: previousBytes,
                nextBytes: nextBytes,
                hadMetaBefore: hadMetaBefore,
                gatewayModeBefore: gatewayModeBefore,
                gatewayModeAfter: gatewayModeAfter)
            if !suspicious.isEmpty {
                self.logger.warning("config write anomaly (\(suspicious.joined(separator: ", "))) at \(url.path)")
            }
            self.appendConfigWriteAudit([
                "result": "success",
                "configPath": url.path,
                "existsBefore": previousData != nil,
                "previousBytes": previousBytes ?? NSNull(),
                "nextBytes": nextBytes,
                "hasMetaBefore": hadMetaBefore,
                "hasMetaAfter": self.hasMeta(output),
                "gatewayModeBefore": gatewayModeBefore ?? NSNull(),
                "gatewayModeAfter": gatewayModeAfter ?? NSNull(),
                "suspicious": suspicious,
            ])
        } catch {
            self.logger.error("config save failed: \(error.localizedDescription)")
            self.appendConfigWriteAudit([
                "result": "failed",
                "configPath": url.path,
                "existsBefore": previousData != nil,
                "previousBytes": previousBytes ?? NSNull(),
                "nextBytes": NSNull(),
                "hasMetaBefore": hadMetaBefore,
                "hasMetaAfter": self.hasMeta(output),
                "gatewayModeBefore": gatewayModeBefore ?? NSNull(),
                "gatewayModeAfter": self.gatewayMode(output) ?? NSNull(),
                "suspicious": [],
                "error": error.localizedDescription,
            ])
        }
    }

    static func loadGatewayDict() -> [String: Any] {
        let root = self.loadDict()
        return root["gateway"] as? [String: Any] ?? [:]
    }

    static func updateGatewayDict(_ mutate: (inout [String: Any]) -> Void) {
        var root = self.loadDict()
        var gateway = root["gateway"] as? [String: Any] ?? [:]
        mutate(&gateway)
        if gateway.isEmpty {
            root.removeValue(forKey: "gateway")
        } else {
            root["gateway"] = gateway
        }
        self.saveDict(root)
    }

    static func browserControlEnabled(defaultValue: Bool = true) -> Bool {
        let root = self.loadDict()
        let browser = root["browser"] as? [String: Any]
        return browser?["enabled"] as? Bool ?? defaultValue
    }

    static func setBrowserControlEnabled(_ enabled: Bool) {
        var root = self.loadDict()
        var browser = root["browser"] as? [String: Any] ?? [:]
        browser["enabled"] = enabled
        root["browser"] = browser
        self.saveDict(root)
        self.logger.debug("browser control updated enabled=\(enabled)")
    }

    static func agentWorkspace() -> String? {
        AgentWorkspaceConfig.workspace(from: self.loadDict())
    }

    static func setAgentWorkspace(_ workspace: String?) {
        var root = self.loadDict()
        AgentWorkspaceConfig.setWorkspace(in: &root, workspace: workspace)
        self.saveDict(root)
        let hasWorkspace = !(workspace?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        self.logger.debug("agents.defaults.workspace updated set=\(hasWorkspace)")
    }

    static func gatewayPassword() -> String? {
        let root = self.loadDict()
        guard let gateway = root["gateway"] as? [String: Any],
              let remote = gateway["remote"] as? [String: Any]
        else {
            return nil
        }
        return remote["password"] as? String
    }

    static func gatewayPort() -> Int? {
        let root = self.loadDict()
        guard let gateway = root["gateway"] as? [String: Any] else { return nil }
        if let port = gateway["port"] as? Int, port > 0 { return port }
        if let number = gateway["port"] as? NSNumber, number.intValue > 0 {
            return number.intValue
        }
        if let raw = gateway["port"] as? String,
           let parsed = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)),
           parsed > 0
        {
            return parsed
        }
        return nil
    }

    static func remoteGatewayPort() -> Int? {
        guard let url = self.remoteGatewayUrl(),
              let port = url.port,
              port > 0
        else { return nil }
        return port
    }

    static func remoteGatewayPort(matchingHost sshHost: String) -> Int? {
        let trimmedSshHost = sshHost.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSshHost.isEmpty,
              let url = self.remoteGatewayUrl(),
              let port = url.port,
              port > 0,
              let urlHost = url.host?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlHost.isEmpty
        else {
            return nil
        }

        let sshKey = Self.hostKey(trimmedSshHost)
        let urlKey = Self.hostKey(urlHost)
        guard !sshKey.isEmpty, !urlKey.isEmpty, sshKey == urlKey else { return nil }
        return port
    }

    static func setRemoteGatewayUrl(host: String, port: Int?) {
        guard let port, port > 0 else { return }
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty else { return }
        self.updateGatewayDict { gateway in
            var remote = gateway["remote"] as? [String: Any] ?? [:]
            let existingUrl = (remote["url"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let scheme = URL(string: existingUrl)?.scheme ?? "ws"
            remote["url"] = "\(scheme)://\(trimmedHost):\(port)"
            gateway["remote"] = remote
        }
    }

    static func clearRemoteGatewayUrl() {
        self.updateGatewayDict { gateway in
            guard var remote = gateway["remote"] as? [String: Any] else { return }
            guard remote["url"] != nil else { return }
            remote.removeValue(forKey: "url")
            if remote.isEmpty {
                gateway.removeValue(forKey: "remote")
            } else {
                gateway["remote"] = remote
            }
        }
    }

    private static func remoteGatewayUrl() -> URL? {
        let root = self.loadDict()
        guard let gateway = root["gateway"] as? [String: Any],
              let remote = gateway["remote"] as? [String: Any],
              let raw = remote["url"] as? String
        else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
        return url
    }

    static func hostKey(_ host: String) -> String {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return "" }
        if trimmed.contains(":") { return trimmed }
        let digits = CharacterSet(charactersIn: "0123456789.")
        if trimmed.rangeOfCharacter(from: digits.inverted) == nil {
            return trimmed
        }
        return trimmed.split(separator: ".").first.map(String.init) ?? trimmed
    }

    private static func parseConfigData(_ data: Data) -> [String: Any]? {
        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return root
        }
        let decoder = JSONDecoder()
        if #available(macOS 12.0, *) {
            decoder.allowsJSON5 = true
        }
        if let decoded = try? decoder.decode([String: AnyCodable].self, from: data) {
            self.logger.notice("config parsed with JSON5 decoder")
            return decoded.mapValues { $0.foundationValue }
        }
        return nil
    }

    private static func persistSanitizedRootIfNeeded(
        _ root: [String: Any],
        originalData: Data,
        to url: URL)
    {
        if ProcessInfo.processInfo.isNixMode, !ProcessInfo.processInfo.isRunningTests { return }

        var output = root
        self.stampMeta(&output)
        guard let data = try? JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys]),
              data != originalData
        else {
            return
        }

        do {
            try FileManager().createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            try data.write(to: url, options: [.atomic])
        } catch {
            self.logger.warning("config sanitize write failed: \(error.localizedDescription)")
        }
    }

    private static func sanitizeRoot(_ root: [String: Any]) -> (root: [String: Any], changed: Bool) {
        var output = root
        var changed = false

        if output.removeValue(forKey: "desktop") != nil {
            changed = true
        }

        if let modelsRoot = output["models"] as? [String: Any] {
            let sanitized = self.sanitizeModelsRoot(modelsRoot)
            if sanitized.changed {
                output["models"] = sanitized.root
                changed = true
            }
        }

        return (output, changed)
    }

    private static func sanitizeModelsRoot(_ root: [String: Any]) -> (root: [String: Any], changed: Bool) {
        var output = root
        guard let providers = output["providers"] as? [String: Any] else {
            return (output, false)
        }

        let sanitized = self.sanitizeProviders(providers)
        guard sanitized.changed else {
            return (output, false)
        }
        output["providers"] = sanitized.providers
        return (output, true)
    }

    private static func sanitizeProviders(_ providers: [String: Any]) -> (providers: [String: Any], changed: Bool) {
        var merged: [String: Any] = [:]
        var changed = false

        for (rawKey, rawValue) in providers {
            guard let entry = rawValue as? [String: Any] else {
                changed = true
                continue
            }
            let canonicalKey = self.canonicalProviderID(rawKey)
            let sanitizedEntry = self.sanitizeProviderEntry(entry)
            if canonicalKey != rawKey || sanitizedEntry.changed {
                changed = true
            }

            if let existing = merged[canonicalKey] as? [String: Any] {
                let combined = self.mergeProviderEntries(existing, sanitizedEntry.entry)
                if NSDictionary(dictionary: existing).isEqual(to: combined) == false {
                    changed = true
                }
                merged[canonicalKey] = combined
            } else {
                merged[canonicalKey] = sanitizedEntry.entry
            }
        }

        if merged.count != providers.count {
            changed = true
        }

        return (merged, changed)
    }

    private static func sanitizeProviderEntry(_ entry: [String: Any]) -> (entry: [String: Any], changed: Bool) {
        var output = entry
        var changed = false

        if let rawModels = output["models"] {
            if let models = rawModels as? [Any] {
                let sanitizedModels = models.compactMap { $0 as? [String: Any] }
                if sanitizedModels.count != models.count {
                    changed = true
                }
                output["models"] = self.mergeProviderModels([], sanitizedModels)
            } else {
                output["models"] = []
                changed = true
            }
        } else if self.providerEntryNeedsModels(entry) {
            output["models"] = []
            changed = true
        }

        return (output, changed)
    }

    private static func providerEntryNeedsModels(_ entry: [String: Any]) -> Bool {
        let scalarKeys = ["api", "apiKey", "baseUrl", "authHeader", "headers", "discovery"]
        return scalarKeys.contains(where: { entry[$0] != nil })
    }

    private static func mergeProviderEntries(
        _ existing: [String: Any],
        _ incoming: [String: Any]) -> [String: Any]
    {
        var merged = existing
        for (key, value) in incoming {
            if key == "models" {
                let existingModels = (merged[key] as? [Any])?.compactMap { $0 as? [String: Any] } ?? []
                let incomingModels = (value as? [Any])?.compactMap { $0 as? [String: Any] } ?? []
                merged[key] = self.mergeProviderModels(existingModels, incomingModels)
                continue
            }

            if merged[key] == nil {
                merged[key] = value
                continue
            }

            let existingString = (merged[key] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if let string = value as? String,
               !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !existingString.isEmpty
            {
                continue
            }

            if let string = value as? String, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                merged[key] = string
            } else if let boolValue = value as? Bool, boolValue {
                merged[key] = true
            } else if merged[key] == nil {
                merged[key] = value
            }
        }

        if merged["models"] == nil, self.providerEntryNeedsModels(merged) {
            merged["models"] = []
        }
        return merged
    }

    private static func mergeProviderModels(
        _ existing: [[String: Any]],
        _ incoming: [[String: Any]]) -> [[String: Any]]
    {
        var merged = existing
        var indexByID: [String: Int] = [:]
        for (index, item) in merged.enumerated() {
            let id = ((item["id"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !id.isEmpty {
                indexByID[id.lowercased()] = index
            }
        }

        for item in incoming {
            let id = ((item["id"] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !id.isEmpty else { continue }
            let key = id.lowercased()
            if let index = indexByID[key] {
                merged[index] = self.mergeModelEntries(merged[index], item)
            } else {
                indexByID[key] = merged.count
                merged.append(item)
            }
        }

        return merged
    }

    private static func mergeModelEntries(
        _ existing: [String: Any],
        _ incoming: [String: Any]) -> [String: Any]
    {
        var merged = existing
        for (key, value) in incoming {
            if merged[key] == nil {
                merged[key] = value
                continue
            }
            if let string = value as? String,
               !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                merged[key] = string
            }
        }
        return merged
    }

    private static func canonicalProviderID(_ raw: String) -> String {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "z.ai", "z-ai":
            return "zai"
        case "qwen":
            return "qwen-portal"
        case "gemini":
            return "google"
        case "bytedance", "doubao":
            return "volcengine"
        default:
            return normalized
        }
    }

    private static func stampMeta(_ root: inout [String: Any]) {
        var meta = root["meta"] as? [String: Any] ?? [:]
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "macos-app"
        meta["lastTouchedVersion"] = version
        meta["lastTouchedAt"] = ISO8601DateFormatter().string(from: Date())
        root["meta"] = meta
    }

    private static func hasMeta(_ root: [String: Any]?) -> Bool {
        guard let root else { return false }
        return root["meta"] is [String: Any]
    }

    private static func hasMeta(_ root: [String: Any]) -> Bool {
        root["meta"] is [String: Any]
    }

    private static func gatewayMode(_ root: [String: Any]?) -> String? {
        guard let root else { return nil }
        return self.gatewayMode(root)
    }

    private static func gatewayMode(_ root: [String: Any]) -> String? {
        guard let gateway = root["gateway"] as? [String: Any],
              let mode = gateway["mode"] as? String
        else { return nil }
        let trimmed = mode.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func configWriteSuspiciousReasons(
        existsBefore: Bool,
        previousBytes: Int?,
        nextBytes: Int,
        hadMetaBefore: Bool,
        gatewayModeBefore: String?,
        gatewayModeAfter: String?) -> [String]
    {
        var reasons: [String] = []
        if !existsBefore {
            return reasons
        }
        if let previousBytes, previousBytes >= 512, nextBytes < max(1, previousBytes / 2) {
            reasons.append("size-drop:\(previousBytes)->\(nextBytes)")
        }
        if !hadMetaBefore {
            reasons.append("missing-meta-before-write")
        }
        if gatewayModeBefore != nil, gatewayModeAfter == nil {
            reasons.append("gateway-mode-removed")
        }
        return reasons
    }

    private static func configAuditLogURL() -> URL {
        self.stateDirURL()
            .appendingPathComponent("logs", isDirectory: true)
            .appendingPathComponent(self.configAuditFileName, isDirectory: false)
    }

    private static func appendConfigWriteAudit(_ fields: [String: Any]) {
        var record: [String: Any] = [
            "ts": ISO8601DateFormatter().string(from: Date()),
            "source": "macos-haoclaw-config-file",
            "event": "config.write",
            "pid": ProcessInfo.processInfo.processIdentifier,
            "argv": Array(ProcessInfo.processInfo.arguments.prefix(8)),
        ]
        for (key, value) in fields {
            record[key] = value is NSNull ? NSNull() : value
        }
        guard JSONSerialization.isValidJSONObject(record),
              let data = try? JSONSerialization.data(withJSONObject: record)
        else {
            return
        }
        var line = Data()
        line.append(data)
        line.append(0x0A)
        let logURL = self.configAuditLogURL()
        do {
            try FileManager().createDirectory(
                at: logURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            if !FileManager().fileExists(atPath: logURL.path) {
                FileManager().createFile(atPath: logURL.path, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: logURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: line)
        } catch {
            // best-effort
        }
    }
}

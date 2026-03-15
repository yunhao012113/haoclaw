import Foundation
import HaoclawProtocol

extension ChannelsStore {
    func loadConfigSchema() async {
        guard !self.configSchemaLoading else { return }
        self.configSchemaLoading = true
        defer { self.configSchemaLoading = false }

        do {
            let res: ConfigSchemaResponse = try await GatewayConnection.shared.requestDecoded(
                method: .configSchema,
                params: nil,
                timeoutMs: 8000)
            let schemaValue = res.schema.foundationValue
            self.configSchema = ConfigSchemaNode(raw: schemaValue)
            let hintValues = res.uihints.mapValues { $0.foundationValue }
            self.configUiHints = decodeUiHints(hintValues)
        } catch {
            self.configStatus = error.localizedDescription
        }
    }

    func loadConfig() async {
        do {
            let snap: ConfigSnapshot = try await GatewayConnection.shared.requestDecoded(
                method: .configGet,
                params: nil,
                timeoutMs: 10000)
            self.configStatus = snap.valid == false
                ? "配置无效，请在 ~/.haoclaw/haoclaw.json 中修正。"
                : nil
            self.configRoot = snap.config?.mapValues { $0.foundationValue } ?? [:]
            self.configDraft = cloneConfigValue(self.configRoot) as? [String: Any] ?? self.configRoot
            self.configDirty = false
            self.configLoaded = true

            self.applyUIConfig(snap)
        } catch {
            self.configStatus = error.localizedDescription
        }
    }

    private func applyUIConfig(_ snap: ConfigSnapshot) {
        let ui = snap.config?["ui"]?.dictionaryValue
        let rawSeam = ui?["seamColor"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        AppStateStore.shared.seamColorHex = rawSeam.isEmpty ? nil : rawSeam
    }

    func channelConfigSchema(for channelId: String) -> ConfigSchemaNode? {
        guard let root = self.configSchema else { return nil }
        return root.node(at: [.key("channels"), .key(channelId)])
    }

    func configValue(at path: ConfigPath) -> Any? {
        if let value = valueAtPath(self.configDraft, path: path) {
            return value
        }
        guard path.count >= 2 else { return nil }
        if case .key("channels") = path[0], case .key = path[1] {
            let fallbackPath = Array(path.dropFirst())
            return valueAtPath(self.configDraft, path: fallbackPath)
        }
        return nil
    }

    func updateConfigValue(path: ConfigPath, value: Any?) {
        var root: Any = self.configDraft
        setValue(&root, path: path, value: value)
        self.configDraft = root as? [String: Any] ?? self.configDraft
        self.configDirty = true
        if let channelId = self.channelId(from: path) {
            self.scheduleChannelAutoSave(for: channelId)
        }
    }

    func saveConfigDraft(autoTriggeredChannelId: String? = nil) async {
        guard !self.isSavingConfig else { return }
        self.isSavingConfig = true
        defer { self.isSavingConfig = false }

        do {
            self.normalizeDraftBeforeSave()
            try await ConfigStore.save(self.configDraft)
            await self.loadConfig()
            await self.refresh(probe: true)
            if let channelId = autoTriggeredChannelId {
                let summary = self.channelSetupSummary(for: channelId)
                self.configStatus = "已自动保存并验证 \(self.resolveChannelLabel(channelId))：\(summary.detail)"
            } else {
                self.configStatus = "渠道配置已保存并刷新。"
            }
        } catch {
            self.configStatus = self.localizeChannelTechnicalText(error.localizedDescription)
        }
    }

    func reloadConfigDraft() async {
        await self.loadConfig()
    }

    private func normalizeDraftBeforeSave() {
        var root = self.configDraft
        var channels = root["channels"] as? [String: Any] ?? [:]

        func normalizeOpenDMChannel(
            _ channelId: String,
            hasCredentials: Bool,
            extra: ((inout [String: Any]) -> Void)? = nil
        ) {
            var channel = channels[channelId] as? [String: Any] ?? [:]
            guard hasCredentials else {
                channels[channelId] = channel
                return
            }
            channel["enabled"] = true
            if (channel["dmPolicy"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                channel["dmPolicy"] = "open"
            }
            if channel["allowFrom"] == nil {
                channel["allowFrom"] = ["*"]
            }
            if (channel["groupPolicy"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                channel["groupPolicy"] = "disabled"
            }
            extra?(&channel)
            channels[channelId] = channel
        }

        do {
            let feishu = channels["feishu"] as? [String: Any] ?? [:]
            let hasCreds = !((feishu["appId"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)).isEmpty &&
                !((feishu["appSecret"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)).isEmpty
            normalizeOpenDMChannel("feishu", hasCredentials: hasCreds) { channel in
                if (channel["connectionMode"] as? String ?? "").isEmpty {
                    channel["connectionMode"] = "websocket"
                }
                if (channel["domain"] as? String ?? "").isEmpty {
                    channel["domain"] = "feishu"
                }
            }
        }

        do {
            let telegram = channels["telegram"] as? [String: Any] ?? [:]
            let botToken = (telegram["botToken"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let tokenFile = (telegram["tokenFile"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            normalizeOpenDMChannel("telegram", hasCredentials: !botToken.isEmpty || !tokenFile.isEmpty) { channel in
                if (channel["streamMode"] as? String ?? "").isEmpty {
                    channel["streamMode"] = "partial"
                }
                if (channel["replyToMode"] as? String ?? "").isEmpty {
                    channel["replyToMode"] = "off"
                }
                let webhookUrl = (channel["webhookUrl"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if webhookUrl.isEmpty, (channel["webhookPath"] as? String ?? "").isEmpty {
                    channel["webhookPath"] = "/telegram-webhook"
                }
            }
        }

        do {
            let discord = channels["discord"] as? [String: Any] ?? [:]
            let token = (discord["token"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            normalizeOpenDMChannel("discord", hasCredentials: !token.isEmpty)
        }

        do {
            let mattermost = channels["mattermost"] as? [String: Any] ?? [:]
            let token = (mattermost["botToken"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let baseUrl = (mattermost["baseUrl"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            normalizeOpenDMChannel("mattermost", hasCredentials: !token.isEmpty && !baseUrl.isEmpty)
        }

        do {
            let slack = channels["slack"] as? [String: Any] ?? [:]
            let botToken = (slack["botToken"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let appToken = (slack["appToken"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let signingSecret = (slack["signingSecret"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            normalizeOpenDMChannel("slack", hasCredentials: !botToken.isEmpty || !appToken.isEmpty || !signingSecret.isEmpty) { channel in
                if (channel["mode"] as? String ?? "").isEmpty {
                    channel["mode"] = !appToken.isEmpty ? "socket" : "http"
                }
            }
        }

        root["channels"] = channels
        self.configDraft = root
        self.configDirty = true
    }

    private func channelId(from path: ConfigPath) -> String? {
        guard path.count >= 2 else { return nil }
        guard case .key("channels") = path[0] else { return nil }
        guard case let .key(channelId) = path[1] else { return nil }
        return channelId
    }

    private func scheduleChannelAutoSave(for channelId: String) {
        self.channelAutoSaveTask?.cancel()
        self.channelAutoSaveTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            guard self.configDirty else { return }

            let missing = self.channelMissingRequiredFields(for: channelId)
            if !missing.isEmpty {
                self.configStatus = "已暂存 \(self.resolveChannelLabel(channelId)) 配置，补全 \(missing.joined(separator: "、")) 后会自动验证。"
                return
            }

            self.configStatus = "正在自动保存并验证 \(self.resolveChannelLabel(channelId))…"
            await self.saveConfigDraft(autoTriggeredChannelId: channelId)
        }
    }
}

private func valueAtPath(_ root: Any, path: ConfigPath) -> Any? {
    var current: Any? = root
    for segment in path {
        switch segment {
        case let .key(key):
            guard let dict = current as? [String: Any] else { return nil }
            current = dict[key]
        case let .index(index):
            guard let array = current as? [Any], array.indices.contains(index) else { return nil }
            current = array[index]
        }
    }
    return current
}

private func setValue(_ root: inout Any, path: ConfigPath, value: Any?) {
    guard let segment = path.first else { return }
    switch segment {
    case let .key(key):
        var dict = root as? [String: Any] ?? [:]
        if path.count == 1 {
            if let value {
                dict[key] = value
            } else {
                dict.removeValue(forKey: key)
            }
            root = dict
            return
        }
        var child = dict[key] ?? [:]
        setValue(&child, path: Array(path.dropFirst()), value: value)
        dict[key] = child
        root = dict
    case let .index(index):
        var array = root as? [Any] ?? []
        if index >= array.count {
            array.append(contentsOf: repeatElement(NSNull() as Any, count: index - array.count + 1))
        }
        if path.count == 1 {
            if let value {
                array[index] = value
            } else if array.indices.contains(index) {
                array.remove(at: index)
            }
            root = array
            return
        }
        var child = array[index]
        setValue(&child, path: Array(path.dropFirst()), value: value)
        array[index] = child
        root = array
    }
}

private func cloneConfigValue(_ value: Any) -> Any {
    guard JSONSerialization.isValidJSONObject(value) else { return value }
    do {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        return try JSONSerialization.jsonObject(with: data, options: [])
    } catch {
        return value
    }
}

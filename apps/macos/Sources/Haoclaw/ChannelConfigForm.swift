import SwiftUI

struct ConfigSchemaForm: View {
    @Bindable var store: ChannelsStore
    let schema: ConfigSchemaNode
    let path: ConfigPath

    var body: some View {
        self.renderNode(self.schema, path: self.path)
    }

    private func renderNode(_ schema: ConfigSchemaNode, path: ConfigPath) -> AnyView {
        let storedValue = self.store.configValue(at: path)
        let value = storedValue ?? schema.explicitDefault
        let label = hintForPath(path, hints: store.configUiHints)?.label ?? schema.title
        let help = hintForPath(path, hints: store.configUiHints)?.help ?? schema.description
        let variants = schema.anyOf.isEmpty ? schema.oneOf : schema.anyOf

        if !variants.isEmpty {
            let nonNull = variants.filter { !$0.isNullSchema }
            if nonNull.count == 1, let only = nonNull.first {
                return self.renderNode(only, path: path)
            }
            let literals = nonNull.compactMap(\.literalValue)
            if !literals.isEmpty, literals.count == nonNull.count {
                return AnyView(
                    VStack(alignment: .leading, spacing: 6) {
                        if let label { Text(label).font(.callout.weight(.semibold)) }
                        if let help {
                            Text(help)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Picker(
                            "",
                            selection: self.enumBinding(
                                path,
                                options: literals,
                                defaultValue: schema.explicitDefault))
                        {
                            Text("请选择…").tag(-1)
                            ForEach(literals.indices, id: \ .self) { index in
                                Text(String(describing: literals[index])).tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                    })
            }
        }

        switch schema.schemaType {
        case "object":
            return AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    if let label {
                        Text(label)
                            .font(.callout.weight(.semibold))
                    }
                    if let help {
                        Text(help)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    let properties = schema.properties
                    let sortedKeys = properties.keys.sorted { lhs, rhs in
                        let orderA = hintForPath(path + [.key(lhs)], hints: store.configUiHints)?.order ?? 0
                        let orderB = hintForPath(path + [.key(rhs)], hints: store.configUiHints)?.order ?? 0
                        if orderA != orderB { return orderA < orderB }
                        return lhs < rhs
                    }
                    ForEach(sortedKeys, id: \ .self) { key in
                        if let child = properties[key] {
                            self.renderNode(child, path: path + [.key(key)])
                        }
                    }
                    if schema.allowsAdditionalProperties {
                        self.renderAdditionalProperties(schema, path: path, value: value)
                    }
                })
        case "array":
            return AnyView(self.renderArray(schema, path: path, value: value, label: label, help: help))
        case "boolean":
            return AnyView(
                Toggle(isOn: self.boolBinding(path, defaultValue: schema.explicitDefault as? Bool)) {
                    if let label { Text(label) } else { Text("已启用") }
                }
                .help(help ?? ""))
        case "number", "integer":
            return AnyView(self.renderNumberField(schema, path: path, label: label, help: help))
        case "string":
            return AnyView(self.renderStringField(schema, path: path, label: label, help: help))
        default:
            return AnyView(
                VStack(alignment: .leading, spacing: 6) {
                    if let label { Text(label).font(.callout.weight(.semibold)) }
                    Text("暂不支持这种字段类型。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                })
        }
    }

    @ViewBuilder
    private func renderStringField(
        _ schema: ConfigSchemaNode,
        path: ConfigPath,
        label: String?,
        help: String?) -> some View
    {
        let hint = hintForPath(path, hints: store.configUiHints)
        let placeholder = hint?.placeholder ?? ""
        let sensitive = hint?.sensitive ?? isSensitivePath(path)
        let defaultValue = schema.explicitDefault as? String
        VStack(alignment: .leading, spacing: 6) {
            if let label { Text(label).font(.callout.weight(.semibold)) }
            if let help {
                Text(help)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let options = schema.enumValues {
                Picker("", selection: self.enumBinding(path, options: options, defaultValue: schema.explicitDefault)) {
                    Text("请选择…").tag(-1)
                    ForEach(options.indices, id: \ .self) { index in
                        Text(String(describing: options[index])).tag(index)
                    }
                }
                .pickerStyle(.menu)
            } else if sensitive {
                SecureField(placeholder, text: self.stringBinding(path, defaultValue: defaultValue))
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(placeholder, text: self.stringBinding(path, defaultValue: defaultValue))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    @ViewBuilder
    private func renderNumberField(
        _ schema: ConfigSchemaNode,
        path: ConfigPath,
        label: String?,
        help: String?) -> some View
    {
        let defaultValue = (schema.explicitDefault as? Double)
            ?? (schema.explicitDefault as? Int).map(Double.init)
        VStack(alignment: .leading, spacing: 6) {
            if let label { Text(label).font(.callout.weight(.semibold)) }
            if let help {
                Text(help)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextField(
                "",
                text: self.numberBinding(
                    path,
                    isInteger: schema.schemaType == "integer",
                    defaultValue: defaultValue))
                .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    private func renderArray(
        _ schema: ConfigSchemaNode,
        path: ConfigPath,
        value: Any?,
        label: String?,
        help: String?) -> some View
    {
        let items = value as? [Any] ?? []
        let itemSchema = schema.items
        VStack(alignment: .leading, spacing: 10) {
            if let label { Text(label).font(.callout.weight(.semibold)) }
            if let help {
                Text(help)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(items.indices, id: \ .self) { index in
                HStack(alignment: .top, spacing: 8) {
                    if let itemSchema {
                        self.renderNode(itemSchema, path: path + [.index(index)])
                    } else {
                        Text(String(describing: items[index]))
                    }
                    Button("删除") {
                        var next = items
                        next.remove(at: index)
                        self.store.updateConfigValue(path: path, value: next)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            Button("添加") {
                var next = items
                if let itemSchema {
                    next.append(itemSchema.defaultValue)
                } else {
                    next.append("")
                }
                self.store.updateConfigValue(path: path, value: next)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    @ViewBuilder
    private func renderAdditionalProperties(
        _ schema: ConfigSchemaNode,
        path: ConfigPath,
        value: Any?) -> some View
    {
        if let additionalSchema = schema.additionalProperties {
            let dict = value as? [String: Any] ?? [:]
            let reserved = Set(schema.properties.keys)
            let extras = dict.keys.filter { !reserved.contains($0) }.sorted()

            VStack(alignment: .leading, spacing: 8) {
                Text("额外条目")
                    .font(.callout.weight(.semibold))
                if extras.isEmpty {
                    Text("暂时还没有额外条目。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(extras, id: \ .self) { key in
                        let itemPath: ConfigPath = path + [.key(key)]
                        HStack(alignment: .top, spacing: 8) {
                            TextField("键名", text: self.mapKeyBinding(path: path, key: key))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 160)
                            self.renderNode(additionalSchema, path: itemPath)
                            Button("删除") {
                                var next = dict
                                next.removeValue(forKey: key)
                                self.store.updateConfigValue(path: path, value: next)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                Button("添加") {
                    var next = dict
                    var index = 1
                    var key = "new-\(index)"
                    while next[key] != nil {
                        index += 1
                        key = "new-\(index)"
                    }
                    next[key] = additionalSchema.defaultValue
                    self.store.updateConfigValue(path: path, value: next)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func stringBinding(_ path: ConfigPath, defaultValue: String?) -> Binding<String> {
        Binding(
            get: {
                if let value = store.configValue(at: path) as? String { return value }
                return defaultValue ?? ""
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                self.store.updateConfigValue(path: path, value: trimmed.isEmpty ? nil : trimmed)
            })
    }

    private func boolBinding(_ path: ConfigPath, defaultValue: Bool?) -> Binding<Bool> {
        Binding(
            get: {
                if let value = store.configValue(at: path) as? Bool { return value }
                return defaultValue ?? false
            },
            set: { newValue in
                self.store.updateConfigValue(path: path, value: newValue)
            })
    }

    private func numberBinding(
        _ path: ConfigPath,
        isInteger: Bool,
        defaultValue: Double?) -> Binding<String>
    {
        Binding(
            get: {
                if let value = store.configValue(at: path) { return String(describing: value) }
                guard let defaultValue else { return "" }
                return isInteger ? String(Int(defaultValue)) : String(defaultValue)
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    self.store.updateConfigValue(path: path, value: nil)
                } else if let value = Double(trimmed) {
                    self.store.updateConfigValue(path: path, value: isInteger ? Int(value) : value)
                }
            })
    }

    private func enumBinding(
        _ path: ConfigPath,
        options: [Any],
        defaultValue: Any?) -> Binding<Int>
    {
        Binding(
            get: {
                let value = self.store.configValue(at: path) ?? defaultValue
                guard let value else { return -1 }
                return options.firstIndex { option in
                    String(describing: option) == String(describing: value)
                } ?? -1
            },
            set: { index in
                guard index >= 0, index < options.count else {
                    self.store.updateConfigValue(path: path, value: nil)
                    return
                }
                self.store.updateConfigValue(path: path, value: options[index])
            })
    }

    private func mapKeyBinding(path: ConfigPath, key: String) -> Binding<String> {
        Binding(
            get: { key },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                guard trimmed != key else { return }
                let current = self.store.configValue(at: path) as? [String: Any] ?? [:]
                guard current[trimmed] == nil else { return }
                var next = current
                next[trimmed] = current[key]
                next.removeValue(forKey: key)
                self.store.updateConfigValue(path: path, value: next)
            })
    }
}

struct ChannelConfigForm: View {
    @Bindable var store: ChannelsStore
    let channelId: String

    var body: some View {
        if self.store.configSchemaLoading {
            ProgressView().controlSize(.small)
        } else if manualChannelFields(for: self.channelId).isEmpty == false {
            ManualChannelConfigForm(store: self.store, channelId: self.channelId)
        } else if let schema = store.channelConfigSchema(for: channelId) {
            ConfigSchemaForm(store: self.store, schema: schema, path: [.key("channels"), .key(self.channelId)])
        } else {
            Text("当前渠道没有可用的配置结构。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ManualChannelOption {
    let label: String
    let value: String
}

private enum ManualChannelFieldKind {
    case text
    case secret
    case number
    case multiline
    case toggle
    case select([ManualChannelOption])
}

private struct ManualChannelField {
    let path: [String]
    let label: String
    let kind: ManualChannelFieldKind
    let placeholder: String
    let help: String?
}

private struct ManualChannelConfigForm: View {
    @Bindable var store: ChannelsStore
    let channelId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("这里只保留最少必填项。你填完后，Haoclaw 会自动补全其余默认配置并立即验证。")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(manualChannelFields(for: self.channelId).enumerated()), id: \.offset) { _, field in
                self.row(for: field)
            }
        }
    }

    @ViewBuilder
    private func row(for field: ManualChannelField) -> some View {
        switch field.kind {
        case .toggle:
            Toggle(isOn: self.boolBinding(field)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.localized(field.label))
                    if let help = field.help {
                        Text(self.localized(help))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        case let .select(options):
            VStack(alignment: .leading, spacing: 6) {
                Text(self.localized(field.label)).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(self.localized(help))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Picker("", selection: self.selectBinding(field)) {
                    Text("请选择").tag("")
                    ForEach(options, id: \.value) { option in
                        Text(self.localized(option.label)).tag(option.value)
                    }
                }
                .pickerStyle(.menu)
            }
        case .multiline:
            VStack(alignment: .leading, spacing: 6) {
                Text(self.localized(field.label)).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(self.localized(help))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                TextEditor(text: self.multilineBinding(field))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 92)
                    .padding(8)
                    .background(Color.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        case .number:
            VStack(alignment: .leading, spacing: 6) {
                Text(self.localized(field.label)).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(self.localized(help))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                TextField(self.localized(field.placeholder), text: self.numberBinding(field))
                    .textFieldStyle(.roundedBorder)
            }
        case .secret:
            VStack(alignment: .leading, spacing: 6) {
                Text(self.localized(field.label)).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(self.localized(help))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                SecureField(self.localized(field.placeholder), text: self.textBinding(field))
                    .textFieldStyle(.roundedBorder)
            }
        case .text:
            VStack(alignment: .leading, spacing: 6) {
                Text(self.localized(field.label)).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(self.localized(help))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                TextField(self.localized(field.placeholder), text: self.textBinding(field))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func localized(_ raw: String?) -> String {
        guard let raw else { return "" }
        var text = raw
        let replacements: [(String, String)] = [
            ("Bot Token", "机器人 Token"),
            ("App Token", "应用 Token"),
            ("User Token", "用户 Token"),
            ("Webhook Secret", "Webhook 密钥"),
            ("Webhook URL", "Webhook 地址"),
            ("Signing Secret", "签名密钥"),
            ("Channel Access Token", "频道访问 Token"),
            ("Channel Secret", "频道密钥"),
            ("Client ID", "客户端 ID"),
            ("Client Secret", "客户端密钥"),
            ("Refresh Token", "刷新 Token"),
            ("OAuth Token", "OAuth Token"),
            ("user id", "用户 ID"),
            ("Slack user id", "Slack 用户 ID"),
            ("Discord user id", "Discord 用户 ID"),
            ("LINE user id", "LINE 用户 ID"),
            ("Mattermost 用户名或 ID", "Mattermost 用户名或 ID"),
            ("/path/to/token.txt", "/路径/到/token.txt"),
            ("/path/to/service-account.json", "/路径/到/service-account.json"),
        ]
        for (source, target) in replacements {
            text = text.replacingOccurrences(of: source, with: target)
        }
        return text
    }

    private func fullPath(for field: ManualChannelField) -> ConfigPath {
        [.key("channels"), .key(self.channelId)] + field.path.map { .key($0) }
    }

    private func rawValue(_ field: ManualChannelField) -> Any? {
        self.store.configValue(at: self.fullPath(for: field))
    }

    private func textBinding(_ field: ManualChannelField) -> Binding<String> {
        Binding(
            get: { self.scalarText(for: field) },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                self.store.updateConfigValue(path: self.fullPath(for: field), value: trimmed.isEmpty ? nil : trimmed)
            })
    }

    private func numberBinding(_ field: ManualChannelField) -> Binding<String> {
        Binding(
            get: {
                if let number = self.rawValue(field) as? NSNumber {
                    return number.stringValue
                }
                return self.scalarText(for: field)
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    self.store.updateConfigValue(path: self.fullPath(for: field), value: nil)
                    return
                }
                if let value = Int(trimmed) {
                    self.store.updateConfigValue(path: self.fullPath(for: field), value: value)
                }
            })
    }

    private func boolBinding(_ field: ManualChannelField) -> Binding<Bool> {
        Binding(
            get: { (self.rawValue(field) as? Bool) ?? false },
            set: { newValue in
                self.store.updateConfigValue(path: self.fullPath(for: field), value: newValue)
            })
    }

    private func selectBinding(_ field: ManualChannelField) -> Binding<String> {
        Binding(
            get: { self.scalarText(for: field) },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                self.store.updateConfigValue(path: self.fullPath(for: field), value: trimmed.isEmpty ? nil : trimmed)
            })
    }

    private func multilineBinding(_ field: ManualChannelField) -> Binding<String> {
        Binding(
            get: { self.multilineText(for: field) },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    self.store.updateConfigValue(path: self.fullPath(for: field), value: nil)
                    return
                }
                if field.path.last == "serviceAccount" {
                    if let data = trimmed.data(using: .utf8),
                       let object = try? JSONSerialization.jsonObject(with: data)
                    {
                        self.store.updateConfigValue(path: self.fullPath(for: field), value: object)
                    } else {
                        self.store.updateConfigValue(path: self.fullPath(for: field), value: trimmed)
                    }
                    return
                }
                let items = trimmed
                    .components(separatedBy: CharacterSet.newlines.union(CharacterSet(charactersIn: ",")))
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                self.store.updateConfigValue(path: self.fullPath(for: field), value: items.isEmpty ? nil : items)
            })
    }

    private func scalarText(for field: ManualChannelField) -> String {
        let raw = self.rawValue(field)
        if let string = raw as? String { return string }
        if let number = raw as? NSNumber { return number.stringValue }
        return ""
    }

    private func multilineText(for field: ManualChannelField) -> String {
        let raw = self.rawValue(field)
        if let items = raw as? [String] {
            return items.joined(separator: "\n")
        }
        if let string = raw as? String {
            return string
        }
        if let object = raw,
           JSONSerialization.isValidJSONObject(object),
           let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
           let string = String(data: data, encoding: .utf8)
        {
            return string
        }
        return ""
    }
}

private func commonPolicyOptions(includeDisabled: Bool = true) -> [ManualChannelOption] {
    var options = [
        ManualChannelOption(label: "开放", value: "open"),
        ManualChannelOption(label: "配对", value: "pairing"),
        ManualChannelOption(label: "白名单", value: "allowlist"),
    ]
    if includeDisabled {
        options.append(ManualChannelOption(label: "禁用", value: "disabled"))
    }
    return options
}

private func commonGroupPolicyOptions() -> [ManualChannelOption] {
    [
        ManualChannelOption(label: "开放", value: "open"),
        ManualChannelOption(label: "白名单", value: "allowlist"),
        ManualChannelOption(label: "禁用", value: "disabled"),
    ]
}

private func manualChannelFields(for channelId: String) -> [ManualChannelField] {
    minimalManualChannelFields(for: channelId)
}

private func minimalManualChannelFields(for channelId: String) -> [ManualChannelField] {
    switch channelId {
    case "feishu":
        return [
            .init(path: ["appId"], label: "应用 App ID", kind: .text, placeholder: "cli_xxx", help: "填入飞书应用的 App ID。"),
            .init(path: ["appSecret"], label: "应用 App Secret", kind: .secret, placeholder: "", help: "填入飞书应用的 App Secret。"),
        ]
    case "telegram":
        return [
            .init(path: ["botToken"], label: "机器人 Token", kind: .secret, placeholder: "123456:ABC...", help: "只填这个就可以，其他 Telegram 默认项会由后台自动补齐。"),
        ]
    case "slack":
        return [
            .init(path: ["botToken"], label: "机器人 Token", kind: .secret, placeholder: "xoxb-...", help: "必填。"),
            .init(path: ["appToken"], label: "应用 Token", kind: .secret, placeholder: "xapp-...", help: "如果你走 Socket 模式，填这个即可自动识别。"),
            .init(path: ["signingSecret"], label: "签名密钥", kind: .secret, placeholder: "", help: "如果你走 HTTP 模式，填这个即可自动识别。"),
        ]
    case "discord":
        return [
            .init(path: ["token"], label: "机器人 Token", kind: .secret, placeholder: "", help: "只填这个就够了。"),
        ]
    case "googlechat":
        return [
            .init(path: ["serviceAccount"], label: "服务账号 JSON", kind: .multiline, placeholder: "{ ... }", help: "可以直接粘贴 JSON。"),
            .init(path: ["serviceAccountFile"], label: "服务账号文件", kind: .text, placeholder: "/路径/到/service-account.json", help: "如果你不想直接粘贴 JSON，可以填文件路径。"),
            .init(path: ["webhookUrl"], label: "Webhook 地址", kind: .text, placeholder: "https://...", help: "如果你走 webhook 模式，只填这个也可以。"),
        ]
    case "signal":
        return [
            .init(path: ["baseUrl"], label: "Signal 服务地址", kind: .text, placeholder: "http://127.0.0.1:8080", help: "填入服务地址即可。"),
        ]
    case "imessage":
        return [
            .init(path: ["cliPath"], label: "命令行路径", kind: .text, placeholder: "imessage / bluebubbles-cli", help: "本机模式优先填这个。"),
            .init(path: ["remoteHost"], label: "远程主机", kind: .text, placeholder: "user@remote-mac", help: "如果走远程 Mac，可直接填这里。"),
        ]
    case "whatsapp":
        return []
    case "line":
        return [
            .init(path: ["channelAccessToken"], label: "频道访问 Token", kind: .secret, placeholder: "", help: "必填。"),
            .init(path: ["channelSecret"], label: "频道密钥", kind: .secret, placeholder: "", help: "必填。"),
        ]
    case "twitch":
        return [
            .init(path: ["username"], label: "机器人用户名", kind: .text, placeholder: "your_bot_name", help: "必填。"),
            .init(path: ["accessToken"], label: "OAuth Token", kind: .secret, placeholder: "oauth:...", help: "必填。"),
        ]
    case "nostr":
        return [
            .init(path: ["relays"], label: "Relay 列表", kind: .multiline, placeholder: "wss://...", help: "每行一个 relay 地址。"),
            .init(path: ["privateKey"], label: "私钥", kind: .secret, placeholder: "", help: "必填。"),
        ]
    case "mattermost":
        return [
            .init(path: ["baseUrl"], label: "服务地址", kind: .text, placeholder: "https://chat.example.com", help: "必填。"),
            .init(path: ["botToken"], label: "机器人 Token", kind: .secret, placeholder: "mm-token", help: "必填。"),
        ]
    default:
        return []
    }
}

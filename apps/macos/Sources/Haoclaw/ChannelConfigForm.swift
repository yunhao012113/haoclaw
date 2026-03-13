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
                            Text("Select…").tag(-1)
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
                    if let label { Text(label) } else { Text("Enabled") }
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
                    Text("Unsupported field type.")
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
                    Text("Select…").tag(-1)
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
                    Button("Remove") {
                        var next = items
                        next.remove(at: index)
                        self.store.updateConfigValue(path: path, value: next)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            Button("Add") {
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
                Text("Extra entries")
                    .font(.callout.weight(.semibold))
                if extras.isEmpty {
                    Text("No extra entries yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(extras, id: \ .self) { key in
                        let itemPath: ConfigPath = path + [.key(key)]
                        HStack(alignment: .top, spacing: 8) {
                            TextField("Key", text: self.mapKeyBinding(path: path, key: key))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 160)
                            self.renderNode(additionalSchema, path: itemPath)
                            Button("Remove") {
                                var next = dict
                                next.removeValue(forKey: key)
                                self.store.updateConfigValue(path: path, value: next)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                Button("Add") {
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
            Text("当前使用渠道专用配置表单。即使后端 schema 没返回，也可以直接填写 Token、Secret、Webhook 和权限策略。")
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
                    Text(field.label)
                    if let help = field.help {
                        Text(help)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        case let .select(options):
            VStack(alignment: .leading, spacing: 6) {
                Text(field.label).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(help)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Picker("", selection: self.selectBinding(field)) {
                    Text("请选择").tag("")
                    ForEach(options, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .pickerStyle(.menu)
            }
        case .multiline:
            VStack(alignment: .leading, spacing: 6) {
                Text(field.label).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(help)
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
                Text(field.label).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(help)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                TextField(field.placeholder, text: self.numberBinding(field))
                    .textFieldStyle(.roundedBorder)
            }
        case .secret:
            VStack(alignment: .leading, spacing: 6) {
                Text(field.label).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(help)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                SecureField(field.placeholder, text: self.textBinding(field))
                    .textFieldStyle(.roundedBorder)
            }
        case .text:
            VStack(alignment: .leading, spacing: 6) {
                Text(field.label).font(.callout.weight(.semibold))
                if let help = field.help {
                    Text(help)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                TextField(field.placeholder, text: self.textBinding(field))
                    .textFieldStyle(.roundedBorder)
            }
        }
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
    switch channelId {
    case "feishu":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["appId"], label: "应用 App ID", kind: .text, placeholder: "cli_xxx", help: nil),
            .init(path: ["appSecret"], label: "应用 App Secret", kind: .secret, placeholder: "", help: nil),
            .init(path: ["encryptKey"], label: "加密 Key", kind: .secret, placeholder: "", help: nil),
            .init(path: ["verificationToken"], label: "校验 Token", kind: .secret, placeholder: "", help: nil),
            .init(path: ["connectionMode"], label: "接入方式", kind: .select([
                .init(label: "WebSocket", value: "websocket"),
                .init(label: "Webhook", value: "webhook"),
            ]), placeholder: "", help: nil),
            .init(path: ["domain"], label: "服务域", kind: .select([
                .init(label: "飞书", value: "feishu"),
                .init(label: "Lark", value: "lark"),
            ]), placeholder: "", help: nil),
            .init(path: ["webhookPath"], label: "Webhook 路径", kind: .text, placeholder: "/webhook/feishu", help: nil),
            .init(path: ["webhookHost"], label: "Webhook 主机", kind: .text, placeholder: "0.0.0.0", help: nil),
            .init(path: ["webhookPort"], label: "Webhook 端口", kind: .number, placeholder: "18789", help: nil),
            .init(path: ["allowFrom"], label: "允许用户", kind: .multiline, placeholder: "", help: "每行一个 open_id 或 user_id"),
            .init(path: ["dmPolicy"], label: "私聊策略", kind: .select(commonPolicyOptions(includeDisabled: false)), placeholder: "", help: nil),
            .init(path: ["groupAllowFrom"], label: "允许群组", kind: .multiline, placeholder: "", help: "每行一个 chat_id"),
            .init(path: ["groupPolicy"], label: "群组策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["requireMention"], label: "群聊必须 @", kind: .toggle, placeholder: "", help: nil),
        ]
    case "telegram":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["botToken"], label: "Bot Token", kind: .secret, placeholder: "123456:ABC...", help: nil),
            .init(path: ["tokenFile"], label: "Token 文件", kind: .text, placeholder: "/path/to/token.txt", help: nil),
            .init(path: ["webhookUrl"], label: "Webhook 公网地址", kind: .text, placeholder: "https://example.com/telegram", help: nil),
            .init(path: ["webhookPath"], label: "Webhook 路径", kind: .text, placeholder: "/webhook/telegram", help: nil),
            .init(path: ["webhookSecret"], label: "Webhook Secret", kind: .secret, placeholder: "", help: nil),
            .init(path: ["proxy"], label: "代理地址", kind: .text, placeholder: "socks5://127.0.0.1:7890", help: nil),
            .init(path: ["allowFrom"], label: "允许用户", kind: .multiline, placeholder: "", help: "每行一个 tg:userId"),
            .init(path: ["groupAllowFrom"], label: "允许群组发送者", kind: .multiline, placeholder: "", help: "每行一个 tg:userId"),
            .init(path: ["dmPolicy"], label: "私聊策略", kind: .select(commonPolicyOptions(includeDisabled: false)), placeholder: "", help: nil),
            .init(path: ["groupPolicy"], label: "群组策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["streamMode"], label: "流式模式", kind: .select([
                .init(label: "关闭", value: "off"),
                .init(label: "草稿流", value: "partial"),
                .init(label: "块流", value: "block"),
            ]), placeholder: "", help: nil),
            .init(path: ["replyToMode"], label: "回复模式", kind: .select([
                .init(label: "关闭", value: "off"),
                .init(label: "首条回复", value: "first"),
                .init(label: "全部回复", value: "all"),
            ]), placeholder: "", help: nil),
            .init(path: ["requireMention"], label: "群聊必须 @", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["defaultTo"], label: "默认发送目标", kind: .text, placeholder: "user:12345678 / group:-100...", help: nil),
        ]
    case "slack":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["mode"], label: "接入模式", kind: .select([
                .init(label: "Socket 模式", value: "socket"),
                .init(label: "HTTP 模式", value: "http"),
            ]), placeholder: "", help: nil),
            .init(path: ["botToken"], label: "Bot Token", kind: .secret, placeholder: "xoxb-...", help: nil),
            .init(path: ["appToken"], label: "App Token", kind: .secret, placeholder: "xapp-...", help: nil),
            .init(path: ["userToken"], label: "User Token", kind: .secret, placeholder: "xoxp-...", help: nil),
            .init(path: ["signingSecret"], label: "Signing Secret", kind: .secret, placeholder: "", help: nil),
            .init(path: ["webhookPath"], label: "Webhook 路径", kind: .text, placeholder: "/webhook/slack", help: nil),
            .init(path: ["allowFrom"], label: "允许用户", kind: .multiline, placeholder: "", help: "每行一个 Slack user id"),
            .init(path: ["dmPolicy"], label: "私聊策略", kind: .select(commonPolicyOptions(includeDisabled: false)), placeholder: "", help: nil),
            .init(path: ["groupPolicy"], label: "频道策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["requireMention"], label: "频道必须 @", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["defaultTo"], label: "默认发送目标", kind: .text, placeholder: "C12345678 / U12345678", help: nil),
            .init(path: ["replyToMode"], label: "回复模式", kind: .select([
                .init(label: "主频道", value: "off"),
                .init(label: "线程回复", value: "thread"),
            ]), placeholder: "", help: nil),
        ]
    case "discord":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["token"], label: "Bot Token", kind: .secret, placeholder: "", help: nil),
            .init(path: ["defaultTo"], label: "默认发送目标", kind: .text, placeholder: "channel:123 / user:456", help: nil),
            .init(path: ["dm", "allowFrom"], label: "允许私聊用户", kind: .multiline, placeholder: "", help: "每行一个 Discord user id"),
            .init(path: ["dm", "policy"], label: "私聊策略", kind: .select(commonPolicyOptions(includeDisabled: false)), placeholder: "", help: nil),
            .init(path: ["groupPolicy"], label: "频道策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["replyToMode"], label: "回复模式", kind: .select([
                .init(label: "关闭", value: "off"),
                .init(label: "回复原消息", value: "reply"),
                .init(label: "线程优先", value: "thread"),
            ]), placeholder: "", help: nil),
        ]
    case "googlechat":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["serviceAccount"], label: "服务账号 JSON", kind: .multiline, placeholder: "{ ... }", help: "可直接粘贴 JSON 内容"),
            .init(path: ["serviceAccountFile"], label: "服务账号文件", kind: .text, placeholder: "/path/to/service-account.json", help: nil),
            .init(path: ["webhookPath"], label: "Webhook 路径", kind: .text, placeholder: "/webhook/googlechat", help: nil),
            .init(path: ["webhookUrl"], label: "Webhook URL", kind: .text, placeholder: "https://...", help: nil),
            .init(path: ["botUser"], label: "Bot 用户", kind: .text, placeholder: "users/123456789", help: nil),
            .init(path: ["audienceType"], label: "Audience 类型", kind: .text, placeholder: "chat-app / service-account", help: nil),
            .init(path: ["audience"], label: "Audience 值", kind: .text, placeholder: "https://chat.googleapis.com/", help: nil),
            .init(path: ["dm", "allowFrom"], label: "允许私聊用户", kind: .multiline, placeholder: "", help: "每行一个 users/xxx"),
            .init(path: ["dm", "policy"], label: "私聊策略", kind: .select(commonPolicyOptions(includeDisabled: false)), placeholder: "", help: nil),
            .init(path: ["groupPolicy"], label: "空间策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["defaultTo"], label: "默认发送目标", kind: .text, placeholder: "spaces/AAAA...", help: nil),
        ]
    case "signal":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["baseUrl"], label: "Signal 服务地址", kind: .text, placeholder: "http://127.0.0.1:8080", help: nil),
            .init(path: ["cliPath"], label: "signal-cli 路径", kind: .text, placeholder: "/usr/local/bin/signal-cli", help: nil),
            .init(path: ["allowFrom"], label: "允许用户", kind: .multiline, placeholder: "", help: "每行一个号码或用户标识"),
            .init(path: ["dmPolicy"], label: "私聊策略", kind: .select(commonPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["groupPolicy"], label: "群组策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["defaultTo"], label: "默认发送目标", kind: .text, placeholder: "+86138...", help: nil),
        ]
    case "imessage":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["cliPath"], label: "命令行路径", kind: .text, placeholder: "imessage / bluebubbles-cli", help: nil),
            .init(path: ["dbPath"], label: "数据库路径", kind: .text, placeholder: "~/Library/Messages/chat.db", help: nil),
            .init(path: ["remoteHost"], label: "远程主机", kind: .text, placeholder: "user@remote-mac", help: nil),
            .init(path: ["service"], label: "发送服务", kind: .select([
                .init(label: "自动", value: "auto"),
                .init(label: "iMessage", value: "imessage"),
                .init(label: "短信", value: "sms"),
            ]), placeholder: "", help: nil),
            .init(path: ["region"], label: "短信区域", kind: .text, placeholder: "CN / US", help: nil),
            .init(path: ["allowFrom"], label: "允许联系人", kind: .multiline, placeholder: "", help: "每行一个手机号或邮箱"),
            .init(path: ["groupAllowFrom"], label: "允许群组发送者", kind: .multiline, placeholder: "", help: "每行一个手机号或邮箱"),
            .init(path: ["dmPolicy"], label: "私聊策略", kind: .select(commonPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["groupPolicy"], label: "群组策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["defaultTo"], label: "默认发送目标", kind: .text, placeholder: "+86138... / someone@example.com", help: nil),
        ]
    case "whatsapp":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["defaultTo"], label: "默认发送目标", kind: .text, placeholder: "+86138...", help: nil),
            .init(path: ["allowFrom"], label: "允许联系人", kind: .multiline, placeholder: "", help: "每行一个号码或 jid"),
            .init(path: ["dmPolicy"], label: "私聊策略", kind: .select(commonPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["groupPolicy"], label: "群组策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
        ]
    case "line":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["channelAccessToken"], label: "Channel Access Token", kind: .secret, placeholder: "", help: nil),
            .init(path: ["channelSecret"], label: "Channel Secret", kind: .secret, placeholder: "", help: nil),
            .init(path: ["webhookPath"], label: "Webhook 路径", kind: .text, placeholder: "/webhook/line", help: nil),
            .init(path: ["allowFrom"], label: "允许用户", kind: .multiline, placeholder: "", help: "每行一个 LINE user id"),
            .init(path: ["dmPolicy"], label: "私聊策略", kind: .select(commonPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["groupPolicy"], label: "群组策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["groupAllowFrom"], label: "允许群组发送者", kind: .multiline, placeholder: "", help: "每行一个 LINE user id"),
        ]
    case "twitch":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["username"], label: "Bot 用户名", kind: .text, placeholder: "your_bot_name", help: nil),
            .init(path: ["accessToken"], label: "OAuth Token", kind: .secret, placeholder: "oauth:...", help: nil),
            .init(path: ["clientId"], label: "Client ID", kind: .text, placeholder: "", help: nil),
            .init(path: ["clientSecret"], label: "Client Secret", kind: .secret, placeholder: "", help: nil),
            .init(path: ["refreshToken"], label: "Refresh Token", kind: .secret, placeholder: "", help: nil),
            .init(path: ["allowFrom"], label: "允许用户", kind: .multiline, placeholder: "", help: "每行一个 Twitch user id"),
        ]
    case "nostr":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["relays"], label: "Relay 列表", kind: .multiline, placeholder: "wss://...", help: "每行一个 relay 地址"),
            .init(path: ["privateKey"], label: "私钥", kind: .secret, placeholder: "", help: nil),
            .init(path: ["publicKey"], label: "公钥", kind: .text, placeholder: "", help: nil),
            .init(path: ["dmPolicy"], label: "私聊策略", kind: .select(commonPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["allowFrom"], label: "允许用户", kind: .multiline, placeholder: "", help: "每行一个 npub 或 hex 公钥"),
            .init(path: ["defaultTo"], label: "默认发送目标", kind: .text, placeholder: "npub...", help: nil),
        ]
    case "mattermost":
        return [
            .init(path: ["enabled"], label: "启用渠道", kind: .toggle, placeholder: "", help: nil),
            .init(path: ["baseUrl"], label: "服务地址", kind: .text, placeholder: "https://chat.example.com", help: nil),
            .init(path: ["botToken"], label: "Bot Token", kind: .secret, placeholder: "mm-token", help: nil),
            .init(path: ["defaultTo"], label: "默认发送目标", kind: .text, placeholder: "channel-id / @username", help: nil),
            .init(path: ["allowFrom"], label: "允许用户", kind: .multiline, placeholder: "", help: "每行一个 Mattermost 用户名或 ID"),
            .init(path: ["dmPolicy"], label: "私聊策略", kind: .select(commonPolicyOptions()), placeholder: "", help: nil),
            .init(path: ["groupPolicy"], label: "频道策略", kind: .select(commonGroupPolicyOptions()), placeholder: "", help: nil),
        ]
    default:
        return []
    }
}

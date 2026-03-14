import Foundation
import HaoclawProtocol

enum ChannelSetupState: Equatable {
    case incomplete
    case ready
    case verified
    case attention
}

struct ChannelSetupSummary: Equatable {
    let state: ChannelSetupState
    let title: String
    let detail: String
}

extension ChannelsStore {
    func channelNextSteps(for channelId: String) -> [String] {
        switch channelId {
        case "feishu":
            let mode = self.channelDraftText(channelId, path: ["connectionMode"]).lowercased()
            if mode == "webhook" {
                return [
                    "去飞书开放平台事件订阅里回填 Haoclaw 的 webhook 地址和校验 Token。",
                    "保存后点“立即验证”，确认回调和签名校验都通过。",
                ]
            }
            return [
                "优先保持 WebSocket 模式，省掉公网回调配置。",
                "如果验证失败，先检查 App ID / App Secret 是否来自同一个应用。",
            ]
        case "telegram":
            return [
                "先给机器人发一条私信，方便后面直接从 Telegram 控制 Haoclaw。",
                "如果你用 webhook，再确认公网地址已经能被 Telegram 访问。",
            ]
        case "slack":
            let mode = self.channelDraftText(channelId, path: ["mode"]).lowercased()
            return mode == "http"
                ? [
                    "去 Slack App 配置里确认 Signing Secret 和事件订阅地址一致。",
                    "装到工作区后再点“立即验证”，确认 bot token 生效。",
                ]
                : [
                    "去 Slack App 里打开 Socket Mode，并确认 App Token 是 xapp- 开头。",
                    "把应用安装到目标工作区后再验证，才能看到 bot 和团队信息。",
                ]
        case "discord":
            return [
                "去 Discord Developer Portal 打开 Message Content Intent，避免机器人收不到完整文本。",
                "把 bot 邀请进目标服务器后，再从频道里 @Haoclaw 做一次真实消息测试。",
            ]
        case "googlechat":
            return [
                "确认服务账号已经被目标 Space 或 Chat 应用授权。",
                "如果是 webhook 方式，再检查回调地址或 audience 配置是否一致。",
            ]
        case "signal":
            return [
                "先确认 signal-cli 或 signal 服务本身能在本机正常响应。",
                "验证通过后再补默认目标号码，后面发消息会更省事。",
            ]
        case "imessage":
            return [
                "先在这台 Mac 上确认 iMessage / CLI 能正常发送消息。",
                "如果走远程主机，再检查 SSH 登录和消息数据库权限。",
            ]
        case "whatsapp":
            return [
                "保存策略后直接点“显示二维码”，用手机完成配对。",
                "配对成功后给自己发一条 WhatsApp 消息，确认会话已经打通。",
            ]
        case "line":
            return [
                "去 LINE Developers 后台确认 Messaging API 已启用，Webhook 已打开。",
                "把 bot 加为好友后再做一次真实消息测试。",
            ]
        case "mattermost":
            return [
                "确认 Bot Token 对应的 bot 已加入目标 Team / Channel。",
                "如果验证失败，优先检查服务地址是否包含正确的协议和域名。",
            ]
        case "nostr":
            return [
                "至少保留一个稳定 relay，避免偶发连接成功但收不到消息。",
                "先用自己的 npub 做一次自测，再补默认发送目标。",
            ]
        case "twitch":
            return [
                "确认 OAuth Token 仍然有效，并且 bot 用户已经能进入目标频道。",
                "先在测试频道发一条消息，确认入站和出站都正常。",
            ]
        default:
            return [
                "保存后先点“立即验证”，确认网关已经识别这份配置。",
                "再做一条真实消息测试，确认不是只通过了静态校验。",
            ]
        }
    }

    func channelQuickSetupHint(for channelId: String) -> String {
        switch channelId {
        case "feishu":
            let mode = self.channelDraftText(channelId, path: ["connectionMode"]).lowercased()
            return mode == "webhook"
                ? "Webhook 模式下先填 App ID、App Secret 和校验 Token，其他路径默认值会自动补齐。"
                : "先填 App ID 和 App Secret 就能开始验证，默认按 WebSocket 模式接入。"
        case "telegram":
            return "先填 Bot Token 就够了。保存后 Haoclaw 会自动探测 bot 信息和 webhook 状态。"
        case "slack":
            let mode = self.channelDraftText(channelId, path: ["mode"]).lowercased()
            return mode == "http"
                ? "HTTP 模式下填 Bot Token 和 Signing Secret 即可，Webhook 路径会沿用默认值。"
                : "Socket 模式下填 Bot Token 和 App Token 就能验证，最省事。"
        case "discord":
            return "Discord 只需要 Bot Token。保存后会自动验证机器人身份。"
        case "googlechat":
            return "贴入服务账号 JSON 或文件路径即可。保存后会自动检查 Google Chat 凭据是否可用。"
        case "signal":
            return "优先填 Signal 服务地址。保存后会自动探测服务是否在线。"
        case "imessage":
            return "先填 CLI 路径或远程主机，让桌面端先验证本机/远程发送能力。"
        case "whatsapp":
            return "WhatsApp 不需要 API Key。保存策略后直接点二维码配对，用手机完成绑定。"
        case "line":
            return "LINE 先填 Channel Access Token 和 Channel Secret，保存后自动验证 webhook 能力。"
        case "twitch":
            return "Twitch 先填机器人用户名和 OAuth Token，保存后检查接入状态。"
        case "nostr":
            return "Nostr 先填私钥和至少一个 relay 地址，保存后验证连接。"
        case "mattermost":
            return "Mattermost 先填服务地址和 Bot Token，保存后自动探测。"
        default:
            return "先填最少必填项，保存后 Haoclaw 会自动检查当前渠道。"
        }
    }

    func channelRequiredFieldSummary(for channelId: String) -> String {
        switch channelId {
        case "feishu":
            let mode = self.channelDraftText(channelId, path: ["connectionMode"]).lowercased()
            return mode == "webhook" ? "App ID、App Secret、校验 Token" : "App ID、App Secret"
        case "telegram":
            return "Bot Token 或 Token 文件"
        case "slack":
            let mode = self.channelDraftText(channelId, path: ["mode"]).lowercased()
            return mode == "http" ? "Bot Token、Signing Secret" : "Bot Token、App Token"
        case "discord":
            return "Bot Token"
        case "googlechat":
            return "服务账号 JSON、服务账号文件 或 Webhook URL"
        case "signal":
            return "Signal 服务地址 或 signal-cli 路径"
        case "imessage":
            return "CLI 路径 或 远程主机"
        case "whatsapp":
            return "启用策略即可，真正接入靠二维码配对"
        case "line":
            return "Channel Access Token、Channel Secret"
        case "twitch":
            return "Bot 用户名、OAuth Token"
        case "nostr":
            return "Relay 列表、私钥"
        case "mattermost":
            return "服务地址、Bot Token"
        default:
            return "按当前渠道最少必填项填写"
        }
    }

    func channelSetupSummary(for channelId: String) -> ChannelSetupSummary {
        let missing = self.channelMissingRequiredFields(for: channelId)
        if !missing.isEmpty {
            return ChannelSetupSummary(
                state: .incomplete,
                title: "还缺关键配置",
                detail: "请先补充：\(missing.joined(separator: "、"))。")
        }

        guard let status = self.snapshot?.channels[channelId]?.dictionaryValue else {
            return ChannelSetupSummary(
                state: .ready,
                title: "可以开始验证",
                detail: "最少必填已经齐了。点击“保存并验证”后，Haoclaw 会自动检查这个渠道。")
        }

        if channelId == "whatsapp" {
            return self.whatsAppSetupSummary(status: status)
        }

        if let probe = status["probe"]?.dictionaryValue, let ok = probe["ok"]?.boolValue {
            return ok
                ? self.verifiedProbeSummary(channelId: channelId, status: status, probe: probe)
                : self.failedProbeSummary(channelId: channelId, status: status, probe: probe)
        }

        if let lastError = status["lastError"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
           !lastError.isEmpty
        {
            return ChannelSetupSummary(
                state: .attention,
                title: "验证异常",
                detail: self.appendLastChecked("最近错误：\(lastError)", status: status))
        }

        let configured = status["configured"]?.boolValue ?? false
        let running = status["running"]?.boolValue ?? false
        let connected = status["connected"]?.boolValue ?? false
        if connected {
            return ChannelSetupSummary(
                state: .verified,
                title: "已连接",
                detail: self.appendLastChecked("当前渠道已经连通，可以直接使用。", status: status))
        }
        if configured || running {
            return ChannelSetupSummary(
                state: .ready,
                title: "配置已保存",
                detail: self.appendLastChecked("网关已经接收配置，正在等待下一次自动探测。", status: status))
        }

        return ChannelSetupSummary(
            state: .ready,
            title: "可以开始验证",
            detail: "点击“保存并验证”后，Haoclaw 会自动检查当前渠道。")
    }

    private func whatsAppSetupSummary(status: [String: AnyCodable]) -> ChannelSetupSummary {
        if status["connected"]?.boolValue == true {
            let account = status["self"]?.dictionaryValue?["e164"]?.stringValue ??
                status["self"]?.dictionaryValue?["jid"]?.stringValue
            let detail = account?.isEmpty == false
                ? "已配对账号：\(account!)。现在可以直接通过 WhatsApp 控制 Haoclaw。"
                : "二维码配对已完成，现在可以直接通过 WhatsApp 控制 Haoclaw。"
            return ChannelSetupSummary(
                state: .verified,
                title: "已完成配对",
                detail: self.appendLastChecked(detail, status: status))
        }

        if let lastError = status["lastError"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
           !lastError.isEmpty
        {
            return ChannelSetupSummary(
                state: .attention,
                title: "等待重新配对",
                detail: self.appendLastChecked("最近状态：\(lastError)。重新生成二维码后再用手机扫码即可。", status: status))
        }

        let configured = status["configured"]?.boolValue ?? false
        let running = status["running"]?.boolValue ?? false
        if configured || running {
            return ChannelSetupSummary(
                state: .ready,
                title: "等待扫码配对",
                detail: self.appendLastChecked("策略已经保存。点击下方“显示二维码”后，用手机完成配对。", status: status))
        }

        return ChannelSetupSummary(
            state: .ready,
            title: "可以开始配对",
            detail: "保存当前策略后，点“显示二维码”即可开始 WhatsApp 配对。")
    }

    private func verifiedProbeSummary(
        channelId: String,
        status: [String: AnyCodable],
        probe: [String: AnyCodable]) -> ChannelSetupSummary
    {
        var fragments: [String] = ["自动验证通过"]
        fragments.append(contentsOf: self.channelSpecificVerifiedFragments(channelId: channelId, status: status, probe: probe))
        fragments.append(contentsOf: self.genericVerifiedFragments(status: status, probe: probe))
        let permissionAlert = self.channelPermissionAlert(channelId: channelId, probe: probe)
        let state: ChannelSetupState = permissionAlert == nil ? .verified : .attention
        let title = permissionAlert == nil ? "验证通过" : "验证通过，但还需补权限"
        let detailBase = ([fragments.joined(separator: "，")] + (permissionAlert.map { [$0] } ?? []))
            .filter { !$0.isEmpty }
            .joined(separator: "。")
        return ChannelSetupSummary(
            state: state,
            title: title,
            detail: self.appendLastChecked(detailBase, status: status))
    }

    private func failedProbeSummary(
        channelId: String,
        status: [String: AnyCodable],
        probe: [String: AnyCodable]) -> ChannelSetupSummary
    {
        let error = probe["error"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        let statusCode = probe["status"]?.intValue
        let detail: String
        if let error, !error.isEmpty {
            detail = "自动验证失败：\(error)"
        } else if let statusCode {
            detail = "自动验证失败，返回状态码 \(statusCode)。"
        } else {
            detail = "自动验证失败，请检查\(self.channelRequiredFieldSummary(for: channelId))。"
        }
        return ChannelSetupSummary(
            state: .attention,
            title: "验证失败",
            detail: self.appendLastChecked(detail, status: status))
    }

    private func appendLastChecked(_ base: String, status: [String: AnyCodable]) -> String {
        guard let date = self.channelLastCheckedDate(status: status) else { return base }
        return "\(base) 最近检查：\(relativeAge(from: date))。"
    }

    private func channelLastCheckedDate(status: [String: AnyCodable]) -> Date? {
        if let lastProbeAt = status["lastProbeAt"]?.doubleValue {
            return Date(timeIntervalSince1970: lastProbeAt / 1000)
        }
        if let lastEventAt = status["lastEventAt"]?.doubleValue {
            return Date(timeIntervalSince1970: lastEventAt / 1000)
        }
        if let lastMessageAt = status["lastMessageAt"]?.doubleValue {
            return Date(timeIntervalSince1970: lastMessageAt / 1000)
        }
        if let lastConnectedAt = status["lastConnectedAt"]?.doubleValue {
            return Date(timeIntervalSince1970: lastConnectedAt / 1000)
        }
        return nil
    }

    private func channelMissingRequiredFields(for channelId: String) -> [String] {
        func anyText(_ labelsAndPaths: [(String, [[String]])]) -> [String] {
            labelsAndPaths.compactMap { label, paths in
                self.channelHasValue(channelId, paths: paths) ? nil : label
            }
        }

        switch channelId {
        case "feishu":
            let mode = self.channelDraftText(channelId, path: ["connectionMode"]).lowercased()
            if mode == "webhook" {
                return anyText([
                    ("App ID", [["appId"]]),
                    ("App Secret", [["appSecret"]]),
                    ("校验 Token", [["verificationToken"]]),
                ])
            }
            return anyText([
                ("App ID", [["appId"]]),
                ("App Secret", [["appSecret"]]),
            ])
        case "telegram":
            return anyText([
                ("Bot Token 或 Token 文件", [["botToken"], ["tokenFile"]]),
            ])
        case "slack":
            let mode = self.channelDraftText(channelId, path: ["mode"]).lowercased()
            if mode == "http" {
                return anyText([
                    ("Bot Token", [["botToken"]]),
                    ("Signing Secret", [["signingSecret"]]),
                ])
            }
            return anyText([
                ("Bot Token", [["botToken"]]),
                ("App Token", [["appToken"]]),
            ])
        case "discord":
            return anyText([
                ("Bot Token", [["token"]]),
            ])
        case "googlechat":
            return anyText([
                ("服务账号 JSON、服务账号文件 或 Webhook URL", [["serviceAccount"], ["serviceAccountFile"], ["webhookUrl"]]),
            ])
        case "signal":
            return anyText([
                ("Signal 服务地址 或 signal-cli 路径", [["baseUrl"], ["cliPath"]]),
            ])
        case "imessage":
            return anyText([
                ("CLI 路径 或 远程主机", [["cliPath"], ["remoteHost"]]),
            ])
        case "whatsapp":
            return []
        case "line":
            return anyText([
                ("Channel Access Token", [["channelAccessToken"]]),
                ("Channel Secret", [["channelSecret"]]),
            ])
        case "twitch":
            return anyText([
                ("Bot 用户名", [["username"]]),
                ("OAuth Token", [["accessToken"]]),
            ])
        case "nostr":
            return anyText([
                ("Relay 列表", [["relays"]]),
                ("私钥", [["privateKey"]]),
            ])
        case "mattermost":
            return anyText([
                ("服务地址", [["baseUrl"]]),
                ("Bot Token", [["botToken"]]),
            ])
        default:
            return []
        }
    }

    private func channelHasValue(_ channelId: String, paths: [[String]]) -> Bool {
        paths.contains { path in
            let value = self.configValue(at: self.channelPath(channelId, path: path))
            if let string = value as? String {
                return !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if let items = value as? [String] {
                return items.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
            if let array = value as? [Any] {
                return !array.isEmpty
            }
            if let dict = value as? [String: Any] {
                return !dict.isEmpty
            }
            if let number = value as? NSNumber {
                return number.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }
            return value != nil
        }
    }

    private func channelDraftText(_ channelId: String, path: [String]) -> String {
        let value = self.configValue(at: self.channelPath(channelId, path: path))
        if let string = value as? String {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return ""
    }

    private func channelPath(_ channelId: String, path: [String]) -> ConfigPath {
        [.key("channels"), .key(channelId)] + path.map { .key($0) }
    }

    private func genericVerifiedFragments(
        status: [String: AnyCodable],
        probe: [String: AnyCodable]) -> [String]
    {
        var fragments: [String] = []
        if let url = probe["webhook"]?.dictionaryValue?["url"]?.stringValue,
           !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            fragments.append("Webhook 已登记")
        }
        if let version = probe["version"]?.stringValue,
           !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            fragments.append("版本 \(version)")
        }
        if let source = status["credentialSource"]?.stringValue,
           !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            fragments.append("凭据来源 \(source)")
        }
        if let tokenSource = status["tokenSource"]?.stringValue,
           !tokenSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            fragments.append("Token 来源 \(tokenSource)")
        }
        if let elapsed = probe["elapsedMs"]?.doubleValue {
            fragments.append("\(Int(elapsed))ms")
        }
        fragments.append(contentsOf: self.accountStateFragments(status: status))
        return fragments
    }

    private func channelSpecificVerifiedFragments(
        channelId: String,
        status: [String: AnyCodable],
        probe: [String: AnyCodable]) -> [String]
    {
        switch channelId {
        case "telegram":
            var fragments: [String] = []
            if let username = probe["bot"]?.dictionaryValue?["username"]?.stringValue,
               !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                fragments.append("Bot @\(username)")
            }
            if let mode = status["mode"]?.stringValue,
               !mode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                fragments.append("模式 \(mode)")
            }
            return fragments
        case "discord":
            var fragments: [String] = []
            if let username = probe["bot"]?.dictionaryValue?["username"]?.stringValue,
               !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                fragments.append("Bot @\(username)")
            }
            if let appId = probe["application"]?.dictionaryValue?["id"]?.stringValue,
               !appId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                fragments.append("应用 ID \(appId)")
            }
            return fragments
        case "slack":
            var fragments: [String] = []
            if let botName = probe["bot"]?.dictionaryValue?["name"]?.stringValue,
               !botName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                fragments.append("Bot \(botName)")
            }
            if let teamName = probe["team"]?.dictionaryValue?["name"]?.stringValue,
               !teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                fragments.append("工作区 \(teamName)")
            }
            let mode = self.channelDraftText(channelId, path: ["mode"]).lowercased()
            if !mode.isEmpty {
                fragments.append(mode == "http" ? "HTTP 模式" : "Socket 模式")
            }
            return fragments
        case "line":
            var fragments: [String] = []
            if let displayName = probe["bot"]?.dictionaryValue?["displayName"]?.stringValue,
               !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                fragments.append("Bot \(displayName)")
            }
            if let basicId = probe["bot"]?.dictionaryValue?["basicId"]?.stringValue,
               !basicId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                fragments.append("LINE ID \(basicId)")
            }
            return fragments
        case "googlechat":
            var fragments: [String] = []
            if let audienceType = status["audienceType"]?.stringValue,
               !audienceType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                fragments.append("Audience \(audienceType)")
            }
            return fragments
        default:
            return []
        }
    }

    private func channelPermissionAlert(channelId: String, probe: [String: AnyCodable]) -> String? {
        guard channelId == "discord" else { return nil }
        let intents = probe["application"]?.dictionaryValue?["intents"]?.dictionaryValue
        let messageContent = intents?["messageContent"]?.stringValue?.lowercased()
        if messageContent == "disabled" || messageContent == "limited" {
            return "Discord 的 Message Content Intent 还没完全打开，机器人可能收不到完整文本。"
        }
        return nil
    }

    private func accountStateFragments(status: [String: AnyCodable]) -> [String] {
        guard let connected = status["connected"]?.boolValue ?? status["running"]?.boolValue else {
            return []
        }
        return [connected ? "运行中" : "已保存配置"]
    }
}

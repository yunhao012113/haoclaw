import Foundation

enum ChatDisplayLocalizer {
    static func localize(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        var text = trimmed

        let directReplacements: [(String, String)] = [
            ("Gateway health not OK; cannot send", "网关状态异常，暂时无法发送消息。"),
            ("Timed out waiting for a reply; try again or refresh.", "等待回复超时，请重试或刷新。"),
            ("Chat failed", "对话请求失败。"),
            ("chat.abort not supported by this transport", "当前连接方式不支持中止对话。"),
            ("sessions.list not supported by this transport", "当前连接方式不支持会话列表。"),
            ("System (untrusted):", "系统（未验证）："),
            ("System:", "系统："),
            ("Node:", "设备："),
            ("Agent failed before reply:", "助手在回复前失败："),
            ("agentDir:", "助手目录："),
            ("Logs: haoclaw logs --follow", "排查日志：haoclaw logs --follow"),
            ("logs: haoclaw logs --follow", "排查日志：haoclaw logs --follow"),
            ("Auth store:", "认证配置："),
            ("Configure auth for this agent", "请为这个助手配置认证"),
            ("copy auth-profiles.json from the main agentDir", "把主助手目录里的 auth-profiles.json 复制过来"),
            ("mode local", "本地模式"),
            ("reason launch", "原因：启动"),
            ("reason connect", "原因：已连接"),
            ("Off", "关闭"),
            ("Low", "低"),
            ("Medium", "中"),
            ("High", "高"),
            ("Connected", "已连接"),
            ("Connecting…", "连接中…"),
            ("Could not connect to the server.", "无法连接到服务器。"),
        ]

        for (source, target) in directReplacements {
            text = text.replacingOccurrences(of: source, with: target)
        }

        text = self.replace(
            text,
            pattern: #"No API key found for provider "([^"]+)"\."#,
            template: "未找到提供商“$1”的 API Key。")
        text = self.replace(
            text,
            pattern: #"Attachment ([^\n]+) exceeds 5 MB limit"#,
            template: "附件 $1 超过 5 MB 限制。")
        text = self.replace(
            text,
            pattern: #"(?m)^系统：\s+\[([^\]]+)\]\s+"#,
            template: "系统：[$1] ")
        text = self.replace(
            text,
            pattern: #"(?m)^设备：\s+"#,
            template: "设备：")
        text = self.replace(
            text,
            pattern: #"\bapp\s+([0-9][^\s·]*)"#,
            template: "应用 $1")
        text = self.replace(
            text,
            pattern: #"\bor copy auth-profiles\.json from the main agentDir\b"#,
            template: "或把主助手目录里的 auth-profiles.json 复制过来")
        text = self.replace(
            text,
            pattern: #"Auth store:\s*([^\n]+)"#,
            template: "认证配置：$1")
        text = self.replace(
            text,
            pattern: #"agentDir:\s*([^\)\n]+)"#,
            template: "助手目录：$1")
        text = self.replace(
            text,
            pattern: #"Only image attachments are supported right now"#,
            template: "目前只支持图片附件。")
        text = self.replace(
            text,
            pattern: #"401 status code \(no body\)"#,
            template: "401 鉴权失败：当前模型接口拒绝了请求，请检查 API Key、服务商和模型是否匹配。")
        text = self.replace(
            text,
            pattern: #"([45][0-9]{2}) status code \(no body\)"#,
            template: "请求失败：HTTP $1，服务端没有返回更多说明。")

        return text
    }

    private static func replace(_ text: String, pattern: String, template: String) -> String {
        text.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
    }
}

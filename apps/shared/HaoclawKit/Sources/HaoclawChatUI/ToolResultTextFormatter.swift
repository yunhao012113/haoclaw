import Foundation

enum ToolResultTextFormatter {
    static func format(text: String, toolName: String?) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        guard self.looksLikeJSON(trimmed),
              let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data)
        else {
            return trimmed
        }

        let normalizedTool = toolName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return self.renderJSON(json, toolName: normalizedTool)
    }

    private static func looksLikeJSON(_ value: String) -> Bool {
        guard let first = value.first else { return false }
        return first == "{" || first == "["
    }

    private static func renderJSON(_ json: Any, toolName: String?) -> String {
        if let dict = json as? [String: Any] {
            return self.renderDictionary(dict, toolName: toolName)
        }
        if let array = json as? [Any] {
            if array.isEmpty { return "没有结果。" }
            return "共 \(array.count) 项。"
        }
        return ""
    }

    private static func renderDictionary(_ dict: [String: Any], toolName: String?) -> String {
        let status = (dict["status"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let errorText = self.firstString(in: dict, keys: ["error", "reason"])
        let messageText = self.firstString(in: dict, keys: ["message", "result", "detail"])

        if status?.lowercased() == "error" || errorText != nil {
            if let errorText {
                return "错误：\(ChatDisplayLocalizer.localize(self.sanitizeError(errorText)))"
            }
            if let messageText {
                return "错误：\(ChatDisplayLocalizer.localize(self.sanitizeError(messageText)))"
            }
            return "错误"
        }

        if toolName == "nodes", let summary = self.renderNodesSummary(dict) {
            return summary
        }

        if let message = messageText {
            return message
        }

        if let status, !status.isEmpty {
            return "状态：\(status)"
        }

        return ""
    }

    private static func renderNodesSummary(_ dict: [String: Any]) -> String? {
        if let nodes = dict["nodes"] as? [[String: Any]] {
            if nodes.isEmpty { return "未发现设备。" }
            var lines: [String] = []
            lines.append("发现 \(nodes.count) 台设备。")

            for node in nodes.prefix(3) {
                let label = self.firstString(in: node, keys: ["displayName", "name", "nodeId"]) ?? "设备"
                var details: [String] = []

                if let connected = node["connected"] as? Bool {
                    details.append(connected ? "在线" : "离线")
                }
                if let platform = self.firstString(in: node, keys: ["platform"]) {
                    details.append(platform)
                }
                if let version = self.firstString(in: node, keys: ["osVersion", "appVersion", "version"]) {
                    details.append(version)
                }
                if let pairing = self.pairingDetail(node) {
                    details.append(pairing)
                }

                if details.isEmpty {
                    lines.append("• \(label)")
                } else {
                    lines.append("• \(label) - \(details.joined(separator: "，"))")
                }
            }

            let extra = nodes.count - 3
            if extra > 0 {
                lines.append("…… 还有 \(extra) 台")
            }
            return lines.joined(separator: "\n")
        }

        if let pending = dict["pending"] as? [Any], let paired = dict["paired"] as? [Any] {
            return "配对请求：待处理 \(pending.count) 个，已配对 \(paired.count) 个。"
        }

        if let pending = dict["pending"] as? [Any] {
            if pending.isEmpty { return "没有待处理的配对请求。" }
            return "有 \(pending.count) 个待处理配对请求。"
        }

        return nil
    }

    private static func pairingDetail(_ node: [String: Any]) -> String? {
        if let paired = node["paired"] as? Bool, !paired {
            return "需要配对"
        }

        for key in ["status", "state", "deviceStatus"] {
            if let raw = node[key] as? String, raw.lowercased().contains("pairing required") {
                return "需要配对"
            }
        }
        return nil
    }

    private static func firstString(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dict[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }

    private static func sanitizeError(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.contains("agent="),
           cleaned.contains("action="),
           let marker = cleaned.range(of: ": ")
        {
            cleaned = String(cleaned[marker.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let firstLine = cleaned.split(separator: "\n").first {
            cleaned = String(firstLine).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if cleaned.count > 220 {
            cleaned = String(cleaned.prefix(217)) + "..."
        }
        return cleaned
    }
}

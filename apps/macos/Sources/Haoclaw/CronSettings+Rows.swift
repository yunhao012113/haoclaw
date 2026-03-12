import SwiftUI

extension CronSettings {
    func jobRow(_ job: CronJob) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(job.displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                if !job.enabled {
                    StatusPill(text: "已停用", tint: .secondary)
                } else if let next = job.nextRunDate {
                    StatusPill(text: self.nextRunLabel(next), tint: .secondary)
                } else {
                    StatusPill(text: "暂无下次执行", tint: .secondary)
                }
            }
            HStack(spacing: 6) {
                StatusPill(text: job.sessionTarget == .main ? "主会话" : "独立会话", tint: .secondary)
                StatusPill(text: job.wakeMode == .now ? "立即" : "下次心跳", tint: .secondary)
                if let agentId = job.agentId, !agentId.isEmpty {
                    StatusPill(text: "助手 \(agentId)", tint: .secondary)
                }
                if let status = job.state.lastStatus {
                    StatusPill(text: self.localizedRunStatus(status), tint: status == "ok" ? .green : .orange)
                }
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    func jobContextMenu(_ job: CronJob) -> some View {
        Button("立即执行") { Task { await self.store.runJob(id: job.id, force: true) } }
        if job.sessionTarget == .isolated {
            Button("打开记录") {
                WebChatManager.shared.show(sessionKey: "cron:\(job.id)")
            }
        }
        Divider()
        Button(job.enabled ? "停用" : "启用") {
            Task { await self.store.setJobEnabled(id: job.id, enabled: !job.enabled) }
        }
        Button("编辑…") {
            self.editingJob = job
            self.editorError = nil
            self.showEditor = true
        }
        Divider()
        Button("删除…", role: .destructive) {
            self.confirmDelete = job
        }
    }

    func detailHeader(_ job: CronJob) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(job.displayName)
                    .font(.title3.weight(.semibold))
                Text(job.id)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            HStack(spacing: 8) {
                Toggle("启用", isOn: Binding(
                    get: { job.enabled },
                    set: { enabled in Task { await self.store.setJobEnabled(id: job.id, enabled: enabled) } }))
                    .toggleStyle(.switch)
                    .labelsHidden()
                Button("执行") { Task { await self.store.runJob(id: job.id, force: true) } }
                    .buttonStyle(.borderedProminent)
                if job.sessionTarget == .isolated {
                    Button("记录") {
                        WebChatManager.shared.show(sessionKey: "cron:\(job.id)")
                    }
                    .buttonStyle(.bordered)
                }
                Button("编辑") {
                    self.editingJob = job
                    self.editorError = nil
                    self.showEditor = true
                }
                .buttonStyle(.bordered)
            }
        }
    }

    func detailCard(_ job: CronJob) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledContent("计划") { Text(self.scheduleSummary(job.schedule)).font(.callout) }
            if case .at = job.schedule, job.deleteAfterRun == true {
                LabeledContent("自动删除") { Text("成功后删除") }
            }
            if let desc = job.description, !desc.isEmpty {
                LabeledContent("说明") { Text(desc).font(.callout) }
            }
            if let agentId = job.agentId, !agentId.isEmpty {
                LabeledContent("助手") { Text(agentId) }
            }
            LabeledContent("会话") { Text(job.sessionTarget == .main ? "主会话" : "独立会话") }
            LabeledContent("唤醒") { Text(job.wakeMode == .now ? "立即" : "下次心跳") }
            LabeledContent("下次执行") {
                if let date = job.nextRunDate {
                    Text(date.formatted(date: .abbreviated, time: .standard))
                } else {
                    Text("—").foregroundStyle(.secondary)
                }
            }
            LabeledContent("上次执行") {
                if let date = job.lastRunDate {
                    Text("\(date.formatted(date: .abbreviated, time: .standard)) · \(relativeAge(from: date))")
                } else {
                    Text("—").foregroundStyle(.secondary)
                }
            }
            if let status = job.state.lastStatus {
                LabeledContent("上次状态") { Text(self.localizedRunStatus(status)) }
            }
            if let err = job.state.lastError, !err.isEmpty {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .textSelection(.enabled)
            }
            self.payloadSummary(job)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(8)
    }

    func runHistoryCard(_ job: CronJob) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("运行记录")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await self.store.refreshRuns(jobId: job.id) }
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(self.store.isLoadingRuns)
            }

            if self.store.isLoadingRuns {
                ProgressView().controlSize(.small)
            }

            if self.store.runEntries.isEmpty {
                Text("还没有运行记录。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(self.store.runEntries) { entry in
                        self.runRow(entry)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(8)
    }

    func runRow(_ entry: CronRunLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                StatusPill(text: self.localizedRunStatus(entry.status ?? "unknown"), tint: self.statusTint(entry.status))
                Text(entry.date.formatted(date: .abbreviated, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let ms = entry.durationMs {
                    Text("\(ms)ms")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if let summary = entry.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(2)
            }
            if let error = entry.error, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .textSelection(.enabled)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    func payloadSummary(_ job: CronJob) -> some View {
        let payload = job.payload
        return VStack(alignment: .leading, spacing: 6) {
            Text("执行内容")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            switch payload {
            case let .systemEvent(text):
                Text(text)
                    .font(.callout)
                    .textSelection(.enabled)
            case let .agentTurn(message, thinking, timeoutSeconds, _, _, _, _):
                VStack(alignment: .leading, spacing: 4) {
                    Text(message)
                        .font(.callout)
                        .textSelection(.enabled)
                    HStack(spacing: 8) {
                        if let thinking, !thinking.isEmpty { StatusPill(text: "思考 \(thinking)", tint: .secondary) }
                        if let timeoutSeconds { StatusPill(text: "\(timeoutSeconds)s", tint: .secondary) }
                        if job.sessionTarget == .isolated {
                            let delivery = job.delivery
                            if let delivery {
                                if delivery.mode == .announce {
                                    StatusPill(text: "发送摘要", tint: .secondary)
                                    if let channel = delivery.channel, !channel.isEmpty {
                                        StatusPill(text: channel, tint: .secondary)
                                    }
                                    if let to = delivery.to, !to.isEmpty { StatusPill(text: to, tint: .secondary) }
                                } else {
                                    StatusPill(text: "不发送", tint: .secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func localizedRunStatus(_ status: String) -> String {
        switch status.lowercased() {
        case "ok":
            "成功"
        case "error":
            "失败"
        case "running":
            "运行中"
        case "queued":
            "排队中"
        case "disabled":
            "已停用"
        case "skipped":
            "已跳过"
        case "unknown":
            "未知"
        default:
            status
        }
    }
}

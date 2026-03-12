import Observation
import HaoclawProtocol
import SwiftUI

struct CronJobEditor: View {
    let job: CronJob?
    @Binding var isSaving: Bool
    @Binding var error: String?
    @Bindable var channelsStore: ChannelsStore
    let onCancel: () -> Void
    let onSave: ([String: AnyCodable]) -> Void

    let labelColumnWidth: CGFloat = 160
    static let introText =
        "创建一个通过网关唤醒 Haoclaw 的自动任务。"
            + "如果希望和主对话分开执行，建议使用独立会话。"
    static let sessionTargetNote =
        "主会话任务会把系统事件写入当前主对话。"
            + "独立会话任务会在单独会话中运行，并可把结果通知到指定渠道。"
    static let scheduleKindNote =
        "“单次”只运行一次，“间隔”按时长重复，“表达式”使用 5 位定时表达式。"
    static let isolatedPayloadNote =
        "独立会话任务始终执行一次代理回合。通知模式会把摘要发送到指定渠道。"
    static let mainPayloadNote =
        "系统事件会注入当前主会话。若要执行代理回合，请切换到独立会话。"

    @State var name: String = ""
    @State var description: String = ""
    @State var agentId: String = ""
    @State var enabled: Bool = true
    @State var sessionTarget: CronSessionTarget = .main
    @State var wakeMode: CronWakeMode = .now
    @State var deleteAfterRun: Bool = false

    enum ScheduleKind: String, CaseIterable, Identifiable { case at, every, cron; var id: String {
        rawValue
    } }
    @State var scheduleKind: ScheduleKind = .every
    @State var atDate: Date = .init().addingTimeInterval(60 * 5)
    @State var everyText: String = "1h"
    @State var cronExpr: String = "0 9 * * 3"
    @State var cronTz: String = ""

    enum PayloadKind: String, CaseIterable, Identifiable { case systemEvent, agentTurn; var id: String {
        rawValue
    } }
    @State var payloadKind: PayloadKind = .systemEvent
    @State var systemEventText: String = ""
    @State var agentMessage: String = ""
    enum DeliveryChoice: String, CaseIterable, Identifiable { case announce, none; var id: String {
        rawValue
    } }
    @State var deliveryMode: DeliveryChoice = .announce
    @State var channel: String = "last"
    @State var to: String = ""
    @State var thinking: String = ""
    @State var timeoutSeconds: String = ""
    @State var bestEffortDeliver: Bool = false

    var channelOptions: [String] {
        let ordered = self.channelsStore.orderedChannelIds()
        var options = ["last"] + ordered
        let trimmed = self.channel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, !options.contains(trimmed) {
            options.append(trimmed)
        }
        var seen = Set<String>()
        return options.filter { seen.insert($0).inserted }
    }

    func channelLabel(for id: String) -> String {
        if id == "last" { return "最近一次渠道" }
        return self.channelsStore.resolveChannelLabel(id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(self.job == nil ? "新建自动任务" : "编辑自动任务")
                    .font(.title3.weight(.semibold))
                Text(Self.introText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 14) {
                    GroupBox("基础信息") {
                        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 10) {
                            GridRow {
                                self.gridLabel("名称")
                                TextField("必填，例如“每日总结”", text: self.$name)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                            }
                            GridRow {
                                self.gridLabel("说明")
                                TextField("可选备注", text: self.$description)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                            }
                            GridRow {
                                self.gridLabel("助手 ID")
                                TextField("可选，留空则使用默认助手", text: self.$agentId)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                            }
                            GridRow {
                                self.gridLabel("启用")
                                Toggle("", isOn: self.$enabled)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                            }
                            GridRow {
                                self.gridLabel("执行会话")
                                Picker("", selection: self.$sessionTarget) {
                                    Text("主会话").tag(CronSessionTarget.main)
                                    Text("独立会话").tag(CronSessionTarget.isolated)
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            GridRow {
                                self.gridLabel("唤醒方式")
                                Picker("", selection: self.$wakeMode) {
                                    Text("立即").tag(CronWakeMode.now)
                                    Text("下次心跳").tag(CronWakeMode.nextHeartbeat)
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            GridRow {
                                Color.clear
                                    .frame(width: self.labelColumnWidth, height: 1)
                                Text(
                                    Self.sessionTargetNote)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    GroupBox("执行计划") {
                        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 10) {
                            GridRow {
                                self.gridLabel("类型")
                                Picker("", selection: self.$scheduleKind) {
                                    Text("单次").tag(ScheduleKind.at)
                                    Text("间隔").tag(ScheduleKind.every)
                                    Text("表达式").tag(ScheduleKind.cron)
                                }
                                .labelsHidden()
                                .pickerStyle(.segmented)
                                .frame(maxWidth: .infinity)
                            }
                            GridRow {
                                Color.clear
                                    .frame(width: self.labelColumnWidth, height: 1)
                                Text(
                                    Self.scheduleKindNote)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            switch self.scheduleKind {
                            case .at:
                                GridRow {
                                    self.gridLabel("执行时间")
                                    DatePicker(
                                        "",
                                        selection: self.$atDate,
                                        displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                GridRow {
                                    self.gridLabel("自动删除")
                                    Toggle("成功执行后删除", isOn: self.$deleteAfterRun)
                                        .toggleStyle(.switch)
                                }
                            case .every:
                                GridRow {
                                    self.gridLabel("间隔")
                                    TextField("例如 10m、1h、1d", text: self.$everyText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: .infinity)
                                }
                            case .cron:
                                GridRow {
                                    self.gridLabel("表达式")
                                    TextField("例如 0 9 * * 3", text: self.$cronExpr)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: .infinity)
                                }
                                GridRow {
                                    self.gridLabel("时区")
                                    TextField("可选，例如 Asia/Shanghai", text: self.$cronTz)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }

                    GroupBox("执行内容") {
                        VStack(alignment: .leading, spacing: 10) {
                            if self.sessionTarget == .isolated {
                                Text(Self.isolatedPayloadNote)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                self.agentTurnEditor
                            } else {
                                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 10) {
                                    GridRow {
                                        self.gridLabel("内容类型")
                                        Picker("", selection: self.$payloadKind) {
                                            Text("系统事件").tag(PayloadKind.systemEvent)
                                            Text("代理回合").tag(PayloadKind.agentTurn)
                                        }
                                        .labelsHidden()
                                        .pickerStyle(.segmented)
                                        .frame(maxWidth: .infinity)
                                    }
                                    GridRow {
                                        Color.clear
                                            .frame(width: self.labelColumnWidth, height: 1)
                                        Text(
                                            Self.mainPayloadNote)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }

                                switch self.payloadKind {
                                case .systemEvent:
                                    TextField("系统事件内容", text: self.$systemEventText, axis: .vertical)
                                        .textFieldStyle(.roundedBorder)
                                        .lineLimit(3...7)
                                        .frame(maxWidth: .infinity)
                                case .agentTurn:
                                    self.agentTurnEditor
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
            }

            if let error, !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Button("取消") { self.onCancel() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.bordered)
                Spacer()
                Button {
                    self.save()
                } label: {
                    if self.isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("保存")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(self.isSaving)
            }
        }
        .padding(24)
        .frame(minWidth: 720, minHeight: 640)
        .onAppear { self.hydrateFromJob() }
        .onChange(of: self.payloadKind) { _, newValue in
            if newValue == .agentTurn, self.sessionTarget == .main {
                self.sessionTarget = .isolated
            }
        }
        .onChange(of: self.sessionTarget) { _, newValue in
            if newValue == .isolated {
                self.payloadKind = .agentTurn
            } else if newValue == .main, self.payloadKind == .agentTurn {
                self.payloadKind = .systemEvent
            }
        }
    }

    var agentTurnEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 10) {
                GridRow {
                    self.gridLabel("任务内容")
                    TextField("请输入要让 Haoclaw 执行的任务", text: self.$agentMessage, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...7)
                        .frame(maxWidth: .infinity)
                }
                GridRow {
                    self.gridLabel("思考强度")
                    TextField("可选，例如 low", text: self.$thinking)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                }
                GridRow {
                    self.gridLabel("超时")
                    TextField("秒数，可选", text: self.$timeoutSeconds)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180, alignment: .leading)
                }
                GridRow {
                    self.gridLabel("结果投递")
                    Picker("", selection: self.$deliveryMode) {
                        Text("发送摘要").tag(DeliveryChoice.announce)
                        Text("不发送").tag(DeliveryChoice.none)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
            }

            if self.deliveryMode == .announce {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 10) {
                    GridRow {
                        self.gridLabel("频道")
                        Picker("", selection: self.$channel) {
                            ForEach(self.channelOptions, id: \.self) { channel in
                                Text(self.channelLabel(for: channel)).tag(channel)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    GridRow {
                        self.gridLabel("收件人")
                        TextField("可选覆盖，例如手机号、聊天 ID 或频道 ID", text: self.$to)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                    }
                    GridRow {
                        self.gridLabel("容错发送")
                        Toggle("发送摘要失败时不让任务整体失败", isOn: self.$bestEffortDeliver)
                            .toggleStyle(.switch)
                    }
                }
            }
        }
    }
}

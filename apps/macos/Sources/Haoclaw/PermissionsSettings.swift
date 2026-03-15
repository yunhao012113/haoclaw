import CoreLocation
import HaoclawIPC
import HaoclawKit
import SwiftUI

struct PermissionsSettings: View {
    let status: [Capability: Bool]
    let refresh: () async -> Void
    let showOnboarding: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SystemRunSettingsView()

                Text("建议开启这些权限，方便 Haoclaw 在需要时发送通知、采集信息和执行操作。")
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)

                PermissionStatusList(status: self.status, refresh: self.refresh)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 6)

                LocationAccessSettings()

                Button("重新开始引导") { self.showOnboarding() }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct LocationAccessSettings: View {
    @AppStorage(locationModeKey) private var locationModeRaw: String = HaoclawLocationMode.off.rawValue
    @AppStorage(locationPreciseKey) private var locationPreciseEnabled: Bool = true
    @State private var lastLocationModeRaw: String = HaoclawLocationMode.off.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("位置权限")
                .font(.body)

            Picker("", selection: self.$locationModeRaw) {
                Text("关闭").tag(HaoclawLocationMode.off.rawValue)
                Text("使用时允许").tag(HaoclawLocationMode.whileUsing.rawValue)
                Text("始终允许").tag(HaoclawLocationMode.always.rawValue)
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Toggle("精确位置", isOn: self.$locationPreciseEnabled)
                .disabled(self.locationMode == .off)

            Text("选择“始终允许”后，可能还需要到系统设置里批准后台定位。")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear {
            self.lastLocationModeRaw = self.locationModeRaw
        }
        .onChange(of: self.locationModeRaw) { _, newValue in
            let previous = self.lastLocationModeRaw
            self.lastLocationModeRaw = newValue
            guard let mode = HaoclawLocationMode(rawValue: newValue) else { return }
            Task {
                let granted = await self.requestLocationAuthorization(mode: mode)
                if !granted {
                    await MainActor.run {
                        self.locationModeRaw = previous
                        self.lastLocationModeRaw = previous
                    }
                }
            }
        }
    }

    private var locationMode: HaoclawLocationMode {
        HaoclawLocationMode(rawValue: self.locationModeRaw) ?? .off
    }

    private func requestLocationAuthorization(mode: HaoclawLocationMode) async -> Bool {
        guard mode != .off else { return true }
        guard CLLocationManager.locationServicesEnabled() else {
            await MainActor.run { LocationPermissionHelper.openSettings() }
            return false
        }

        let status = CLLocationManager().authorizationStatus
        let requireAlways = mode == .always
        if PermissionManager.isLocationAuthorized(status: status, requireAlways: requireAlways) {
            return true
        }
        let updated = await LocationPermissionRequester.shared.request(always: requireAlways)
        return PermissionManager.isLocationAuthorized(status: updated, requireAlways: requireAlways)
    }
}

struct PermissionStatusList: View {
    let status: [Capability: Bool]
    let refresh: () async -> Void
    @State private var pendingCapability: Capability?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Capability.allCases, id: \.self) { cap in
                PermissionRow(
                    capability: cap,
                    status: self.status[cap] ?? false,
                    isPending: self.pendingCapability == cap)
                {
                    Task { await self.handle(cap) }
                }
            }
            Button {
                Task { await self.refresh() }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .font(.footnote)
            .padding(.top, 2)
            .help("刷新权限状态")
        }
    }

    @MainActor
    private func handle(_ cap: Capability) async {
        guard self.pendingCapability == nil else { return }
        self.pendingCapability = cap
        defer { self.pendingCapability = nil }

        _ = await PermissionManager.ensure([cap], interactive: true)
        await self.refreshStatusTransitions()
    }

    @MainActor
    private func refreshStatusTransitions() async {
        await self.refresh()

        // TCC and notification settings can settle after the prompt closes or when the app regains focus.
        for delay in [300_000_000, 900_000_000, 1_800_000_000] {
            try? await Task.sleep(nanoseconds: UInt64(delay))
            await self.refresh()
        }
    }
}

struct PermissionRow: View {
    let capability: Capability
    let status: Bool
    let isPending: Bool
    let compact: Bool
    let action: () -> Void

    init(
        capability: Capability,
        status: Bool,
        isPending: Bool = false,
        compact: Bool = false,
        action: @escaping () -> Void)
    {
        self.capability = capability
        self.status = status
        self.isPending = isPending
        self.compact = compact
        self.action = action
    }

    var body: some View {
        HStack(spacing: self.compact ? 10 : 12) {
            ZStack {
                Circle().fill(self.status ? Color.green.opacity(0.2) : Color.gray.opacity(0.15))
                    .frame(width: self.iconSize, height: self.iconSize)
                Image(systemName: self.icon)
                    .foregroundStyle(self.status ? Color.green : Color.secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title).font(.body.weight(.semibold))
                Text(self.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            VStack(alignment: .trailing, spacing: 4) {
                if self.status {
                    Label("已授权", systemImage: "checkmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.green)
                        .font(.title3)
                        .help("已授权")
                } else if self.isPending {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 78)
                } else {
                    Button("授权") { self.action() }
                        .buttonStyle(.bordered)
                        .controlSize(self.compact ? .small : .regular)
                        .frame(minWidth: self.compact ? 68 : 78, alignment: .trailing)
                }

                if self.status {
                    Text("已授权")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.green)
                } else if self.isPending {
                    Text("检查中…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("等待授权")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: self.compact ? 86 : 104, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, self.compact ? 4 : 6)
    }

    private var iconSize: CGFloat {
        self.compact ? 28 : 32
    }

    private var title: String {
        switch self.capability {
        case .appleScript: "自动化控制（AppleScript）"
        case .notifications: "通知"
        case .accessibility: "辅助功能"
        case .screenRecording: "屏幕录制"
        case .microphone: "麦克风"
        case .speechRecognition: "语音识别"
        case .camera: "相机"
        case .location: "位置"
        }
    }

    private var subtitle: String {
        switch self.capability {
        case .appleScript:
            "允许 Haoclaw 控制其他应用，例如 Terminal。"
        case .notifications: "允许 Haoclaw 发送桌面通知。"
        case .accessibility: "在需要操作界面元素时允许辅助控制。"
        case .screenRecording: "允许截取屏幕内容，用于上下文理解或截图。"
        case .microphone: "允许语音唤醒和音频采集。"
        case .speechRecognition: "允许在本机识别语音唤醒词。"
        case .camera: "允许调用摄像头拍照或录制短视频。"
        case .location: "在助手需要时提供位置信息。"
        }
    }

    private var icon: String {
        switch self.capability {
        case .appleScript: "applescript"
        case .notifications: "bell"
        case .accessibility: "hand.raised"
        case .screenRecording: "display"
        case .microphone: "mic"
        case .speechRecognition: "waveform"
        case .camera: "camera"
        case .location: "location"
        }
    }
}

#if DEBUG
struct PermissionsSettings_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsSettings(
            status: [
                .appleScript: true,
                .notifications: true,
                .accessibility: false,
                .screenRecording: false,
                .microphone: true,
                .speechRecognition: false,
            ],
            refresh: {},
            showOnboarding: {})
            .frame(width: SettingsTab.windowWidth, height: SettingsTab.windowHeight)
    }
}
#endif

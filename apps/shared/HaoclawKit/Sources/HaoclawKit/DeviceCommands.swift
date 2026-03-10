import Foundation

public enum HaoclawDeviceCommand: String, Codable, Sendable {
    case status = "device.status"
    case info = "device.info"
}

public enum HaoclawBatteryState: String, Codable, Sendable {
    case unknown
    case unplugged
    case charging
    case full
}

public enum HaoclawThermalState: String, Codable, Sendable {
    case nominal
    case fair
    case serious
    case critical
}

public enum HaoclawNetworkPathStatus: String, Codable, Sendable {
    case satisfied
    case unsatisfied
    case requiresConnection
}

public enum HaoclawNetworkInterfaceType: String, Codable, Sendable {
    case wifi
    case cellular
    case wired
    case other
}

public struct HaoclawBatteryStatusPayload: Codable, Sendable, Equatable {
    public var level: Double?
    public var state: HaoclawBatteryState
    public var lowPowerModeEnabled: Bool

    public init(level: Double?, state: HaoclawBatteryState, lowPowerModeEnabled: Bool) {
        self.level = level
        self.state = state
        self.lowPowerModeEnabled = lowPowerModeEnabled
    }
}

public struct HaoclawThermalStatusPayload: Codable, Sendable, Equatable {
    public var state: HaoclawThermalState

    public init(state: HaoclawThermalState) {
        self.state = state
    }
}

public struct HaoclawStorageStatusPayload: Codable, Sendable, Equatable {
    public var totalBytes: Int64
    public var freeBytes: Int64
    public var usedBytes: Int64

    public init(totalBytes: Int64, freeBytes: Int64, usedBytes: Int64) {
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
        self.usedBytes = usedBytes
    }
}

public struct HaoclawNetworkStatusPayload: Codable, Sendable, Equatable {
    public var status: HaoclawNetworkPathStatus
    public var isExpensive: Bool
    public var isConstrained: Bool
    public var interfaces: [HaoclawNetworkInterfaceType]

    public init(
        status: HaoclawNetworkPathStatus,
        isExpensive: Bool,
        isConstrained: Bool,
        interfaces: [HaoclawNetworkInterfaceType])
    {
        self.status = status
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.interfaces = interfaces
    }
}

public struct HaoclawDeviceStatusPayload: Codable, Sendable, Equatable {
    public var battery: HaoclawBatteryStatusPayload
    public var thermal: HaoclawThermalStatusPayload
    public var storage: HaoclawStorageStatusPayload
    public var network: HaoclawNetworkStatusPayload
    public var uptimeSeconds: Double

    public init(
        battery: HaoclawBatteryStatusPayload,
        thermal: HaoclawThermalStatusPayload,
        storage: HaoclawStorageStatusPayload,
        network: HaoclawNetworkStatusPayload,
        uptimeSeconds: Double)
    {
        self.battery = battery
        self.thermal = thermal
        self.storage = storage
        self.network = network
        self.uptimeSeconds = uptimeSeconds
    }
}

public struct HaoclawDeviceInfoPayload: Codable, Sendable, Equatable {
    public var deviceName: String
    public var modelIdentifier: String
    public var systemName: String
    public var systemVersion: String
    public var appVersion: String
    public var appBuild: String
    public var locale: String

    public init(
        deviceName: String,
        modelIdentifier: String,
        systemName: String,
        systemVersion: String,
        appVersion: String,
        appBuild: String,
        locale: String)
    {
        self.deviceName = deviceName
        self.modelIdentifier = modelIdentifier
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.appVersion = appVersion
        self.appBuild = appBuild
        self.locale = locale
    }
}

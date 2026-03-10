import Foundation

public enum HaoclawCameraCommand: String, Codable, Sendable {
    case list = "camera.list"
    case snap = "camera.snap"
    case clip = "camera.clip"
}

public enum HaoclawCameraFacing: String, Codable, Sendable {
    case back
    case front
}

public enum HaoclawCameraImageFormat: String, Codable, Sendable {
    case jpg
    case jpeg
}

public enum HaoclawCameraVideoFormat: String, Codable, Sendable {
    case mp4
}

public struct HaoclawCameraSnapParams: Codable, Sendable, Equatable {
    public var facing: HaoclawCameraFacing?
    public var maxWidth: Int?
    public var quality: Double?
    public var format: HaoclawCameraImageFormat?
    public var deviceId: String?
    public var delayMs: Int?

    public init(
        facing: HaoclawCameraFacing? = nil,
        maxWidth: Int? = nil,
        quality: Double? = nil,
        format: HaoclawCameraImageFormat? = nil,
        deviceId: String? = nil,
        delayMs: Int? = nil)
    {
        self.facing = facing
        self.maxWidth = maxWidth
        self.quality = quality
        self.format = format
        self.deviceId = deviceId
        self.delayMs = delayMs
    }
}

public struct HaoclawCameraClipParams: Codable, Sendable, Equatable {
    public var facing: HaoclawCameraFacing?
    public var durationMs: Int?
    public var includeAudio: Bool?
    public var format: HaoclawCameraVideoFormat?
    public var deviceId: String?

    public init(
        facing: HaoclawCameraFacing? = nil,
        durationMs: Int? = nil,
        includeAudio: Bool? = nil,
        format: HaoclawCameraVideoFormat? = nil,
        deviceId: String? = nil)
    {
        self.facing = facing
        self.durationMs = durationMs
        self.includeAudio = includeAudio
        self.format = format
        self.deviceId = deviceId
    }
}

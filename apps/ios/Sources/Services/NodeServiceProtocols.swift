import CoreLocation
import Foundation
import HaoclawKit
import UIKit

typealias HaoclawCameraSnapResult = (format: String, base64: String, width: Int, height: Int)
typealias HaoclawCameraClipResult = (format: String, base64: String, durationMs: Int, hasAudio: Bool)

protocol CameraServicing: Sendable {
    func listDevices() async -> [CameraController.CameraDeviceInfo]
    func snap(params: HaoclawCameraSnapParams) async throws -> HaoclawCameraSnapResult
    func clip(params: HaoclawCameraClipParams) async throws -> HaoclawCameraClipResult
}

protocol ScreenRecordingServicing: Sendable {
    func record(
        screenIndex: Int?,
        durationMs: Int?,
        fps: Double?,
        includeAudio: Bool?,
        outPath: String?) async throws -> String
}

@MainActor
protocol LocationServicing: Sendable {
    func authorizationStatus() -> CLAuthorizationStatus
    func accuracyAuthorization() -> CLAccuracyAuthorization
    func ensureAuthorization(mode: HaoclawLocationMode) async -> CLAuthorizationStatus
    func currentLocation(
        params: HaoclawLocationGetParams,
        desiredAccuracy: HaoclawLocationAccuracy,
        maxAgeMs: Int?,
        timeoutMs: Int?) async throws -> CLLocation
    func startLocationUpdates(
        desiredAccuracy: HaoclawLocationAccuracy,
        significantChangesOnly: Bool) -> AsyncStream<CLLocation>
    func stopLocationUpdates()
    func startMonitoringSignificantLocationChanges(onUpdate: @escaping @Sendable (CLLocation) -> Void)
    func stopMonitoringSignificantLocationChanges()
}

@MainActor
protocol DeviceStatusServicing: Sendable {
    func status() async throws -> HaoclawDeviceStatusPayload
    func info() -> HaoclawDeviceInfoPayload
}

protocol PhotosServicing: Sendable {
    func latest(params: HaoclawPhotosLatestParams) async throws -> HaoclawPhotosLatestPayload
}

protocol ContactsServicing: Sendable {
    func search(params: HaoclawContactsSearchParams) async throws -> HaoclawContactsSearchPayload
    func add(params: HaoclawContactsAddParams) async throws -> HaoclawContactsAddPayload
}

protocol CalendarServicing: Sendable {
    func events(params: HaoclawCalendarEventsParams) async throws -> HaoclawCalendarEventsPayload
    func add(params: HaoclawCalendarAddParams) async throws -> HaoclawCalendarAddPayload
}

protocol RemindersServicing: Sendable {
    func list(params: HaoclawRemindersListParams) async throws -> HaoclawRemindersListPayload
    func add(params: HaoclawRemindersAddParams) async throws -> HaoclawRemindersAddPayload
}

protocol MotionServicing: Sendable {
    func activities(params: HaoclawMotionActivityParams) async throws -> HaoclawMotionActivityPayload
    func pedometer(params: HaoclawPedometerParams) async throws -> HaoclawPedometerPayload
}

struct WatchMessagingStatus: Sendable, Equatable {
    var supported: Bool
    var paired: Bool
    var appInstalled: Bool
    var reachable: Bool
    var activationState: String
}

struct WatchQuickReplyEvent: Sendable, Equatable {
    var replyId: String
    var promptId: String
    var actionId: String
    var actionLabel: String?
    var sessionKey: String?
    var note: String?
    var sentAtMs: Int?
    var transport: String
}

struct WatchNotificationSendResult: Sendable, Equatable {
    var deliveredImmediately: Bool
    var queuedForDelivery: Bool
    var transport: String
}

protocol WatchMessagingServicing: AnyObject, Sendable {
    func status() async -> WatchMessagingStatus
    func setReplyHandler(_ handler: (@Sendable (WatchQuickReplyEvent) -> Void)?)
    func sendNotification(
        id: String,
        params: HaoclawWatchNotifyParams) async throws -> WatchNotificationSendResult
}

extension CameraController: CameraServicing {}
extension ScreenRecordService: ScreenRecordingServicing {}
extension LocationService: LocationServicing {}

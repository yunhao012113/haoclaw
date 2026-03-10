package ai.haoclaw.app.protocol

import org.junit.Assert.assertEquals
import org.junit.Test

class HaoclawProtocolConstantsTest {
  @Test
  fun canvasCommandsUseStableStrings() {
    assertEquals("canvas.present", HaoclawCanvasCommand.Present.rawValue)
    assertEquals("canvas.hide", HaoclawCanvasCommand.Hide.rawValue)
    assertEquals("canvas.navigate", HaoclawCanvasCommand.Navigate.rawValue)
    assertEquals("canvas.eval", HaoclawCanvasCommand.Eval.rawValue)
    assertEquals("canvas.snapshot", HaoclawCanvasCommand.Snapshot.rawValue)
  }

  @Test
  fun a2uiCommandsUseStableStrings() {
    assertEquals("canvas.a2ui.push", HaoclawCanvasA2UICommand.Push.rawValue)
    assertEquals("canvas.a2ui.pushJSONL", HaoclawCanvasA2UICommand.PushJSONL.rawValue)
    assertEquals("canvas.a2ui.reset", HaoclawCanvasA2UICommand.Reset.rawValue)
  }

  @Test
  fun capabilitiesUseStableStrings() {
    assertEquals("canvas", HaoclawCapability.Canvas.rawValue)
    assertEquals("camera", HaoclawCapability.Camera.rawValue)
    assertEquals("voiceWake", HaoclawCapability.VoiceWake.rawValue)
    assertEquals("location", HaoclawCapability.Location.rawValue)
    assertEquals("sms", HaoclawCapability.Sms.rawValue)
    assertEquals("device", HaoclawCapability.Device.rawValue)
    assertEquals("notifications", HaoclawCapability.Notifications.rawValue)
    assertEquals("system", HaoclawCapability.System.rawValue)
    assertEquals("photos", HaoclawCapability.Photos.rawValue)
    assertEquals("contacts", HaoclawCapability.Contacts.rawValue)
    assertEquals("calendar", HaoclawCapability.Calendar.rawValue)
    assertEquals("motion", HaoclawCapability.Motion.rawValue)
  }

  @Test
  fun cameraCommandsUseStableStrings() {
    assertEquals("camera.list", HaoclawCameraCommand.List.rawValue)
    assertEquals("camera.snap", HaoclawCameraCommand.Snap.rawValue)
    assertEquals("camera.clip", HaoclawCameraCommand.Clip.rawValue)
  }

  @Test
  fun notificationsCommandsUseStableStrings() {
    assertEquals("notifications.list", HaoclawNotificationsCommand.List.rawValue)
    assertEquals("notifications.actions", HaoclawNotificationsCommand.Actions.rawValue)
  }

  @Test
  fun deviceCommandsUseStableStrings() {
    assertEquals("device.status", HaoclawDeviceCommand.Status.rawValue)
    assertEquals("device.info", HaoclawDeviceCommand.Info.rawValue)
    assertEquals("device.permissions", HaoclawDeviceCommand.Permissions.rawValue)
    assertEquals("device.health", HaoclawDeviceCommand.Health.rawValue)
  }

  @Test
  fun systemCommandsUseStableStrings() {
    assertEquals("system.notify", HaoclawSystemCommand.Notify.rawValue)
  }

  @Test
  fun photosCommandsUseStableStrings() {
    assertEquals("photos.latest", HaoclawPhotosCommand.Latest.rawValue)
  }

  @Test
  fun contactsCommandsUseStableStrings() {
    assertEquals("contacts.search", HaoclawContactsCommand.Search.rawValue)
    assertEquals("contacts.add", HaoclawContactsCommand.Add.rawValue)
  }

  @Test
  fun calendarCommandsUseStableStrings() {
    assertEquals("calendar.events", HaoclawCalendarCommand.Events.rawValue)
    assertEquals("calendar.add", HaoclawCalendarCommand.Add.rawValue)
  }

  @Test
  fun motionCommandsUseStableStrings() {
    assertEquals("motion.activity", HaoclawMotionCommand.Activity.rawValue)
    assertEquals("motion.pedometer", HaoclawMotionCommand.Pedometer.rawValue)
  }
}

package ai.haoclaw.app.node

import ai.haoclaw.app.protocol.HaoclawCalendarCommand
import ai.haoclaw.app.protocol.HaoclawCameraCommand
import ai.haoclaw.app.protocol.HaoclawCapability
import ai.haoclaw.app.protocol.HaoclawContactsCommand
import ai.haoclaw.app.protocol.HaoclawDeviceCommand
import ai.haoclaw.app.protocol.HaoclawLocationCommand
import ai.haoclaw.app.protocol.HaoclawMotionCommand
import ai.haoclaw.app.protocol.HaoclawNotificationsCommand
import ai.haoclaw.app.protocol.HaoclawPhotosCommand
import ai.haoclaw.app.protocol.HaoclawSmsCommand
import ai.haoclaw.app.protocol.HaoclawSystemCommand
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class InvokeCommandRegistryTest {
  private val coreCapabilities =
    setOf(
      HaoclawCapability.Canvas.rawValue,
      HaoclawCapability.Device.rawValue,
      HaoclawCapability.Notifications.rawValue,
      HaoclawCapability.System.rawValue,
      HaoclawCapability.Photos.rawValue,
      HaoclawCapability.Contacts.rawValue,
      HaoclawCapability.Calendar.rawValue,
    )

  private val optionalCapabilities =
    setOf(
      HaoclawCapability.Camera.rawValue,
      HaoclawCapability.Location.rawValue,
      HaoclawCapability.Sms.rawValue,
      HaoclawCapability.VoiceWake.rawValue,
      HaoclawCapability.Motion.rawValue,
    )

  private val coreCommands =
    setOf(
      HaoclawDeviceCommand.Status.rawValue,
      HaoclawDeviceCommand.Info.rawValue,
      HaoclawDeviceCommand.Permissions.rawValue,
      HaoclawDeviceCommand.Health.rawValue,
      HaoclawNotificationsCommand.List.rawValue,
      HaoclawNotificationsCommand.Actions.rawValue,
      HaoclawSystemCommand.Notify.rawValue,
      HaoclawPhotosCommand.Latest.rawValue,
      HaoclawContactsCommand.Search.rawValue,
      HaoclawContactsCommand.Add.rawValue,
      HaoclawCalendarCommand.Events.rawValue,
      HaoclawCalendarCommand.Add.rawValue,
    )

  private val optionalCommands =
    setOf(
      HaoclawCameraCommand.Snap.rawValue,
      HaoclawCameraCommand.Clip.rawValue,
      HaoclawCameraCommand.List.rawValue,
      HaoclawLocationCommand.Get.rawValue,
      HaoclawMotionCommand.Activity.rawValue,
      HaoclawMotionCommand.Pedometer.rawValue,
      HaoclawSmsCommand.Send.rawValue,
    )

  private val debugCommands = setOf("debug.logs", "debug.ed25519")

  @Test
  fun advertisedCapabilities_respectsFeatureAvailability() {
    val capabilities = InvokeCommandRegistry.advertisedCapabilities(defaultFlags())

    assertContainsAll(capabilities, coreCapabilities)
    assertMissingAll(capabilities, optionalCapabilities)
  }

  @Test
  fun advertisedCapabilities_includesFeatureCapabilitiesWhenEnabled() {
    val capabilities =
      InvokeCommandRegistry.advertisedCapabilities(
        defaultFlags(
          cameraEnabled = true,
          locationEnabled = true,
          smsAvailable = true,
          voiceWakeEnabled = true,
          motionActivityAvailable = true,
          motionPedometerAvailable = true,
        ),
      )

    assertContainsAll(capabilities, coreCapabilities + optionalCapabilities)
  }

  @Test
  fun advertisedCommands_respectsFeatureAvailability() {
    val commands = InvokeCommandRegistry.advertisedCommands(defaultFlags())

    assertContainsAll(commands, coreCommands)
    assertMissingAll(commands, optionalCommands + debugCommands)
  }

  @Test
  fun advertisedCommands_includesFeatureCommandsWhenEnabled() {
    val commands =
      InvokeCommandRegistry.advertisedCommands(
        defaultFlags(
          cameraEnabled = true,
          locationEnabled = true,
          smsAvailable = true,
          motionActivityAvailable = true,
          motionPedometerAvailable = true,
          debugBuild = true,
        ),
      )

    assertContainsAll(commands, coreCommands + optionalCommands + debugCommands)
  }

  @Test
  fun advertisedCommands_onlyIncludesSupportedMotionCommands() {
    val commands =
      InvokeCommandRegistry.advertisedCommands(
        NodeRuntimeFlags(
          cameraEnabled = false,
          locationEnabled = false,
          smsAvailable = false,
          voiceWakeEnabled = false,
          motionActivityAvailable = true,
          motionPedometerAvailable = false,
          debugBuild = false,
        ),
      )

    assertTrue(commands.contains(HaoclawMotionCommand.Activity.rawValue))
    assertFalse(commands.contains(HaoclawMotionCommand.Pedometer.rawValue))
  }

  private fun defaultFlags(
    cameraEnabled: Boolean = false,
    locationEnabled: Boolean = false,
    smsAvailable: Boolean = false,
    voiceWakeEnabled: Boolean = false,
    motionActivityAvailable: Boolean = false,
    motionPedometerAvailable: Boolean = false,
    debugBuild: Boolean = false,
  ): NodeRuntimeFlags =
    NodeRuntimeFlags(
      cameraEnabled = cameraEnabled,
      locationEnabled = locationEnabled,
      smsAvailable = smsAvailable,
      voiceWakeEnabled = voiceWakeEnabled,
      motionActivityAvailable = motionActivityAvailable,
      motionPedometerAvailable = motionPedometerAvailable,
      debugBuild = debugBuild,
    )

  private fun assertContainsAll(actual: List<String>, expected: Set<String>) {
    expected.forEach { value -> assertTrue(actual.contains(value)) }
  }

  private fun assertMissingAll(actual: List<String>, forbidden: Set<String>) {
    forbidden.forEach { value -> assertFalse(actual.contains(value)) }
  }
}

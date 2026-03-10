package ai.haoclaw.app.node

import ai.haoclaw.app.protocol.HaoclawCalendarCommand
import ai.haoclaw.app.protocol.HaoclawCanvasA2UICommand
import ai.haoclaw.app.protocol.HaoclawCanvasCommand
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

data class NodeRuntimeFlags(
  val cameraEnabled: Boolean,
  val locationEnabled: Boolean,
  val smsAvailable: Boolean,
  val voiceWakeEnabled: Boolean,
  val motionActivityAvailable: Boolean,
  val motionPedometerAvailable: Boolean,
  val debugBuild: Boolean,
)

enum class InvokeCommandAvailability {
  Always,
  CameraEnabled,
  LocationEnabled,
  SmsAvailable,
  MotionActivityAvailable,
  MotionPedometerAvailable,
  DebugBuild,
}

enum class NodeCapabilityAvailability {
  Always,
  CameraEnabled,
  LocationEnabled,
  SmsAvailable,
  VoiceWakeEnabled,
  MotionAvailable,
}

data class NodeCapabilitySpec(
  val name: String,
  val availability: NodeCapabilityAvailability = NodeCapabilityAvailability.Always,
)

data class InvokeCommandSpec(
  val name: String,
  val requiresForeground: Boolean = false,
  val availability: InvokeCommandAvailability = InvokeCommandAvailability.Always,
)

object InvokeCommandRegistry {
  val capabilityManifest: List<NodeCapabilitySpec> =
    listOf(
      NodeCapabilitySpec(name = HaoclawCapability.Canvas.rawValue),
      NodeCapabilitySpec(name = HaoclawCapability.Device.rawValue),
      NodeCapabilitySpec(name = HaoclawCapability.Notifications.rawValue),
      NodeCapabilitySpec(name = HaoclawCapability.System.rawValue),
      NodeCapabilitySpec(
        name = HaoclawCapability.Camera.rawValue,
        availability = NodeCapabilityAvailability.CameraEnabled,
      ),
      NodeCapabilitySpec(
        name = HaoclawCapability.Sms.rawValue,
        availability = NodeCapabilityAvailability.SmsAvailable,
      ),
      NodeCapabilitySpec(
        name = HaoclawCapability.VoiceWake.rawValue,
        availability = NodeCapabilityAvailability.VoiceWakeEnabled,
      ),
      NodeCapabilitySpec(
        name = HaoclawCapability.Location.rawValue,
        availability = NodeCapabilityAvailability.LocationEnabled,
      ),
      NodeCapabilitySpec(name = HaoclawCapability.Photos.rawValue),
      NodeCapabilitySpec(name = HaoclawCapability.Contacts.rawValue),
      NodeCapabilitySpec(name = HaoclawCapability.Calendar.rawValue),
      NodeCapabilitySpec(
        name = HaoclawCapability.Motion.rawValue,
        availability = NodeCapabilityAvailability.MotionAvailable,
      ),
    )

  val all: List<InvokeCommandSpec> =
    listOf(
      InvokeCommandSpec(
        name = HaoclawCanvasCommand.Present.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = HaoclawCanvasCommand.Hide.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = HaoclawCanvasCommand.Navigate.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = HaoclawCanvasCommand.Eval.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = HaoclawCanvasCommand.Snapshot.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = HaoclawCanvasA2UICommand.Push.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = HaoclawCanvasA2UICommand.PushJSONL.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = HaoclawCanvasA2UICommand.Reset.rawValue,
        requiresForeground = true,
      ),
      InvokeCommandSpec(
        name = HaoclawSystemCommand.Notify.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawCameraCommand.List.rawValue,
        requiresForeground = true,
        availability = InvokeCommandAvailability.CameraEnabled,
      ),
      InvokeCommandSpec(
        name = HaoclawCameraCommand.Snap.rawValue,
        requiresForeground = true,
        availability = InvokeCommandAvailability.CameraEnabled,
      ),
      InvokeCommandSpec(
        name = HaoclawCameraCommand.Clip.rawValue,
        requiresForeground = true,
        availability = InvokeCommandAvailability.CameraEnabled,
      ),
      InvokeCommandSpec(
        name = HaoclawLocationCommand.Get.rawValue,
        availability = InvokeCommandAvailability.LocationEnabled,
      ),
      InvokeCommandSpec(
        name = HaoclawDeviceCommand.Status.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawDeviceCommand.Info.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawDeviceCommand.Permissions.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawDeviceCommand.Health.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawNotificationsCommand.List.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawNotificationsCommand.Actions.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawPhotosCommand.Latest.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawContactsCommand.Search.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawContactsCommand.Add.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawCalendarCommand.Events.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawCalendarCommand.Add.rawValue,
      ),
      InvokeCommandSpec(
        name = HaoclawMotionCommand.Activity.rawValue,
        availability = InvokeCommandAvailability.MotionActivityAvailable,
      ),
      InvokeCommandSpec(
        name = HaoclawMotionCommand.Pedometer.rawValue,
        availability = InvokeCommandAvailability.MotionPedometerAvailable,
      ),
      InvokeCommandSpec(
        name = HaoclawSmsCommand.Send.rawValue,
        availability = InvokeCommandAvailability.SmsAvailable,
      ),
      InvokeCommandSpec(
        name = "debug.logs",
        availability = InvokeCommandAvailability.DebugBuild,
      ),
      InvokeCommandSpec(
        name = "debug.ed25519",
        availability = InvokeCommandAvailability.DebugBuild,
      ),
    )

  private val byNameInternal: Map<String, InvokeCommandSpec> = all.associateBy { it.name }

  fun find(command: String): InvokeCommandSpec? = byNameInternal[command]

  fun advertisedCapabilities(flags: NodeRuntimeFlags): List<String> {
    return capabilityManifest
      .filter { spec ->
        when (spec.availability) {
          NodeCapabilityAvailability.Always -> true
          NodeCapabilityAvailability.CameraEnabled -> flags.cameraEnabled
          NodeCapabilityAvailability.LocationEnabled -> flags.locationEnabled
          NodeCapabilityAvailability.SmsAvailable -> flags.smsAvailable
          NodeCapabilityAvailability.VoiceWakeEnabled -> flags.voiceWakeEnabled
          NodeCapabilityAvailability.MotionAvailable -> flags.motionActivityAvailable || flags.motionPedometerAvailable
        }
      }
      .map { it.name }
  }

  fun advertisedCommands(flags: NodeRuntimeFlags): List<String> {
    return all
      .filter { spec ->
        when (spec.availability) {
          InvokeCommandAvailability.Always -> true
          InvokeCommandAvailability.CameraEnabled -> flags.cameraEnabled
          InvokeCommandAvailability.LocationEnabled -> flags.locationEnabled
          InvokeCommandAvailability.SmsAvailable -> flags.smsAvailable
          InvokeCommandAvailability.MotionActivityAvailable -> flags.motionActivityAvailable
          InvokeCommandAvailability.MotionPedometerAvailable -> flags.motionPedometerAvailable
          InvokeCommandAvailability.DebugBuild -> flags.debugBuild
        }
      }
      .map { it.name }
  }
}

import Foundation

// Stable identifier used for both the macOS LaunchAgent label and Nix-managed defaults suite.
// nix-haoclaw writes app defaults into this suite to survive app bundle identifier churn.
let launchdLabel = "ai.haoclaw.mac"
let gatewayLaunchdLabel = "ai.haoclaw.gateway"
let onboardingVersionKey = "haoclaw.onboardingVersion"
let onboardingSeenKey = "haoclaw.onboardingSeen"
let currentOnboardingVersion = 7
let pauseDefaultsKey = "haoclaw.pauseEnabled"
let iconAnimationsEnabledKey = "haoclaw.iconAnimationsEnabled"
let swabbleEnabledKey = "haoclaw.swabbleEnabled"
let swabbleTriggersKey = "haoclaw.swabbleTriggers"
let voiceWakeTriggerChimeKey = "haoclaw.voiceWakeTriggerChime"
let voiceWakeSendChimeKey = "haoclaw.voiceWakeSendChime"
let showDockIconKey = "haoclaw.showDockIcon"
let defaultVoiceWakeTriggers = ["haoclaw"]
let voiceWakeMaxWords = 32
let voiceWakeMaxWordLength = 64
let voiceWakeMicKey = "haoclaw.voiceWakeMicID"
let voiceWakeMicNameKey = "haoclaw.voiceWakeMicName"
let voiceWakeLocaleKey = "haoclaw.voiceWakeLocaleID"
let voiceWakeAdditionalLocalesKey = "haoclaw.voiceWakeAdditionalLocaleIDs"
let voicePushToTalkEnabledKey = "haoclaw.voicePushToTalkEnabled"
let talkEnabledKey = "haoclaw.talkEnabled"
let iconOverrideKey = "haoclaw.iconOverride"
let connectionModeKey = "haoclaw.connectionMode"
let remoteTargetKey = "haoclaw.remoteTarget"
let remoteIdentityKey = "haoclaw.remoteIdentity"
let remoteProjectRootKey = "haoclaw.remoteProjectRoot"
let remoteCliPathKey = "haoclaw.remoteCliPath"
let canvasEnabledKey = "haoclaw.canvasEnabled"
let cameraEnabledKey = "haoclaw.cameraEnabled"
let systemRunPolicyKey = "haoclaw.systemRunPolicy"
let systemRunAllowlistKey = "haoclaw.systemRunAllowlist"
let systemRunEnabledKey = "haoclaw.systemRunEnabled"
let locationModeKey = "haoclaw.locationMode"
let locationPreciseKey = "haoclaw.locationPreciseEnabled"
let peekabooBridgeEnabledKey = "haoclaw.peekabooBridgeEnabled"
let deepLinkKeyKey = "haoclaw.deepLinkKey"
let modelCatalogPathKey = "haoclaw.modelCatalogPath"
let modelCatalogReloadKey = "haoclaw.modelCatalogReload"
let cliInstallPromptedVersionKey = "haoclaw.cliInstallPromptedVersion"
let heartbeatsEnabledKey = "haoclaw.heartbeatsEnabled"
let debugPaneEnabledKey = "haoclaw.debugPaneEnabled"
let debugFileLogEnabledKey = "haoclaw.debug.fileLogEnabled"
let appLogLevelKey = "haoclaw.debug.appLogLevel"
let desktopDownloadsURL = "https://yunhao012113.github.io/haoclaw/"
let voiceWakeSupported: Bool = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.Data
import qs.Helpers
import qs.Components

Scope {
	id: root

	property bool isVolumeOSDShow: false
	property string icon: Audio.getIcon(root.node)
	property PwNode node: Pipewire.defaultAudioSink

	PwObjectTracker {
		objects: [Pipewire.defaultAudioSink]
	}

	Connections {
		target: Pipewire.defaultAudioSink?.audio
		function onVolumeChanged() {
			root.isVolumeOSDShow = true;
			hideVolumeOSDTimer.restart();
		}
	}

	property bool capsLockState: false
	property bool isCapsLockOSDShow: false

	function getCapsLockState(): void {
		capsLockInfo.running = true;
	}

	Process {
		id: capsLockInfo

		running: true
		command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .capsLock'"]
		stdout: StdioCollector {
			onStreamFinished: {
				let newState = text.trim() === "true";
				if (root.capsLockState !== newState) {
					root.capsLockState = newState;
					root.isCapsLockOSDShow = true;
					hideCapsLockOSDTimer.restart();
				}
			}
		}
		onExited: {
			root.getCapsLockState();
		}
	}

	property bool numLockState: false
	property bool isNumLockOSDShow: false

	function getNumlockState(): void {
		numLockInfo.running = true;
	}

	Process {
		id: numLockInfo

		running: true
		command: ["sh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .numLock'"]
		stdout: StdioCollector {
			onStreamFinished: {
				let newState = text.trim() === "true";
				if (root.numLockState !== newState) {
					root.numLockState = newState;
					root.isNumLockOSDShow = true;
					hideNumLockOSDTimer.restart();
				}
			}
		}
		onExited: {
			root.getNumlockState();
		}
	}

	Timer {
		id: hideVolumeOSDTimer

		interval: 2000
		onTriggered: {
			root.isVolumeOSDShow = false;
		}
	}

	Timer {
		id: hideCapsLockOSDTimer

		interval: 2000
		onTriggered: {
			root.isCapsLockOSDShow = false;
		}
	}

	Timer {
		id: hideNumLockOSDTimer

		interval: 2000
		onTriggered: {
			root.isNumLockOSDShow = false;
		}
	}

	// LMAO, what is this
	LazyLoader {
		id: volumeOsdLoader

		activeAsync: root.isVolumeOSDShow
		component: PanelWindow {
			required property ShellScreen screen
			anchors {
				bottom: true
			}
			WlrLayershell.namespace: "shell:osd:volume"
			screen: screen
			color: "transparent"
			exclusionMode: ExclusionMode.Ignore
			focusable: false
			implicitWidth: 350
			implicitHeight: 50
			exclusiveZone: 0
			margins.bottom: 30
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: height / 2
				color: Appearance.colors.background
				Volumes {}
			}
		}
	}

	LazyLoader {
		id: capsLockOsdLoader

		activeAsync: root.isCapsLockOSDShow
		component: PanelWindow {
			required property ShellScreen screen
			anchors {
				bottom: true
			}
			WlrLayershell.namespace: "shell:osd:capslock"
			screen: screen
			color: "transparent"
			exclusionMode: ExclusionMode.Ignore
			focusable: false
			implicitWidth: 350
			implicitHeight: 50
			exclusiveZone: 0
			margins.bottom: 90
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: height / 2
				color: Appearance.colors.background

				Row {
					anchors.centerIn: parent
					spacing: 10

					StyledText {
						text: "Caps Lock"
						color: Appearance.colors.on_background
						font.pixelSize: Appearance.fonts.large * 1.5
					}

					MatIcon {
						icon: root.capsLockState ? "lock" : "lock_open_right"
						color: root.capsLockState ? Appearance.colors.primary : Appearance.colors.tertiary
						font.pixelSize: Appearance.fonts.large * 1.5
					}
				}
			}
		}
	}

	LazyLoader {
		id: numLockOsdLoader

		activeAsync: root.isNumLockOSDShow
		component: PanelWindow {
			required property ShellScreen screen
			anchors {
				bottom: true
			}
			WlrLayershell.namespace: "shell:osd:numlock"
			screen: screen
			color: "transparent"
			exclusionMode: ExclusionMode.Ignore
			focusable: false
			implicitWidth: 350
			implicitHeight: 50
			exclusiveZone: 0
			margins.bottom: 150
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: height / 2
				color: Appearance.colors.background

				Row {
					anchors.centerIn: parent
					spacing: 10

					StyledText {
						text: "Num Lock"
						color: Appearance.colors.on_background
						font.pixelSize: Appearance.fonts.large * 1.5
					}

					MatIcon {
						icon: root.numLockState ? "lock" : "lock_open_right"
						color: root.numLockState ? Appearance.colors.primary : Appearance.colors.tertiary
						font.pixelSize: Appearance.fonts.large * 1.5
					}
				}
			}
		}
	}
}

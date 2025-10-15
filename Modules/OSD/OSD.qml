pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import qs.Data

Scope {
	id: root

	property bool isVolumeOSDShow: false
	property bool isCapsLockOSDShow: false
	property bool isNumLockOSDShow: false

	Connections {
		target: KeyLockState

		function onCapsLockStateChanged() {
			root.isCapsLockOSDShow = KeyLockState.capsLockState;
			if (KeyLockState.capsLockState)
				hideOSDTimer.restart();
		}
		function onNumLockStateChanged() {
			root.isNumLockOSDShow = KeyLockState.numLockState;
			if (KeyLockState.numLockState)
				hideOSDTimer.restart();
		}
	}

	property string icon: Audio.getIcon(root.node)
	property PwNode node: Pipewire.defaultAudioSink

	PwObjectTracker {
		objects: [Pipewire.defaultAudioSink]
	}

	Connections {
		target: Pipewire.defaultAudioSink.audio
		function onVolumeChanged() {
			root.isVolumeOSDShow = true;
			hideOSDTimer.restart();
		}
	}

	Timer {
		id: hideOSDTimer

		interval: 2000
		onTriggered: {
			root.isVolumeOSDShow = false;
			root.isCapsLockOSDShow = false;
			root.isNumLockOSDShow = false;
		}
	}

	Volumes {
		volumeOSDStatus: root.isVolumeOSDShow
	}

	CapsLockWidget {
		capsLockOSDStatus: root.isCapsLockOSDShow
	}

	NumLockWidget {
		numLockOSDStatus: root.isNumLockOSDShow
	}
}

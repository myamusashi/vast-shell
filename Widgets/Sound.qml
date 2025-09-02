import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Data
import qs.Helpers
import qs.Windows

Rectangle {
	id: root

	property string icon: Audio.getIcon(root.node)
	property PwNode node: Pipewire.defaultAudioSink
	property int padding: 20

	Layout.fillHeight: true
	color: Appearance.colors.withAlpha(Appearance.colors.background, 0.79)
	implicitWidth: container.width + padding
	radius: 5

	Behavior on implicitWidth {
		NumberAnimation {
			duration: Appearance.animations.durations.normal
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.standard
		}
	}

	PwObjectTracker {
		objects: [root.node]
	}

	Dots {
		id: container

		spacing: 10

		icon {
			color: Appearance.colors.on_background
			text: root.icon
		}

		text {
			color: Appearance.colors.on_background
			text: (node.audio.volume * 100).toFixed(0) + "%"
		}
	}

	Mixer {
		id: mixer
	}

	MouseArea {
		acceptedButtons: Qt.MiddleButton | Qt.LeftButton
		anchors.fill: parent

		onClicked: mevent => {
			if (mevent.button === Qt.MiddleButton) {
				Audio.toggleMute(root.node);
			} else if (mevent.button === Qt.LeftButton) {
				mixer.visible = !mixer.visible;
			}
		}

		onWheel: mevent => Audio.wheelAction(mevent, root.node)
	}
}

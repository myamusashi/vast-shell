import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

import qs.Data
import qs.Helpers
import qs.Components

RowLayout {
	anchors {
		fill: parent
		leftMargin: 10
		rightMargin: 15
	}

	MatIcon {
		color: Appearance.colors.on_background
		icon: root.icon
		Layout.alignment: Qt.AlignVCenter
		font.pixelSize: Appearance.fonts.extraLarge * 1.2
	}

	Rectangle {
		Layout.fillWidth: true

		implicitHeight: 10
		radius: 20
		color: Appearance.colors.withAlpha(Appearance.colors.primary, 0.3)

		Rectangle {
			anchors {
				left: parent.left
				top: parent.top
				bottom: parent.bottom
			}

			color: Appearance.colors.primary

			implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
			radius: parent.radius
		}
	}
}

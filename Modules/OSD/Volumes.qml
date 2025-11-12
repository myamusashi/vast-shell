pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.Data
import qs.Helpers
import qs.Widgets
import qs.Components

LazyLoader {
	id: volumeOsdLoader

	active: false
	component: PanelWindow {
		id: root

		anchors.bottom: true
		WlrLayershell.namespace: "shell:osd:volume"
		color: "transparent"
		focusable: false
		implicitWidth: content.implicitWidth * 1.5
		implicitHeight: content.implicitHeight * 1.5
		exclusiveZone: 0
		margins.bottom: 15

		required property PwNode node
		PwObjectTracker {
			objects: [root.node]
		}

		property string icon: Audio.getIcon(volumeOsdLoader.node)

		StyledRect {
			anchors.fill: parent
			radius: Appearance.rounding.full
			color: Colors.colors.background

			RowLayout {
				id: content

				anchors {
					fill: parent
					leftMargin: 10
					rightMargin: 15
				}

				MatIcon {
					color: Colors.colors.on_background
					icon: root.icon
					Layout.alignment: Qt.AlignVCenter
					font.pixelSize: Appearance.fonts.extraLarge * 1.2
				}

				ColumnLayout {
					Layout.fillWidth: true
					Layout.fillHeight: true

					RowLayout {
						Layout.fillWidth: true
						Layout.alignment: Qt.AlignLeft
						StyledText {
							text: "Volumes:"
							color: Colors.colors.on_background
							font.pixelSize: Appearance.fonts.large
						}
						StyledText {
							text: `${Math.round(Pipewire.defaultAudioSink?.audio.volume * 100)}%`
							color: Colors.colors.on_background
							font.pixelSize: Appearance.fonts.normal
						}
					}
					StyledSlide {
						Layout.fillWidth: true
						Layout.preferredHeight: 32
						value: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
						onValueChanged: root.node.audio.volume = value
					}
				}
			}
		}
	}
}

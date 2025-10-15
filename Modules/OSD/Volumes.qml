import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

import qs.Data
import qs.Helpers
import qs.Components

LazyLoader {
	id: volumeOsdLoader

	required property bool volumeOSDStatus

	active: volumeOSDStatus
	component: PanelWindow {
		anchors.bottom: true
		WlrLayershell.namespace: "shell:osd:volume"
		color: "transparent"
		exclusionMode: ExclusionMode.Ignore
		focusable: false
		implicitWidth: 350
		implicitHeight: 50
		exclusiveZone: 0
		margins.bottom: 30
		mask: Region {}

		StyledRect {
			anchors.fill: parent
			radius: height / 2
			color: Colors.colors.background

			RowLayout {
				anchors {
					fill: parent
					leftMargin: 10
					rightMargin: 15
				}

				MatIcon {
					color: Colors.dark.on_background
					icon: root.icon
					Layout.alignment: Qt.AlignVCenter
					font.pixelSize: Appearance.fonts.extraLarge * 1.2
				}

				StyledRect {
					Layout.fillWidth: true

					implicitHeight: 10
					radius: 20
					color: Colors.withAlpha(Colors.dark.primary, 0.3)

					StyledRect {
						anchors {
							left: parent.left
							top: parent.top
							bottom: parent.bottom
						}

						color: Colors.dark.primary

						implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
						radius: parent.radius
					}
				}
			}
		}
	}
}

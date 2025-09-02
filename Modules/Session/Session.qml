import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers

Scope {
	id: session

	property int currentIndex: 0
	property bool isSessionOpen: false
	PanelWindow {
		id: sessionWindow
		visible: isSessionOpen
		focusable: true
		anchors.right: true
		margins.right: 10
		exclusiveZone: 0
		implicitWidth: 80
		implicitHeight: 550
		color: "transparent"

		Item {
			anchors.fill: parent

			Rectangle {
				anchors.fill: parent
				radius: Appearance.rounding.normal
				color: Appearance.colors.background

				ColumnLayout {
					anchors.fill: parent
					spacing: 5

					// AnimatedImage {
					// 	source: "https://duiqt.github.io/herta_kuru/static/img/hertaa1.gif"
					// 	sourceSize: "80x70"
					// }

					Repeater {
						model: [
							{
								icon: "power_settings_circle",
								action: () => {
									Quickshell.execDetached({
										command: ["sh", "-c", "systemctl poweroff"]
									});
								}
							},
							{
								icon: "restart_alt",
								action: () => {
									Quickshell.execDetached({
										command: ["sh", "-c", "systemctl reboot"]
									});
								}
							},
							{
								icon: "door_open",
								action: () => {
									Quickshell.execDetached({
										command: ["sh", "-c", "hyprctl dispatch exit"]
									});
								}
							},
							{
								icon: "lock",
								action: () => {
									Quickshell.execDetached({
										command: ["sh", "-c", "qs -c lock ipc call lock lock"]
									});
								}
							}
						]

						delegate: MatIcon {
							id: iconDelegate
							required property var modelData
							required property int index

							Layout.alignment: Qt.AlignHCenter
							Layout.preferredWidth: 60
							Layout.preferredHeight: 60

							color: Appearance.colors.primary
							fill: mouseArea.containsMouse || iconDelegate.focus
							font.pointSize: Appearance.fonts.large * 3
							icon: modelData.icon

							focus: index === session.currentIndex

							Keys.onEnterPressed: modelData.action()
							Keys.onReturnPressed: modelData.action()
							Keys.onSpacePressed: modelData.action()

							Keys.onUpPressed: {
								if (session.currentIndex > 0) 
									session.currentIndex--;
								
							}
							Keys.onDownPressed: {
								if (session.currentIndex < 3) 
									session.currentIndex++;
								
							}

							Keys.onEscapePressed: {
								session.isSessionOpen = !session.isSessionOpen;
							}

							scale: mouseArea.pressed ? 0.95 : 1.0

							Behavior on scale {
								NumberAnimation {
									duration: 100
									easing.type: Easing.OutQuad
								}
							}

							MouseArea {
								id: mouseArea
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								hoverEnabled: true

								onClicked: {
									parent.focus = true;
									parent.modelData.action();
								}

								onEntered: parent.focus = true
							}
						}
					}
				}
			}
		}

	}

	IpcHandler {
		target: "session"

		function toggle(): void {
			session.isSessionOpen = !session.isSessionOpen;
		}
	}
}

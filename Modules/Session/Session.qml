pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers

Scope {
	id: session

	property int currentIndex: 0
	property bool isSessionOpen: false

	Loader {
		active: session.isSessionOpen
		asynchronous: true

		sourceComponent: PanelWindow {
			id: sessionWindow
			visible: session.isSessionOpen
			focusable: true
			anchors.right: true
			margins.right: 10
			exclusiveZone: 0
			implicitWidth: 80
			implicitHeight: 550
			WlrLayershell.namespace: "shell:session"
			color: "transparent"

			Item {
				anchors.fill: parent

				Rectangle {
					anchors.fill: parent
					radius: Appearance.rounding.normal
					color: Appearance.colors.withAlpha(Appearance.colors.background, 0.7)

					ColumnLayout {
						anchors.fill: parent
						spacing: 5

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

							delegate: Rectangle {
								id: rectDelegate

								required property var modelData
								required property int index
								property bool isHighlighted: mouseArea.containsMouse || (iconDelegate.focus && rectDelegate.index === session.currentIndex)

								Layout.alignment: Qt.AlignHCenter
								Layout.preferredWidth: 60
								Layout.preferredHeight: 70

								radius: Appearance.rounding.normal
								color: isHighlighted ? Appearance.colors.withAlpha(Appearance.colors.secondary, 0.2) : "transparent"

								Behavior on color {
									ColorAnimation {
										duration: Appearance.animations.durations.normal
										easing.type: Easing.BezierSpline
										easing.bezierCurve: Appearance.animations.curves.standard
									}
								}

								MatIcon {
									id: iconDelegate

									color: Appearance.colors.primary
									font.family: "Material Symbols Rounded"
									font.pixelSize: Appearance.fonts.large * 4
									icon: rectDelegate.modelData.icon

									focus: rectDelegate.index === session.currentIndex

									Keys.onEnterPressed: rectDelegate.modelData.action()
									Keys.onReturnPressed: rectDelegate.modelData.action()
									Keys.onUpPressed: session.currentIndex > 0 ? session.currentIndex-- : ""
									Keys.onDownPressed: session.currentIndex < 3 ? session.currentIndex++ : ""
									Keys.onEscapePressed: session.isSessionOpen = !session.isSessionOpen

									scale: mouseArea.pressed ? 0.95 : 1.0

									Behavior on scale {
										NumberAnimation {
											duration: Appearance.animations.durations.normal
											easing.type: Easing.BezierSpline
											easing.bezierCurve: Appearance.animations.curves.standard
										}
									}

									MouseArea {
										id: mouseArea

										anchors.fill: parent
										cursorShape: Qt.PointingHandCursor
										hoverEnabled: true

										onClicked: {
											parent.focus = true;
											rectDelegate.modelData.action();
										}

										onEntered: parent.focus = true
									}
								}
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

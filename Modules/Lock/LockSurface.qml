import qs.Data

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Io
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell.Wayland

WlSessionLockSurface {
	id: root

	required property WlSessionLock lock
	required property Pam pam

	property bool isWallReady: false

	Connections {
		target: root.lock

		function onUnlock(): void {
			out.start();
		}
	}

	Rectangle {
		id: surface
		anchors.fill: parent

		property color clockColor: Appearance.colors.primary_container
		property string path
		color: Appearance.colors.background

		Process {
			id: wallPath
			running: true
			command: ["sh", "-c", "qs -c lock ipc call img get"]
			stdout: StdioCollector {
				onStreamFinished: {
					surface.path = text.trim();
				}
			}
		}
		Image {
			id: wall
			antialiasing: true
			asynchronous: true
			retainWhileLoading: true
			smooth: true
			source: `${surface.path}`
			fillMode: Image.PreserveAspectCrop
			visible: false
			opacity: 0
			width: parent.width
			height: parent.width

			onStatusChanged: root.isWallReady = true
		}

		MultiEffect {
			source: wall
			anchors.fill: wall
			width: parent.width
			height: parent.height
			blurEnabled: true
			blurMax: 60
			blur: 1.0

			opacity: wall.opacity
			Behavior on opacity {
				NumberAnimation {
					duration: Appearance.animations.durations.small * 1.2
					easing.type: Easing.BezierSpline
					easing.bezierCurve: Appearance.animations.curves.standardAccel
				}
			}
		}

		ColumnLayout {
			id: clockContainer

			anchors.centerIn: parent
			spacing: 5
			opacity: 0

			property var currentDate: new Date()

			function getDayName(index) {
				const days = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];
				return days[index];
			}

			function getMonthName(index) {
				const months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Des"];
				return months[index];
			}

			Timer {
				interval: 1000
				repeat: true
				running: true
				onTriggered: parent.currentDate = new Date()
			}

			Label {
				font.pointSize: Appearance.fonts.extraLarge * 4
				font.family: Appearance.fonts.family_Clock
				font.bold: true
				color: surface.clockColor
				renderType: Text.NativeRendering
				text: {
					const hours = parent.currentDate.getHours().toString().padStart(2, '0');
					const minutes = parent.currentDate.getMinutes().toString().padStart(2, '0');
					return `${hours}\n${minutes}`;
				}
				Layout.alignment: Qt.AlignHCenter
			}

			Label {
				font.pointSize: Appearance.fonts.medium * 2
				font.family: Appearance.fonts.family_Mono
				color: surface.clockColor
				renderType: Text.NativeRendering
				text: parent.getDayName(parent.currentDate.getDay())
				Layout.alignment: Qt.AlignHCenter
			}

			Label {
				font.pointSize: Appearance.fonts.smaller * 3.5
				font.family: Appearance.fonts.family_Sans
				color: Appearance.colors.on_primary
				renderType: Text.NativeRendering
				text: `${parent.currentDate.getDate()} ${parent.getMonthName(parent.currentDate.getMonth())}`
				Layout.alignment: Qt.AlignHCenter
			}
		}

		ColumnLayout {
			id: inputContainer

			opacity: 0

			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				bottomMargin: 75
			}
			Label {
				id: incorrectPasswordText
				text: "Incorrect password"
				color: Appearance.colors.on_error
				visible: root.pam ? root.pam.showFailure : false
				opacity: (root.pam && root.pam.showFailure) ? 1 : 0

				Behavior on opacity {
					PropertyAnimation {
						duration: Appearance.animations.durations.normal
						easing.type: Easing.BezierSpline
						easing.bezierCurve: Appearance.animations.curves.standard
					}
				}
			}

			RowLayout {
				TextField {
					id: passwordBox

					echoMode: TextInput.Password
					focus: true
					enabled: !root.pam.unlockInProgress
					color: root.pam.unlockInProgress ? Appearance.colors.on_error : Appearance.colors.on_background
					background: Rectangle {
						anchors.fill: parent
						color: Appearance.colors.withAlpha(Appearance.colors.background, 0.25)
						border.color: Appearance.colors.on_primary
						border.width: 2
						radius: 35
						opacity: passwordBox.activeFocus ? 1 : 0.5

						Behavior on border.width {
							PropertyAnimation {
								duration: Appearance.animations.durations.normal
								easing.type: Easing.BezierSpline
								easing.bezierCurve: Appearance.animations.curves.standard
							}
						}
						Behavior on opacity {
							PropertyAnimation {
								duration: Appearance.animations.durations.normal
								easing.type: Easing.BezierSpline
								easing.bezierCurve: Appearance.animations.curves.standard
							}
						}
					}
					implicitWidth: 400
					inputMethodHints: Qt.ImhSensitiveData
					padding: 10
					onAccepted: if (root.pam)
						root.pam.tryUnlock()
					onTextChanged: if (root.pam)
						root.pam.currentText = this.text
					Layout.alignment: Qt.AlignVBottom
					Connections {
						function onCurrentTextChanged() {
							passwordBox.text = root.pam.currentText;
						}
						target: root.pam
					}
				}
			}
		}
	}

	NumberAnimation {
		id: out

		target: wall
		property: "opacity"
		from: 1
		to: 0
		duration: Appearance.animations.durations.small * 1.2
		easing.type: Easing.BezierSpline
		easing.bezierCurve: Appearance.animations.curves.standardAccel

		onFinished: {
			outAnim.start();
		}
	}

	SequentialAnimation {
		id: outAnim

		NumberAnimation {
			target: clockContainer
			property: "opacity"
			from: 1
			to: 0
			duration: Appearance.animations.durations.large
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.standardAccel
		}

		NumberAnimation {
			target: inputContainer
			property: "opacity"
			from: 1
			to: 0
			duration: Appearance.animations.durations.normal
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.standardAccel
		}

		PropertyAction {
			target: root.lock
			property: "locked"
			value: false
		}
	}

	NumberAnimation {
		target: wall
		running: root.isWallReady
		property: "opacity"
		from: 0
		to: 1
		duration: Appearance.animations.durations.small
		easing.type: Easing.BezierSpline
		easing.bezierCurve: Appearance.animations.curves.standardAccel
		onFinished: {
			initAnim.start();
		}
	}

	SequentialAnimation {
		id: initAnim

		NumberAnimation {
			target: clockContainer
			property: "opacity"
			from: 0
			to: 1
			duration: Appearance.animations.durations.large
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.standardAccel
		}

		NumberAnimation {
			target: inputContainer
			property: "opacity"
			from: 0
			to: 1
			duration: Appearance.animations.durations.large
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Appearance.animations.curves.standardAccel
		}
	}
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.Data
import qs.Helpers
import qs.Components

StyledRect {
	Layout.fillHeight: true
	clip: true
	color: "transparent"
	// color: Colors.colors.withAlpha(Colors.colors.background, 0.79)
	implicitWidth: container.width
	radius: Appearance.rounding.small

	Behavior on implicitWidth {
		NumbAnim {}
	}

	MouseArea {
		id: mArea

		anchors.fill: parent
		hoverEnabled: true

		RowLayout {
			id: container

			anchors.bottom: parent.bottom
			anchors.left: parent.left
			anchors.top: parent.top

			Repeater {
				model: [
					{
						icon: "energy_savings_leaf",
						profile: PowerProfile.PowerSaver
					},
					{
						icon: "balance",
						profile: PowerProfile.Balanced
					},
					{
						icon: "rocket_launch",
						profile: PowerProfile.Performance
					},
				]

				delegate: Item {
					id: delegateRoot

					required property int index
					required property var modelData

					property bool isAnimating: false

					Layout.fillHeight: true
					implicitWidth: height ? height : 1

					StyledRect {
						id: bgCon

						anchors.fill: parent
						anchors.margins: 2
						color: Colors.colors.primary
						radius: Appearance.rounding.small
						visible: delegateRoot.modelData.profile == PowerProfiles.profile

						Behavior on visible {
							enabled: !delegateRoot.isAnimating
							NumbAnim {}
						}
					}

					MArea {
						id: clickArea

						anchors.margins: 4
						layerColor: fgText.color
						cursorShape: Qt.PointingHandCursor
						layerRadius: 5

						visible: !bgCon.visible

						StyledRect {
							id: rippleEffect

							anchors.centerIn: parent
							width: 0
							height: width
							radius: width / 2
							color: Colors.colors.primary
							opacity: 0

							ParallelAnimation {
								id: rippleAnimation

								running: false

								NumbAnim {
									target: rippleEffect
									property: "width"
									from: 0
									to: Math.max(clickArea.width, clickArea.height) * 2
									duration: Appearance.animations.durations.large
									easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
								}
								SequentialAnimation {
									NumbAnim {
										target: rippleEffect
										property: "opacity"
										from: 0
										to: 0.3
										duration: Appearance.animations.durations.small
										easing.bezierCurve: Appearance.animations.curves.standardAccel
									}
									NumbAnim {
										target: rippleEffect
										property: "opacity"
										from: 0.3
										to: 0
										easing.bezierCurve: Appearance.animations.curves.standardDecel
									}
								}
							}
						}

						SequentialAnimation {
							id: clickAnimation

							running: false

							onStarted: delegateRoot.isAnimating = true
							onFinished: delegateRoot.isAnimating = false

							ParallelAnimation {
								ScaleAnimator {
									target: delegateRoot
									from: 1.0
									to: 0.3
									easing.type: Easing.BezierSpline
									easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
								}

								ScriptAction {
									script: rippleAnimation.start()
								}
							}

							ParallelAnimation {
								ScaleAnimator {
									target: delegateRoot
									from: 0.3
									to: 1.0
									easing.type: Easing.BezierSpline
									easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
								}
							}

							PauseAnimation {
								duration: Appearance.animations.durations.small
							}
						}

						onClicked: {
							PowerProfiles.profile = delegateRoot.modelData.profile;
							clickAnimation.start();
						}
					}

					MatIcon {
						id: fgText

						anchors.centerIn: parent
						color: bgCon.visible ? Colors.colors.on_primary : Colors.colors.on_background
						font.pixelSize: Appearance.fonts.larger + 2
						icon: delegateRoot.modelData.icon
					}
				}
			}
		}
	}
}

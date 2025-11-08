import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects

import qs.Data

Slider {
	id: root

	hoverEnabled: true
	Layout.alignment: Qt.AlignHCenter

	property bool dotEnd: true
	property int progressBackgroundHeight: 24
	property int handleHeight: 40
	property int handleWidth: 4
	property int valueWidth
	property int valueHeight

	background: Item {
		id: progressItem

		implicitWidth: root.valueWidth
		implicitHeight: root.valueHeight
		width: root.availableWidth
		height: root.availableHeight
		x: root.leftPadding
		y: root.topPadding

		StyledRect {
			id: unprogressBackground

			width: parent.width
			height: root.progressBackgroundHeight
			x: 0
			y: (parent.height - height) / 2
			color: Colors.colors.surface_container_highest
			radius: Appearance.rounding.small * 0.5

			StyledRect {
				id: startDot

				visible: root.dotEnd
				width: 6
				height: 6
				radius: 3
				anchors.verticalCenter: parent.verticalCenter
				anchors.leftMargin: (parent.height - height) / 2
				anchors.left: parent.left
				color: Colors.colors.on_surface
			}

			StyledRect {
				id: centerDot

				visible: root.dotEnd
				width: 6
				height: 6
				radius: 3
				anchors.centerIn: parent
				color: Colors.colors.on_surface
			}

			StyledRect {
				id: endDot

				visible: root.dotEnd
				width: 6
				height: 6
				radius: 3
				anchors.verticalCenter: parent.verticalCenter
				anchors.right: parent.right
				anchors.rightMargin: (parent.height - height) / 2
				color: Colors.colors.on_surface
			}
		}

		StyledRect {
			id: progressBackground

			width: parent.width * root.visualPosition
			height: unprogressBackground.height
			x: 0
			y: (parent.height - height) / 2
			color: Colors.colors.primary
			radius: Appearance.rounding.small * 0.5
		}
	}

	handle: Item {
		id: handleContainer
		x: root.leftPadding + root.visualPosition * (root.availableWidth - root.handleWidth)
		y: root.topPadding + root.availableHeight / 2 - root.handleHeight / 2
		width: root.handleWidth
		height: root.handleHeight

		StyledRect {
			anchors.centerIn: parent
			width: 15
			height: root.handleHeight
			color: Colors.colors.surface_container_high
			z: 1
			radius: Appearance.rounding.full
		}

		StyledRect {
			anchors.centerIn: parent
			z: 2
			width: root.hovered || root.pressed ? 8 : root.handleWidth
			height: root.handleHeight
			color: Colors.colors.primary
			radius: Appearance.rounding.small

			Behavior on width {
				NumbAnim {
					duration: Appearance.animations.durations.small
				}
			}
		}
	}
}

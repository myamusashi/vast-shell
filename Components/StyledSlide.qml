import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data

Slider {
	id: root

	hoverEnabled: true
	Layout.alignment: Qt.AlignHCenter

	property bool dotEnd: true
	property int progressBackgroundHeight: 24
	property int handleHeight: 44
	property int handleWidth: 4
	property int valueWidth
	property int valueHeight

	background: Item {
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
			radius: Appearance.rounding.small

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
			radius: Appearance.rounding.small
		}
	}

	handle: StyledRect {
		id: sliderHandle

		x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
		y: root.topPadding + root.availableHeight / 2 - height / 2
		implicitWidth: root.handleWidth
		implicitHeight: root.handleHeight
		width: root.hovered || root.pressed ? 6 : root.handleWidth
		height: root.hovered || root.pressed ? 48 : root.handleHeight
		color: Colors.colors.primary
		radius: Appearance.rounding.small

		Behavior on width {
			NumbAnim {
				duration: Appearance.animations.durations.small
			}
		}

		Behavior on height {
			NumbAnim {
				duration: Appearance.animations.durations.small
			}
		}
	}
}

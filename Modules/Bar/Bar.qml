import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.Helpers
import qs.Components

StyledRect {
	visible: GlobalStates.isBarOpen

	height: 40
	width: parent.width
	GlobalShortcut {
		name: "layershell"
		onPressed: GlobalStates.isBarOpen = !GlobalStates.isBarOpen
	}
	anchors {
		top: parent.top
		left: parent.left
		right: parent.right
	}

    RowLayout {
        id: rowbar

		anchors {
			fill: parent
            leftMargin: 5
            rightMargin: 5
        }

        Left {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width / 6
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }
        Middle {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width / 6
            Layout.alignment: Qt.AlignCenter
        }
        Right {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width / 6
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        }
    }
}

import qs.Widgets
import qs.Data
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

Item {
	RowLayout {
		anchors.fill: parent
		anchors.rightMargin: 8
		layoutDirection: Qt.RightToLeft
		spacing: Appearance.spacing.small
		
		Clock {
			Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
		}
		Tray {
			Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
			parentWindow: root
			parentScreen: root.modelData
		}
		PowerProfiles {
			Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
		}
		Sound {
			Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
		}
		Sound {
			Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
			node: Pipewire.defaultAudioSource
		}
		Battery {
			Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
		}
		
		Item {
			Layout.fillWidth: true
		}
	}
}

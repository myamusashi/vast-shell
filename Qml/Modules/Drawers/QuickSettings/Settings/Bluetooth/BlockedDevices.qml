pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ColumnLayout {
    spacing: Appearance.spacing.small * 0.5
    visible: BluetoothServices.hasBlocked

    StyledText {
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        font.weight: Font.DemiBold
        text: qsTr("Blocked devices")
    }

    Repeater {
        model: BluetoothServices.blockedDevices
        delegate: WrapperRectangle {
            id: blockedDelegate

            required property var modelData

            Layout.fillWidth: true
            color: "transparent"
            margin: Appearance.margin.small
            radius: Appearance.rounding.large

            RowLayout {
                spacing: Appearance.spacing.small

                anchors {
                    left: parent.left
                    margins: Appearance.margin.small
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 28
                    color: Qt.alpha(Colours.m3Colors.m3Error, 0.12)
                    radius: Appearance.rounding.small

                    Icon {
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3Error
                        font.pixelSize: Appearance.fonts.size.large
                        icon: "block"
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.normal
                    text: BluetoothServices.displayName(blockedDelegate.modelData)
                }

                FloatingButton {
                    backgroundRadius: Appearance.rounding.normal
                    color: "transparent"
                    icon.name: "block"
                    implicitHeight: 28
                    implicitWidth: 28
                    onClicked: blockedDelegate.modelData.blocked = false
                }
            }
        }
    }
}

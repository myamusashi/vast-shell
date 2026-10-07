import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import qs.Components.Effects

PopupWidget {
    icon: "memory"
    text: qsTr("Memory")
    content: ColumnLayout {
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                text: qsTr("RAM Size")
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                color: Colours.m3Colors.m3Green
                font.pixelSize: Appearance.fonts.size.large
                font.weight: Font.DemiBold
                text: (SystemUsage.memTotal / 1048576).toFixed(2) + " GB"
            }
        }

        Repeater {
            model: [
                {
                    text: qsTr("Used"),
                    value: (SystemUsage.memUsed / 1048576).toFixed(2) + " GB"
                },
                {
                    text: qsTr("Free"),
                    value: ((SystemUsage.memTotal - SystemUsage.memUsed) / 1048576).toFixed(2) + " GB"
                }
            ]
            delegate: RowLayout {
                id: row

                required property var modelData

                Layout.fillWidth: true
                spacing: Appearance.spacing.small * 0.5

                StyledText {
                    Layout.minimumWidth: 60
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.7)
                    font.pixelSize: Appearance.fonts.size.normal
                    text: row.modelData.text
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    horizontalAlignment: Text.AlignRight
                    text: row.modelData.value
                }
            }
        }

        SliderValues {
            Layout.fillWidth: true
            Layout.topMargin: Appearance.spacing.small
            totalValue: SystemUsage.memTotal / 1048576
            usedValue: SystemUsage.memUsed / 1048576
        }
    }
    component SliderValues: Item {
        id: root

        readonly property real freePercent: 1 - usedPercent
        readonly property real usedPercent: totalValue > 0 ? (usedValue / totalValue) : 0

        property real          totalValue: 100
        property real          usedValue: 0

        implicitHeight: 12

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
            radius: height / 2
        }

        Rectangle {
            id: usedBar

            property color target: Colours.m3Colors.m3Green

            implicitWidth: parent.width * root.usedPercent
            radius: height / 2
            Behavior on implicitWidth {
                SpringAnimation {
                    damping: 0.5
                    spring: 2
                }
            }

            BlendColor {
                host: usedBar
                target: usedBar.target
            }

            anchors {
                bottom: parent.bottom
                left: parent.left
                top: parent.top
            }
        }
    }
}

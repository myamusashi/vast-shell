import QtGraphs
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Services
import qs.Components

PopupWidget {
    icon: "apps"
    text: qsTr("Installed apps")

    content: ColumnLayout {
        PieChart {
            implicitWidth: parent.width
            implicitHeight: 200

            value1: DesktopEntries.applications.values.filter(e => !e.runInTerminal).length
            value2: DesktopEntries.applications.values.filter(e => e.runInTerminal).length
        }

        RowLayout {
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Repeater {
                model: [
                    {
                        color: Colours.m3Colors.m3Green,
                        text: qsTr("Graphic User Interfaces")
                    },
                    {
                        color: Colours.withAlpha(Colours.m3Colors.m3Green, 0.5),
                        text: qsTr("Terminal User Interfaces")
                    }
                ]

                delegate: RowLayout {
                    required property var modelData

                    StyledRect {
                        color: parent.modelData.color
                        implicitWidth: 15
                        implicitHeight: 15
                    }

                    StyledText {
                        text: parent.modelData.text
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }
            }
        }
    }

    component PieChart: GraphsView {
        id: pie

        required property int value1
        required property int value2

        theme: GraphsTheme {
            colorScheme: GraphsTheme.ColorScheme.Dark
            theme: GraphsTheme.Theme.QtGreen
        }

        PieSeries {
            id: pieSeries

            holeSize: 0.5

            PieSlice {
                label: pie.value1
                value: pie.value1
                color: Colours.m3Colors.m3Green
                borderColor: "transparent"
                labelVisible: true
                labelColor: "white"
                labelPosition: PieSlice.LabelPosition.Outside
                labelArmLengthFactor: 0.3
                explodeDistanceFactor: 0.02
            }

            PieSlice {
                label: pie.value2
                value: pie.value2
                color: Colours.withAlpha(Colours.m3Colors.m3Green, 0.5)
                borderColor: "transparent"
                labelVisible: true
                labelColor: "white"
                labelPosition: PieSlice.LabelPosition.Outside
                labelArmLengthFactor: 0.15
                explodeDistanceFactor: 0.02
            }
        }
    }
}

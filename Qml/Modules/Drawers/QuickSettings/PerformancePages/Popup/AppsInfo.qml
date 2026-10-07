import QtQuick
import QtQuick.Layouts
import Quickshell
import QtGraphs

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    icon: "apps"
    text: qsTr("Installed apps")
    content: ColumnLayout {

        PieChart {
            graphicalAppCount: DesktopEntries.applications.values.filter(app => !app.runInTerminal).length
            implicitHeight: 200
            implicitWidth: parent.width
            terminalAppCount: DesktopEntries.applications.values.filter(app => app.runInTerminal).length
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
                        color: Qt.alpha(Colours.m3Colors.m3Green, 0.5),
                        text: qsTr("Terminal User Interfaces")
                    }
                ]
                delegate: RowLayout {
                    required property var modelData

                    StyledRect {
                        color: parent.modelData.color
                        implicitHeight: 15
                        implicitWidth: 15
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: parent.modelData.text
                    }
                }
            }
        }
    }
    component PieChart: GraphsView {
        id: pieChart

        required property int graphicalAppCount
        required property int terminalAppCount

        theme: GraphsTheme {
            colorScheme: GraphsTheme.ColorScheme.Dark
            theme: GraphsTheme.Theme.QtGreen
        }

        PieSeries {
            id: pieSeries

            holeSize: 0.5

            PieSlice {
                borderColor: "transparent"
                color: Colours.m3Colors.m3Green
                explodeDistanceFactor: 0.02
                label: pieChart.graphicalAppCount
                labelArmLengthFactor: 0.3
                labelColor: "white"
                labelPosition: PieSlice.LabelPosition.Outside
                labelVisible: true
                value: pieChart.graphicalAppCount
            }

            PieSlice {
                borderColor: "transparent"
                color: Qt.alpha(Colours.m3Colors.m3Green, 0.5)
                explodeDistanceFactor: 0.02
                label: pieChart.terminalAppCount
                labelArmLengthFactor: 0.15
                labelColor: "white"
                labelPosition: PieSlice.LabelPosition.Outside
                labelVisible: true
                value: pieChart.terminalAppCount
            }
        }
    }
}

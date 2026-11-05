pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import QtGraphs

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    id: root

    readonly property var appCounts: {
        let graphicalCount = 0;
        let terminalCount  = 0;
        const entries      = DesktopEntries.applications.values;
        for (let index = 0; index < entries.length; index++) {
            if (entries[index].runInTerminal)
                terminalCount++;
            else
                graphicalCount++;
        }
        return {
            graphical: graphicalCount,
            terminal: terminalCount
        };
    }

    icon: "apps"
    text: qsTr("Installed apps")
    content: ColumnLayout {

        PieChart {
            graphicalAppCount: root.appCounts.graphical
            implicitHeight: 200
            implicitWidth: root.width
            terminalAppCount: root.appCounts.terminal
        }

        RowLayout {
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter

            Repeater {
                model: [qsTr("Graphic User Interfaces"), qsTr("Terminal User Interfaces")]
                delegate: RowLayout {
                    id: legendRow

                    required property int    index
                    required property string modelData

                    StyledRect {
                        color: legendRow.index === 0 ? Colours.m3Colors.m3Green : Qt.alpha(Colours.m3Colors.m3Green, 0.5)
                        implicitHeight: 15
                        implicitWidth: 15
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        text: legendRow.modelData
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

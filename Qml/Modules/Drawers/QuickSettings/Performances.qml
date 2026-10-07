pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtGraphs

import qs.Core.Configs
import qs.Widgets as WID
import qs.Core.Utils
import qs.Services
import qs.Components.Base

import "."
import "PerformancePages/Popup" as POPUP

Item {
    id: wrapper

    property bool anyPopupVisible: batteryInfoPopup.isVisible || networkInfoPopup.isVisible || displayInfoPopup.isVisible || appsInfoPopup.isVisible || ramInfoPopup.isVisible || diskInfoPopup.isVisible || osInfoPopup.isVisible

    anchors.fill: parent

    ScrollView {
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            id: root

            readonly property string batteryRemaining: FormatTimeUtils.formatBattery(UPower.displayDevice.timeToEmpty ?? 0)
            readonly property int    totalApps: DesktopEntries.applications.values.filter(e => !e.runInTerminal).length
            readonly property int    totalTerminalApps: DesktopEntries.applications.values.filter(e => e.runInTerminal).length

            spacing: Appearance.spacing.small
            width: parent.width

            Item {
                Layout.fillWidth: true
                implicitHeight: cpuLayout.implicitHeight + 50

                WrapperRectangle {
                    anchors.fill: parent
                    color: Colours.m3Colors.m3SurfaceContainer
                    margin: Appearance.margin.normal
                    radius: Appearance.rounding.normal

                    ColumnLayout {
                        id: cpuLayout

                        StyledText {
                            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                            color: Colours.m3Colors.m3Green
                            font.pixelSize: Appearance.fonts.size.large
                            text: qsTr("CPU status")
                        }

                        GridLayout {
                            Layout.alignment: Qt.AlignCenter
                            columns: 1
                            rows: 4

                            Repeater {
                                delegate: StyledText {
                                    required property var modelData

                                    color: Colours.m3Colors.m3OnSurfaceVariant
                                    font.pixelSize: Appearance.fonts.size.large
                                    text: modelData.freqMHz.toFixed(0) + " MHz"
                                }
                                model: ScriptModel {
                                    values: [...SystemUsage.cpuCores]
                                }
                            }
                        }
                    }
                }

                CpuFrequencyGraphic {
                    anchors.fill: parent
                    z: 99
                }
            }

            WrapperRectangle {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3SurfaceContainer
                margin: Appearance.margin.normal
                radius: Appearance.rounding.normal

                RowLayout {

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        text: qsTr("CPU: %1°C").arg(SystemUsage.cpuTemp)
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        text: qsTr("GPU: %1°C").arg(SystemUsage.gpuTemp)
                    }
                }
            }

            GridLayout {
                id: gridOverview

                readonly property int cellHeight: 150

                Layout.fillWidth: true
                columnSpacing: 2
                columns: 2
                rowSpacing: 2
                rows: 3

                StatusCard {
                    isTopLeft: true
                    title: qsTr("Battery")
                    zoomId: batteryInfoPopup
                    zoomTarget: wrapper

                    RowLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.normal

                        WID.Battery {
                            heightBattery: 22
                            widthBattery: 40
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            RowLayout {
                                spacing: Appearance.spacing.small * 0.4

                                StyledText {
                                    color: Colours.m3Colors.m3Green
                                    font.pixelSize: Appearance.fonts.size.normal
                                    font.weight: Font.DemiBold
                                    text: (UPower.displayDevice.percentage * 100).toFixed(0) + "%"
                                }

                                StyledText {
                                    color: Colours.m3Colors.m3Green
                                    font.pixelSize: Appearance.fonts.size.normal
                                    font.weight: Font.DemiBold
                                    text: SystemUsage.batteryTemp + "°C"
                                }
                            }

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: Battery.charging ? qsTr("Charging") : qsTr("Discharging")
                            }

                            StyledText {
                                color: Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.6)
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: qsTr("Rem. ") + root.batteryRemaining
                            }
                        }
                    }
                }

                StatusCard {
                    id: network

                    readonly property bool activeNetwork: Networking.wifiEnabled
                    readonly property bool isWired: SystemUsage.statusWiredInterface === "connected" && activeNetwork

                    isTopRight: true
                    title: qsTr("Network")
                    zoomId: networkInfoPopup
                    zoomTarget: wrapper

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        Icon {
                            color: Colours.m3Colors.m3Green
                            font.pixelSize: Appearance.fonts.size.extraLarge
                            icon: "lan"
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignLeft
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                color: Colours.m3Colors.m3Green
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: network.isWired ? qsTr("Ethernet") : qsTr("Wi-Fi")
                            }

                            Repeater {
                                model: [
                                    {
                                        label: qsTr("Download ↓"),
                                        value: network.isWired ? SystemUsage.formatSpeed(SystemUsage.wiredDownloadSpeed) : SystemUsage.formatSpeed(SystemUsage.wirelessDownloadSpeed)
                                    },
                                    {
                                        label: qsTr("Upload ↑"),
                                        value: network.isWired ? SystemUsage.formatSpeed(SystemUsage.wiredUploadSpeed) : SystemUsage.formatSpeed(SystemUsage.wirelessUploadSpeed)
                                    }
                                ]
                                delegate: RowLayout {
                                    required property var modelData

                                    spacing: Appearance.spacing.small * 0.4

                                    StyledText {
                                        id: netLabelDelegate

                                        Layout.preferredWidth: netLabelMetrics.advanceWidth(netLabelDelegate.text)
                                        color: Colours.m3Colors.m3OnSurfaceVariant
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: Font.DemiBold
                                        text: parent.modelData.label

                                        FontMetrics {
                                            id: netLabelMetrics

                                            font: netLabelDelegate.font
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        color: Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.small
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignRight
                                        maximumLineCount: 2
                                        text: parent.modelData.value
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                color: Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.6)
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                maximumLineCount: 2
                                text: network.isWired ? qsTr("Link speed: ") + SystemUsage.wiredLinkSpeed + " Mbps" : qsTr("Link speed: ") + SystemUsage.wirelessLinkSpeed + " Mbps"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                StatusCard {
                    title: qsTr("Apps")
                    zoomId: appsInfoPopup
                    zoomTarget: wrapper

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                color: Colours.m3Colors.m3Green
                                font.pixelSize: Appearance.fonts.size.extraLarge
                                font.weight: Font.DemiBold
                                text: (root.totalApps + root.totalTerminalApps)
                            }

                            StyledText {
                                color: Colours.m3Colors.m3Green
                                font.pixelSize: Appearance.fonts.size.small
                                text: qsTr("Total")
                            }
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: root.totalApps + qsTr(" GUI")
                            }

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: root.totalTerminalApps + qsTr(" CLI")
                            }
                        }
                    }
                }

                StatusCard {
                    title: qsTr("Display")
                    zoomId: displayInfoPopup
                    zoomTarget: wrapper

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        Icon {
                            color: Colours.m3Colors.m3Green
                            font.pixelSize: Appearance.fonts.size.extraLarge
                            icon: "monitor"
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                Layout.fillWidth: true
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.medium
                                font.weight: Font.DemiBold
                                maximumLineCount: 4
                                text: SystemUsage.gpuName
                                wrapMode: Text.Wrap
                            }

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: qsTr("%1x%2 @ %3Hz").arg(Hypr.focusedMonitor.width).arg(Hypr.focusedMonitor.height).arg(Hypr.focusedMonitor.lastIpcObject.refreshRate.toFixed(0))
                            }
                        }
                    }
                }

                StatusCard {
                    isBottomLeft: true
                    title: qsTr("RAM")
                    zoomId: ramInfoPopup
                    zoomTarget: wrapper

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        Circular {
                            circleColor: Colours.m3Colors.m3Green
                            implicitHeight: 80
                            implicitWidth: 80
                            text: value + "%"
                            textSize: Appearance.fonts.size.small
                            value: Math.round(SystemUsage.memUsed / SystemUsage.memTotal * 100)
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: SystemUsage.memProp.toFixed(0) + qsTr(" GB used")
                            }

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: (SystemUsage.memTotal / 1048576).toFixed(0) + qsTr(" GB total")
                            }
                        }
                    }
                }

                StatusCard {
                    isBottomRight: true
                    title: qsTr("Disk")
                    zoomId: diskInfoPopup
                    zoomTarget: wrapper

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        Circular {
                            circleColor: Colours.m3Colors.m3Green
                            implicitHeight: 80
                            implicitWidth: 80
                            text: value + "%"
                            textSize: Appearance.fonts.size.small
                            value: SystemUsage.diskPercent.toFixed(0)
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: SystemUsage.diskProp.toFixed(0) + qsTr(" GB used")
                            }

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: (SystemUsage.diskTotal / 1048576).toFixed(0) + qsTr(" GB total")
                            }
                        }
                    }
                }
            }

            WrapperRectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: osLayout.implicitHeight
                bottomRightRadius: Appearance.rounding.normal
                color: Colours.m3Colors.m3SurfaceContainer
                margin: Appearance.margin.normal
                radius: Appearance.rounding.small * 0.5

                Item {

                    RowLayout {
                        id: osLayout

                        spacing: Appearance.spacing.normal

                        StyledText {
                            color: Colours.m3Colors.m3Green
                            font.family: Distro.match(SystemUsage.osId, SystemUsage.osIdLike)?.name === "nixos" ? Fonts.mono : Fonts.sans
                            font.pixelSize: Appearance.fonts.size.small * 0.5
                            lineHeight: 1.0
                            text: Distro.ascii(SystemUsage.osId, SystemUsage.osIdLike)
                            textFormat: Text.PlainText
                            wrapMode: Text.NoWrap
                        }

                        ColumnLayout {

                            StyledText {
                                Layout.fillWidth: true
                                color: Colours.m3Colors.m3Green
                                font.pixelSize: Appearance.fonts.size.large * 1.2
                                font.weight: Font.DemiBold
                                maximumLineCount: 2
                                text: SystemUsage.osPrettyName
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                maximumLineCount: 2
                                text: SystemUsage.cpuName
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                Layout.fillWidth: true
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                maximumLineCount: 2
                                text: SystemUsage.kernelName
                                wrapMode: Text.WordWrap
                            }

                            StyledText {
                                color: Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.6)
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: SystemUsage.uptimeFormatted
                            }
                        }
                    }

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: osInfoPopup.openFrom(wrapper)
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    POPUP.BatteryInfo {
        id: batteryInfoPopup

        anchors.centerIn: parent
        z: 99
    }

    POPUP.NetworkInfo {
        id: networkInfoPopup

        anchors.centerIn: parent
        z: 99
    }

    POPUP.DisplayInfo {
        id: displayInfoPopup

        anchors.centerIn: parent
        z: 99
    }

    POPUP.AppsInfo {
        id: appsInfoPopup

        anchors.centerIn: parent
        z: 99
    }

    POPUP.RamInfo {
        id: ramInfoPopup

        anchors.centerIn: parent
        z: 99
    }

    POPUP.DiskInfo {
        id: diskInfoPopup

        anchors.centerIn: parent
        z: 99
    }

    POPUP.OSInfo {
        id: osInfoPopup

        anchors.centerIn: parent
        z: 99
    }

    StyledRect {
        anchors.fill: parent
        color: Qt.alpha(Colours.m3Colors.m3Surface, 0.7)
        visible: wrapper.anyPopupVisible
        z: 98

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: (networkInfoPopup.isVisible = false) || (batteryInfoPopup.isVisible = false) || (displayInfoPopup.isVisible = false) || (appsInfoPopup.isVisible = false) || (ramInfoPopup.isVisible = false) || (diskInfoPopup.isVisible = false) || (osInfoPopup.isVisible = false)
        }
    }

    component CpuFrequencyGraphic: Item {
        id: graph

        readonly property int maxPoints: 30

        property int          counter: -1
        property real         currentValue: 0

        function              pushValue() {
            if (!graphView || graphView.width === 0 || graphView.height === 0)
                return;

            counter += 1;
            currentValue = SystemUsage.cpuPerc;
            dataPoints.append(counter, currentValue);

            if (dataPoints.count > maxPoints + 1)
                dataPoints.removeMultiple(0, dataPoints.count - maxPoints - 1);

            axisX.min = Math.max(0, counter - maxPoints);
            axisX.max = counter;
        }

        Component.onCompleted: Qt.callLater(pushValue)

        Connections {
            function onCpuPercChanged() {
                graph.pushValue();
            }

            target: SystemUsage
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: Appearance.rounding.small * 0.5

            border {
                color: Colours.m3Colors.m3Primary
                width: 1
            }

            GraphsView {
                id: graphView

                anchors.fill: parent
                marginBottom: 1
                marginLeft: 1
                marginRight: 1
                marginTop: 1
                axisX: ValueAxis {
                    id: axisX

                    gridVisible: false
                    lineVisible: false
                    subGridVisible: false
                    visible: false
                }
                axisY: ValueAxis {
                    id: axisY

                    gridVisible: false
                    lineVisible: false
                    max: 100
                    min: 0
                    subGridVisible: false
                    visible: false
                }
                theme: GraphsTheme {
                    backgroundVisible: false
                    borderWidth: 0
                    gridVisible: true
                    plotAreaBackgroundColor: "transparent"
                }

                AreaSeries {
                    borderWidth: 0
                    color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
                    upperSeries: LineSeries {
                        id: dataPoints
                    }
                }

                LineSeries {
                    id: borderLine

                    color: Colours.m3Colors.m3Green
                    width: 2
                }
            }
        }

        Connections {
            function onPointAdded(index) {
                borderLine.append(dataPoints.at(index).x, dataPoints.at(index).y);
            }
            function onPointsRemoved(index, count) {
                borderLine.removeMultiple(index, count);
            }

            target: dataPoints
        }
    }
}

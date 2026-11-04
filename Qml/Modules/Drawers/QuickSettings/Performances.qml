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

            readonly property var    appCounts: {
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
            readonly property string batteryRemaining: FormatTimeUtils.formatBattery(UPower.displayDevice.timeToEmpty ?? 0)
            readonly property int    totalApps: appCounts.graphical
            readonly property int    totalTerminalApps: appCounts.terminal

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
                                model: SystemUsage.cpuCores.length
                                delegate: StyledText {
                                    required property int index

                                    color: Colours.m3Colors.m3OnSurfaceVariant
                                    font.pixelSize: Appearance.fonts.size.large
                                    text: (SystemUsage.cpuCores[index]?.freqMHz ?? 0).toFixed(0) + " MHz"
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

                Layout.fillWidth: true
                columnSpacing: 2
                columns: 2
                rowSpacing: 2
                rows: 3

                StatusCard {
                    isTopLeft: true
                    title: qsTr("Battery")
                    zoomId: batteryInfoPopup

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
                                text: UPower.displayDevice.state === UPowerDeviceState.Charging ? qsTr("Charging") : qsTr("Discharging")
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
                                model: [qsTr("Download ↓"), qsTr("Upload ↑")]
                                delegate: RowLayout {
                                    id: networkSpeedRow

                                    required property int    index
                                    required property string modelData

                                    spacing: Appearance.spacing.small * 0.4

                                    StyledText {
                                        id: netLabelDelegate

                                        Layout.preferredWidth: netLabelMetrics.advanceWidth(netLabelDelegate.text)
                                        color: Colours.m3Colors.m3OnSurfaceVariant
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: Font.DemiBold
                                        text: networkSpeedRow.modelData

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
                                        text: networkSpeedRow.index === 0 ? (network.isWired ? SystemUsage.formatSpeed(SystemUsage.wiredDownloadSpeed) : SystemUsage.formatSpeed(SystemUsage.wirelessDownloadSpeed)) : (network.isWired ? SystemUsage.formatSpeed(SystemUsage.wiredUploadSpeed) : SystemUsage.formatSpeed(SystemUsage.wirelessUploadSpeed))
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

                        readonly property var matchedDistro: Distro.match(SystemUsage.osId, SystemUsage.osIdLike)

                        spacing: Appearance.spacing.normal

                        StyledText {
                            color: Colours.m3Colors.m3Green
                            font.family: osLayout.matchedDistro?.name === "nixos" ? Fonts.mono : Fonts.sans
                            font.pixelSize: Appearance.fonts.size.small * 0.5
                            lineHeight: 1.0
                            text: osLayout.matchedDistro?.ascii ?? Distro.ascii(SystemUsage.osId, SystemUsage.osIdLike)
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

    LazyPopup {
        id: batteryInfoPopup

        sourceComponent: POPUP.BatteryInfo {
            hostItem: wrapper
            isVisible: batteryInfoPopup.isVisible
            zoomOriginX: batteryInfoPopup.zoomOriginX
            zoomOriginY: batteryInfoPopup.zoomOriginY
            onClosed: batteryInfoPopup.isVisible = false
        }
    }

    LazyPopup {
        id: networkInfoPopup

        sourceComponent: POPUP.NetworkInfo {
            hostItem: wrapper
            isVisible: networkInfoPopup.isVisible
            zoomOriginX: networkInfoPopup.zoomOriginX
            zoomOriginY: networkInfoPopup.zoomOriginY
            onClosed: networkInfoPopup.isVisible = false
        }
    }

    LazyPopup {
        id: displayInfoPopup

        sourceComponent: POPUP.DisplayInfo {
            hostItem: wrapper
            isVisible: displayInfoPopup.isVisible
            zoomOriginX: displayInfoPopup.zoomOriginX
            zoomOriginY: displayInfoPopup.zoomOriginY
            onClosed: displayInfoPopup.isVisible = false
        }
    }

    LazyPopup {
        id: appsInfoPopup

        sourceComponent: POPUP.AppsInfo {
            hostItem: wrapper
            isVisible: appsInfoPopup.isVisible
            zoomOriginX: appsInfoPopup.zoomOriginX
            zoomOriginY: appsInfoPopup.zoomOriginY
            onClosed: appsInfoPopup.isVisible = false
        }
    }

    LazyPopup {
        id: ramInfoPopup

        sourceComponent: POPUP.RamInfo {
            hostItem: wrapper
            isVisible: ramInfoPopup.isVisible
            zoomOriginX: ramInfoPopup.zoomOriginX
            zoomOriginY: ramInfoPopup.zoomOriginY
            onClosed: ramInfoPopup.isVisible = false
        }
    }

    LazyPopup {
        id: diskInfoPopup

        sourceComponent: POPUP.DiskInfo {
            hostItem: wrapper
            isVisible: diskInfoPopup.isVisible
            zoomOriginX: diskInfoPopup.zoomOriginX
            zoomOriginY: diskInfoPopup.zoomOriginY
            onClosed: diskInfoPopup.isVisible = false
        }
    }

    LazyPopup {
        id: osInfoPopup

        sourceComponent: POPUP.OSInfo {
            hostItem: wrapper
            isVisible: osInfoPopup.isVisible
            zoomOriginX: osInfoPopup.zoomOriginX
            zoomOriginY: osInfoPopup.zoomOriginY
            onClosed: osInfoPopup.isVisible = false
        }
    }

    StyledRect {
        anchors.fill: parent
        color: Qt.alpha(Colours.m3Colors.m3Surface, 0.7)
        visible: wrapper.anyPopupVisible
        z: 98

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                networkInfoPopup.close();
                batteryInfoPopup.close();
                displayInfoPopup.close();
                appsInfoPopup.close();
                ramInfoPopup.close();
                diskInfoPopup.close();
                osInfoPopup.close();
            }
        }
    }

    component LazyPopup: Loader {
        property bool isVisible: false
        property real zoomOriginX: parent ? parent.width / 2 : 0
        property real zoomOriginY: parent ? parent.height / 2 : 0

        function      close(): void {
            isVisible = false;
        }

        function      openFrom(sourceItem: Item): void {
            if (!sourceItem || !parent)
                return;
            const mappedPoint = sourceItem.mapToItem(parent, sourceItem.width / 2, sourceItem.height / 2);
            zoomOriginX       = mappedPoint.x;
            zoomOriginY       = mappedPoint.y;
            active            = true;
            isVisible         = true;
        }

        active: false
        anchors.centerIn: parent
        asynchronous: false
        z: 99
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
                    borderColor: Colours.m3Colors.m3Green
                    borderWidth: 2
                    color: Qt.alpha(Colours.m3Colors.m3Green, 0.2)
                    upperSeries: LineSeries {
                        id: dataPoints
                    }
                }
            }
        }
    }
}

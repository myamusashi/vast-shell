pragma ComponentBehavior: Bound

import QtGraphs
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower

import qs.Configs
import qs.Widgets as WID
import qs.Helpers
import qs.Services
import qs.Components

import "PerformancePages/Popup" as POPUP

Item {
    id: wrapper

    anchors.fill: parent

    property bool anyPopupVisible: batteryInfoPopup.isVisible || networkInfoPopup.isVisible || displayInfoPopup.isVisible || appsInfoPopup.isVisible || ramInfoPopup.isVisible || diskInfoPopup.isVisible || osInfoPopup.isVisible

    objectName: "rootWrapper"

    ScrollView {
        anchors.fill: parent
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: root

            anchors.fill: parent

            readonly property int totalApps: DesktopEntries.applications.values.filter(e => !e.runInTerminal).length
            readonly property int totalTerminalApps: DesktopEntries.applications.values.filter(e => e.runInTerminal).length
            readonly property string batteryRemaining: formatBatteryTime(UPower.displayDevice.timeToEmpty ?? 0)

            spacing: Appearance.spacing.small

            function formatBatteryTime(seconds) {
                if (seconds <= 0)
                    return qsTr("N/A");

                const minutes = Math.floor(seconds / 60);
                const hours = Math.floor(minutes / 60);
                const remainingMinutes = minutes % 60;

                if (minutes < 60)
                    return minutes + qsTr(" min");

                return remainingMinutes > 0 ? hours + qsTr(" h ") + remainingMinutes + qsTr(" min") : hours + qsTr(" h");
            }

            Item {
                implicitWidth: parent.width
                implicitHeight: cpuLayout.implicitHeight + 50

                WrapperRectangle {
                    anchors.fill: parent
                    margin: Appearance.margin.normal
                    radius: Appearance.rounding.normal
                    color: Colours.m3Colors.m3SurfaceContainer

                    ColumnLayout {
                        id: cpuLayout

                        StyledText {
                            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                            text: qsTr("CPU status")
                            color: Colours.m3Colors.m3Green
                            font.pixelSize: Appearance.fonts.size.large
                        }

                        GridLayout {
                            Layout.alignment: Qt.AlignCenter
                            columns: 1
                            rows: 4

                            Repeater {
                                model: ScriptModel {
                                    values: [...SystemUsage.cpuCores]
                                }

                                delegate: StyledText {
                                    required property var modelData
                                    text: modelData.freqMHz.toFixed(0) + " MHz"
                                    color: Colours.m3Colors.m3OnSurfaceVariant
                                    font.pixelSize: Appearance.fonts.size.large
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
                implicitWidth: parent.width
                margin: Appearance.margin.normal
                radius: Appearance.rounding.normal
                color: Colours.m3Colors.m3SurfaceContainer

                RowLayout {
                    StyledText {
                        text: "CPU: " + SystemUsage.cpuTemp + "°C"
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                    }

                    StyledText {
                        text: "GPU: " + SystemUsage.gpuTemp + "°C"
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                    }
                }
            }

            GridLayout {
                id: gridOverview

                Layout.fillWidth: true
                rows: 3
                columns: 2
                columnSpacing: 2
                rowSpacing: 2

                readonly property int cellHeight: 150

                StatusCard {
                    title: qsTr("Battery")
                    isTopLeft: true
                    zoomId: batteryInfoPopup

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Appearance.spacing.normal

                        WID.Battery {
                            widthBattery: 40
                            heightBattery: 22
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            RowLayout {
                                spacing: Appearance.spacing.small * 0.4

                                StyledText {
                                    text: (UPower.displayDevice.percentage * 100).toFixed(0) + "%"
                                    color: Colours.m3Colors.m3Green
                                    font.pixelSize: Appearance.fonts.size.normal
                                    font.weight: Font.DemiBold
                                }
                                StyledText {
                                    text: SystemUsage.batteryTemp + "°C"
                                    color: Colours.m3Colors.m3Green
                                    font.pixelSize: Appearance.fonts.size.normal
                                    font.weight: Font.DemiBold
                                }
                            }

                            StyledText {
                                text: Battery.charging ? qsTr("Charging") : qsTr("Discharging")
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                text: qsTr("Rem. ") + root.batteryRemaining
                                color: Colours.withAlpha(Colours.m3Colors.m3OnSurfaceVariant, 0.6)
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                StatusCard {
                    id: network

                    title: qsTr("Network")
                    isTopRight: true
                    zoomId: networkInfoPopup

                    readonly property var activeNetwork: {
                        return Network.networks.find(n => n.active) ?? null;
                    }
                    readonly property bool isWired: SystemUsage.statusWiredInterface === "connected" && activeNetwork

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        Icon {
                            icon: "lan"
                            color: Colours.m3Colors.m3Green
                            font.pixelSize: Appearance.fonts.size.extraLarge
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                text: network.isWired ? "Ethernet" : "Wi-Fi"
                                color: Colours.m3Colors.m3Green
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
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
                                        Layout.preferredWidth: contentWidth
                                        text: parent.modelData.label
                                        color: Colours.m3Colors.m3OnSurfaceVariant
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: Font.DemiBold
                                    }

                                    StyledText {
                                        text: parent.modelData.value
                                        color: Colours.m3Colors.m3OnSurface
                                        font.pixelSize: Appearance.fonts.size.normal
                                        font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }

                            StyledText {
                                text: network.isWired ? qsTr("Link speed: ") + SystemUsage.wiredLinkSpeed + " Mbps" : qsTr("Link speed: ") + SystemUsage.wirelessLinkSpeed + " Mbps"
                                color: Colours.withAlpha(Colours.m3Colors.m3OnSurfaceVariant, 0.6)
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignRight
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
                                text: (root.totalApps + root.totalTerminalApps)
                                color: Colours.m3Colors.m3Green
                                font.pixelSize: Appearance.fonts.size.extraLarge
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                text: qsTr("Total")
                                color: Colours.m3Colors.m3Green
                                font.pixelSize: Appearance.fonts.size.small
                            }
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                text: root.totalApps + qsTr(" GUI")
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                            }
                            StyledText {
                                text: root.totalTerminalApps + qsTr(" CLI")
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
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
                            icon: "monitor"
                            color: Colours.m3Colors.m3Green
                            font.pixelSize: Appearance.fonts.size.extraLarge
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                Layout.fillWidth: true
                                text: SystemUsage.gpuName
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.medium
                                font.weight: Font.DemiBold
                                maximumLineCount: 4
                                wrapMode: Text.Wrap
                            }

                            StyledText {
                                text: "%1x%2 @ %3Hz".arg(Hypr.focusedMonitor.width).arg(Hypr.focusedMonitor.height).arg(Hypr.focusedMonitor.lastIpcObject.refreshRate.toFixed(0))
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                StatusCard {
                    title: "RAM"
                    zoomId: ramInfoPopup
                    isBottomLeft: true

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        Circular {
                            value: Math.round(SystemUsage.memUsed / SystemUsage.memTotal * 100)
                            circleColor: Colours.m3Colors.m3Green
                            text: value + "%"
                            textSize: Appearance.fonts.size.small
                            fixedSize: 80
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                text: SystemUsage.memProp.toFixed(0) + qsTr(" GB used")
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                text: (SystemUsage.memTotal / 1048576).toFixed(0) + qsTr(" GB total")
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                StatusCard {
                    title: "Disk"
                    zoomId: diskInfoPopup
                    isBottomRight: true

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        Circular {
                            value: SystemUsage.diskPercent.toFixed(0)
                            circleColor: Colours.m3Colors.m3Green
                            text: value + "%"
                            textSize: Appearance.fonts.size.small
                            fixedSize: 80
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.small * 0.4

                            StyledText {
                                text: SystemUsage.diskProp.toFixed(0) + qsTr(" GB used")
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                            }

                            StyledText {
                                text: (SystemUsage.diskTotal / 1048576).toFixed(0) + qsTr(" GB total")
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            WrapperRectangle {
                Layout.fillWidth: true
                margin: Appearance.margin.normal
                radius: Appearance.rounding.small * 0.5
                bottomRightRadius: Appearance.rounding.normal
                color: Colours.m3Colors.m3SurfaceContainer

                RowLayout {
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: {
                            const osName = SystemUsage.osName.toLowerCase();
                            const match = DistroAscii.listDistro.find(distro => osName.includes(distro.toLowerCase()));
                            return match ? DistroAscii[match] : "Unknown";
                        }
                        color: Colours.m3Colors.m3Green
                        font.pixelSize: Appearance.fonts.size.small * 0.5
                        font.family: SystemUsage.osName.toLowerCase() === "nixos" ? Appearance.fonts.family.mono : Appearance.fonts.family.sans
                        textFormat: Text.PlainText
                        lineHeight: 1.0
                        wrapMode: Text.NoWrap
                    }

                    ColumnLayout {
                        StyledText {
                            text: SystemUsage.osPrettyName
                            color: Colours.m3Colors.m3Green
                            font.pixelSize: Appearance.fonts.size.large * 1.2
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            text: SystemUsage.cpuName
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            text: SystemUsage.kernelName
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            text: SystemUsage.uptimeFormatted
                            color: Colours.withAlpha(Colours.m3Colors.m3OnSurfaceVariant, 0.6)
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.DemiBold
                        }
                    }

                    MArea {
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var cardCenter = osInfoPopup.mapToItem(wrapper, osInfoPopup.width / 2, osInfoPopup.height / 2);

                            osInfoPopup.zoomOriginX = cardCenter.x;
                            osInfoPopup.zoomOriginY = cardCenter.y;
                            osInfoPopup.isVisible = true;
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    component StatusCard: WrapperRectangle {
        id: card

        default property alias content: contentLayout.data
        required property string title
        property bool isTopLeft: false
        property bool isTopRight: false
        property bool isBottomLeft: false
        property bool isBottomRight: false
        property var zoomId: null

        Layout.fillWidth: true
        implicitWidth: width * 0.5
        Layout.preferredHeight: gridOverview.cellHeight
        margin: Appearance.margin.normal
        radius: Appearance.rounding.small * 0.5

        topLeftRadius: isTopLeft ? Appearance.rounding.normal : radius
        topRightRadius: isTopRight ? Appearance.rounding.normal : radius
        bottomLeftRadius: isBottomLeft ? Appearance.rounding.normal : radius
        bottomRightRadius: isBottomRight ? Appearance.rounding.normal : radius

        color: Colours.m3Colors.m3SurfaceContainer

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: card.margin
                spacing: Appearance.spacing.small

                StyledText {
                    text: card.title
                    color: Colours.m3Colors.m3Green
                    font.pixelSize: Appearance.fonts.size.large
                }

                ColumnLayout {
                    id: contentLayout

                    spacing: Appearance.spacing.small
                }
            }

            MArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                layerRadius: (card.isTopLeft ? card.topLeftRadius : card.isTopRight ? card.topRightRadius : card.isBottomRight ? card.bottomRightRadius : card.isBottomLeft ? card.bottomLeftRadius : card.radius)
                onClicked: {
                    var cardCenter = card.mapToItem(wrapper, card.width / 2, card.height / 2);

                    card.zoomId.zoomOriginX = cardCenter.x;
                    card.zoomId.zoomOriginY = cardCenter.y;
                    card.zoomId.isVisible = true;
                }
            }
        }
    }

    component CpuFrequencyGraphic: Item {
        id: graph

        readonly property int maxPoints: 30
        property int counter: -1
        property real currentValue: 0

        function pushValue() {
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
            target: SystemUsage
            function onCpuPercChanged() {
                graph.pushValue();
            }
        }

        Rectangle {
            anchors.fill: parent
            border {
                color: Colours.m3Colors.m3Primary
                width: 1
            }
            color: "transparent"
            radius: Appearance.rounding.small * 0.5

            GraphsView {
                id: graphView

                anchors.fill: parent
                marginBottom: 1
                marginTop: 1
                marginLeft: 1
                marginRight: 1

                theme: GraphsTheme {
                    backgroundVisible: false
                    plotAreaBackgroundColor: "transparent"
                    gridVisible: true
                    borderWidth: 0
                }

                axisX: ValueAxis {
                    id: axisX

                    visible: false
                    lineVisible: false
                    gridVisible: false
                    subGridVisible: false
                }

                axisY: ValueAxis {
                    id: axisY

                    visible: false
                    lineVisible: false
                    gridVisible: false
                    subGridVisible: false
                    max: 100
                    min: 0
                }

                AreaSeries {
                    color: Colours.withAlpha(Colours.m3Colors.m3Green, 0.2)
                    borderWidth: 0

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
            target: dataPoints

            function onPointAdded(index) {
                borderLine.append(dataPoints.at(index).x, dataPoints.at(index).y);
            }

            function onPointsRemoved(index, count) {
                borderLine.removeMultiple(index, count);
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
        visible: wrapper.anyPopupVisible
        color: Colours.withAlpha(Colours.m3Colors.m3Surface, 0.7)
        z: 98

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: (networkInfoPopup.isVisible = false) || (batteryInfoPopup.isVisible = false) || (displayInfoPopup.isVisible = false) || (appsInfoPopup.isVisible = false) || (ramInfoPopup.isVisible = false) || (diskInfoPopup.isVisible = false) || (osInfoPopup.isVisible = false)
        }
    }
}

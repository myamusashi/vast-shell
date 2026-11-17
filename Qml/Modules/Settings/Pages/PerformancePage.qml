pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Services.UPower
import QtGraphs

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Widgets as WID

import "../Components"

SettingsPageBase {
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
    readonly property bool   isWiredNetwork: SystemUsage.statusWiredInterface === "connected" && (Networking.wifiEnabled ?? false)
    readonly property real   maxCoreFrequencyMHz: {
        let peak    = 3000;
        const cores = SystemUsage.cpuCores ?? [];
        for (let index = 0; index < cores.length; index++) {
            if (cores[index].freqMHz > peak)
                peak = cores[index].freqMHz;
        }
        return peak;
    }
    readonly property var    monitorEntries: {
        const list = [];
        for (const name in Hypr.monitorData) {
            const monitor = Hypr.monitorData[name];
            list.push({
                name: name,
                description: monitor.description ?? "",
                resolution: monitor.resolution ?? "",
                scale: monitor.scale ?? 1,
                refreshRate: monitor.refreshRate ?? 0,
                colorManagementPreset: monitor.colorManagementPreset ?? ""
            });
        }
        return list;
    }
    readonly property int    totalApps: appCounts.graphical + appCounts.terminal

    function                 formatStoragePercent(part: real, total: real): string {
        if (total <= 0)
            return "0%";
        return Math.round((part / total) * 100) + "%";
    }

    pageTitle: qsTr("System Monitor")
    Component.onCompleted: SystemUsage.ensureGraphicsInfoLoaded()

    SettingsCard {
        title: qsTr("CPU & Thermals")

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.DemiBold
                    text: SystemUsage.cpuName || qsTr("Processor")
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    text: qsTr("%1 logical cores").arg((SystemUsage.cpuCores ?? []).length)
                }
            }

            MetricBadge {
                accentColor: Colours.m3Colors.m3Green
                label: qsTr("Load")
                valueText: SystemUsage.cpuPerc + "%"
            }

            MetricBadge {
                accentColor: Colours.m3Colors.m3Primary
                label: qsTr("CPU Temp")
                valueText: SystemUsage.cpuTemp + "°C"
            }

            MetricBadge {
                accentColor: Colours.m3Colors.m3Tertiary
                label: qsTr("GPU Temp")
                valueText: SystemUsage.gpuTemp + "°C"
            }
        }

        CpuUsageGraph {
            Layout.fillWidth: true
            Layout.preferredHeight: 170

            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: Appearance.margin.small
                anchors.top: parent.top
                z: 1

                StyledText {
                    color: Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.8)
                    font.family: Fonts.mono
                    font.pixelSize: Appearance.fonts.size.small
                    text: "100%"
                }

                Item {
                    Layout.fillHeight: true
                }

                StyledText {
                    color: Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.8)
                    font.family: Fonts.mono
                    font.pixelSize: Appearance.fonts.size.small
                    text: "50%"
                }

                Item {
                    Layout.fillHeight: true
                }

                StyledText {
                    color: Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.8)
                    font.family: Fonts.mono
                    font.pixelSize: Appearance.fonts.size.small
                    text: "0%"
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columnSpacing: Appearance.spacing.normal
            columns: 3
            rowSpacing: Appearance.spacing.normal

            Repeater {
                model: SystemUsage.cpuCores
                delegate: Rectangle {
                    id: coreDelegate

                    required property int freqMHz
                    required property int index

                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3SurfaceContainer
                    implicitHeight: coreColumn.implicitHeight + Appearance.margin.normal * 2
                    radius: Appearance.rounding.normal

                    ColumnLayout {
                        id: coreColumn

                        anchors.fill: parent
                        anchors.margins: Appearance.margin.normal
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                                text: qsTr("Core %1").arg(coreDelegate.index)
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.family: Fonts.mono
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: `${coreDelegate.freqMHz} MHz`
                            }
                        }

                        UsageBar {
                            Layout.fillWidth: true
                            barHeight: 6
                            fillColor: Colours.m3Colors.m3Green
                            ratio: root.maxCoreFrequencyMHz > 0 ? coreDelegate.freqMHz / root.maxCoreFrequencyMHz : 0
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        id: memoryCard

        readonly property real freeGiB: Math.max(0, totalGiB - usedGiB)
        readonly property real totalGiB: SystemUsage.memTotal / 1048576
        readonly property real usedGiB: SystemUsage.memUsed / 1048576
        readonly property int  usedPercent: SystemUsage.memTotal > 0 ? Math.round((SystemUsage.memUsed / SystemUsage.memTotal) * 100) : 0

        title: qsTr("Memory (RAM)")

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.large

            Circular {
                circleColor: Colours.m3Colors.m3Green
                implicitHeight: 96
                implicitWidth: 96
                text: value + "%"
                textSize: Appearance.fonts.size.medium
                value: memoryCard.usedPercent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        text: qsTr("RAM Size")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Colours.m3Colors.m3Green
                        font.family: Fonts.mono
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.DemiBold
                        text: memoryCard.totalGiB.toFixed(2) + " GiB"
                    }
                }

                UsageBar {
                    Layout.fillWidth: true
                    barHeight: 14
                    fillColor: Colours.m3Colors.m3Green
                    ratio: SystemUsage.memTotal > 0 ? SystemUsage.memUsed / SystemUsage.memTotal : 0
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.large

                    LegendValue {
                        swatchColor: Colours.m3Colors.m3Green
                        label: qsTr("Used")
                        valueText: memoryCard.usedGiB.toFixed(2) + " GiB"
                    }

                    LegendValue {
                        swatchColor: Qt.alpha(Colours.m3Colors.m3Green, 0.25)
                        label: qsTr("Free")
                        valueText: memoryCard.freeGiB.toFixed(2) + " GiB"
                    }
                }
            }
        }
    }

    SettingsCard {
        id: storageCard

        readonly property real totalStorageKiB: SystemUsage.storageFree + SystemUsage.storageSystem + SystemUsage.storageAppsData

        title: qsTr("Storage & Filesystems")

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.large

            Circular {
                circleColor: Colours.m3Colors.m3Primary
                implicitHeight: 96
                implicitWidth: 96
                text: value + "%"
                textSize: Appearance.fonts.size.medium
                value: Math.round(SystemUsage.diskPercent)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.DemiBold
                        text: SystemUsage.diskUsedGiB.toFixed(0) + qsTr(" GiB used")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.family: Fonts.mono
                        font.pixelSize: Appearance.fonts.size.normal
                        text: (SystemUsage.diskTotal / 1048576).toFixed(0) + qsTr(" GiB total")
                    }
                }

                StorageSegmentedBar {
                    Layout.fillWidth: true
                    appsValue: SystemUsage.storageAppsData
                    freeValue: SystemUsage.storageFree
                    systemValue: SystemUsage.storageSystem
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    LegendValue {
                        Layout.fillWidth: true
                        swatchColor: Colours.m3Colors.m3Primary
                        label: qsTr("Root (%1)").arg(root.formatStoragePercent(SystemUsage.storageAppsData, storageCard.totalStorageKiB))
                        valueText: SystemUsage.formatKiB(SystemUsage.storageAppsData)
                    }

                    LegendValue {
                        Layout.fillWidth: true
                        swatchColor: Colours.m3Colors.m3Tertiary
                        label: qsTr("Boot (%1)").arg(root.formatStoragePercent(SystemUsage.storageSystem, storageCard.totalStorageKiB))
                        valueText: SystemUsage.formatKiB(SystemUsage.storageSystem)
                    }

                    LegendValue {
                        Layout.fillWidth: true
                        swatchColor: Colours.m3Colors.m3SurfaceContainerHighest
                        label: qsTr("Free (%1)").arg(root.formatStoragePercent(SystemUsage.storageFree, storageCard.totalStorageKiB))
                        valueText: SystemUsage.formatKiB(SystemUsage.storageFree)
                    }
                }
            }
        }

        StyledText {
            Layout.topMargin: Appearance.spacing.small
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            text: qsTr("Internal Storage")
        }

        GridLayout {
            Layout.fillWidth: true
            columnSpacing: Appearance.spacing.normal
            columns: 2
            rowSpacing: Appearance.spacing.normal

            Repeater {
                model: SystemUsage.filesystems
                delegate: Rectangle {
                    id: fsDelegate

                    required property string deviceName
                    required property string filesystemType
                    required property string formattedFree
                    required property string formattedTotal
                    required property string formattedUsed
                    required property string mountPoint
                    required property real   totalKiB
                    required property real   usedKiB

                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3SurfaceContainer
                    implicitHeight: fsColumn.implicitHeight + Appearance.margin.normal * 2
                    radius: Appearance.rounding.normal

                    ColumnLayout {
                        id: fsColumn

                        anchors.fill: parent
                        anchors.margins: Appearance.margin.normal
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.small

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: fsDelegate.mountPoint || fsDelegate.deviceName
                            }

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.family: Fonts.mono
                                font.pixelSize: Appearance.fonts.size.small
                                text: fsDelegate.deviceName
                                visible: fsDelegate.deviceName !== "" && fsDelegate.mountPoint !== ""
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                color: Colours.m3Colors.m3SecondaryContainer
                                implicitHeight: fsTypeText.implicitHeight + 6
                                implicitWidth: fsTypeText.implicitWidth + 14
                                radius: Appearance.rounding.small
                                visible: fsDelegate.filesystemType !== ""

                                StyledText {
                                    id: fsTypeText

                                    anchors.centerIn: parent
                                    color: Colours.m3Colors.m3OnSecondaryContainer
                                    font.family: Fonts.mono
                                    font.pixelSize: Appearance.fonts.size.small
                                    text: fsDelegate.filesystemType
                                }
                            }
                        }

                        UsageBar {
                            Layout.fillWidth: true
                            barHeight: 10
                            fillColor: Colours.m3Colors.m3Primary
                            ratio: fsDelegate.totalKiB > 0 ? fsDelegate.usedKiB / fsDelegate.totalKiB : 0
                            visible: fsDelegate.usedKiB > 0 || fsDelegate.totalKiB > 0
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.small
                                text: qsTr("Used: %1").arg(fsDelegate.formattedUsed)
                                visible: fsDelegate.formattedUsed !== ""
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                                text: qsTr("Free: %1 · Total: %2").arg(fsDelegate.formattedFree).arg(fsDelegate.formattedTotal)
                                visible: fsDelegate.formattedTotal !== ""
                            }
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("Battery")

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            WID.Battery {
                heightBattery: 24
                widthBattery: 44
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledText {
                        color: Colours.m3Colors.m3Green
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.DemiBold
                        text: (UPower.displayDevice.percentage * 100).toFixed(0) + "%"
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        text: Battery.charging ? qsTr("Charging") : qsTr("Discharging")
                    }
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    text: qsTr("Remaining: %1").arg(root.batteryRemaining)
                }
            }

            MetricBadge {
                accentColor: Colours.m3Colors.m3Green
                label: qsTr("Temp")
                valueText: SystemUsage.batteryTemp + "°C"
            }

            MetricBadge {
                accentColor: Colours.m3Colors.m3Primary
                label: qsTr("Health")
                valueText: Battery.overallBatteryHealth + "%"
            }

            MetricBadge {
                accentColor: Colours.m3Colors.m3Secondary
                label: qsTr("Technology")
                valueText: SystemUsage.batteryTechnologies || qsTr("Unknown")
            }

            MetricBadge {
                accentColor: Colours.m3Colors.m3Tertiary
                label: qsTr("Voltage")
                valueText: UPower.displayDevice.energyCapacity + " V"
            }
        }

        UsageBar {
            Layout.fillWidth: true
            barHeight: 12
            fillColor: Colours.m3Colors.m3Green
            ratio: UPower.displayDevice.percentage
        }

        GridLayout {
            Layout.fillWidth: true
            columnSpacing: Appearance.spacing.normal
            columns: 2
            rowSpacing: Appearance.spacing.normal

            Repeater {
                model: Battery.batteries
                delegate: Rectangle {
                    id: batteryDelegate

                    required property var  modelData

                    readonly property real capacityRatio: (modelData?.designCapacity ?? 0) > 0 ? (modelData.currentCapacity / modelData.designCapacity) : 0

                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3SurfaceContainer
                    implicitHeight: batteryUnitCol.implicitHeight + Appearance.margin.normal * 2
                    radius: Appearance.rounding.normal

                    ColumnLayout {
                        id: batteryUnitCol

                        anchors.fill: parent
                        anchors.margins: Appearance.margin.normal
                        spacing: Appearance.spacing.small

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: batteryDelegate.modelData?.name ?? qsTr("Battery")
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                color: Colours.m3Colors.m3Green
                                font.family: Fonts.mono
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Font.DemiBold
                                text: qsTr("Health: %1%").arg(batteryDelegate.modelData?.health ?? 0)
                            }
                        }

                        UsageBar {
                            Layout.fillWidth: true
                            barHeight: 8
                            fillColor: Colours.m3Colors.m3Green
                            ratio: batteryDelegate.capacityRatio
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                                text: qsTr("Current: %1").arg(Battery.formatCapacity(batteryDelegate.modelData?.currentCapacity ?? 0))
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.small
                                text: qsTr("Design: %1").arg(Battery.formatCapacity(batteryDelegate.modelData?.designCapacity ?? 0))
                            }
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("Network")

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            Icon {
                color: Colours.m3Colors.m3Green
                font.pixelSize: Appearance.fonts.size.extraLarge
                icon: root.isWiredNetwork ? "lan" : "network_wifi"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.DemiBold
                    text: root.isWiredNetwork ? qsTr("Ethernet") : qsTr("Wi-Fi")
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    text: root.isWiredNetwork ? qsTr("Connected") : qsTr("Signal: -70 dBm")
                }
            }

            MetricBadge {
                accentColor: Colours.m3Colors.m3Green
                label: qsTr("Download ↓")
                valueText: root.isWiredNetwork ? SystemUsage.formatSpeedMiBps(SystemUsage.wiredDownloadSpeed) : SystemUsage.formatSpeedMiBps(SystemUsage.wirelessDownloadSpeed)
            }

            MetricBadge {
                accentColor: Colours.m3Colors.m3Primary
                label: qsTr("Upload ↑")
                valueText: root.isWiredNetwork ? SystemUsage.formatSpeedMiBps(SystemUsage.wiredUploadSpeed) : SystemUsage.formatSpeedMiBps(SystemUsage.wirelessUploadSpeed)
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columnSpacing: Appearance.spacing.large
            columns: 2
            rowSpacing: Appearance.spacing.small

            InfoPair {
                label: qsTr("Status")
                valueText: root.isWiredNetwork ? qsTr("Connected") : qsTr("Disconnected")
            }

            InfoPair {
                label: qsTr("Link speed")
                valueText: (root.isWiredNetwork ? SystemUsage.wiredLinkSpeed : SystemUsage.wirelessLinkSpeed) + " Mbps"
            }

            InfoPair {
                label: qsTr("Signal strength")
                valueText: root.isWiredNetwork ? "0 dBm" : "-70 dBm"
            }

            InfoPair {
                label: qsTr("Total wireless download")
                valueText: SystemUsage.formatUsageMiB(SystemUsage.totalWirelessDownloadUsage)
            }

            InfoPair {
                label: qsTr("Total wireless upload")
                valueText: SystemUsage.formatUsageMiB(SystemUsage.totalWirelessUploadUsage)
            }

            InfoPair {
                label: qsTr("Total wired download")
                valueText: SystemUsage.formatUsageMiB(SystemUsage.totalWiredDownloadUsage)
            }

            InfoPair {
                label: qsTr("Total wired upload")
                valueText: SystemUsage.formatUsageMiB(SystemUsage.totalWiredUploadUsage)
            }
        }
    }

    SettingsCard {
        title: qsTr("Display & Graphics")

        InfoPair {
            label: qsTr("GPU")
            valueText: SystemUsage.gpuName || qsTr("N/A")
        }

        GridLayout {
            Layout.fillWidth: true
            columnSpacing: Appearance.spacing.large
            columns: 2
            rowSpacing: Appearance.spacing.small

            InfoPair {
                label: qsTr("Vulkan")
                valueText: SystemUsage.vulkanAvailable ? SystemUsage.vulkanVersion : qsTr("Not available")
            }

            InfoPair {
                label: qsTr("OpenGL")
                valueText: SystemUsage.openglAvailable ? SystemUsage.openglVersion : qsTr("Not available")
            }

            InfoPair {
                label: qsTr("VA-API Driver")
                valueText: SystemUsage.vaApiDriver || qsTr("N/A")
            }

            InfoPair {
                label: qsTr("OpenGL Vendor")
                valueText: SystemUsage.openglVendor || qsTr("N/A")
            }
        }

        InfoPair {
            label: qsTr("OpenGL Renderer")
            valueText: SystemUsage.openglRenderer || qsTr("N/A")
        }

        StyledText {
            Layout.topMargin: Appearance.spacing.small
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            text: qsTr("Connected Monitors")
        }

        Repeater {
            model: root.monitorEntries
            delegate: Rectangle {
                id: monitorDelegate

                required property var modelData

                Layout.fillWidth: true
                color: Colours.m3Colors.m3SurfaceContainer
                implicitHeight: monitorCol.implicitHeight + Appearance.margin.normal * 2
                radius: Appearance.rounding.normal

                ColumnLayout {
                    id: monitorCol

                    anchors.fill: parent
                    anchors.margins: Appearance.margin.normal
                    spacing: Appearance.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3Green
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        text: monitorDelegate.modelData.description || monitorDelegate.modelData.name
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columnSpacing: Appearance.spacing.large
                        columns: 2
                        rowSpacing: Appearance.spacing.small * 0.5

                        InfoPair {
                            label: qsTr("Resolution")
                            valueText: monitorDelegate.modelData.resolution
                        }

                        InfoPair {
                            label: qsTr("Refresh Rate")
                            valueText: monitorDelegate.modelData.refreshRate + " Hz"
                        }

                        InfoPair {
                            label: qsTr("Scale")
                            valueText: String(monitorDelegate.modelData.scale)
                        }

                        InfoPair {
                            label: qsTr("Color Management")
                            valueText: monitorDelegate.modelData.colorManagementPreset || qsTr("N/A")
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("Installed Applications")

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.large

            GraphsView {
                Layout.preferredHeight: 160
                Layout.preferredWidth: 160
                theme: GraphsTheme {
                    colorScheme: GraphsTheme.ColorScheme.Dark
                    theme: GraphsTheme.Theme.QtGreen
                }

                PieSeries {
                    holeSize: 0.55

                    PieSlice {
                        borderColor: "transparent"
                        color: Colours.m3Colors.m3Green
                        explodeDistanceFactor: 0.02
                        label: String(root.appCounts.graphical)
                        labelColor: Colours.m3Colors.m3OnSurface
                        labelPosition: PieSlice.LabelPosition.Outside
                        labelVisible: true
                        value: root.appCounts.graphical
                    }

                    PieSlice {
                        borderColor: "transparent"
                        color: Qt.alpha(Colours.m3Colors.m3Green, 0.45)
                        explodeDistanceFactor: 0.02
                        label: String(root.appCounts.terminal)
                        labelColor: Colours.m3Colors.m3OnSurface
                        labelPosition: PieSlice.LabelPosition.Outside
                        labelVisible: true
                        value: root.appCounts.terminal
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        text: qsTr("Total Installed")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Colours.m3Colors.m3Green
                        font.family: Fonts.mono
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        font.weight: Font.DemiBold
                        text: String(root.totalApps)
                    }
                }

                UsageBar {
                    Layout.fillWidth: true
                    barHeight: 12
                    fillColor: Colours.m3Colors.m3Green
                    ratio: root.totalApps > 0 ? root.appCounts.graphical / root.totalApps : 0
                }

                LegendValue {
                    swatchColor: Colours.m3Colors.m3Green
                    label: qsTr("Graphical User Interfaces")
                    valueText: qsTr("%1 apps").arg(root.appCounts.graphical)
                }

                LegendValue {
                    swatchColor: Qt.alpha(Colours.m3Colors.m3Green, 0.45)
                    label: qsTr("Terminal User Interfaces")
                    valueText: qsTr("%1 apps").arg(root.appCounts.terminal)
                }
            }
        }
    }

    component CpuUsageGraph: Rectangle {
        id: graph

        readonly property int maxPoints: 30

        property var          samples: []

        function              packVec4(startIndex: int): vector4d {
            const list = graph.samples;
            const v0   = startIndex < list.length ? list[startIndex] : 0;
            const v1   = startIndex + 1 < list.length ? list[startIndex + 1] : v0;
            const v2   = startIndex + 2 < list.length ? list[startIndex + 2] : v1;
            const v3   = startIndex + 3 < list.length ? list[startIndex + 3] : v2;
            return Qt.vector4d(v0, v1, v2, v3);
        }

        function              pushValue(): void {
            const next = graph.samples.slice();
            next.push(Math.max(0, Math.min(1, SystemUsage.cpuPerc / 100.0)));
            if (next.length > maxPoints)
                next.shift();
            graph.samples = next;
            if (graph.visible && GlobalStates.isSettingsOpen)
                syncUniforms();
        }

        function              syncUniforms(): void {
            const count = graph.samples.length;
            if (count < 2)
                return;
            graphShader.pointCount = count;
            graphShader.p0         = packVec4(0);
            graphShader.p1         = packVec4(4);
            graphShader.p2         = packVec4(8);
            graphShader.p3         = packVec4(12);
            graphShader.p4         = packVec4(16);
            graphShader.p5         = packVec4(20);
            graphShader.p6         = packVec4(24);
            graphShader.p7         = packVec4(28);
        }

        border.color: Colours.m3Colors.m3OutlineVariant
        border.width: 1
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.small
        Component.onCompleted: {
            const initial = Math.max(0, Math.min(1, SystemUsage.cpuPerc / 100.0));
            graph.samples = [initial, initial];
            syncUniforms();
        }
        onVisibleChanged: {
            if (visible)
                syncUniforms();
        }

        Connections {

            function onCpuPercChanged(): void {
                graph.pushValue();
            }

            target: SystemUsage
        }

        Connections {

            function onIsSettingsOpenChanged(): void {
                if (GlobalStates.isSettingsOpen && graph.visible)
                    graph.syncUniforms();
            }

            target: GlobalStates
        }

        ShaderEffect {
            id: graphShader

            property color    fillColor: Qt.alpha(Colours.m3Colors.m3Green, 0.22)
            property color    gridColor: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.35)
            property real     gridLines: 4
            property color    lineColor: Colours.m3Colors.m3Green
            property real     lineWidth: 2.2
            property vector4d p0: Qt.vector4d(0, 0, 0, 0)
            property vector4d p1: Qt.vector4d(0, 0, 0, 0)
            property vector4d p2: Qt.vector4d(0, 0, 0, 0)
            property vector4d p3: Qt.vector4d(0, 0, 0, 0)
            property vector4d p4: Qt.vector4d(0, 0, 0, 0)
            property vector4d p5: Qt.vector4d(0, 0, 0, 0)
            property vector4d p6: Qt.vector4d(0, 0, 0, 0)
            property vector4d p7: Qt.vector4d(0, 0, 0, 0)
            property real     pointCount: 2
            property vector2d resolution: Qt.vector2d(width, height)

            anchors.fill: parent
            anchors.margins: 1
            blending: true
            fragmentShader: Paths.projectRoot + "/Assets/shaders/cpuGraph.frag.qsb"
        }
    }
    component InfoPair: RowLayout {
        id: infoPair

        property alias label: pairLabel.text
        property alias valueText: pairValue.text

        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            id: pairLabel

            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
        }

        Item {
            Layout.fillWidth: true
        }

        StyledText {
            id: pairValue

            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.WordWrap
        }
    }
    component LegendValue: RowLayout {
        id: legendItem

        property alias label: legendLabel.text
        property color swatchColor: Colours.m3Colors.m3Primary
        property alias valueText: legendValue.text

        spacing: Appearance.spacing.small

        Rectangle {
            color: legendItem.swatchColor
            implicitHeight: 12
            implicitWidth: 12
            radius: 3
        }

        StyledText {
            id: legendLabel

            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
        }

        StyledText {
            id: legendValue

            color: Colours.m3Colors.m3OnSurface
            font.family: Fonts.mono
            font.pixelSize: Appearance.fonts.size.small
            font.weight: Font.DemiBold
        }
    }
    component MetricBadge: Rectangle {
        id: badge

        property color accentColor: Colours.m3Colors.m3Primary
        property alias label: badgeLabel.text
        property alias valueText: badgeValue.text

        color: Colours.m3Colors.m3SurfaceContainer
        implicitHeight: badgeLayout.implicitHeight + Appearance.margin.small * 2
        implicitWidth: badgeLayout.implicitWidth + Appearance.margin.normal * 2
        radius: Appearance.rounding.small

        ColumnLayout {
            id: badgeLayout

            anchors.centerIn: parent
            spacing: 1

            StyledText {
                id: badgeLabel

                Layout.alignment: Qt.AlignHCenter
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
            }

            StyledText {
                id: badgeValue

                Layout.alignment: Qt.AlignHCenter
                color: badge.accentColor
                font.family: Fonts.mono
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
            }
        }
    }
    component StorageSegmentedBar: Item {
        id: segBar

        readonly property real appsRatio: total > 0 ? Math.max(0, Math.min(1, appsValue / total)) : 0
        readonly property real systemPlusAppsRatio: total > 0 ? Math.max(0, Math.min(1, (systemValue + appsValue) / total)) : 0
        readonly property real total: freeValue + systemValue + appsValue

        property real          appsValue: 0
        property real          freeValue: 0
        property real          systemValue: 0

        implicitHeight: 14

        Rectangle {
            anchors.fill: parent
            color: Colours.m3Colors.m3SurfaceContainerHighest
            radius: height / 2
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.top: parent.top
            color: Colours.m3Colors.m3Tertiary
            radius: height / 2
            width: Math.round(parent.width * segBar.systemPlusAppsRatio)
            z: 1
            Behavior on width {
                SpringAnimation {
                    damping: 0.6
                    epsilon: 0.5
                    spring: 2.5
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.top: parent.top
            color: Colours.m3Colors.m3Primary
            radius: height / 2
            width: Math.round(parent.width * segBar.appsRatio)
            z: 2
            Behavior on width {
                SpringAnimation {
                    damping: 0.6
                    epsilon: 0.5
                    spring: 2.5
                }
            }
        }
    }
    component UsageBar: Item {
        id: usageBar

        readonly property real clampedRatio: Math.max(0, Math.min(1, ratio))

        property int           barHeight: 12
        property color         fillColor: Colours.m3Colors.m3Green
        property real          ratio: 0
        property color         trackColor: Qt.alpha(fillColor, 0.2)

        implicitHeight: barHeight

        Rectangle {
            anchors.fill: parent
            color: usageBar.trackColor
            radius: height / 2
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.top: parent.top
            color: usageBar.fillColor
            radius: height / 2
            width: Math.round(parent.width * usageBar.clampedRatio)
            Behavior on width {
                SpringAnimation {
                    damping: 0.6
                    epsilon: 0.5
                    spring: 2.5
                }
            }
        }
    }
}

pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking
import Vast.SystemUsage

import qs.Core.States

Singleton {
    id: root

    readonly property var    allEthernetDevices: {
        const devices = [];
        for (const device of Networking.devices.values) {
            if (device.type !== DeviceType.Wired) {
                continue;
            }
            devices.push({
                interface: device.name ?? "",
                model: device.name ?? "Unknown Ethernet",
                state: device.connected ? "connected" : "disconnected",
                isActive: device.connected,
                name: device.name ?? ""
            });
        }
        return devices;
    }
    readonly property var    ethernetDevice: Networking.devices.values.find(device => device.type === DeviceType.Wired) ?? null
    readonly property string statusWiredInterface: ethernetDevice?.connected === true ? "connected" : "disconnected"
    readonly property string wiredInterface: ethernetDevice?.name ?? ""
    readonly property int    wiredLinkSpeed: ethernetDevice?.linkSpeed ?? 0

    // Hardware & OS Info
    readonly property string archDesign: SystemUsageMonitor.archDesign
    readonly property string batteryTechnologies: SystemUsageMonitor.batteryTechnologies
    readonly property string cpuName: SystemUsageMonitor.cpuName
    readonly property string gpuName: SystemUsageMonitor.gpuName
    readonly property string kernelName: SystemUsageMonitor.kernelName
    readonly property string osId: SystemUsageMonitor.osId
    readonly property string osIdLike: SystemUsageMonitor.osIdLike
    readonly property string osPrettyName: SystemUsageMonitor.osPrettyName

    // Temperatures & Battery
    readonly property real   batteryTemp: SystemUsageMonitor.batteryTemp
    readonly property real   cpuTemp: SystemUsageMonitor.cpuTemp
    readonly property real   gpuTemp: SystemUsageMonitor.gpuTemp

    // CPU & Memory
    readonly property var    cpuCores: SystemUsageMonitor.cpuCores
    readonly property int    cpuPerc: SystemUsageMonitor.cpuPerc
    readonly property real   memTotal: SystemUsageMonitor.memTotal
    readonly property real   memUsed: SystemUsageMonitor.memUsed
    readonly property real   memUsedGiB: SystemUsageMonitor.memUsedGiB

    // Storage & Filesystems
    readonly property real   diskPercent: SystemUsageMonitor.diskPercent
    readonly property real   diskTotal: SystemUsageMonitor.diskTotal
    readonly property real   diskUsed: SystemUsageMonitor.diskUsed
    readonly property real   diskUsedGiB: SystemUsageMonitor.diskUsedGiB
    readonly property var    filesystemNames: SystemUsageMonitor.filesystems
    readonly property var    filesystems: SystemUsageMonitor.filesystems
    readonly property real   storageAppsData: SystemUsageMonitor.storageAppsData
    readonly property real   storageFree: SystemUsageMonitor.storageFree
    readonly property real   storageSystem: SystemUsageMonitor.storageSystem

    // Uptime
    readonly property string uptimeFormatted: SystemUsageMonitor.uptimeFormatted

    // Network
    readonly property string statusVPNInterface: SystemUsageMonitor.statusVPNInterface
    readonly property real   totalWiredDownloadUsage: SystemUsageMonitor.totalWiredDownloadUsage
    readonly property real   totalWiredUploadUsage: SystemUsageMonitor.totalWiredUploadUsage
    readonly property real   totalWirelessDownloadUsage: SystemUsageMonitor.totalWirelessDownloadUsage
    readonly property real   totalWirelessUploadUsage: SystemUsageMonitor.totalWirelessUploadUsage
    readonly property real   wiredDownloadSpeed: SystemUsageMonitor.wiredDownloadSpeed
    readonly property real   wiredUploadSpeed: SystemUsageMonitor.wiredUploadSpeed
    readonly property real   wirelessDownloadSpeed: SystemUsageMonitor.wirelessDownloadSpeed
    readonly property string wirelessInterface: SystemUsageMonitor.wirelessInterface
    readonly property int    wirelessLinkSpeed: SystemUsageMonitor.wirelessLinkSpeed
    readonly property real   wirelessUploadSpeed: SystemUsageMonitor.wirelessUploadSpeed

    // Graphics API
    readonly property bool   openglAvailable: SystemUsageMonitor.openglAvailable
    readonly property string openglRenderer: SystemUsageMonitor.openglRenderer
    readonly property string openglVendor: SystemUsageMonitor.openglVendor
    readonly property string openglVersion: SystemUsageMonitor.openglVersion
    readonly property string vaApiDriver: SystemUsageMonitor.vaApiDriver
    readonly property bool   vulkanAvailable: SystemUsageMonitor.vulkanAvailable
    readonly property string vulkanVersion: SystemUsageMonitor.vulkanVersion

    function                 ensureGraphicsInfoLoaded(): void {
        SystemUsageMonitor.ensureGraphicsInfoLoaded();
    }

    function                 formatKiB(kib: real): string {
        return SystemUsageMonitor.formatKiB(kib);
    }

    function                 formatSpeedMiBps(speedMiBps: real): string {
        return SystemUsageMonitor.formatSpeedMiBps(speedMiBps);
    }

    function                 formatUsageMiB(usageMiB: real): string {
        return SystemUsageMonitor.formatUsageMiB(usageMiB);
    }

    function                 sampleNow(): void {
        SystemUsageMonitor.sampleNow();
    }

    Binding {
        target: SystemUsageMonitor
        property: "running"
        value: GlobalStates.isQuickSettingsOpen
    }

    Binding {
        target: SystemUsageMonitor
        property: "wiredInterface"
        value: root.wiredInterface
    }
}

pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Memory and disk
    property int memTotal: 0
    property int memUsed: 0
    property int diskUsed: 0
    property int diskTotal: 0

    readonly property real diskProp: diskUsed / 1048576
    readonly property real memProp: memUsed / 1048576
    readonly property real diskPercent: diskTotal > 0 ? (diskUsed / diskTotal) * 100 : 0
    readonly property real memPercent: memTotal > 0 ? (memUsed / memTotal) * 100 : 0

    property string wiredInterface: ""
    property string wirelessInterface: ""
    property string statusWiredInterface: ""
    property string statusVPNInterface: ""

    property double wirelessUploadSpeed: 0
    property double wirelessDownloadSpeed: 0
    property double totalWirelessDownloadUsage: 0
    property double totalWirelessUploadUsage: 0

    property double wiredUploadSpeed: 0
    property double wiredDownloadSpeed: 0
    property double totalWiredDownloadUsage: 0
    property double totalWiredUploadUsage: 0

    property int cpuPerc: 0

    property var previousData: null
    property double lastUpdateTime: 0
    property int lastCpuIdle: 0
    property int lastCpuTotal: 0
    property bool initialized: false

    FileView {
        id: netDevFileView

        path: "/proc/net/dev"
        onLoaded: root.calculateNetworkStats(text())
    }

    Process {
        id: networkInfoProc
        command: ["sh", "-c", `
            nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '
            /ethernet/ && !eth_found {
            print "WIRED_DEV:" $1;
            print "WIRED_STATE:" $3;
            eth_found=1
            }
            /wifi/ && !wifi_found {
            print "WIFI_DEV:" $1;
            wifi_found=1
            }
            /^(wg0|CloudflareWARP):/ {
            print "VPN_DEV:" $1
            }
            '
            `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                for (const line of lines) {
                    if (line.startsWith("WIRED_DEV:")) {
                        root.wiredInterface = line.substring(10).trim();
                    } else if (line.startsWith("WIRED_STATE:")) {
                        root.statusWiredInterface = line.substring(12).replace(" (externally)", "").trim();
                    } else if (line.startsWith("WIFI_DEV:")) {
                        root.wirelessInterface = line.substring(9).trim();
                    } else if (line.startsWith("VPN_DEV:")) {
                        root.statusVPNInterface = line.substring(8).trim();
                    }
                }
            }
        }
    }

    function parseNetworkData(data) {
        const lines = data.split('\n');
        const interfaces = {};

        for (var i = 2; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line)
                continue;
            const parts = line.split(/\s+/);
            if (parts.length < 17)
                continue;
            const ifaceName = parts[0].replace(':', '');

            if (ifaceName !== root.wirelessInterface && ifaceName !== root.wiredInterface) {
                continue;
            }

            interfaces[ifaceName] = {
                "rxBytes": parseInt(parts[1]) || 0,
                "txBytes": parseInt(parts[9]) || 0
            };
        }

        return interfaces;
    }

    // Thx claude
    function calculateNetworkStats(data) {
        const currentTime = Date.now();
        const currentData = parseNetworkData(data);

        // Update total usage (these are cheap calculations)
        const wirelessData = currentData[wirelessInterface];
        const wiredData = currentData[wiredInterface];

        if (wirelessData) {
            totalWirelessDownloadUsage = wirelessData.rxBytes / 1048576; // Use constant instead of 1024*1024
            totalWirelessUploadUsage = wirelessData.txBytes / 1048576;
        }

        if (wiredData) {
            totalWiredDownloadUsage = wiredData.rxBytes / 1048576;
            totalWiredUploadUsage = wiredData.txBytes / 1048576;
        }

        // Speed calculation only if we have previous data
        if (previousData && lastUpdateTime > 0) {
            const timeDiffSec = (currentTime - lastUpdateTime) / 1000;

            if (timeDiffSec > 0.1) {
                // Minimum 100ms between updates
                const prevWireless = previousData[wirelessInterface];
                const prevWired = previousData[wiredInterface];

                if (wirelessData && prevWireless) {
                    const rxDiff = wirelessData.rxBytes - prevWireless.rxBytes;
                    const txDiff = wirelessData.txBytes - prevWireless.txBytes;

                    wirelessDownloadSpeed = Math.max(0, rxDiff / 1048576 / timeDiffSec);
                    wirelessUploadSpeed = Math.max(0, txDiff / 1048576 / timeDiffSec);
                }

                if (wiredData && prevWired) {
                    const rxDiff = wiredData.rxBytes - prevWired.rxBytes;
                    const txDiff = wiredData.txBytes - prevWired.txBytes;

                    wiredDownloadSpeed = Math.max(0, rxDiff / 1048576 / timeDiffSec);
                    wiredUploadSpeed = Math.max(0, txDiff / 1048576 / timeDiffSec);
                }
            }
        }

        // Store only relevant data (not deep clone of everything)
        previousData = currentData;
        lastUpdateTime = currentTime;
    }

    // OPTIMIZATION: Use lookup table for common speeds
    readonly property var speedThresholds: [
        {
            "limit": 0.01,
            "format": () => "0.00 MB/s"
        },
        {
            "limit": 1,
            "format": s => (s * 1024).toFixed(2) + " KB/s"
        },
        {
            "limit": Infinity,
            "format": s => s.toFixed(2) + " MB/s"
        }
    ]

    function formatSpeed(speedMBps) {
        for (const threshold of speedThresholds) {
            if (speedMBps < threshold.limit) {
                return threshold.format(speedMBps);
            }
        }
    }

    function formatUsage(usageMB) {
        return usageMB < 1024 ? usageMB.toFixed(2) + " MB" : (usageMB / 1024).toFixed(2) + " GB";
    }

    FileView {
        id: meminfoFileView

        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            const memMatch = data.match(/MemTotal:\s+(\d+)[\s\S]*?MemAvailable:\s+(\d+)/);
            if (memMatch) {
                root.memTotal = parseInt(memMatch[1], 10);
                root.memUsed = root.memTotal - parseInt(memMatch[2], 10);
            }
        }
    }

    // Thx caelestia
    Process {
        id: diskDfProc

        command: ["sh", "-c", "df | grep '^/dev/' | awk '{print $1, $3, $4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const deviceMap = new Map();

                for (const line of text.trim().split("\n")) {
                    if (line.trim() === "")
                        continue;
                    const parts = line.trim().split(/\s+/);
                    if (parts.length >= 3) {
                        const device = parts[0];
                        const used = parseInt(parts[1], 10) || 0;
                        const avail = parseInt(parts[2], 10) || 0;

                        // Only keep the entry with the largest total space for each device
                        if (!deviceMap.has(device) || (used + avail) > (deviceMap.get(device).used + deviceMap.get(device).avail)) {
                            deviceMap.set(device, {
                                "used": used,
                                "avail": avail
                            });
                        }
                    }
                }

                let totalUsed = 0;
                let totalAvail = 0;

                for (const stats of deviceMap.values()) {
                    totalUsed += stats.used;
                    totalAvail += stats.avail;
                }

                root.diskUsed = totalUsed;
                root.diskTotal = totalUsed + totalAvail;
            }
        }
    }

    FileView {
        id: cpuStatFileView

        path: "/proc/stat"
        onLoaded: {
            const data = text();
            // OPTIMIZATION: More specific regex, early match
            const match = data.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+))?/m);

            if (!match)
                return;

            // Parse only what we need
            const user = parseInt(match[1], 10);
            const nice = parseInt(match[2], 10);
            const system = parseInt(match[3], 10);
            const idle = parseInt(match[4], 10);
            const iowait = parseInt(match[5], 10) || 0;

            const total = user + nice + system + idle + iowait;
            const idleTotal = idle + iowait;

            if (!root.initialized) {
                root.lastCpuTotal = total;
                root.lastCpuIdle = idleTotal;
                root.initialized = true;
                return;
            }

            const totalDiff = total - root.lastCpuTotal;
            const idleDiff = idleTotal - root.lastCpuIdle;

            if (totalDiff > 0) {
                const usage = (totalDiff - idleDiff) / totalDiff;
                root.cpuPerc = Math.round(Math.max(0, Math.min(1, usage)) * 100);
            }

            root.lastCpuTotal = total;
            root.lastCpuIdle = idleTotal;
        }
    }

    Timer {
        id: mainTimer
        running: true
        interval: 2000
        repeat: true
        triggeredOnStart: true

        property int updateCycle: 0

        onTriggered: {
            cpuStatFileView.reload();
            meminfoFileView.reload();
            netDevFileView.reload();
            diskDfProc.started();

            updateCycle = (updateCycle + 1) % 3;

            switch (updateCycle) {
            case 0:
                networkInfoProc.running = true;
                break;
            case 1:
                diskDfProc.running = true;
                break;
            }
        }
    }

    Component.onDestruction: {
        previousData = null;
    }
}

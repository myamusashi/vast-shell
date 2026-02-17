pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Helpers

Singleton {
    id: root

    // gpu, network, disk & mem informations
    readonly property real diskProp: diskUsed / 1048576
    readonly property real diskPercent: diskTotal > 0 ? (diskUsed / diskTotal) * 100 : 0
    readonly property real memProp: memUsed / 1048576
    readonly property real memPercent: memTotal > 0 ? (memUsed / memTotal) * 100 : 0
    readonly property string gpuPowerText: gpuPower + " W"
    readonly property string gpuFreqText: gpuFreqActual + " MHz"
    readonly property string gpuRc6Text: gpuRc6 + "%"
    readonly property string gpuBandwidthText: `R: ${gpuMemBandwidthRead} MiB/s W: ${gpuMemBandwidthWrite} MiB/s`
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

    // GPU name
    property string gpuName: ""
    property string cpuName: ""

    // Rendering backend information
    property bool vulkanAvailable: false
    property bool openglAvailable: false
    property bool hardwareAccelAvailable: false
    property bool vdpauAvailable: false
    property string vulkanDriver: ""
    property string vdpauDriver: ""
    property string vaApiDriver: ""
    property string openglVersion: ""
    property string vulkanVersion: ""
    property string openglRenderer: ""
    property string openglVendor: ""
    property var vulkanDevices: []
    property var vaApiProfiles: []

    // Storage breakdown
    readonly property string storageAppsFormatted: (storageAppsData / 1024 / 1024).toFixed(2) + " GB"
    readonly property string storageSystemFormatted: (storageSystem / 1024 / 1024).toFixed(2) + " GB"
    readonly property string storageFreeFormatted: (storageFree / 1024 / 1024).toFixed(2) + " GB"
    property real storageAppsData: 0
    property real storageSystem: 0
    property real storageFree: 0

    // Filesystem info: list of {name, type, mountpoint, usedKB, freeKB, totalKB}
    property var filesystemNames: []

    property var cpuCores: [] // .freqMHz, .percent
    property int cpuCoreCount: 0
    property int cpuMaxFreqKHz: 1

    // Temperatures (°C)
    property real cpuTemp: 0
    property real gpuTemp: 0
    property real batteryTemp: 0
    property var cpuCoreTemps: []

    // Battery informations
    property string batteryTechnologies: ""

    // Deep sleep & uptime
    property bool deepSleepSupported: false
    property real uptimeSeconds: 0
    property string sleepMode: ""
    readonly property string uptimeFormatted: {
        const s = Math.floor(uptimeSeconds);
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        const m = Math.floor((s % 3600) / 60);
        if (d > 0)
            return `${d}d ${h}h ${m}m`;
        if (h > 0)
            return `${h}h ${m}m`;
        return `${m}m`;
    }

    // OS info
    property string osName: ""
    property string osVersion: ""
    property string osPrettyName: ""
    property string kernelName: ""
    property string archDesign: ""
    property string cpuFlags: ""

    // mem & disk info
    property int memTotal: 0
    property int memUsed: 0
    property int diskUsed: 0
    property int diskTotal: 0

    // network interfaces name and status
    property string wiredInterface: ""
    property string wirelessInterface: ""
    property string statusWiredInterface: ""
    property string statusVPNInterface: ""

    // wireless usage for download and upload
    property double wirelessUploadSpeed: 0
    property double wirelessDownloadSpeed: 0
    property double totalWirelessDownloadUsage: 0
    property double totalWirelessUploadUsage: 0

    // wired usage for download and upload
    property double wiredUploadSpeed: 0
    property double wiredDownloadSpeed: 0
    property double totalWiredDownloadUsage: 0
    property double totalWiredUploadUsage: 0

    // wired & wireless link speed
    property int wiredLinkSpeed: 0
    property int wirelessLinkSpeed: 0

    // cpu, gpu & vram informations
    property string gpuPower: "0.00"
    property string gpuRc6: "0.0"
    property int cpuPerc: 0
    property int gpuUsage: 0
    property int vramUsed: 0
    property int gpuFreqActual: 0
    property int gpuFreqRequested: 0
    property int gpuMemBandwidthRead: 0
    property int gpuMemBandwidthWrite: 0

    // temp data
    property bool initialized: false
    property bool staticInfoLoaded: false
    property double lastUpdateTime: 0
    property int lastCpuTotal: 0
    property int lastCpuIdle: 0
    property var previousData: null
    property var lastPerCoreCpuData: null

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

            if (ifaceName !== root.wirelessInterface && ifaceName !== root.wiredInterface)
                continue;
            interfaces[ifaceName] = {
                "rxBytes": parseInt(parts[1]) || 0,
                "txBytes": parseInt(parts[9]) || 0
            };
        }

        return interfaces;
    }

    function calculateNetworkStats(data) {
        const currentTime = Date.now();
        const currentData = parseNetworkData(data);

        const wirelessData = currentData[wirelessInterface];
        const wiredData = currentData[wiredInterface];

        if (wirelessData) {
            totalWirelessDownloadUsage = wirelessData.rxBytes / 1048576;
            totalWirelessUploadUsage = wirelessData.txBytes / 1048576;
        }

        if (wiredData) {
            totalWiredDownloadUsage = wiredData.rxBytes / 1048576;
            totalWiredUploadUsage = wiredData.txBytes / 1048576;
        }

        if (previousData && lastUpdateTime > 0) {
            const timeDiffSec = (currentTime - lastUpdateTime) / 1000;

            if (timeDiffSec > 0.1) {
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

        previousData = currentData;
        lastUpdateTime = currentTime;
    }

    function formatSpeed(speedMBps) {
        for (const threshold of speedThresholds)
            if (speedMBps < threshold.limit)
                return threshold.format(speedMBps);
    }

    function formatUsage(usageMB) {
        return usageMB < 1024 ? usageMB.toFixed(2) + " MB" : (usageMB / 1024).toFixed(2) + " GB";
    }

    FileView {
        id: netDevFileView

        path: "/proc/net/dev"
        onLoaded: root.calculateNetworkStats(text())
    }

    Process {
        id: batteryTechProc

        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/technology"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const technologies = text.trim().split('\n');
                root.batteryTechnologies = technologies[0] || "Unknown";
            }
        }
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
                    if (line.startsWith("WIRED_DEV:"))
                        root.wiredInterface = line.substring(10).trim();
                    else if (line.startsWith("WIRED_STATE:"))
                        root.statusWiredInterface = line.substring(12).replace(" (externally)", "").trim();
                    else if (line.startsWith("WIFI_DEV:"))
                        root.wirelessInterface = line.substring(9).trim();
                    else if (line.startsWith("VPN_DEV:"))
                        root.statusVPNInterface = line.substring(8).trim();
                }
            }
        }
    }

    Process {
        id: linkSpeedProc

        property string comm: `
            if [ -n "${root.wiredInterface}" ] && [ -f "/sys/class/net/${root.wiredInterface}/speed" ]; then
                echo "WIRED_SPEED:$(cat /sys/class/net/${root.wiredInterface}/speed 2>/dev/null || echo 0)"
            else
                echo "WIRED_SPEED:0"
            fi

            if [ -n "${root.wirelessInterface}" ]; then
                speed=$(iw dev ${root.wirelessInterface} link 2>/dev/null | grep 'tx bitrate:' | awk '{print $3}')
                echo "WIRELESS_SPEED:\${speed:-0}"
            else
                echo "WIRELESS_SPEED:0"
            fi
		`

        command: ["sh", "-c", comm]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    if (line.startsWith("WIRED_SPEED:"))
                        root.wiredLinkSpeed = parseInt(line.substring(12), 10) || 0;
                    else if (line.startsWith("WIRELESS_SPEED:"))
                        root.wirelessLinkSpeed = parseFloat(line.substring(15)) || 0;
                }
            }
        }
    }

    Process {
        id: vulkanInfoProc

        command: ["sh", "-c", `
            if command -v vulkaninfo >/dev/null 2>&1; then
                echo "VULKAN:AVAILABLE"
                vulkaninfo --summary 2>/dev/null | awk '
                /Vulkan Instance Version:/ {print "VERSION:" $NF}
                /GPU id.*deviceName/ {
                    match($0, /deviceName = (.+)/, arr)
                    print "DEVICE:" arr[1]
                }
                /GPU id.*driverName/ {
                    match($0, /driverName = (.+)/, arr)
                    print "DRIVER:" arr[1]
                }
                /GPU id.*driverInfo/ {
                    match($0, /driverInfo = (.+)/, arr)
                    print "DRIVER_INFO:" arr[1]
                }
                '
            else
                echo "VULKAN:UNAVAILABLE"
            fi
        `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                const devices = [];
                let currentDevice = {};

                for (const line of lines) {
                    if (line === "VULKAN:AVAILABLE") {
                        root.vulkanAvailable = true;
                    } else if (line === "VULKAN:UNAVAILABLE") {
                        root.vulkanAvailable = false;
                    } else if (line.startsWith("VERSION:")) {
                        root.vulkanVersion = line.substring(8).trim();
                    } else if (line.startsWith("DEVICE:")) {
                        if (currentDevice.name) {
                            devices.push(currentDevice);
                        }
                        currentDevice = {
                            name: line.substring(7).trim()
                        };
                    } else if (line.startsWith("DRIVER:")) {
                        root.vulkanDriver = line.substring(7).trim();
                        currentDevice.driver = root.vulkanDriver;
                    } else if (line.startsWith("DRIVER_INFO:")) {
                        currentDevice.driverInfo = line.substring(12).trim();
                    }
                }

                if (currentDevice.name) {
                    devices.push(currentDevice);
                }

                root.vulkanDevices = devices;
            }
        }
    }

    Process {
        id: openglInfoProc

        command: ["sh", "-c", `
            if command -v glxinfo >/dev/null 2>&1; then
                echo "OPENGL:AVAILABLE"
                glxinfo 2>/dev/null | awk '
                /^OpenGL version string:/ {
                    sub(/^OpenGL version string: */, "")
                    print "GL_VERSION:" $0
                }
                /^OpenGL vendor string:/ {
                    sub(/^OpenGL vendor string: */, "")
                    print "GL_VENDOR:" $0
                }
                /^OpenGL renderer string:/ {
                    sub(/^OpenGL renderer string: */, "")
                    print "GL_RENDERER:" $0
                }
                /direct rendering:/ {
                    print "GL_DIRECT:" $NF
                }
                '
            else
                echo "OPENGL:UNAVAILABLE"
            fi
        `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');

                for (const line of lines) {
                    if (line === "OPENGL:AVAILABLE")
                        root.openglAvailable = true;
                    else if (line === "OPENGL:UNAVAILABLE")
                        root.openglAvailable = false;
                    else if (line.startsWith("GL_VERSION:"))
                        root.openglVersion = line.substring(11).trim();
                    else if (line.startsWith("GL_VENDOR:"))
                        root.openglVendor = line.substring(10).trim();
                    else if (line.startsWith("GL_RENDERER:"))
                        root.openglRenderer = line.substring(12).trim();
                }
            }
        }
    }

    Process {
        id: vaApiInfoProc

        command: ["sh", "-c", `
            if command -v vainfo >/dev/null 2>&1; then
                vainfo 2>/dev/null | awk '
                /Driver version:/ {
                    sub(/.*Driver version: */, "")
                    print "VAAPI_DRIVER:" $0
                }
                /VAProfile/ {
                    if ($2 == ":") {
                        print "VAAPI_PROFILE:" $1
                    }
                }
                ' || echo "VAAPI:ERROR"
                if [ $? -eq 0 ]; then
                    echo "VAAPI:AVAILABLE"
                else
                    echo "VAAPI:UNAVAILABLE"
                fi
            else
                echo "VAAPI:UNAVAILABLE"
            fi
        `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                const profiles = [];

                for (const line of lines) {
                    if (line === "VAAPI:AVAILABLE") {
                        root.hardwareAccelAvailable = true;
                    } else if (line === "VAAPI:UNAVAILABLE" || line === "VAAPI:ERROR") {
                        root.hardwareAccelAvailable = false;
                    } else if (line.startsWith("VAAPI_DRIVER:")) {
                        root.vaApiDriver = line.substring(13).trim();
                    } else if (line.startsWith("VAAPI_PROFILE:")) {
                        profiles.push(line.substring(14).trim());
                    }
                }

                root.vaApiProfiles = profiles;
            }
        }
    }

    Process {
        id: vdpauInfoProc

        command: ["sh", "-c", `
            if command -v vdpauinfo >/dev/null 2>&1; then
                vdpauinfo 2>/dev/null | awk '
                /Information string:/ {
                    sub(/.*Information string: */, "")
                    print "VDPAU_INFO:" $0
                }
                /display:/ {
                    if ($0 ~ /display:.*\'/) {
                        print "VDPAU:AVAILABLE"
                    }
                }
                '
                if [ $? -eq 0 ]; then
                    echo "VDPAU:AVAILABLE"
                else
                    echo "VDPAU:UNAVAILABLE"
                fi
            else
                echo "VDPAU:UNAVAILABLE"
            fi
        `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');

                for (const line of lines) {
                    if (line === "VDPAU:AVAILABLE") {
                        root.vdpauAvailable = true;
                    } else if (line === "VDPAU:UNAVAILABLE") {
                        root.vdpauAvailable = false;
                    } else if (line.startsWith("VDPAU_INFO:")) {
                        root.vdpauDriver = line.substring(11).trim();
                    }
                }
            }
        }
    }

    Process {
        id: intelGpuProc

        command: ["sh", "-c", "timeout 1 intel_gpu_top -J -s 500"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const jsonText = text.trim();
                    const cleanedJson = jsonText.endsWith(',') ? jsonText.slice(0, -1) + ']' : jsonText + ']';
                    const dataArray = JSON.parse(cleanedJson);

                    // Get the last sample (most recent data)
                    if (dataArray.length === 0)
                        return;
                    const data = dataArray[dataArray.length - 1];

                    // Get GPU usage from render/3d engine
                    if (data.engines && data.engines["Render/3D"])
                        root.gpuUsage = Math.round(data.engines["Render/3D"].busy || 0);

                    // Get power consumption
                    if (data.power && data.power.GPU)
                        root.gpuPower = data.power.GPU.toFixed(2);

                    let totalVramUsed = 0;
                    if (data.clients)
                        for (const clientId in data.clients) {
                            const client = data.clients[clientId];
                            if (client.memory && client.memory.system)
                                totalVramUsed += parseInt(client.memory.system.resident) || 0;
                        }

                    // Convert bytes to MB
                    root.vramUsed = Math.round(totalVramUsed / 1048576);

                    // Get frequency info
                    if (data.frequency) {
                        root.gpuFreqActual = Math.round(data.frequency.actual || 0);
                        root.gpuFreqRequested = Math.round(data.frequency.requested || 0);
                    }

                    // RC6 (power saving state)
                    if (data.rc6)
                        root.gpuRc6 = data.rc6.value.toFixed(1);

                    // Get memory bandwidth
                    if (data["imc-bandwidth"]) {
                        root.gpuMemBandwidthRead = Math.round(data["imc-bandwidth"].reads || 0);
                        root.gpuMemBandwidthWrite = Math.round(data["imc-bandwidth"].writes || 0);
                    }
                } catch (e) {
                    console.log("Failed to parse intel_gpu_top output:", e);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.log("intel_gpu_top error:", text.trim());
            }
        }
    }

    // Fallback
    Process {
        id: intelGpuSysfsProc

        command: ["sh", "-c", `
            cat /sys/class/drm/card0/gt_cur_freq_mhz 2>/dev/null || echo "0"
            cat /sys/class/drm/card0/gt_max_freq_mhz 2>/dev/null || echo "1"

            cat /sys/kernel/debug/dri/0/i915_gem_objects 2>/dev/null | awk '/bytes total/ {print $1}'
            `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                if (lines.length >= 3) {
                    const curFreq = parseInt(lines[0]) || 0;
                    const maxFreq = parseInt(lines[1]) || 1;
                    const vramBytes = parseInt(lines[2]) || 0;

                    root.gpuUsage = Math.round((curFreq / maxFreq) * 100);

                    if (vramBytes > 0)
                        root.vramUsed = Math.round(vramBytes / 1048576);
                }
            }
        }
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

    Process {
        id: diskDfProc

        command: ["sh", "-c", "df -T 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const deviceMap = new Map();
                const fsList = [];
                let sysUsed = 0;
                let appsUsed = 0;
                let totalFree = 0;
                let totalUsed = 0;

                for (let i = 1; i < lines.length; i++) {
                    const line = lines[i].trim();
                    if (!line)
                        continue;
                    const parts = line.split(/\s+/);
                    if (parts.length < 7)
                        continue;

                    const dev = parts[0];
                    const fsType = parts[1];
                    const usedKB = parseInt(parts[3], 10) || 0;
                    const freeKB = parseInt(parts[4], 10) || 0;
                    const mountpoint = parts[6];
                    const totalKB = usedKB + freeKB;
                    const usedPercent = totalKB > 0 ? ((usedKB / totalKB) * 100).toFixed(1) : 0;

                    if (dev.startsWith("/dev/")) {
                        if (!deviceMap.has(dev) || totalKB > deviceMap.get(dev)) {
                            deviceMap.set(dev, totalKB);

                            fsList.push({
                                "name": dev,
                                "type": fsType,
                                "mountpoint": mountpoint,
                                "usedKB": usedKB,
                                "freeKB": freeKB,
                                "totalKB": totalKB,
                                "usedPercent": parseFloat(usedPercent),
                                "usedFormatted": (usedKB / 1024 / 1024).toFixed(2) + " GB",
                                "freeFormatted": (freeKB / 1024 / 1024).toFixed(2) + " GB",
                                "totalFormatted": (totalKB / 1024 / 1024).toFixed(2) + " GB"
                            });

                            totalUsed += usedKB;
                            totalFree += freeKB;

                            if (mountpoint === "/nix" || mountpoint === "/boot" || mountpoint === "/nix/store")
                                sysUsed += usedKB;
                            else
                                appsUsed += usedKB;
                        }
                    }
                }

                root.filesystemNames = fsList;
                root.storageAppsData = appsUsed;
                root.storageSystem = sysUsed;
                root.storageFree = totalFree;
                root.diskUsed = totalUsed;
                root.diskTotal = totalUsed + totalFree;
            }
        }
    }

    FileView {
        id: cpuStatFileView

        path: "/proc/stat"
        onLoaded: {
            const data = text();
            const match = data.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+))?/m);

            if (!match)
                return;
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

                const perCoreRegex = /^cpu(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+))?/gm;
                const initial = {};
                let m;
                while ((m = perCoreRegex.exec(data)) !== null) {
                    const coreId = parseInt(m[1], 10);
                    const cTotal = parseInt(m[2]) + parseInt(m[3]) + parseInt(m[4]) + parseInt(m[5]) + (parseInt(m[6]) || 0);
                    const cIdle = parseInt(m[5]) + (parseInt(m[6]) || 0);
                    initial[coreId] = {
                        "total": cTotal,
                        "idle": cIdle
                    };
                }
                root.lastPerCoreCpuData = initial;
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

            if (root.lastPerCoreCpuData) {
                const perCoreRegex = /^cpu(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+))?/gm;
                const newPerCore = {};
                const coreResults = root.cpuCores.length > 0 ? [...root.cpuCores] : [];
                let m;

                while ((m = perCoreRegex.exec(data)) !== null) {
                    const coreId = parseInt(m[1], 10);
                    const cTotal = parseInt(m[2]) + parseInt(m[3]) + parseInt(m[4]) + parseInt(m[5]) + (parseInt(m[6]) || 0);
                    const cIdle = parseInt(m[5]) + (parseInt(m[6]) || 0);
                    newPerCore[coreId] = {
                        "total": cTotal,
                        "idle": cIdle
                    };

                    const prev = root.lastPerCoreCpuData[coreId];
                    if (prev) {
                        const td = cTotal - prev.total;
                        const id = cIdle - prev.idle;
                        const pct = td > 0 ? Math.round(((td - id) / td) * 100) : 0;

                        // Update or create per-core entry
                        if (coreId < coreResults.length) {
                            coreResults[coreId] = {
                                "core": coreId,
                                "freqMHz": coreResults[coreId].freqMHz,
                                "percent": pct
                            };
                        } else {
                            coreResults.push({
                                "core": coreId,
                                "freqMHz": 0,
                                "percent": pct
                            });
                        }
                    }
                }

                root.lastPerCoreCpuData = newPerCore;
                root.cpuCores = coreResults;
            }
        }
    }

    FileView {
        id: uptimeFileView

        path: "/proc/uptime"
        onLoaded: {
            const parts = text().trim().split(/\s+/);
            if (parts.length >= 1)
                root.uptimeSeconds = parseFloat(parts[0]) || 0;
        }
    }

    Process {
        id: cpuFreqProc

        command: ["sh", "-c", "for c in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do cat \"$c\" 2>/dev/null; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const cores = root.cpuCores.length > 0 ? [...root.cpuCores] : [];
                const maxFreq = root.cpuMaxFreqKHz;

                for (let i = 0; i < lines.length; i++) {
                    const freqKHz = parseInt(lines[i].trim(), 10) || 0;
                    const freqMHz = Math.round(freqKHz / 1000);

                    if (i < cores.length) {
                        cores[i] = {
                            "core": i,
                            "freqMHz": freqMHz,
                            "percent": cores[i].percent || 0
                        };
                    } else {
                        cores.push({
                            "core": i,
                            "freqMHz": freqMHz,
                            "percent": 0
                        });
                    }
                }

                root.cpuCores = cores;
            }
        }
    }

    Process {
        id: temperatureProc

        command: ["sh", "-c", `
            # CPU package and core temps from coretemp hwmon
            for hwmon in /sys/class/hwmon/hwmon*; do
                name=$(cat "$hwmon/name" 2>/dev/null)
                if [ "$name" = "coretemp" ]; then
                    i=1
                    while [ -f "$hwmon/temp$\{i}_input" ]; do
                        label=$(cat "$hwmon/temp$\{i}_label" 2>/dev/null)
                        temp=$(cat "$hwmon/temp$\{i}_input" 2>/dev/null)
                        echo "CORETEMP:$label:$temp"
                        i=$((i + 1))
                    done
                fi
            done

            # Battery temp
            for bat in /sys/class/power_supply/BAT*; do
                if [ -f "$bat/temp" ]; then
                    echo "BATTEMP:$(cat "$bat/temp" 2>/dev/null)"
                fi
            done

            # dGPU temp (NVIDIA/AMD)
            for card in /sys/class/drm/card*; do
                if [ -d "$card/device/hwmon" ]; then
                    for hwmon in "$card/device/hwmon/hwmon"*; do
                        if [ -f "$hwmon/temp1_input" ]; then
                            echo "GPUTEMP:$(cat "$hwmon/temp1_input" 2>/dev/null)"
                        fi
                    done
                fi
            done
            `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const coreTemps = [];
                let foundGpuTemp = false;

                for (const line of text.trim().split("\n")) {
                    if (line.startsWith("CORETEMP:")) {
                        const parts = line.substring(9).split(":");
                        if (parts.length >= 2) {
                            const label = parts[0];
                            const temp = parseInt(parts[1], 10) / 1000;

                            if (label.startsWith("Package"))
                                root.cpuTemp = temp;
                            else if (label.startsWith("Core"))
                                coreTemps.push({
                                    "core": coreTemps.length,
                                    "temp": temp
                                });
                        }
                    } else if (line.startsWith("BATTEMP:")) {
                        const val = parseInt(line.substring(8), 10);
                        if (!isNaN(val))
                            root.batteryTemp = val / 10;
                    } else if (line.startsWith("GPUTEMP:")) {
                        const val = parseInt(line.substring(8), 10);
                        if (!isNaN(val)) {
                            root.gpuTemp = val / 1000;
                            foundGpuTemp = true;
                        }
                    }
                }

                root.cpuCoreTemps = coreTemps;
                if (!foundGpuTemp)
                    root.gpuTemp = 0;
            }
        }
    }

    Process {
        id: cpuNameProc

        command: ["sh", "-c", "lscpu | grep 'Model name' | cut -f 2 -d ':' | awk '{$1=$1}1'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.cpuName = text.trim();
            }
        }
    }

    Process {
        id: gpuNameProc

        command: ["sh", "-c", "lspci 2>/dev/null | grep -i 'vga\\|3d\\|display' | head -1 | sed 's/.*: //'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.gpuName = text.trim();
            }
        }
    }

    Process {
        id: osInfoProc

        command: ["sh", "-c", `
            echo "OS_PRETTY:$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
            echo "OS_NAME:$(grep '^NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
            echo "OS_VERSION:$(grep '^VERSION=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
            echo "KERNEL:$(uname -r)"
            echo "ARCH:$(uname -m)"
            echo "NPROC:$(nproc)"
            echo "MAXFREQ:$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 1)"
            echo "FLAGS:$(grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | xargs)"
            echo "MEMSLEEP:$(cat /sys/power/mem_sleep 2>/dev/null || echo '')"
            `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    if (line.startsWith("OS_PRETTY:"))
                        root.osPrettyName = line.substring(10);
                    else if (line.startsWith("OS_NAME:"))
                        root.osName = line.substring(8);
                    else if (line.startsWith("OS_VERSION:"))
                        root.osVersion = line.substring(11);
                    else if (line.startsWith("KERNEL:"))
                        root.kernelName = line.substring(7);
                    else if (line.startsWith("ARCH:"))
                        root.archDesign = line.substring(5);
                    else if (line.startsWith("NPROC:"))
                        root.cpuCoreCount = parseInt(line.substring(6), 10) || 0;
                    else if (line.startsWith("MAXFREQ:"))
                        root.cpuMaxFreqKHz = parseInt(line.substring(8), 10) || 1;
                    else if (line.startsWith("FLAGS:"))
                        root.cpuFlags = line.substring(6);
                    else if (line.startsWith("MEMSLEEP:")) {
                        const sleepStr = line.substring(9);
                        root.deepSleepSupported = sleepStr.includes("deep");
                        const activeMatch = sleepStr.match(/\[([^\]]+)\]/);
                        root.sleepMode = activeMatch ? activeMatch[1] : "";
                    }
                }

                root.staticInfoLoaded = true;
            }
        }
    }

    Timer {
        id: mainTimer

        property int updateCycle: 0

        running: GlobalStates.isDashboardOpen || GlobalStates.isQuickSettingsOpen
        interval: 2000
        repeat: GlobalStates.isDashboardOpen || GlobalStates.isQuickSettingsOpen
        triggeredOnStart: true

        onTriggered: {
            cpuStatFileView.reload();
            meminfoFileView.reload();
            netDevFileView.reload();
            uptimeFileView.reload();

            updateCycle = (updateCycle + 1) % 6;

            switch (updateCycle) {
            case 0:
                networkInfoProc.running = true;
                break;
            case 1:
                diskDfProc.running = true;
                break;
            case 2:
                intelGpuProc.running = true;
                break;
            case 3:
                intelGpuSysfsProc.running = true;
                break;
            case 4:
                cpuFreqProc.running = true;
                break;
            case 5:
                temperatureProc.running = true;
                linkSpeedProc.running = true;
                break;
            }

            if (!root.staticInfoLoaded) {
                gpuNameProc.running = true;
                cpuNameProc.running = true;
                osInfoProc.running = true;
                vulkanInfoProc.running = true;
                openglInfoProc.running = true;
                vaApiInfoProc.running = true;
                vdpauInfoProc.running = true;
            }
        }
    }

    Component.onDestruction: {
        previousData = null;
        lastPerCoreCpuData = null;
    }
}

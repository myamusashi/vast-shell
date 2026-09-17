pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    function parseNetworkData(data, wirelessInterface, wiredInterface) {
        const lines = data.split("\n");
        const interfaces = {};

        for (let i = 2; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line)
                continue;
            const parts = line.split(/\s+/);
            if (parts.length < 17)
                continue;
            const ifaceName = parts[0].replace(":", "");
            if (ifaceName !== wirelessInterface && ifaceName !== wiredInterface)
                continue;
            interfaces[ifaceName] = {
                rxBytes: parseInt(parts[1]) || 0,
                txBytes: parseInt(parts[9]) || 0
            };
        }
        return interfaces;
    }

    function formatSpeed(speedMBps, thresholds) {
        for (const threshold of thresholds)
            if (speedMBps < threshold.limit)
                return threshold.format(speedMBps);
        return "0.00 MB/s";
    }

    function formatUsage(usageMB) {
        return usageMB < 1024 ? usageMB.toFixed(2) + " MB" : (usageMB / 1024).toFixed(2) + " GB";
    }

    function formatKB(kb) {
        return formatUsage(kb / 1024);
    }

    function parsePerCoreCpu(data) {
        const regex = /^cpu(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+))?/gm;
        const result = {};
        let match;
        while ((match = regex.exec(data)) !== null) {
            const id = parseInt(match[1], 10);
            const total = parseInt(match[2]) + parseInt(match[3]) + parseInt(match[4]) + parseInt(match[5]) + (parseInt(match[6]) || 0);
            const idle = parseInt(match[5]) + (parseInt(match[6]) || 0);
            result[id] = {
                total: total,
                idle: idle
            };
        }
        return result;
    }
}

pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    function connectedCount(devices, adapter): int {
        if (!adapter)
            return 0;
        let n = 0;
        for (const d of devices)
            if (d.adapter === adapter && d.connected)
                n++;
        return n;
    }

    function hasWhere(devices, adapter, key): bool {
        if (!adapter)
            return false;
        for (const d of devices)
            if (d.adapter === adapter && d[key])
                return true;
        return false;
    }

    function pairedDevices(devices, adapter): var {
        if (!adapter)
            return [];
        return [...devices].filter(d => d.adapter === adapter && d.paired).sort((a, b) => {
            if (a.connected !== b.connected)
                return b.connected - a.connected;
            return (a.name || a.address).localeCompare(b.name || b.address);
        });
    }

    function availableDevices(devices, adapter): var {
        if (!adapter)
            return [];
        return [...devices].filter(d => d.adapter === adapter && !d.paired).sort((a, b) => {
            const an = a.name || a.deviceName || "";
            const bn = b.name || b.deviceName || "";
            if (!!an !== !!bn)
                return bn ? 1 : -1;
            return (a.name || a.address).localeCompare(b.name || b.address);
        });
    }

    function blockedDevices(devices, adapter): var {
        if (!adapter)
            return [];
        return [...devices].filter(d => d.adapter === adapter && d.blocked);
    }
}

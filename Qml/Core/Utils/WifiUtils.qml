pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    function iconFor(strength, locked) {
        const s = strength ?? 0;
        var base = "";
        if (s >= 0.8)
            base = "network_wifi";
        else if (s >= 0.5)
            base = "network_wifi_3_bar";
        else if (s >= 0.3)
            base = "network_wifi_2_bar";
        else if (s >= 0.15)
            base = "network_wifi_1_bar";
        else
            return "signal_wifi_0_bar";
        return locked ? base + "_locked" : base;
    }

    function sorted(networks) {
        return [...(networks ?? [])].sort((a, b) => {
            if (a.connected !== b.connected)
                return b.connected - a.connected;
            if (a.known !== b.known)
                return b.known - a.known;
            return b.signalStrength - a.signalStrength;
        });
    }

    function tryConnect(network, showPsk) {
        if (!network || network.connected)
            return;
        if (network.known || network.security === WifiSecurityType.Open)
            network.connect();
        else if (showPsk)
            showPsk(network);
    }

    function handleConnectionFailed(network, reason, showPsk) {
        if (reason === ConnectionFailReason.NoSecrets && showPsk)
            showPsk(network);
    }
}

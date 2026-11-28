pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

Singleton {
    id: root

    readonly property bool        hasPrimaryMonitor: primaryMonitorName !== ""
    readonly property string      primaryMonitorName: {
        const primaryName = MonitorServices.primaryMonitorName;
        if (primaryName === "")
            return "";
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i]?.name === primaryName)
                return primaryName;
        }
        return "";
    }
    readonly property string      targetMonitorName: {
        if (primaryMonitorName !== "")
            return primaryMonitorName;
        const screens     = Quickshell.screens;
        const focusedName = Hypr.focusedMonitor?.name ?? "";
        if (focusedName !== "") {
            for (let i = 0; i < screens.length; i++) {
                if (screens[i]?.name === focusedName)
                    return focusedName;
            }
        }
        return screens.length > 0 ? (screens[0]?.name ?? "") : "";
    }
    readonly property ShellScreen targetScreen: {
        const screens = Quickshell.screens;
        if (screens.length === 0)
            return null;
        if (targetMonitorName !== "") {
            for (let i = 0; i < screens.length; i++) {
                if (screens[i]?.name === targetMonitorName)
                    return screens[i];
            }
        }
        return screens[0];
    }

    function                      isOnFocusedMonitor(monitorName: string): bool {
        if (primaryMonitorName !== "")
            return monitorName === primaryMonitorName;
        return !Configs.generals.followFocusMonitor || monitorName === targetMonitorName;
    }
}

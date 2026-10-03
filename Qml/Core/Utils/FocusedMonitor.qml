pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

import qs.Core.Configs
import qs.Services

Singleton {
    function isOnFocusedMonitor(monitorName) {
        return !Configs.generals.followFocusMonitor || monitorName === Hypr.focusedMonitor.name;
    }
}

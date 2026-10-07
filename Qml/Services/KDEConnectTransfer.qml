pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property bool   active: match !== null
    readonly property var    match: {
        for (const toplevel of root.toplevels) {
            const found = /^(.*) \((\d+)% of ([^)]+)\) — KDE Connect Daemon$/.exec(toplevel.title ?? "");
            if (found)
                return {
                    percent: Number(found[2]),
                    sizeText: found[3]
                };
        }
        return null;
    }
    readonly property int    percent: match ? match.percent : 0
    readonly property string sizeText: match ? match.sizeText : ""
    readonly property var    toplevels: Hyprland.toplevels.values ?? Hyprland.toplevels
}

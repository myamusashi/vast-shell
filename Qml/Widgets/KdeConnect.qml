pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.States
import qs.Services

StyledRect {
    id: root

    property bool dragHover: false

    color: dragHover ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : "transparent"
    implicitHeight: parent.height
    implicitWidth: kdeIcon.width + Appearance.padding.small * 2
    radius: 6
    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    IconImage {
        id: kdeIcon

        anchors.centerIn: parent
        backer.cache: true
        implicitSize: Appearance.fonts.size.normal
        opacity: KDEConnect.hasAvailableDevices ? 1.0 : 0.4
        source: Quickshell.iconPath("kdeconnect", "image-missing")
        Behavior on opacity {
            NAnim {}
        }
    }

    DropArea {
        anchors.fill: parent
        onDropped: drop => {
            root.dragHover = false;
            if (!drop.hasUrls)
                return;
            var incoming = [];
            for (var i = 0; i < drop.urls.length; i++)
                incoming.push(String(drop.urls[i]).replace("file://", ""));
            GlobalStates.shareFilesViaKdeConnect(incoming);
        }
        onEntered: drag => {
            root.dragHover = drag.hasUrls;
        }
        onExited: root.dragHover = false
        onPositionChanged: drag => {
            if (root.dragHover !== drag.hasUrls)
                root.dragHover = drag.hasUrls;
        }
    }

    Tooltip {
        anchorItem: root
        enabled: !root.dragHover
        text: {
            if (!KDEConnect.hasAvailableDevices)
                return qsTr("KDE Connect · No devices available");
            const names = KDEConnect.availableDevices.map(d => d.name).filter(Boolean).join(", ");
            return names ? qsTr("KDE Connect: %1 · Drop files to share").arg(names) : qsTr("KDE Connect · Drop files to share");
        }
    }
}

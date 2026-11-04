pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

import "../../Components"

SettingsPageBase {
    id: root

    readonly property var monitorSnapshot: MonitorServices.monitorList()

    property string       monitorKeyCache: ""
    property var          monitorKeys: []

    function              duplicateText(): string {
        const duplicates = MonitorServices.duplicateIdentities();
        return qsTr("Multiple connected monitors share the same description (%1). Hyprland matches rules by description prefix, so the stored settings apply to all of them.").arg(duplicates.join(", "));
    }

    function              luaFileText(): string {
        if (HyprlandSetupServices.luaFileState === "exists" || HyprlandSetupServices.luaFileState === "created")
            return qsTr("vast_shell.lua is set up.");
        if (HyprlandSetupServices.luaFileState === "missing" || HyprlandSetupServices.luaFileState === "creating")
            return qsTr("vast_shell.lua will be created.");
        return "";
    }

    function              refreshMonitorKeys(): void {
        const joined = monitorSnapshot.map(item => `${item.key}\u0001${item.live}`).join("\u0002");
        if (joined === monitorKeyCache)
            return;
        monitorKeyCache = joined;
        monitorKeys     = monitorSnapshot.map(item => item.key);
    }

    Component.onCompleted: root.refreshMonitorKeys()
    onMonitorSnapshotChanged: root.refreshMonitorKeys()
    pageTitle: qsTr("Hyprland Monitors")

    HyprlandNoticeCard {
        icon: "warning"
        visible: !HyprlandSetupServices.onHyprland
        warning: true

        StyledText {
            color: Colours.m3Colors.m3OnErrorContainer
            text: qsTr("Hyprland with Lua configuration was not detected. Values are saved, but only Hyprland applies them.")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    HyprlandNoticeCard {
        icon: "info"
        visible: HyprlandSetupServices.onHyprland

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                text: qsTr("Add at the bottom of hyprland.lua: %1").arg(HyprlandSetupServices.requireLine)
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurfaceVariant
                text: root.luaFileText()
                visible: text !== ""
                wrapMode: Text.Wrap
                Layout.maximumWidth: 260
            }

            ExtendedFloatingButton {
                icon.name: "content_copy"
                onClicked: HyprlandSetupServices.copyRequireLine()
            }
        }
    }

    HyprlandNoticeCard {
        icon: "warning"
        visible: MonitorServices.duplicateIdentities().length > 0
        warning: true

        StyledText {
            color: Colours.m3Colors.m3OnErrorContainer
            text: root.duplicateText()
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    SettingsCard {
        title: qsTr("Monitor Layout")

        MonitorLayoutCanvas {
            Layout.fillWidth: true
        }
    }

    SettingsCard {
        title: qsTr("Monitors")

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            text: qsTr("No monitors detected.")
            visible: root.monitorKeys.length === 0
        }

        Repeater {
            model: root.monitorKeys
            delegate: MonitorCard {
                Layout.fillWidth: true
            }
        }
    }

    footer: [
        Item {
            Layout.fillWidth: true
        },
        ExtendedFloatingButton {
            enabled: MonitorServices.dirty
            outlined: true
            text: qsTr("Revert")
            textColor: Colours.m3Colors.m3OnSurface
            onClicked: MonitorServices.discardAll()
        },
        ExtendedFloatingButton {
            enabled: MonitorServices.dirty
            text: qsTr("Apply")
            onClicked: MonitorServices.apply()
        }
    ]
}

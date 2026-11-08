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

    readonly property var  historyModel: historyMonitors.map(item => ({
                key: item.key,
                text: (item.entry.model ?? "") !== "" ? `${item.entry.model} (${item.entry.lastConnector || qsTr("offline")})` : item.key
            }))
    readonly property var  historyMonitors: monitorSnapshot.filter(item => !item.live)
    readonly property bool isSelectedHistory: historyMonitors.some(item => item.key === root.selectedMonitorKey)
    readonly property var  monitorSnapshot: MonitorServices.monitorList()

    property string        monitorKeyCache: ""
    property var           monitorKeys: []
    property string        selectedMonitorKey: ""

    function               duplicateText(): string {
        const duplicates = MonitorServices.duplicateIdentities();
        return qsTr("Multiple connected monitors share the same description (%1). Hyprland matches rules by description prefix, so the stored settings apply to all of them.").arg(duplicates.join(", "));
    }

    function               refreshMonitorKeys(): void {
        const joined = monitorSnapshot.map(item => `${item.key}\u0001${item.live}`).join("\u0002");
        if (joined === monitorKeyCache)
            return;
        monitorKeyCache = joined;
        monitorKeys     = monitorSnapshot.map(item => item.key);
        root.resolveSelectedMonitor();
    }

    function               resolveSelectedMonitor(): void {
        if (selectedMonitorKey !== "" && monitorKeys.includes(selectedMonitorKey))
            return;
        const focusedKey = Hypr.focusedMonitor ? MonitorServices.identityOf(Hypr.focusedMonitor) : "";
        if (focusedKey !== "" && monitorKeys.includes(focusedKey)) {
            selectedMonitorKey = focusedKey;
            return;
        }
        if (monitorKeys.length > 0) {
            selectedMonitorKey = monitorKeys[0];
            return;
        }
        selectedMonitorKey = "";
    }

    Connections {

        function onFocusedMonitorChanged(): void {
            if (!Hypr.focusedMonitor)
                return;
            const focusedKey = MonitorServices.identityOf(Hypr.focusedMonitor);
            if (root.monitorKeys.includes(focusedKey))
                root.selectedMonitorKey = focusedKey;
        }

        target: Hypr
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
            selectedKey: root.selectedMonitorKey
            onMonitorSelected: key => root.selectedMonitorKey = key
        }
    }

    SettingsCard {
        title: qsTr("Monitors")

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("Select a monitor from the layout above, or choose from previously connected monitors.")
            }

            SplitButton {
                id: historySplitButton

                enabled: root.historyModel.length > 0
                icon.name: "history"
                model: root.historyModel
                text: root.isSelectedHistory ? (root.historyModel.find(item => item.key === root.selectedMonitorKey)?.text ?? qsTr("History")) : qsTr("History")
                textRole: "text"
                onClicked: toggleMenu()
                onMenuItemActivated: index => {
                    if (index >= 0 && index < root.historyModel.length)
                        root.selectedMonitorKey = root.historyModel[index].key;
                }
            }
        }

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            text: qsTr("No monitors detected.")
            visible: root.selectedMonitorKey === ""
        }

        MonitorCard {
            Layout.fillWidth: true
            modelData: root.selectedMonitorKey
            visible: root.selectedMonitorKey !== ""
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

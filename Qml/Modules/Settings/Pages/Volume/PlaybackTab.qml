pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import "../../Components"

SettingsCard {
    id: root

    readonly property int count: streamNodes.length
    readonly property var streamNodes: {
        const nodes = Pipewire.nodes.values;
        const filtered = nodes.filter(n => n.isStream && n.audio && (n.type & PwNodeType.Sink));
        filtered.sort((a, b) => (a.description || a.name).localeCompare(b.description || b.name));
        return filtered;
    }

    title: qsTr("Playback")

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("No active playback streams.")
            visible: root.count === 0
        }
        Repeater {
            model: root.streamNodes

            delegate: RowLayout {
                id: streamDelegate

                required property PwNode modelData

                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                IconImage {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 48
                    Layout.preferredWidth: 48
                    asynchronous: true
                    source: IconUtils.guessIconPath(streamDelegate.modelData)
                }
                AudioLevelRow {
                    Layout.fillWidth: true
                    node: streamDelegate.modelData
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import "../../Components"

SettingsCard {
    id: root

    readonly property int count: sinkNodes.length
    readonly property var currentSink: Pipewire.defaultAudioSink
    readonly property var sinkNodes: {
        const nodes = Pipewire.nodes.values;
        const filtered = nodes.filter(n => !n.isStream && n.audio && (n.type & PwNodeType.Sink));
        filtered.sort((a, b) => (a.description || a.name).localeCompare(b.description || b.name));
        return filtered;
    }

    title: qsTr("Output Devices")

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("No output devices detected.")
            visible: root.count === 0
        }
        Repeater {
            model: root.sinkNodes

            delegate: AudioLevelRow {
                id: sinkDelegate

                required property PwNode modelData

                Layout.fillWidth: true
                isCurrent: root.currentSink && sinkDelegate.modelData.id === root.currentSink.id
                node: sinkDelegate.modelData
                selectable: true

                onDefaultRequested: {
                    Pipewire.preferredDefaultAudioSink = sinkDelegate.modelData;
                    Configs.audio.defaultSinkName = sinkDelegate.modelData.name;
                }
            }
        }
    }
}

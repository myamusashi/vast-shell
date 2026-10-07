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

    readonly property int count: sourceNodes.length
    readonly property var currentSource: Pipewire.defaultAudioSource
    readonly property var sourceNodes: {
        const nodes    = Pipewire.nodes.values;
        const filtered = nodes.filter(n => !n.isStream && n.audio && (n.type & PwNodeType.Source));
        filtered.sort((a, b) => (a.description || a.name).localeCompare(b.description || b.name));
        return filtered;
    }

    title: qsTr("Input Devices")

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("No input devices detected.")
            visible: root.count === 0
        }

        Repeater {
            model: root.sourceNodes
            delegate: AudioLevelRow {
                id: sourceDelegate

                required property PwNode modelData

                Layout.fillWidth: true
                isCurrent: root.currentSource && sourceDelegate.modelData.id === root.currentSource.id
                node: sourceDelegate.modelData
                selectable: true
                onDefaultRequested: {
                    Pipewire.preferredDefaultAudioSource = sourceDelegate.modelData;
                }
            }
        }
    }
}

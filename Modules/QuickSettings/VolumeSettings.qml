pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Widgets

ScrollView {
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    RowLayout {
        anchors.fill: parent
        Layout.margins: 15
        spacing: 20

        ColumnLayout {
            Layout.margins: 10
            Layout.alignment: Qt.AlignTop

            PwNodeLinkTracker {
                id: linkTracker

                node: Pipewire.defaultAudioSink
            }

            MixerEntry {
                useCustomProperties: true
                node: Pipewire.defaultAudioSink

                customProperty: AudioProfiles {}
            }

            Rectangle {
                Layout.fillWidth: true
                color: Themes.m3Colors.m3Outline
                implicitHeight: 1
            }

            Repeater {
                model: linkTracker.linkGroups

                MixerEntry {
                    required property PwLinkGroup modelData
                    useCustomProperties: false
                    node: modelData.source
                }
            }
        }
    }
}

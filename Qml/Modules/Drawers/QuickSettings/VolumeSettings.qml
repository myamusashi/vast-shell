pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Vast.Audio

import qs.Core.Configs
import qs.Core.Utils
import qs.Widgets
import qs.Services
import qs.Components.Base

ScrollView {
    id: root

    anchors.fill: parent
    clip: true
    contentWidth: availableWidth

    RowLayout {
        Layout.margins: 15
        anchors.fill: parent
        spacing: 20

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.margins: 10

            PwNodeLinkTracker {
                id: linkTracker

                node: Pipewire.defaultAudioSink
            }

            Repeater {
                delegate: RowLayout {
                    id: volumeEntryDelegate

                    required property int    index
                    required property PwNode modelData

                    readonly property bool   isCurrentSink: Pipewire.defaultAudioSink?.id === modelData.id

                    spacing: Appearance.spacing.small

                    StyledRect {
                        id: sinkIndicator

                        border.color: Colours.m3Colors.m3Primary
                        border.width: 1
                        color: volumeEntryDelegate.isCurrentSink ? Colours.m3Colors.m3Primary : "transparent"
                        implicitHeight: 15
                        implicitWidth: 15
                    }

                    StyledText {
                        color: volumeEntryDelegate.isCurrentSink ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: volumeEntryDelegate.isCurrentSink ? Font.Medium : Font.Normal
                        text: volumeEntryDelegate.modelData.description ?? ""
                    }

                    TapHandler {
                        onTapped: {
                            AudioDevicesWatcher.setDefaultSink(volumeEntryDelegate.modelData.name);
                            Configs.audio.defaultSinkName = volumeEntryDelegate.modelData.name;
                        }
                    }
                }
                model: ScriptModel {
                    objectProp: "id"
                    values: Pipewire.nodes.values.filter(node => !node.isStream && node.audio && (node.type & PwNodeType.Sink))
                }
            }

            MixerEntry {
                audioNode: Pipewire.defaultAudioSink
                useCustomProperties: true
                customProperty: AudioProfiles {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3Outline
                implicitHeight: 1
            }

            Repeater {
                model: linkTracker.linkGroups
                delegate: RowLayout {
                    id: groups

                    required property PwLinkGroup modelData

                    Layout.alignment: Qt.AlignLeft
                    Layout.fillWidth: true

                    PwObjectTracker {
                        objects: [groups.modelData.source]
                    }

                    IconImage {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 60
                        Layout.preferredWidth: 60
                        asynchronous: true
                        source: IconUtils.guessIconPath(groups.modelData.source)
                    }

                    MixerEntry {
                        id: mixerGroup

                        audioNode: groups.modelData.source
                    }
                }
            }
        }
    }
}

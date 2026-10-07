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
import qs.Components.Effects

ScrollView {
    id: root

    property var    audioCards: ({})
    property string audioProfileDescription: ""
    property string audioProfileName: ""
    property int    currentSinkIndex: 0

    anchors.fill: parent
    clip: true
    contentWidth: availableWidth

    Instantiator {
        id: audioProfiles

        model: AudioProfilesWatcher.cards
        delegate: QtObject {
            required property var    card
            required property string description
            required property string name

            Component.onCompleted: {
                root.audioCards              = card;
                root.audioProfileName        = name;
                root.audioProfileDescription = description;
            }
        }
    }

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

                    required property int index
                    required property var modelData

                    spacing: Appearance.spacing.small

                    StyledRect {
                        id: sinkIndicator

                        property color target: root.currentSinkIndex === volumeEntryDelegate.index ? Colours.m3Colors.m3Primary : "transparent"

                        border.color: Colours.m3Colors.m3Primary
                        border.width: 1
                        implicitHeight: 15
                        implicitWidth: 15

                        BlendColor {
                            host: sinkIndicator
                            target: sinkIndicator.target
                        }
                    }

                    StyledText {
                        color: root.currentSinkIndex === volumeEntryDelegate.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: root.currentSinkIndex === volumeEntryDelegate.index ? Font.Medium : Font.Normal
                        text: volumeEntryDelegate.modelData.description ?? ""
                    }

                    TapHandler {
                        onTapped: {
                            root.currentSinkIndex = volumeEntryDelegate.index;
                            AudioDevicesWatcher.setDefaultSink(volumeEntryDelegate.modelData.name);
                            Configs.audio.defaultSinkName = volumeEntryDelegate.modelData.name;
                        }
                    }
                }
                model: ScriptModel {
                    values: Pipewire.nodes.values.filter(n => !n.isStream && n.audio && (n.type & PwNodeType.Sink)).map(n => ({
                                nodeId: n.id,
                                name: n.name,
                                description: n.description
                            }))
                }
            }

            MixerEntry {
                audioNode: Pipewire.defaultAudioSink
                useCustomProperties: true
                customProperty: AudioProfiles {
                    Layout.fillWidth: true
                    card: root.audioCards
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

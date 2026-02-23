pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Helpers
import qs.Widgets
import qs.Services
import qs.Components

ScrollView {
    id: root

    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    property int currentSinkIndex: 0

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

            Repeater {
                model: ScriptModel {
                    values: [...Audio.listSink]
                }

                delegate: RowLayout {
                    id: del

                    required property var modelData
                    required property int index

                    spacing: Appearance.spacing.small

                    StyledRect {
                        implicitWidth: 15
                        implicitHeight: 15
                        radius: Appearance.rounding.full
                        color: root.currentSinkIndex === del.index ? Colours.m3Colors.m3Primary : "transparent"
                        border.width: 2
                        border.color: Colours.m3Colors.m3Primary

                        Behavior on color {
                            CAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }
                    }

                    StyledText {
                        text: del.modelData.description ?? ""
                        color: root.currentSinkIndex === del.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: root.currentSinkIndex === del.index ? Font.Medium : Font.Normal
                    }

                    TapHandler {
                        onTapped: {
                            root.currentSinkIndex = del.index;
                            Quickshell.execDetached({
                                command: ["wpctl", "set-default", del.modelData.nodeId]
                            });
                        }
                    }
                }
            }

            RowLayout {
                MixerEntry {
                    useCustomProperties: true
                    node: Pipewire.defaultAudioSink
                    customProperty: AudioProfiles {}
                }

                Icon {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: (42 - font.pixelSize) / 2
                    icon: "refresh"
                    color: Colours.m3Colors.m3Primary
                    font.pixelSize: Appearance.fonts.size.large * 1.5

                    MArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.restartAudioProfiles()
                    }
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

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    IconImage {
                        source: Quickshell.iconPath(DesktopEntries.heuristicLookup(groups.modelData.source.name)?.icon, "image-missing")
                        asynchronous: true
                        Layout.preferredWidth: 60
                        Layout.preferredHeight: 60
                        Layout.alignment: Qt.AlignVCenter
                    }

                    MixerEntry {
                        id: mixerGroup

                        node: groups.modelData.source
                    }
                }
            }
        }
    }
}

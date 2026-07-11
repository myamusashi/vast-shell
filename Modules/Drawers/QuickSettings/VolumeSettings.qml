pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.Utils
import qs.Widgets
import qs.Services
import qs.Components.Base

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
                        id: sinkIndicator
                        property color _target: root.currentSinkIndex === del.index ? Colours.m3Colors.m3Primary : "transparent"
                        property color _cFrom
                        property color _cTo
                        property bool _cActive: false
                        property real _cBlend: 1.0
                        on_CBlendChanged: {
                            if (!_cActive) return
                            if (_cBlend >= 1) {
                                color = _cTo
                                _cActive = false
                            } else if (_cBlend > 0) {
                                color = Colours.blendColors(_cFrom, _cTo, _cBlend)
                            }
                        }
                        on_TargetChanged: {
                            _cAnim.stop()
                            _cFrom = color
                            _cTo = _target
                            _cActive = true
                            _cBlend = 0.0
                            _cAnim.start()
                        }

                        implicitWidth: 15
                        implicitHeight: 15
                        radius: Appearance.rounding.full
                        border.width: 2
                        border.color: Colours.m3Colors.m3Primary

                        NumberAnimation {
                            id: _cAnim
                            target: sinkIndicator
                            property: "_cBlend"
                            from: 0.0
                            to: 1.0
                            duration: Appearance.animations.durations.small
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animations.curves.standard
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

            MixerEntry {
                useCustomProperties: true
                node: Pipewire.defaultAudioSink
                customProperty: AudioProfiles {}
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

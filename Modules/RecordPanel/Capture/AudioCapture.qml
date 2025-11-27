pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Widgets
import qs.Components

ClippingRectangle {
    id: root

    required property int state
    signal tabClicked(int index)

    Layout.fillWidth: true
    Layout.preferredHeight: columnContent.implicitHeight
    color: Themes.m3Colors.m3SurfaceContainerHigh

    ColumnLayout {
        id: columnContent

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 0

        Header {
            id: tabLayout
        }

        View {
            id: audioCaptureStackView
        }
    }

    component Header: Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 50

        RowLayout {
            id: tabRowLayout

            anchors.fill: parent
            anchors.margins: 5
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: Appearance.spacing.large

            Repeater {
                id: tabRepeater

                model: [
                    {
                        "title": "Mix",
                        "index": 0
                    },
                    {
                        "title": "Voice",
                        "index": 1
                    }
                ]

                StyledButton {
                    id: audioTabButton

                    required property var modelData
                    required property int index
                    buttonTitle: modelData.title
                    Layout.preferredWidth: implicitWidth
                    buttonColor: "transparent"
                    buttonTextColor: root.state === index ? Themes.m3Colors.m3Primary : Themes.m3Colors.m3OnBackground
                    onClicked: root.tabClicked(index)
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Themes.m3Colors.m3OutlineVariant
        }

        StyledRect {
            id: indicator

            anchors.bottom: parent.bottom
            width: tabRepeater.itemAt(root.state).width
            height: 5
            color: Themes.m3Colors.m3Primary
            radius: Appearance.rounding.large
            x: {
                var item = tabRepeater.itemAt(root.state);
                return item.x + tabRowLayout.anchors.leftMargin;
            }
            visible: tabRepeater.itemAt(root.state) !== null

            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            Behavior on width {
                NAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                }
            }
        }
    }

    component View: StackView {
        property Component viewComponent: contentView

        Layout.fillWidth: true
        Layout.preferredHeight: 250

        initialItem: viewComponent
        onCurrentItemChanged: {
            if (currentItem)
                currentItem.viewIndex = root.state;
        }

        Component {
            id: contentView

            StyledRect {
                implicitHeight: 250
                property int viewIndex: 0

                Loader {
                    anchors.fill: parent
                    active: parent.viewIndex === 0
                    visible: active

                    sourceComponent: Mix {}
                }

                Loader {
                    anchors.fill: parent
                    active: parent.viewIndex === 1
                    visible: active

                    sourceComponent: Voice {}
                }
            }
        }
    }

    component Mix: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        anchors.rightMargin: 10
        anchors.leftMargin: 10
        spacing: Appearance.spacing.normal
        StyledLabel {
            text: "LINUX DEFAULT OUTPUT"
            font.pixelSize: Appearance.fonts.large
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            implicitHeight: contentLayout.implicitHeight
            clip: true

            RowLayout {
                id: contentLayout

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

                    CustomMixerEntry {
                        useCustomProperties: true
                        node: Pipewire.defaultAudioSink

                        customProperty: AudioProfiles {}
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        color: Themes.m3Colors.m3Outline
                        implicitHeight: 1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        Repeater {
                            model: linkTracker.linkGroups

                            delegate: Item {
                                id: delegateTracker

                                required property PwLinkGroup modelData
                                Layout.fillWidth: true
                                implicitHeight: rowLayout.implicitHeight

                                RowLayout {
                                    id: rowLayout

                                    anchors.fill: parent
                                    spacing: 10

                                    IconImage {
                                        source: Quickshell.iconPath(Players.active.desktopEntry)
                                        asynchronous: true
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 60
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    CustomMixerEntry {
                                        Layout.fillWidth: true
                                        useCustomProperties: false
                                        node: delegateTracker.modelData.source
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
    component Voice: ColumnLayout {}
}

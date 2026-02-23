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

StyledRect {
    id: root

    required property int state
    signal tabClicked(int index)

    Layout.fillWidth: true
    Layout.preferredHeight: columnContent.implicitHeight
    color: Colours.m3Colors.m3SurfaceContainerHigh
    radius: 0
    clip: true

    ColumnLayout {
        id: columnContent

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Appearance.margin.normal
        }

        spacing: Appearance.spacing.normal

        Header {
            id: tabLayout
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colours.m3Colors.m3OutlineVariant
        }

        View {
            id: audioCaptureStackView
        }
    }

    component Header: RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        height: 40

        Repeater {
            model: ["Mix", "Voice"]

            delegate: Item {
                id: delegate

                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: 40

                StyledRect {
                    anchors.fill: parent
                    color: root.state === delegate.index ? Colours.m3Colors.m3Primary : "transparent"
                    opacity: 0.1
                    radius: 0
                }

                StyledLabel {
                    id: tabLabel

                    anchors.centerIn: parent
                    text: delegate.modelData.toUpperCase()
                    font.pixelSize: Appearance.fonts.size.small
                    font.bold: root.state === delegate.index
                    color: root.state === delegate.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledRect {
                    anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }
                    implicitHeight: 2
                    color: Colours.m3Colors.m3Primary
                    visible: root.state === delegate.index
                    opacity: visible ? 1 : 0
                    radius: 0

                    Behavior on opacity {
                        NAnim {}
                    }
                }

                MArea {
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tabClicked(delegate.index)
                    layerRadius: 0
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
            text: qsTr("LINUX DEFAULT OUTPUT")
            font.pixelSize: Appearance.fonts.size.large
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

                    MixerEntry {
                        node: Pipewire.defaultAudioSink
                        useCustomProperties: true
                        customProperty: AudioProfiles {}
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3Outline
                        implicitHeight: 1
                    }

                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.topMargin: 20
                        Repeater {
                            model: ScriptModel {
                                values: [...linkTracker.linkGroups]
                            }

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
                                        source: {
                                            const name = delegateTracker.modelData.source.name;
                                            const appName = name.split(".").pop();

                                            // alright man
                                            let isZen = appName === "zen" || appName === "zen-twilight" || appName === "Twilight" || appName === "twilight";

                                            if (isZen) {
                                                const entry = DesktopEntries.heuristicLookup("zen-twilight") ?? DesktopEntries.heuristicLookup("zen");
                                                return Quickshell.iconPath(entry?.icon, "image-missing");
                                            }

                                            return Quickshell.iconPath(DesktopEntries.heuristicLookup(appName)?.icon, "image-missing");
                                        }
                                        asynchronous: true
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 60
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    MixerEntry {
                                        Layout.fillWidth: true
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

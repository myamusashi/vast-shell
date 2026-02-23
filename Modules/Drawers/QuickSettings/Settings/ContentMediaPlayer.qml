pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Qcm.Material as MD

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

RowLayout {
    id: root

    property var trackArtColors: ({})
    property bool hovered: false
    property var formatTime: function (seconds) {
        return "0:00";
    }

    spacing: Appearance.spacing.small

    ColumnLayout {
        Layout.margins: 8
        Layout.fillWidth: true
        spacing: Appearance.spacing.small
        opacity: root.hovered ? 1 : 0

        Behavior on opacity {
            NAnim {}
        }

        StyledLabel {
            Layout.fillWidth: true
            text: Players.active?.trackTitle ?? ""
            color: root.trackArtColors.onSurface
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                text: Players.active?.trackArtist ?? ""
                color: root.trackArtColors.onSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                text: Players.active == null ? "0:00" : `${root.formatTime(Players.active?.position)} / ${root.formatTime(Players.active?.length)}`
                color: root.trackArtColors.onSurface
                font.pixelSize: Appearance.fonts.size.small
                font.weight: Font.DemiBold

                Timer {
                    running: GlobalStates.isQuickSettingsOpen && Players.active?.playbackState == MprisPlaybackState.Playing
                    interval: 1000
                    repeat: true
                    onTriggered: Players.active.positionChanged()
                }
            }
        }

        Wavy {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            activeColor: root.trackArtColors.primary
            value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0
            enableWave: Players.active?.playbackState === MprisPlaybackState.Playing && !pressed
            onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

            FrameAnimation {
                running: GlobalStates.isMediaPlayerOpen && Players.active?.playbackState == MprisPlaybackState.Playing
                onTriggered: Players.active.positionChanged()
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: controlsRow.implicitHeight

            RowLayout {
                id: controlsRow

                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                StyledButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    bgRadius: Appearance.rounding.normal
                    icon.name: Players.active?.shuffleSupported || Players.active?.shuffleSupported || Players.active?.shuffle ? "shuffle_on" : "shuffle"
                    icon.color: Players.active?.shuffleSupported || Players.active?.shuffle ? root.trackArtColors.primary : root.trackArtColors.outline
                    color: "transparent"
                    enabled: Players.active?.shuffleSupported
                    onClicked: {
                        if (Players.active)
                            Players.active.shuffle = !Players.active.shuffle;
                    }
                }

                StyledButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    bgRadius: Appearance.rounding.normal
                    icon.name: "skip_previous"
                    icon.color: root.trackArtColors.onPrimary
                    color: root.trackArtColors.primary
                    onClicked: Players.active?.previous()
                }

                Icon {
                    icon: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                    color: root.trackArtColors.onSurface
                    font.pixelSize: Appearance.fonts.size.extraLarge * 1.2
                    MArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Players.active?.togglePlaying()
                    }
                }

                StyledButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    icon.name: "skip_next"
                    icon.color: root.trackArtColors.onPrimary
                    bgRadius: Appearance.rounding.normal
                    color: root.trackArtColors.primary
                    onClicked: Players.active?.next()
                }

                StyledButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    bgRadius: Appearance.rounding.normal
                    icon.name: Players.active?.loopState === MprisLoopState.Playlist ? "repeat_on" : Players.active?.loopState === MprisLoopState.Track ? "repeat_one_on" : "repeat"
                    icon.color: Players.active?.loopSupported || (Players.active?.loopState === MprisLoopState.Playlist || Players.active?.loopState === MprisLoopState.Track) ? root.trackArtColors.primary : root.trackArtColors.outline
                    color: "transparent"
                    enabled: Players.active?.loopSupported
                    onClicked: {
                        if (!Players.active)
                            return;
                        switch (Players.active.loopState) {
                        case MprisLoopState.None:
                            Players.active.loopState = MprisLoopState.Playlist;
                            break;
                        case MprisLoopState.Playlist:
                            Players.active.loopState = MprisLoopState.Track;
                            break;
                        case MprisLoopState.Track:
                            Players.active.loopState = MprisLoopState.None;
                            break;
                        }
                    }
                }
            }

            ComboBox {
                id: playerComboBox

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                model: Players.players
                textRole: "desktopMenu"
                onActivated: index => {
                    currentIndex = index;
                    Players.index = index;
                }

                contentItem: Row {
                    spacing: Appearance.spacing.small
                    leftPadding: Appearance.padding.normal

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        source: Players.active ? Quickshell.iconPath(Players.active.desktopEntry) : ""
                        implicitWidth: 20
                        implicitHeight: 20
                        asynchronous: true
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Players.active?.desktopEntry ?? "No Player"
                        color: root.trackArtColors.onSurface
                        font.pixelSize: Appearance.fonts.size.large
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                background: StyledRect {
                    implicitWidth: 140
                    implicitHeight: 28
                    color: "transparent"
                }

                popup: Popup {
                    y: playerComboBox.height + 4
                    x: playerComboBox.width - width
                    width: 220
                    padding: 0
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

                    enter: Transition {
                        NAnim {
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: Appearance.animations.durations.small
                        }
                        NAnim {
                            property: "scale"
                            from: 0.95
                            to: 1
                            duration: Appearance.animations.durations.small
                        }
                    }
                    exit: Transition {
                        NAnim {
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: Appearance.animations.durations.small
                        }
                    }

                    background: StyledRect {
                        color: root.trackArtColors.surfaceVariant
                        radius: Appearance.rounding.large

                        Elevation {
                            anchors.fill: parent
                            z: -1
                            level: 2
                            radius: parent.radius - 2
                        }
                    }

                    contentItem: ListView {
                        id: listView

                        implicitHeight: Math.min(contentHeight, 320)
                        model: playerComboBox.delegateModel
                        clip: true
                        currentIndex: playerComboBox.currentIndex

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        header: Item {
                            height: 8
                        }
                        footer: Item {
                            height: 8
                        }
                    }
                }

                delegate: ItemDelegate {
                    id: itemDel

                    required property MprisPlayer modelData
                    required property int index

                    width: playerComboBox.popup.width
                    highlighted: playerComboBox.highlightedIndex === index

                    onClicked: {
                        playerComboBox.currentIndex = index;
                        Players.index = index;
                        playerComboBox.popup.close();
                    }

                    background: StyledRect {
                        id: itemBg

                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: Appearance.margin.small
                        }
                        radius: Appearance.rounding.normal
                        height: parent.height
                        color: (playerComboBox.currentIndex === itemDel.index || itemDel.highlighted) ? Qt.darker(root.trackArtColors.primary, 1.5) : "transparent"

                        Behavior on color {
                            CAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }

                        MD.Ripple2 {
                            anchors.fill: parent
                            radius: itemBg.radius
                            pressX: itemDel.pressX
                            pressY: itemDel.pressY
                            pressed: itemDel.pressed
                            stateOpacity: 0.08
                            color: root.trackArtColors.primary
                        }
                    }

                    contentItem: Row {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: Appearance.margin.large
                            rightMargin: Appearance.margin.large
                        }
                        spacing: Appearance.spacing.normal

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            source: Quickshell.iconPath(itemDel.modelData.desktopEntry, "image-missing")
                            asynchronous: true
                            implicitWidth: 20
                            implicitHeight: 20
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 16 - parent.spacing
                            text: itemDel.modelData.desktopEntry ?? ""
                            color: root.trackArtColors.onSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: playerComboBox.currentIndex === itemDel.index ? Font.Medium : Font.Normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}

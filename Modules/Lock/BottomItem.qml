pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris

import qs.Core.Configs
import qs.Core.Utils
import qs.Components.Base
import qs.Services

Item {
    id: root

    anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
        bottomMargin: Appearance.margin.normal
    }

    property alias lockIcon: lockIcon
    property alias iconName: lockIcon.icon
    property alias contentLayout: contentLayout

    required property bool isLockscreenOpen
    required property color drawerColors
    required property var pam

    property string inputBuffer: ""
    property bool showErrorMessage: false

    FontMetrics {
        id: lockIconMetrics
        font: lockIcon.font
    }

    implicitHeight: 0

    Behavior on implicitHeight {
        NAnim {}
    }

    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: Appearance.spacing.normal

        Item {
            Layout.fillWidth: true
        }

        WrapperRectangle {
            id: bottomWrapperRect

            Layout.fillHeight: true
            implicitHeight: mediaLayout.implicitHeight + Appearance.margin.small * 2
            color: root.drawerColors
            clip: true
            radius: Appearance.rounding.normal
            leftMargin: Appearance.margin.normal
            rightMargin: Appearance.margin.normal

            RowLayout {
                id: contentLayout

                anchors {
                    fill: parent
                    leftMargin: Appearance.margin.normal
                    rightMargin: Appearance.margin.normal
                }
                spacing: Appearance.spacing.normal
                opacity: 0

                ClippingWrapperRectangle {
                    implicitWidth: 48
                    implicitHeight: 48
                    radius: Appearance.rounding.full
                    color: "transparent"
                    z: -1

                    IconImage {
                        id: avatar

                        source: Qt.resolvedUrl(`${Paths.home}/.face`)
                        z: 1
                        backer.cache: true
                        asynchronous: true
                    }
                }

                Icon {
                    id: lockIcon

                    property color c0From
                    property color c0To
                    property bool c0Active: false
                    property real c0Blend: 1.0

                    onC0BlendChanged: {
                        if (!c0Active)
                            return;
                        if (c0Blend >= 1) {
                            color = c0To;
                            c0Active = false;
                        } else if (c0Blend > 0) {
                            color = Colours.blendColors(c0From, c0To, c0Blend);
                        }
                    }

                    NAnim {
                        id: c0Anim
                        target: lockIcon
                        property: "c0Blend"
                        from: 0.0
                        to: 1.0
                        duration: Appearance.animations.durations.small
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }

                    Layout.alignment: Qt.AlignCenter
                    icon: "lock"
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                    transformOrigin: Item.Bottom

                    SequentialAnimation {
                        id: shakeAnim
                        running: root.showErrorMessage

                        NAnim {
                            target: lockIcon
                            property: "rotation"
                            to: 18
                            duration: 100
                            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                        }
                        NAnim {
                            target: lockIcon
                            property: "rotation"
                            to: -18
                            duration: 100
                            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                        }
                        NAnim {
                            target: lockIcon
                            property: "rotation"
                            to: 12
                            duration: 100
                            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                        }
                        NAnim {
                            target: lockIcon
                            property: "rotation"
                            to: -12
                            duration: 100
                            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                        }
                        NAnim {
                            target: lockIcon
                            property: "rotation"
                            to: 6
                            duration: 100
                            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                        }
                        NAnim {
                            target: lockIcon
                            property: "rotation"
                            to: -6
                            duration: 100
                            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                        }
                        NAnim {
                            target: lockIcon
                            property: "rotation"
                            to: 0
                            duration: 100
                            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                        }
                        ScriptAction {
                            script: {
                                c0Anim.stop();
                                c0From = lockIcon.color;
                                c0To = Colours.m3Colors.m3Red;
                                c0Active = true;
                                c0Blend = 0.0;
                                c0Anim.start();
                            }
                        }
                    }
                }

                StyledText {
                    id: errorLabel

                    Layout.alignment: Qt.AlignCenter
                    text: "WRONG"
                    color: Colours.m3Colors.m3Error
                    font.pixelSize: Appearance.fonts.size.medium
                    font.bold: true
                    opacity: root.showErrorMessage ? 1 : 0
                    visible: root.showErrorMessage

                    Behavior on opacity {
                        NAnim {
                            duration: 200
                        }
                    }
                }

                Clock {
                    id: clockItem
                    Layout.alignment: Qt.AlignCenter
                }

                StyledRect {
                    id: submitBtn

                    property color c1From
                    property color c1To
                    property bool c1Active: false
                    property real c1Blend: 1.0

                    onC1BlendChanged: {
                        if (!c1Active)
                            return;
                        if (c1Blend >= 1) {
                            color = c1To;
                            c1Active = false;
                        } else if (c1Blend > 0) {
                            color = Colours.blendColors(c1From, c1To, c1Blend);
                        }
                    }

                    NAnim {
                        id: c1Anim
                        target: submitBtn
                        property: "c1Blend"
                        from: 0.0
                        to: 1.0
                        duration: Appearance.animations.durations.small
                    }

                    readonly property bool loading: root.pam.unlockInProgress
                    readonly property bool canSubmit: root.pam && root.inputBuffer.length > 0

                    property color submitTarget: canSubmit ? root.pam.isUnlock ? Qt.alpha(Colours.m3Colors.m3Primary, 0.4) : Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3Primary, 0.4)

                    implicitWidth: 34
                    implicitHeight: 34
                    radius: Appearance.rounding.full
                    scale: pressHandler.pressed ? 0.88 : hoverHandler.hovered ? 1.08 : 1.0

                    onSubmitTargetChanged: {
                        c1Anim.stop();
                        c1From = submitBtn.color;
                        c1To = submitTarget;
                        c1Active = true;
                        c1Blend = 0.0;
                        c1Anim.start();
                    }
                    Behavior on scale {
                        NAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }

                    Icon {
                        anchors.centerIn: parent
                        icon: submitBtn.loading ? "refresh" : "arrow_right_alt"
                        color: Colours.m3Colors.m3OnPrimary
                        font.pixelSize: Appearance.fonts.size.large * 1.3
                        opacity: submitBtn.loading ? 0.85 : 1.0

                        Behavior on opacity {
                            NAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }

                        RotationAnimator on rotation {
                            id: spinAnim
                            running: submitBtn.loading
                            from: 0
                            to: 360
                            duration: 900
                            loops: Animation.Infinite
                            easing.type: Easing.Linear
                        }

                        NAnim on rotation {
                            running: !submitBtn.loading
                            to: 0
                            duration: 0
                        }
                    }

                    HoverHandler {
                        id: hoverHandler
                        cursorShape: submitBtn.canSubmit ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                    }

                    TapHandler {
                        id: pressHandler
                        enabled: submitBtn.canSubmit && !submitBtn.loading
                        onTapped: {
                            root.pam.currentText = root.inputBuffer;
                            root.pam.tryUnlock();
                        }
                    }
                }
            }
        }

        StyledRect {
            id: mediaPlayerRect
            visible: Players.active !== null
            color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHighest, 0.3)
            radius: Appearance.rounding.normal

            Elevation {
                anchors.fill: parent
                level: 1
                radius: parent.radius
            }

            Layout.alignment: Qt.AlignVCenter
            implicitHeight: mediaLayout.implicitHeight + Appearance.margin.small * 2
            implicitWidth: Math.max(280, mediaRow.implicitWidth + Appearance.margin.normal * 2)

            ColumnLayout {
                id: mediaLayout
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Appearance.margin.small
                }
                spacing: Appearance.spacing.small

                RowLayout {
                    id: mediaRow
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    Item {
                        implicitWidth: 28
                        implicitHeight: 28

                        Icon {
                            anchors.fill: parent
                            icon: "music_note"
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.large
                        }

                        Image {
                            anchors.fill: parent
                            visible: Players.active?.trackArtUrl !== "" && Players.active?.trackArtUrl !== undefined
                            source: Players.active?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.maximumWidth: 120

                        StyledText {
                            text: Players.active?.trackTitle ?? ""
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.small
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: Players.active?.trackArtist ?? ""
                            color: Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.xSmall
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Icon {
                        icon: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active?.togglePlaying()
                        }
                    }

                    Icon {
                        icon: "skip_next"
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large

                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active?.next()
                        }
                    }
                }

                Wavy {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0
                    enableWave: Players.active?.playbackState === MprisPlaybackState.Playing
                    onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

                    FrameAnimation {
                        running: Players.active?.playbackState === MprisPlaybackState.Playing
                        onTriggered: Players.active.positionChanged()
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }
}

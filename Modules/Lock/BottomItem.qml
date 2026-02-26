pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Item {
    id: root

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
    }

    property alias leftCorner: bottomLeftCorner
    property alias rightCorner: bottomRightCorner
    property alias showConfirmDialog: sessionWrapperRect.showConfirmDialog
    property alias pendingAction: sessionWrapperRect.pendingAction
    property alias pendingActionName: sessionWrapperRect.pendingActionName

    required property bool isLockscreenOpen
    required property color drawerColors
    required property var pam

    property bool isUnlock: false

    // Prefer explicit height so children aren't clipped unexpectedly
    implicitWidth: isLockscreenOpen ? bottomWrapperRect.implicitWidth : icon.implicitWidth
    implicitHeight: isLockscreenOpen ? bottomWrapperRect.implicitHeight : 0

    Behavior on implicitWidth {
        NAnim {}
    }
    Behavior on implicitHeight {
        NAnim {}
    }

    Corner {
        id: bottomRightCorner

        location: Qt.BottomRightCorner
        extensionSide: Qt.Horizontal
        radius: 0
        color: root.drawerColors
    }

    Corner {
        id: bottomLeftCorner

        location: Qt.BottomLeftCorner
        extensionSide: Qt.Horizontal
        radius: 0
        color: root.drawerColors
    }

    WrapperRectangle {
        id: bottomWrapperRect

        anchors.fill: parent
        color: root.drawerColors
        clip: true
        radius: 0
        leftMargin: Appearance.margin.large
        rightMargin: Appearance.margin.large
        topLeftRadius: Appearance.rounding.normal
        topRightRadius: topLeftRadius

        RowLayout {
            id: mainRow

            anchors {
                fill: parent
                leftMargin: Appearance.margin.normal
                rightMargin: Appearance.margin.normal
            }
            spacing: Appearance.spacing.normal

            ClippingRectangle {
                implicitWidth: 60
                implicitHeight: 60
                radius: Appearance.rounding.full
                color: "transparent"
                z: -1

                IconImage {
                    id: icon
                    anchors.fill: parent
                    source: Qt.resolvedUrl(`${Paths.home}/.face`)
                    z: 1
                }
            }

            RowLayout {
                Item {
                    id: passwordField

                    implicitWidth: 200
                    implicitHeight: 40

                    readonly property bool isUnlocked: root.pam ? root.pam.isUnlock : false
                    property var shape: [MaterialShape.Clover4Leaf, MaterialShape.Arrow, MaterialShape.Pill, MaterialShape.SoftBurst, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon]

                    TextInput {
                        id: passwordInput

                        width: 0
                        height: 0
                        visible: false

                        echoMode: TextInput.Password
                        passwordMaskDelay: 0
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        enabled: !root.pam.unlockInProgress

                        text: root.pam || root.pam.isUnlock ? root.pam.currentText : ""

                        onTextChanged: {
                            if (root.pam)
                                root.pam.currentText = text;
                        }

                        Keys.onReturnPressed: {
                            if (root.pam && text.length > 0)
                                root.pam.tryUnlock();
                        }

                        Component.onCompleted: forceActiveFocus()
                    }

                    Connections {
                        target: root.pam
                        enabled: root.pam !== null

                        function onCurrentTextChanged() {
                            if (passwordInput.text !== root.pam.currentText)
                                passwordInput.text = root.pam.currentText;
                        }
                    }

                    ListModel {
                        id: dotsModel
                    }

                    Connections {
                        target: passwordInput
                        function onTextChanged() {
                            const len = passwordInput.text.length;
                            while (dotsModel.count < len)
                                dotsModel.append({});
                            while (dotsModel.count > len)
                                dotsModel.remove(dotsModel.count - 1);

                            Qt.callLater(() => dotsView.positionViewAtEnd());
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        visible: passwordInput.text.length === 0
                        text: root.pam.showFailure ? qsTr("Password invalid") : qsTr("Enter password")
                        color: root.pam.showFailure ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.large
                    }

                    ListView {
                        id: dotsView

                        anchors.centerIn: parent
                        orientation: ListView.Horizontal
                        spacing: 1
                        model: dotsModel
                        clip: true

                        visible: passwordInput.text.length > 0
                        implicitWidth: Math.min(contentWidth, passwordField.implicitWidth)
                        implicitHeight: 20

                        Behavior on implicitWidth {
                            NAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }

                        delegate: MaterialShape {
                            id: passwordShape

                            required property int index

                            implicitWidth: 20
                            implicitHeight: 20
                            shape: passwordField.shape[index % passwordField.shape.length]
                            color: root.pam.unlockInProgress ? Colours.m3Colors.m3OnSurfaceVariant : root.pam.isUnlock ? Colours.m3Colors.m3Green : Colours.m3Colors.m3Primary

                            Behavior on color {
                                CAnim {}
                            }
                        }

                        add: Transition {
                            ParallelAnimation {
                                NAnim {
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: Appearance.animations.durations.small
                                }
                                NAnim {
                                    property: "scale"
                                    from: 0.5
                                    to: 1
                                    duration: Appearance.animations.durations.small
                                }
                            }
                        }

                        remove: Transition {
                            ParallelAnimation {
                                NAnim {
                                    property: "opacity"
                                    from: 1
                                    to: 0
                                    duration: Appearance.animations.durations.small
                                }
                                NAnim {
                                    property: "scale"
                                    from: 1
                                    to: 0.5
                                    duration: Appearance.animations.durations.small
                                }
                            }
                        }

                        displaced: Transition {
                            NAnim {
                                properties: "x"
                                duration: Appearance.animations.durations.small
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: passwordInput.forceActiveFocus()
                    }
                }

                StyledRect {
                    id: submitBtn

                    readonly property bool loading: root.pam.unlockInProgress
                    readonly property bool canSubmit: root.pam && passwordInput.text.length > 0

                    implicitWidth: 34
                    implicitHeight: 34
                    radius: Appearance.rounding.full
                    color: canSubmit ? root.pam.isUnlock ? Colours.withAlpha(Colours.m3Colors.m3Primary, 0.4) : Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3Primary, 0.4)
                    scale: pressHandler.pressed ? 0.88 : hoverHandler.hovered ? 1.08 : 1.0

                    Behavior on color {
                        CAnim {
                            duration: Appearance.animations.durations.small
                        }
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
                        onTapped: root.pam.tryUnlock()
                    }
                }
            }

            StyledRect {
                id: mediaPlayer

                readonly property bool hasArtwork: Players.active !== null && Players.active.trackArtUrl !== ""

                implicitWidth: hasArtwork ? 240 : 0
                implicitHeight: hasArtwork ? 60 : 0
                clip: true
                radius: 0
                visible: Players.active

                Behavior on implicitWidth {
                    NAnim {}
                }

                Behavior on implicitHeight {
                    NAnim {}
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.small

                    ClippingRectangle {
                        implicitWidth: 60
                        implicitHeight: 60
                        radius: Appearance.rounding.full
                        color: "transparent"

                        Image {
                            id: coverArt
                            anchors.fill: parent
                            source: Players.active ? Players.active.trackArtUrl : ""
                            sourceSize: Qt.size(60, 60)
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        StyledText {
                            Layout.fillWidth: true
                            text: Players.active ? Players.active.trackArtist : ""
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.medium
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                        }

                        Wavy {
                            readonly property real safePosition: (Players.active && Players.active.length > 0) ? Players.active.position / Players.active.length : 0
                            readonly property bool isPlaying: Players.active !== null && Players.active.playbackState === MprisPlaybackState.Playing

                            value: safePosition
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            enableWave: isPlaying && !pressed
                            onMoved: {
                                if (Players.active)
                                    Players.active.position = value * Players.active.length;
                            }

                            FrameAnimation {
                                running: mediaPlayer.visible && Players.active !== null && Players.active.playbackState === MprisPlaybackState.Playing
                                onTriggered: Players.active.positionChanged()
                            }
                        }
                    }
                }
            }

            WrapperRectangle {
                id: sessionWrapperRect

                property bool showConfirmDialog: false
                property var pendingAction: null
                property string pendingActionName: ""

                implicitWidth: sessionContent.implicitWidth
                implicitHeight: 60
                leftMargin: Appearance.margin.normal
                rightMargin: Appearance.margin.normal
                radius: Appearance.rounding.full
                color: "transparent"

                function requestAction(action, name) {
                    pendingAction = action;
                    pendingActionName = name + "?";
                    showConfirmDialog = true;
                }

                RowLayout {
                    id: sessionContent

                    spacing: Appearance.spacing.normal

                    Repeater {
                        model: [
                            {
                                icon: "power_settings_circle",
                                name: qsTr("Shutdown"),
                                action: () => Quickshell.execDetached({
                                        command: ["systemctl", "poweroff"]
                                    })
                            },
                            {
                                icon: "restart_alt",
                                name: qsTr("Reboot"),
                                action: () => Quickshell.execDetached({
                                        command: ["systemctl", "reboot"]
                                    })
                            },
                            {
                                icon: "sleep",
                                name: qsTr("Sleep"),
                                action: () => Quickshell.execDetached({
                                        command: ["systemctl", "suspend"]
                                    })
                            },
                            {
                                icon: "door_open",
                                name: qsTr("Logout"),
                                action: () => Quickshell.execDetached({
                                        command: ["hyprctl", "dispatch", "exit"]
                                    })
                            },
                        ]

                        delegate: Item {
                            id: sessionBtn

                            required property var modelData

                            implicitWidth: sessionIcon.implicitWidth
                            implicitHeight: sessionIcon.implicitHeight

                            Icon {
                                id: sessionIcon
                                anchors.fill: parent
                                icon: sessionBtn.modelData.icon
                                color: sessionHoverHandler.hovered ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3Primary, 0.65)
                                font.pixelSize: Appearance.fonts.size.extraLarge

                                Behavior on color {
                                    CAnim {
                                        duration: Appearance.animations.durations.small
                                    }
                                }
                            }

                            HoverHandler {
                                id: sessionHoverHandler

                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: sessionWrapperRect.requestAction(sessionBtn.modelData.action, sessionBtn.modelData.name)
                            }
                        }
                    }
                }
            }
        }
    }
}

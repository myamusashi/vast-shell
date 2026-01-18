pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Services.Mpris

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    property bool isClosing: false
    property bool showErrorMessage: false
    color: "transparent"

    Connections {
        target: root.lock

        function onUnlock(): void {
            root.isClosing = true;
            unlockSequence.start();
        }
    }

    Connections {
        target: root.pam
        enabled: root.pam !== null

        function onShowFailureChanged() {
            if (root.pam.showFailure)
                root.showErrorMessage = true;
            else
                root.showErrorMessage = false;
        }
    }

    ScreencopyView {
        id: wallpaper

        anchors.fill: parent

        property int blurSize: 0

        captureSource: root.screen
        live: false
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: wallpaper.blurSize
            blur: 1.0
        }
    }

    StyledRect {
        id: rectSurface

        anchors.fill: parent
        radius: 0
        color: "transparent"

        Component.onCompleted: {
            lockSequence.start();
        }

        WrapperRectangle {
            id: centerClock

            anchors.centerIn: parent
            color: "transparent"

            property var currentDate: new Date()

            function getDayName(index) {
                const days = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];
                return days[index];
            }

            function getMonthName(index) {
                const months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Des"];
                return months[index];
            }

            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: centerClock.currentDate = new Date()
            }

            ColumnLayout {
                StyledText {
                    Layout.alignment: Qt.AlignCenter
                    color: Colours.m3Colors.m3OnSurface
                    renderType: Text.NativeRendering
                    text: {
                        const hours = centerClock.currentDate.getHours().toString().padStart(2, '0');
                        const minutes = centerClock.currentDate.getMinutes().toString().padStart(2, '0');
                        return `${hours}:${minutes}`;
                    }
                    font.pixelSize: Appearance.fonts.size.extraLarge * 3
                    font.weight: Font.Medium
                }

                StyledText {
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.Medium
                    color: Colours.m3Colors.m3OnSurface
                    text: centerClock.getDayName(centerClock.currentDate.getDay())
                }

                StyledText {
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.Medium
                    color: Colours.m3Colors.m3OnSurface
                    text: `${centerClock.currentDate.getDate()} ${centerClock.getMonthName(centerClock.currentDate.getMonth())}`
                }
            }
        }

        Item {
            id: topItem

            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
            }

            implicitWidth: GlobalStates.isLockscreenOpen ? topWrapperRect.implicitWidth : 80
            implicitHeight: 0

            Behavior on implicitWidth {
                NAnim {}
            }

            Corner {
                id: topRightCorner

                location: Qt.TopRightCorner
                extensionSide: Qt.Horizontal
                radius: 0
                color: GlobalStates.drawerColors
            }

            Corner {
                id: topLeftCorner

                location: Qt.TopLeftCorner
                extensionSide: Qt.Horizontal
                radius: 0
                color: GlobalStates.drawerColors
            }

            ClippingWrapperRectangle {
                id: topWrapperRect

                anchors.fill: parent
                color: GlobalStates.drawerColors
                radius: 0
                leftMargin: Appearance.margin.normal
                rightMargin: Appearance.margin.normal
                bottomLeftRadius: Appearance.rounding.normal
                bottomRightRadius: bottomLeftRadius

                RowLayout {
                    spacing: 0

                    Icon {
                        id: lockIcon

                        Layout.alignment: Qt.AlignCenter
                        icon: root.lock.locked ? "lock_open_right" : "lock"
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        font.variableAxes: {
                            "FILL": 10,
                            "opsz": fontInfo.pixelSize,
                            "wght": fontInfo.weight
                        }

                        rotation: 0
                    }

                    WrapperRectangle {
                        implicitWidth: root.showErrorMessage ? failText.implicitWidth : 0
                        implicitHeight: 40
                        color: "transparent"

                        StyledText {
                            id: failText

                            text: "Password Invalid"
                            color: Colours.m3Colors.m3Error
                            font.pixelSize: Appearance.fonts.size.large * 1.5
                            transformOrigin: Item.Left
                        }
                    }
                }
            }
        }

        Item {
            id: bottomItem

            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            implicitWidth: GlobalStates.isLockscreenOpen ? bottomWrapperRect.implicitWidth : 80
            implicitHeight: 0

            Behavior on implicitWidth {
                NAnim {}
            }

            Corner {
                id: bottomRightCorner

                location: Qt.BottomRightCorner
                extensionSide: Qt.Horizontal
                radius: 0
                color: GlobalStates.drawerColors
            }

            Corner {
                id: bottomLeftCorner

                location: Qt.BottomLeftCorner
                extensionSide: Qt.Horizontal
                radius: 0
                color: GlobalStates.drawerColors
            }

            ClippingWrapperRectangle {
                id: bottomWrapperRect

                anchors.fill: parent
                color: GlobalStates.drawerColors
                radius: 0
                leftMargin: Appearance.margin.large
                rightMargin: Appearance.margin.large
                topLeftRadius: Appearance.rounding.normal
                topRightRadius: topLeftRadius

                RowLayout {
                    ClippingRectangle {
                        implicitWidth: 60
                        implicitHeight: 60
                        radius: Appearance.rounding.full
                        color: "transparent"
                        z: -1

                        IconImage {
                            anchors.fill: parent
                            source: Qt.resolvedUrl(`${Paths.home}/.face`)
                            z: 1
                        }
                    }

                    TextField {
                        id: passwordField

                        implicitWidth: 200
                        implicitHeight: 40
                        echoMode: TextInput.Password
                        focus: true
                        enabled: !root.pam.unlockInProgress
                        color: root.pam.unlockInProgress ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        renderType: Text.NativeRendering
                        wrapMode: TextEdit.NoWrap
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        placeholderText: root.pam.showFailure ? "Password invalid" : "Enter password"
                        placeholderTextColor: root.pam.showFailure ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
                        onAccepted: {
                            if (root.pam && text.length > 0)
                                root.pam.tryUnlock();
                        }
                        onTextChanged: {
                            if (root.pam)
                                root.pam.currentText = text;
                        }

                        background: Item {}

                        Connections {
                            target: root.pam
                            enabled: root.pam !== null

                            function onCurrentTextChanged() {
                                if (passwordField.text !== root.pam.currentText)
                                    passwordField.text = root.pam.currentText;
                            }
                        }
                    }

                    StyledRect {
                        id: mediaPlayer

                        implicitWidth: Players.active && Players.active.trackArtUrl !== "" ? 240 : 0
                        implicitHeight: Players.active && Players.active.trackArtUrl !== "" ? 60 : 0
                        clip: true
                        radius: 0

                        RowLayout {
                            anchors.fill: parent

                            ClippingRectangle {
                                implicitWidth: 60
                                implicitHeight: 60
                                radius: Appearance.rounding.full
                                color: "transparent"

                                Image {
                                    id: coverArt

                                    anchors.fill: parent
                                    source: Players.active && Players.active.trackArtUrl !== "" ? Players.active.trackArtUrl : "root:/Assets/kuru.gif"
                                    sourceSize: Qt.size(60, 60)
                                    fillMode: Image.PreserveAspectCrop
                                    visible: Players.active !== null
                                    cache: false
                                    asynchronous: true
                                }
                            }

                            ColumnLayout {
                                implicitHeight: parent.height

                                StyledText {
                                    Layout.preferredWidth: width
                                    text: Players.active ? Players.active.trackArtist : ""
                                    color: Colours.m3Colors.m3OnSurface
                                    font.pixelSize: Appearance.fonts.size.small
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                }

                                Wavy {
                                    value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    enableWave: Players.active.playbackState === MprisPlaybackState.Playing && !pressed

                                    FrameAnimation {
                                        running: GlobalStates.isMediaPlayerOpen && Players.active && Players.active.playbackState == MprisPlaybackState.Playing
                                        onTriggered: Players.active.positionChanged()
                                    }

                                    onMoved: Players.active ? Players.active.position = value * Players.active.length : {}
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

                        RowLayout {
                            id: sessionContent

                            spacing: Appearance.spacing.normal

                            Repeater {
                                model: [
                                    {
                                        "icon": "power_settings_circle",
                                        "name": "Shutdown",
                                        "action": () => {
                                            Quickshell.execDetached({
                                                "command": ["sh", "-c", "systemctl poweroff"]
                                            });
                                        }
                                    },
                                    {
                                        "icon": "restart_alt",
                                        "name": "Reboot",
                                        "action": () => {
                                            Quickshell.execDetached({
                                                "command": ["sh", "-c", "systemctl reboot"]
                                            });
                                        }
                                    },
                                    {
                                        "icon": "sleep",
                                        "name": "Sleep",
                                        "action": () => {
                                            Quickshell.execDetached({
                                                "command": ["sh", "-c", "systemctl suspend"]
                                            });
                                        }
                                    },
                                    {
                                        "icon": "door_open",
                                        "name": "Logout",
                                        "action": () => {
                                            Quickshell.execDetached({
                                                "command": ["sh", "-c", "hyprctl dispatch exit"]
                                            });
                                        }
                                    }
                                ]

                                delegate: Icon {
                                    required property var modelData

                                    icon: modelData.icon
                                    color: Colours.m3Colors.m3Primary
                                    font.pixelSize: Appearance.fonts.size.extraLarge

                                    function handleAction() {
                                        sessionWrapperRect.pendingAction = modelData.action;
                                        sessionWrapperRect.pendingActionName = modelData.name + "?";
                                        sessionWrapperRect.showConfirmDialog = true;
                                    }

                                    MArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: parent.handleAction()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        ClippingWrapperRectangle {
            anchors.centerIn: parent
            radius: Appearance.rounding.large
            margin: Appearance.margin.normal
            implicitWidth: sessionWrapperRect.showConfirmDialog ? column.implicitWidth + 20 : 0
            implicitHeight: sessionWrapperRect.showConfirmDialog ? column.implicitHeight + 20 : 0
            color: GlobalStates.drawerColors

            Behavior on implicitWidth {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            Behavior on implicitHeight {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            Column {
                id: column

                spacing: Appearance.spacing.large

                StyledText {
                    id: header

                    text: "Session"
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideMiddle
                    font.pixelSize: Appearance.fonts.size.extraLarge
                    font.bold: true
                }

                StyledRect {
                    width: column.width
                    height: 2
                    color: Colours.m3Colors.m3OutlineVariant
                }

                StyledText {
                    id: body

                    text: "Do you want to " + sessionWrapperRect.pendingActionName.toLowerCase() + "?"
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurface
                    wrapMode: Text.Wrap
                    width: Math.max(300, implicitWidth)
                }

                StyledRect {
                    width: column.width
                    height: 2
                    color: Colours.m3Colors.m3OutlineVariant
                }

                Row {
                    id: rowButtons

                    anchors.right: parent.right
                    spacing: Appearance.spacing.normal

                    StyledButton {
                        implicitWidth: 80
                        implicitHeight: 40
                        elideText: false
                        iconButton: "cancel"
                        buttonTitle: "No"
                        buttonColor: "transparent"
                        onClicked: {
                            sessionWrapperRect.showConfirmDialog = false;
                            sessionWrapperRect.pendingAction = null;
                            sessionWrapperRect.pendingActionName = "";
                        }
                    }

                    StyledButton {
                        implicitWidth: 80
                        implicitHeight: 40
                        iconButton: "check"
                        buttonTitle: "Yes"
                        buttonTextColor: Colours.m3Colors.m3OnPrimary
                        onClicked: {
                            if (sessionWrapperRect.pendingAction)
                                sessionWrapperRect.pendingAction();
                            sessionWrapperRect.showConfirmDialog = false;
                            sessionWrapperRect.isSessionOpen = false;
                            sessionWrapperRect.pendingAction = null;
                            sessionWrapperRect.pendingActionName = "";
                        }
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: lockSequence

        ParallelAnimation {
            NAnim {
                target: topItem
                property: "implicitHeight"
                to: 80
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "implicitHeight"
                to: 80
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: wallpaper
                property: "blurSize"
                to: 40
            }

            NAnim {
                target: topLeftCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: topRightCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomLeftCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomRightCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ParallelAnimation {
            NAnim {
                target: topItem
                property: "implicitWidth"
                to: topWrapperRect.implicitWidth + 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "implicitWidth"
                to: bottomWrapperRect.implicitWidth + 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ScriptAction {
            script: {
                GlobalStates.isLockscreenOpen = true;
            }
        }
    }

    SequentialAnimation {
        id: unlockSequence

        ParallelAnimation {
            NAnim {
                target: topItem
                property: "implicitWidth"
                to: 80
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "implicitWidth"
                to: 80
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ParallelAnimation {
            NAnim {
                target: topItem
                property: "implicitHeight"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "implicitHeight"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: wallpaper
                property: "blurSize"
                to: 0
            }

            NAnim {
                target: bottomLeftCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomRightCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: topLeftCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: topRightCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ScriptAction {
            script: GlobalStates.isLockscreenOpen = false
        }

        PauseAnimation {
            duration: Appearance.animations.durations.normal
        }

        ScriptAction {
            script: root.lock.locked = false
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes

import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    readonly property alias isFocused: passwordInput.activeFocus
    property alias toggleButtonVisible: toggleButton.visible
    property alias placeHolderText: placeHolderText.text
    property alias text: passwordInput.text

    readonly property bool isUnlocked: root.pam ? root.pam.isUnlock : false
    readonly property bool unlockInProgress: root.pam ? root.pam.unlockInProgress : false
    readonly property bool showFailure: root.pam ? root.pam.showFailure : false
    readonly property var shapeList: [MaterialShape.Clover4Leaf, MaterialShape.Arrow, MaterialShape.Pill, MaterialShape.SoftBurst, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon]

    property var pam: null
    property bool passwordMode: false

    function forceActiveFocus() {
        passwordInput.forceActiveFocus();
    }

    signal accepted

    implicitWidth: 240
    implicitHeight: 44

    TextInput {
        id: passwordInput

        width: 0
        height: 0
        visible: false

        // Always mask internally; we render our own visuals
        echoMode: TextInput.Password
        passwordMaskDelay: 0
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        enabled: !root.unlockInProgress

        // Sync with PAM if bound
        text: (root.pam && root.pam.isUnlock) ? root.pam.currentText : ""

        onTextChanged: {
            if (root.pam)
                root.pam.currentText = text;
        }

        Keys.onReturnPressed: {
            if (root.pam && text.length > 0)
                root.pam.tryUnlock();
            root.accepted();
        }

        Component.onCompleted: forceActiveFocus()
    }

    // Keep sync when PAM changes externally
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

    Rectangle {
        id: bg

        anchors.fill: parent
        radius: height / 2
        color: Colours.m3Colors.m3SurfaceVariant
        opacity: 0.4
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border {
            color: root.showFailure ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Primary
            width: root.isFocused ? 2 : 0
        }
        opacity: root.isFocused ? 1 : 0

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    StyledText {
        id: placeHolderText

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: Appearance.margin.large
            rightMargin: Appearance.margin.large
        }
        visible: passwordInput.text.length === 0
        text: root.showFailure ? qsTr("Password invalid") : qsTr("Enter password")
        color: root.showFailure ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.large
    }

    ListView {
        id: dotsView

        anchors {
            left: parent.left
            right: toggleButton.left
            verticalCenter: parent.verticalCenter
            leftMargin: Appearance.margin.large
            rightMargin: Appearance.margin.large
        }

        orientation: ListView.Horizontal
        spacing: 4
        model: dotsModel
        clip: true
        visible: root.passwordMode && passwordInput.text.length > 0
        implicitWidth: Math.min(contentWidth, parent.width - toggleButton.width - 20)
        implicitHeight: 20

        Behavior on implicitWidth {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        delegate: MaterialShape {
            required property int index

            implicitWidth: 20
            implicitHeight: 20
            shape: root.shapeList[index % root.shapeList.length]
            color: root.unlockInProgress ? Colours.m3Colors.m3OnSurfaceVariant : root.isUnlocked ? Colours.m3Colors.m3Green : Colours.m3Colors.m3Primary

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

    Rectangle {
        id: dotsCaret

        x: dotsView.visible ? dotsView.x + Math.min(dotsView.contentWidth, dotsView.width) + 3 : 12
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 2
        implicitHeight: 20
        radius: 1
        color: Colours.m3Colors.m3Primary
        visible: root.passwordMode && root.isFocused && !root.unlockInProgress

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        SequentialAnimation on opacity {
            running: dotsCaret.visible
            loops: Animation.Infinite

            NAnim {
                to: 1
                duration: 0
            }
            PauseAnimation {
                duration: 530
            }
            NAnim {
                to: 0
                duration: 0
            }
            PauseAnimation {
                duration: 530
            }
        }
        onVisibleChanged: if (visible)
            opacity = 1
    }

    TextInput {
        id: visibleInput

        anchors {
            left: parent.left
            right: toggleButton.left
            verticalCenter: parent.verticalCenter
            leftMargin: 12
            rightMargin: 4
        }

        visible: !root.passwordMode && passwordInput.text.length > 0
        readOnly: true
        text: passwordInput.text
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.large
        clip: true
        echoMode: TextInput.Normal
    }

    Rectangle {
        id: textCaret

        anchors.verticalCenter: parent.verticalCenter
        x: Math.min(visibleInput.x + visibleInput.contentWidth + 2, toggleButton.x - 6)
        implicitWidth: 2
        implicitHeight: visibleInput.font.pixelSize + 2
        radius: 1
        color: Colours.m3Colors.m3Primary
        visible: !root.passwordMode && root.isFocused && !root.unlockInProgress

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        SequentialAnimation on opacity {
            running: textCaret.visible
            loops: Animation.Infinite
            NAnim {
                to: 1
                duration: 0
            }
            PauseAnimation {
                duration: Appearance.animations.durations.large
            }
            NAnim {
                to: 0
                duration: 0
            }
            PauseAnimation {
                duration: Appearance.animations.durations.large
            }
        }
        onVisibleChanged: {
            if (visible)
                opacity = 1;
        }
    }

    Item {
        id: toggleButton

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: Appearance.margin.normal
        }

        implicitWidth: 32
        implicitHeight: 32
        z: 1

        Icon {
            icon: "visibility_off"
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.large * 1.5
            opacity: root.passwordMode ? 1.0 : 0.0
            scale: root.passwordMode ? 1.0 : 0.5

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on scale {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }

        Icon {
            icon: "visibility"
            color: Colours.m3Colors.m3Secondary
            font.pixelSize: Appearance.fonts.size.large * 1.5
            opacity: root.passwordMode ? 0.0 : 1.0
            scale: root.passwordMode ? 0.5 : 1.0

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on scale {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            z: 1
            onClicked: {
                if (root.toggleButtonVisible) {
                    root.passwordMode = !root.passwordMode;
                    passwordInput.forceActiveFocus();
                }
            }
        }
    }

    MArea {
        layerRadius: bg.radius
        z: 0
        propagateComposedEvents: true
        onClicked: passwordInput.forceActiveFocus()
    }
}

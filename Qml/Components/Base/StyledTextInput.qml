pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "TextInputComponents" as TI

Item {
    id: root

    property bool autoFocus: true
    readonly property int dotStep: 24
    readonly property bool hasSelection: passwordInput.selectionStart !== passwordInput.selectionEnd
    readonly property bool hasText: passwordInput.text.length > 0
    readonly property alias isFocused: passwordInput.activeFocus
    readonly property bool isUnlocked: root.pam ? root.pam.isUnlock : false
    property bool keyboardFocusable: true
    property var pam: null
    property bool passwordMode: false
    property string placeHolderText: ""
    readonly property bool selectedAll: passwordInput.selectionStart === 0 && passwordInput.selectionEnd === passwordInput.text.length && passwordInput.text.length > 0
    readonly property int selectionEnd: passwordInput.selectionEnd
    readonly property int selectionStart: passwordInput.selectionStart
    readonly property var shapeList: [MaterialShape.Clover4Leaf, MaterialShape.Arrow, MaterialShape.Pill, MaterialShape.SoftBurst, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon]
    readonly property bool showFailure: root.pam ? root.pam.showFailure : false
    property alias text: passwordInput.text
    property alias toggleButtonVisible: toggleButton.visible
    readonly property bool unlockInProgress: root.pam ? root.pam.unlockInProgress : false

    signal accepted
    signal editingFinished
    signal keyPressed(var event)

    function forceActiveFocus() {
        passwordInput.forceActiveFocus();
    }
    function requestKeyboardFocus() {
        passwordInput.forceActiveFocus();
    }

    implicitHeight: 44
    implicitWidth: 240

    TextInput {
        id: passwordInput

        clip: true
        echoMode: TextInput.Password
        enabled: !root.unlockInProgress
        height: 0
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        passwordMaskDelay: 0
        text: (root.pam && root.pam.isUnlock) ? root.pam.currentText : ""
        width: 0

        Component.onCompleted: {
            if (root.autoFocus)
                forceActiveFocus();
        }
        Keys.onEscapePressed: event => {
            root.keyPressed(event);
            if (event.accepted)
                return;

            if (root.hasSelection) {
                passwordInput.cursorPosition = passwordInput.selectionEnd;
                passwordInput.deselect();
                event.accepted = true;
            }
        }
        Keys.onPressed: event => {
            // Let consumers (e.g. the clipboard vim keybinds) intercept and
            // accept the key before it becomes text input.
            root.keyPressed(event);
            if (event.accepted)
                return;

            if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                passwordInput.selectAll();
                event.accepted = true;
            }
        }
        Keys.onReturnPressed: event => {
            if (root.pam && text.length > 0)
                root.pam.tryUnlock();
            root.accepted();
            event.accepted = true;
        }
        onTextChanged: {
            if (root.pam)
                root.pam.currentText = text;

            const len = text.length;
            while (dotsModel.count < len)
                dotsModel.append({});
            while (dotsModel.count > len)
                dotsModel.remove(dotsModel.count - 1);
        }
    }
    Connections {
        function onCurrentTextChanged() {
            if (passwordInput.text !== root.pam.currentText)
                passwordInput.text = root.pam.currentText;
        }

        enabled: root.pam !== null
        target: root.pam
    }
    ListModel {
        id: dotsModel
    }
    Rectangle {
        id: background

        anchors.fill: parent
        color: Colours.m3Colors.m3SurfaceVariant
        opacity: 0.4
        radius: height / 2
    }
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        opacity: root.isFocused ? 1 : 0
        radius: height / 2

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        border {
            color: root.showFailure ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Primary
            width: root.isFocused ? 2 : 0
        }
    }
    Loader {
        active: !root.hasText
        sourceComponent: placeHolderComponent

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: Appearance.margin.large
            verticalCenter: parent.verticalCenter
        }
    }
    Component {
        id: placeHolderComponent

        StyledText {
            color: root.showFailure ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.large
            text: root.placeHolderText !== "" ? root.placeHolderText : (root.showFailure ? qsTr("Password invalid") : qsTr("Enter password"))
        }
    }
    Loader {
        id: passwordModeLoader

        active: root.passwordMode
        anchors.fill: parent
        sourceComponent: passwordModeComponent
    }
    Component {
        id: passwordModeComponent

        TI.PasswordInput {
            dotsModel: dotsModel
            hasSelection: root.hasSelection
            isFocused: root.isFocused
            isUnlocked: root.isUnlocked
            passwordInput: passwordInput
            selectionEnd: root.selectionEnd
            selectionStart: root.selectionStart
            toggleButton: toggleButton
            unlockInProgress: root.unlockInProgress
        }
    }
    Loader {
        id: visibleModeLoader

        active: !root.passwordMode && root.hasText
        anchors.fill: parent
        sourceComponent: visibleModeComponent
    }
    Component {
        id: visibleModeComponent

        TI.VisibleInput {
            hasSelection: root.hasSelection
            isFocused: root.isFocused
            passwordInput: passwordInput
            selectionEnd: root.selectionEnd
            selectionStart: root.selectionStart
            toggleButton: toggleButton
            unlockInProgress: root.unlockInProgress
        }
    }
    Item {
        id: toggleButton

        implicitHeight: 32
        implicitWidth: 32
        z: 1

        anchors {
            right: parent.right
            rightMargin: Appearance.margin.normal
            verticalCenter: parent.verticalCenter
        }
        Icon {
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.large * 1.5
            icon: "visibility_off"
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
            color: Colours.m3Colors.m3Secondary
            font.pixelSize: Appearance.fonts.size.large * 1.5
            icon: "visibility"
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
        layerRadius: background.radius
        propagateComposedEvents: true
        z: 0

        onClicked: passwordInput.forceActiveFocus()
    }
}

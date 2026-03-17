pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property alias toggleButtonVisible: toggleButton.visible
    property alias placeHolderText: placeHolderText.text
    property alias text: passwordInput.text
    readonly property alias isFocused: passwordInput.activeFocus

    readonly property bool isUnlocked: root.pam ? root.pam.isUnlock : false
    readonly property bool unlockInProgress: root.pam ? root.pam.unlockInProgress : false
    readonly property bool showFailure: root.pam ? root.pam.showFailure : false

    readonly property var shapeList: [MaterialShape.Clover4Leaf, MaterialShape.Arrow, MaterialShape.Pill, MaterialShape.SoftBurst, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon]
    readonly property int dotStep: 24

    property var pam: null
    property bool passwordMode: false
    property bool selectedAll: false

    function forceActiveFocus() {
        passwordInput.forceActiveFocus();
    }

    signal accepted
    signal editingFinished

    implicitWidth: 240
    implicitHeight: 44

    TextInput {
        id: passwordInput

        width: 0
        height: 0
        visible: false

        echoMode: TextInput.Password
        passwordMaskDelay: 0
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        enabled: !root.unlockInProgress
        text: (root.pam && root.pam.isUnlock) ? root.pam.currentText : ""

        onTextChanged: {
            root.selectedAll = false;
            if (root.pam)
                root.pam.currentText = text;

            const len = text.length;
            while (dotsModel.count < len)
                dotsModel.append({});
            while (dotsModel.count > len)
                dotsModel.remove(dotsModel.count - 1);
        }

        onCursorPositionChanged: Qt.callLater(() => {
            if (root.passwordMode && dotsModel.count > 0)
                dotsView.positionViewAtIndex(Math.max(0, cursorPosition - 1), ListView.Contain);
        })

        Keys.onReturnPressed: {
            if (root.pam && text.length > 0)
                root.pam.tryUnlock();
            root.accepted();
        }
        Keys.onPressed: event => {
            if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                root.selectedAll = text.length > 0;
                event.accepted = true;
            } else if (!(event.modifiers & Qt.ControlModifier)) {
                root.selectedAll = false;
            }
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
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: Appearance.margin.large
        }
        visible: passwordInput.text.length === 0
        text: root.showFailure ? qsTr("Password invalid") : qsTr("Enter password")
        color: root.showFailure ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.large
    }

    Rectangle {
        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large - 4
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: dotsView.implicitWidth + 8
        implicitHeight: 28
        radius: 6
        color: Colours.m3Colors.m3Primary
        opacity: root.selectedAll && root.passwordMode ? 0.25 : 0.0
        visible: root.passwordMode && passwordInput.text.length > 0

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
        Behavior on implicitWidth {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: Math.min(visibleInputMetrics.advanceWidth(visibleInput.text) + 8, toggleButton.x - 12)
        implicitHeight: visibleInput.font.pixelSize + 6
        radius: 4
        color: Colours.m3Colors.m3Primary
        opacity: root.selectedAll && !root.passwordMode ? 0.25 : 0.0
        visible: !root.passwordMode && passwordInput.text.length > 0

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
        Behavior on implicitWidth {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    ListView {
        id: dotsView

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: toggleButton.left
            rightMargin: Appearance.margin.large
            verticalCenter: parent.verticalCenter
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

        anchors.verticalCenter: parent.verticalCenter
        x: {
            if (!dotsView.visible)
                return 12;

            return passwordInput.cursorPosition * root.dotStep - dotsView.contentX + (root.passwordMode ? 15 : 0);
        }
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
            leftMargin: 12
            right: toggleButton.left
            rightMargin: 4
            verticalCenter: parent.verticalCenter
        }
        visible: !root.passwordMode && passwordInput.text.length > 0
        readOnly: true
        text: passwordInput.text
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.large
        clip: true
        echoMode: TextInput.Normal

        Keys.onReturnPressed: root.editingFinished()
    }

    FontMetrics {
        id: visibleInputMetrics

        font: visibleInput.font
    }

    Rectangle {
        id: textCaret

        x: Math.min(visibleInput.x + visibleInputMetrics.advanceWidth(visibleInput.text.substring(0, passwordInput.cursorPosition)), toggleButton.x - 8)
        anchors.verticalCenter: parent.verticalCenter
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
        onVisibleChanged: if (visible)
            opacity = 1
    }

    Item {
        id: toggleButton

        anchors {
            right: parent.right
            rightMargin: Appearance.margin.normal
            verticalCenter: parent.verticalCenter
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

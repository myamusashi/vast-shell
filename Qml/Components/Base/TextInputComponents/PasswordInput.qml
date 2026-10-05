pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import QtQml.Models

import qs.Components.Base
import qs.Core.Configs
import qs.Services
import Vast.Utils

Item {
    id: root

    readonly property int dotStep: 24
    required property ListModel dotsModel
    required property bool hasSelection
    required property bool isFocused
    required property bool isUnlocked
    required property TextInput passwordInput
    required property int selectionEnd
    required property int selectionStart
    readonly property var shapeList: [MaterialShape.Clover4Leaf, MaterialShape.Arrow, MaterialShape.Pill, MaterialShape.SoftBurst, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon]
    required property Item toggleButton
    required property bool unlockInProgress

    function scrollToCursor() {
        if (root.dotsModel.count > 0)
            dotsView.positionViewAtIndex(Math.min(root.passwordInput.cursorPosition, root.dotsModel.count - 1), ListView.Contain);
    }

    Item {
        clip: true
        implicitHeight: 28

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large - 4
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.margin.large
            verticalCenter: parent.verticalCenter
        }
        Rectangle {
            id: passwordRectSelected

            anchors.verticalCenter: parent.verticalCenter
            color: Colours.m3Colors.m3Primary
            implicitHeight: 28
            implicitWidth: (root.selectionEnd - root.selectionStart) * root.dotStep + radius
            opacity: 0.0
            radius: 2
            x: root.selectionStart * root.dotStep

            Behavior on implicitWidth {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
            states: [
                State {
                    name: "selection"
                    when: root.hasSelection

                    PropertyChanges {
                        opacity: 0.25 // qmllint disable
                        target: passwordRectSelected // qmllint disable
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "*"
                    to: "*"

                    NAnim {
                        duration: Appearance.animations.durations.small
                        properties: "opacity"
                    }
                }
            ]
            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }
    ListView {
        id: dotsView

        clip: true
        implicitHeight: 20
        implicitWidth: Math.min(contentWidth, parent.width - root.toggleButton.width - 20)
        model: root.dotsModel
        orientation: ListView.Horizontal
        spacing: 4

        add: Transition {
            ParallelAnimation {
                NAnim {
                    duration: Appearance.animations.durations.small
                    from: 0
                    property: "opacity"
                    to: 1
                }
                SpringAnimation {
                    damping: 0.4
                    from: 0.5
                    mass: 1.0
                    property: "scale"
                    spring: 3.0
                    to: 1
                }
            }
        }
        delegate: MaterialShape {
            id: shapeDelegate

            property real colorBlendProgress: 1.0
            property bool colorBlending: false
            property color colorFrom
            property color colorTo
            required property int index
            property color shapeTarget: root.unlockInProgress ? Colours.m3Colors.m3OnSurfaceVariant : root.isUnlocked ? Colours.m3Colors.m3Green : Colours.m3Colors.m3Primary

            animationDuration: 350
            implicitHeight: 20
            implicitWidth: 20
            shape: MaterialShape.Circle

            Component.onCompleted: {
                shape = root.shapeList[index % root.shapeList.length];

                colorBlendAnim.stop();
                color = "white";
                colorFrom = "white";
                colorTo = shapeTarget;
                colorBlending = true;
                colorBlendProgress = 0.0;
                colorBlendAnim.start();
            }
            onColorBlendProgressChanged: {
                if (!colorBlending)
                    return;
                if (colorBlendProgress >= 1) {
                    color = colorTo;
                    colorBlending = false;
                } else if (colorBlendProgress > 0) {
                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }
            onShapeTargetChanged: {
                colorBlendAnim.stop();
                colorFrom = color;
                colorTo = shapeTarget;
                colorBlending = true;
                colorBlendProgress = 0.0;
                colorBlendAnim.start();
            }

            Connections {
                function onIsUnlockedChanged() {
                    if (root.isUnlocked)
                        shapeDelegate.shape = MaterialShape.Circle;
                }

                target: root
            }
            NAnim {
                id: colorBlendAnim

                from: 0.0
                property: "colorBlendProgress"
                target: shapeDelegate
                to: 1.0
            }
        }
        displaced: Transition {
            SpringAnimation {
                damping: 0.4
                mass: 1.0
                properties: "x"
                spring: 3.0
            }
        }
        Behavior on implicitWidth {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
        remove: Transition {
            ParallelAnimation {
                NAnim {
                    duration: Appearance.animations.durations.small
                    from: 1
                    property: "opacity"
                    to: 0
                }
                SpringAnimation {
                    damping: 0.6
                    from: 1
                    mass: 1.0
                    property: "scale"
                    spring: 4.0
                    to: 0.5
                }
            }
        }

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.margin.large
            verticalCenter: parent.verticalCenter
        }
    }
    Connections {
        function onCursorPositionChanged() {
            root.scrollToCursor();
        }
        function onTextChanged() {
            root.scrollToCursor();
        }

        target: root.passwordInput
    }
    Item {
        id: caretArea

        clip: true
        implicitHeight: 28

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.margin.large
            verticalCenter: parent.verticalCenter
        }
        Rectangle {
            id: dotsCaret

            anchors.verticalCenter: parent.verticalCenter
            color: Colours.m3Colors.m3Primary
            implicitHeight: 20
            implicitWidth: 2
            radius: 1
            visible: root.isFocused && !root.unlockInProgress && !root.hasSelection
            x: root.passwordInput.cursorPosition * root.dotStep - dotsView.contentX

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: dotsCaret.visible

                NAnim {
                    duration: 0
                    to: 1
                }
                PauseAnimation {
                    duration: 530
                }
                NAnim {
                    duration: 0
                    to: 0
                }
                PauseAnimation {
                    duration: 530
                }
            }
            Behavior on x {
                NAnim {
                    duration: 50
                }
            }

            onVisibleChanged: {
                if (visible)
                    opacity = 1;
            }
        }
    }
}

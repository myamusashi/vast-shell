import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    readonly property real caretRawX: visibleInputMetrics.advanceWidth(visibleInput.text.substring(0, root.passwordInput.cursorPosition))
    required property bool hasSelection
    required property bool isFocused
    required property TextInput passwordInput
    readonly property real scrollOffset: Math.max(0, caretRawX - (visibleArea.width - 4))
    required property int selectionEnd
    required property int selectionStart
    required property Item toggleButton
    required property bool unlockInProgress

    signal editingFinished

    Item {
        id: visibleArea

        clip: true
        implicitHeight: visibleInput.font.pixelSize + Appearance.spacing.normal

        anchors {
            left: parent.left
            leftMargin: Appearance.margin.large
            right: parent.right
            rightMargin: root.toggleButton.width + Appearance.margin.normal + Appearance.spacing.small
            verticalCenter: parent.verticalCenter
        }
        Rectangle {
            id: visibleRectSelected

            anchors.verticalCenter: parent.verticalCenter
            color: Colours.m3Colors.m3Primary
            implicitHeight: visibleInput.font.pixelSize + Appearance.spacing.normal
            implicitWidth: visibleInputMetrics.advanceWidth(visibleInput.text.substring(root.selectionStart, root.selectionEnd)) + Appearance.spacing.small
            opacity: 0.0
            radius: 2
            x: visibleInputMetrics.advanceWidth(visibleInput.text.substring(0, root.selectionStart)) - root.scrollOffset

            Behavior on implicitWidth {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
            states: [
                State {
                    name: "selection"
                    when: root.hasSelection

                    // qmllint disable
                    PropertyChanges {
                        opacity: 0.25
                        target: visibleRectSelected
                    }
                    // qmllint enable
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
        TextInput {
            id: visibleInput

            clip: true
            color: Colours.m3Colors.m3OnSurface
            echoMode: TextInput.Normal
            font.pixelSize: Appearance.fonts.size.large
            readOnly: true
            text: root.passwordInput.text
            x: -root.scrollOffset

            Keys.onReturnPressed: root.editingFinished()

            anchors {
                verticalCenter: parent.verticalCenter
            }
        }
        Rectangle {
            id: textCaret

            anchors.verticalCenter: parent.verticalCenter
            color: Colours.m3Colors.m3Primary
            implicitHeight: visibleInput.font.pixelSize + 2
            implicitWidth: 2
            radius: 1
            visible: root.isFocused && !root.unlockInProgress && !root.hasSelection
            x: root.caretRawX - root.scrollOffset

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: textCaret.visible

                NAnim {
                    duration: 0
                    to: 1
                }
                PauseAnimation {
                    duration: Appearance.animations.durations.large
                }
                NAnim {
                    duration: 0
                    to: 0
                }
                PauseAnimation {
                    duration: Appearance.animations.durations.large
                }
            }
            Behavior on x {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            onVisibleChanged: {
                if (visible)
                    opacity = 1;
            }
        }
    }
    FontMetrics {
        id: visibleInputMetrics

        font: visibleInput.font
    }
}

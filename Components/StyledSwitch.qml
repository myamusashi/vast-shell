import QtQuick
import QtQuick.Controls

import qs.Data
import qs.Helpers

Switch {
    id: root

    indicator: Rectangle {
        implicitWidth: 52
        implicitHeight: 32
        x: root.leftPadding
        y: parent.height / 2 - height / 2
        radius: Appearance.rounding.full
        color: root.checked ? Themes.colors.primary : Themes.colors.surface_container_highest
        border.width: 2
        border.color: Themes.colors.outline

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: handle

            readonly property int margin: 5
            readonly property bool isActive: root.down || root.checked

            readonly property int targetX: root.checked ? parent.width - targetWidth
                                                          - margin : margin
            readonly property int targetWidth: isActive ? 24 : 16
            readonly property int targetHeight: root.down ? 28 : (root.checked ? 24 : 16)

            x: targetX
            y: (parent.height - height) / 2
            width: targetWidth
            height: targetHeight
            radius: Appearance.rounding.full
            color: isActive ? Themes.colors.on_primary : Themes.colors.outline

            ParallelAnimation {
                id: handleAnimation
                running: false

                NumbAnim {
                    target: handle
                    property: "x"
                    to: handle.targetX
                    duration: Appearance.animations.durations.small
                }
                NumbAnim {
                    target: handle
                    property: "width"
                    to: handle.targetWidth
                    duration: Appearance.animations.durations.small
                }
                NumbAnim {
                    target: handle
                    property: "height"
                    to: handle.targetHeight
                    duration: Appearance.animations.durations.small
                }
                ColAnim {
                    target: handle
                    property: "color"
                    to: handle.isActive ? Themes.colors.on_primary : Themes.colors.outline
                    duration: Appearance.animations.durations.small
                }
            }

            onTargetXChanged: handleAnimation.restart()
            onTargetWidthChanged: handleAnimation.restart()
            onTargetHeightChanged: handleAnimation.restart()

            Loader {
                active: root.checked
                anchors.centerIn: parent
                asynchronous: true
                sourceComponent: MatIcon {
                    icon: "check"
                    color: Themes.colors.on_background
                    font.pixelSize: Appearance.fonts.large
                }
            }
        }
    }
}

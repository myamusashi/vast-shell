pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Core.Configs
import qs.Services

Switch {
    id: root

    indicator: StyledRect {
        id: track

        border.width: 2
        implicitHeight: 32
        implicitWidth: 52
        radius: Appearance.rounding.full
        x: root.leftPadding
        y: parent.height / 2 - height / 2

        StyledRect {
            id: handle

            readonly property int margin: 4

            radius: Appearance.rounding.full
            y: (parent.height - height) / 2
        }
    }

    // qmllint disable
    states: [
        State {
            name: "unchecked"
            when: !root.checked && !root.down

            PropertyChanges {
                border.color: Colours.m3Colors.m3Outline
                color: Colours.m3Colors.m3SurfaceContainerHighest
                target: track
            }

            PropertyChanges {
                color: Colours.m3Colors.m3Outline
                height: 16
                target: handle
                width: 16
                x: handle.margin
            }
        },
        State {
            name: "checked"
            when: root.checked && !root.down

            PropertyChanges {
                border.color: "transparent"
                color: Colours.m3Colors.m3Primary
                target: track
            }

            PropertyChanges {
                color: Colours.m3Colors.m3OnPrimary
                height: 24
                target: handle
                width: 28
                x: track.width - 28 - handle.margin
            }
        },
        State {
            name: "pressedUnchecked"
            when: root.down && !root.checked

            PropertyChanges {
                border.color: Colours.m3Colors.m3Outline
                color: Colours.m3Colors.m3SurfaceContainerHighest
                target: track
            }

            PropertyChanges {
                color: Colours.m3Colors.m3Outline
                height: 28
                target: handle
                width: 28
                x: handle.margin
            }
        },
        State {
            name: "pressedChecked"
            when: root.down && root.checked

            PropertyChanges {
                border.color: "transparent"
                color: Colours.m3Colors.m3Primary
                target: track
            }

            PropertyChanges {
                color: Colours.m3Colors.m3OnPrimary
                height: 28
                target: handle
                width: 28
                x: track.width - 28 - handle.margin
            }
        }
    ]
    // qmllint enable

    transitions: Transition {

        NAnim {
            duration: Appearance.animations.durations.small
            easing.bezierCurve: Appearance.animations.curves.emphasized
            properties: "x,width,height"
        }
    }
}

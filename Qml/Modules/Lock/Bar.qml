import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Effects
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

WrapperRectangle {
    id: bottomWrapperRect

    required property var  mediaLayout
    required property bool showErrorMessage

    property alias         contentLayout: contentLayout
    property alias         lockIcon: lockIcon

    Layout.fillHeight: true
    clip: true
    color: GlobalStates.drawerColors
    implicitHeight: mediaLayout.implicitHeight + Appearance.margin.small * 2
    leftMargin: Appearance.margin.normal
    radius: Appearance.rounding.normal
    rightMargin: Appearance.margin.normal

    FontMetrics {
        id: lockIconMetrics

        font: lockIcon.font
    }

    RowLayout {
        id: contentLayout

        opacity: 0
        spacing: Appearance.spacing.normal

        ClippingWrapperRectangle {
            color: "transparent"
            implicitHeight: 48
            implicitWidth: 48
            radius: Appearance.rounding.full
            z: -1

            IconImage {
                id: avatar

                asynchronous: true
                backer.cache: true
                source: Qt.resolvedUrl(`${Paths.home}/.face`)
                z: 1
            }
        }

        Icon {
            id: lockIcon

            function blendTo(target) {
                tintAnim.blendTo(target);
            }

            Layout.alignment: Qt.AlignCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large * 1.5
            icon: "lock"
            transformOrigin: Item.Bottom

            BlendColor {
                id: tintAnim

                host: lockIcon
            }

            SequentialAnimation {
                id: shakeAnim

                running: bottomWrapperRect.showErrorMessage

                NAnim {
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    property: "rotation"
                    target: lockIcon
                    to: 18
                }

                NAnim {
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    property: "rotation"
                    target: lockIcon
                    to: -18
                }

                NAnim {
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    property: "rotation"
                    target: lockIcon
                    to: 12
                }

                NAnim {
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    property: "rotation"
                    target: lockIcon
                    to: -12
                }

                NAnim {
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    property: "rotation"
                    target: lockIcon
                    to: 6
                }

                NAnim {
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    property: "rotation"
                    target: lockIcon
                    to: -6
                }

                NAnim {
                    duration: 100
                    easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    property: "rotation"
                    target: lockIcon
                    to: 0
                }

                ScriptAction {
                    script: lockIcon.color(Colours.m3Colors.m3Red)
                }
            }
        }

        StyledText {
            id: errorLabel

            Layout.alignment: Qt.AlignCenter
            color: Colours.m3Colors.m3Error
            font.bold: true
            font.pixelSize: Appearance.fonts.size.medium
            opacity: bottomWrapperRect.showErrorMessage ? 1 : 0
            text: "WRONG"
            visible: bottomWrapperRect.showErrorMessage
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
    }
}

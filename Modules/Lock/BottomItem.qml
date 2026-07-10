pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.Utils
import qs.Components.Base
import qs.Services

Item {
    id: root

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
    }

    property alias lockIcon: lockIcon
    property alias iconName: lockIcon.icon
    property alias contentLayout: contentLayout

    required property bool isLockscreenOpen
    required property color drawerColors
    required property var pam

    property string inputBuffer: ""
    property bool showErrorMessage: false

    FontMetrics {
        id: lockIconMetrics
        font: lockIcon.font
    }

    implicitWidth: isLockscreenOpen ? bottomWrapperRect.implicitWidth : lockIconMetrics.advanceWidth(lockIcon.text)
    implicitHeight: 0

    Behavior on implicitWidth {
        NAnim {}
    }
    Behavior on implicitHeight {
        NAnim {}
    }

    WrapperRectangle {
        id: bottomWrapperRect

        anchors.fill: parent

        color: root.drawerColors
        clip: true
        radius: 0
        leftMargin: Appearance.margin.normal
        rightMargin: Appearance.margin.normal
        topLeftRadius: Appearance.rounding.normal
        topRightRadius: topLeftRadius

        RowLayout {
            id: contentLayout

            anchors {
                fill: parent
                leftMargin: Appearance.margin.normal
                rightMargin: Appearance.margin.normal
            }
            spacing: Appearance.spacing.normal
            opacity: 0

            ClippingWrapperRectangle {
                implicitWidth: 48
                implicitHeight: 48
                radius: Appearance.rounding.full
                color: "transparent"
                z: -1

                IconImage {
                    id: avatar

                    source: Qt.resolvedUrl(`${Paths.home}/.face`)
                    z: 1
                    backer.cache: true
                    asynchronous: true
                }
            }

            Icon {
                id: lockIcon

                Layout.alignment: Qt.AlignCenter
                icon: "lock"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                transformOrigin: Item.Bottom

                SequentialAnimation {
                    id: shakeAnim
                    running: root.showErrorMessage

                    NAnim {
                        target: lockIcon
                        property: "rotation"
                        to: 18
                        duration: 100
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                    NAnim {
                        target: lockIcon
                        property: "rotation"
                        to: -18
                        duration: 100
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                    NAnim {
                        target: lockIcon
                        property: "rotation"
                        to: 12
                        duration: 100
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                    NAnim {
                        target: lockIcon
                        property: "rotation"
                        to: -12
                        duration: 100
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                    NAnim {
                        target: lockIcon
                        property: "rotation"
                        to: 6
                        duration: 100
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                    NAnim {
                        target: lockIcon
                        property: "rotation"
                        to: -6
                        duration: 100
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                    NAnim {
                        target: lockIcon
                        property: "rotation"
                        to: 0
                        duration: 100
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                    CAnim {
                        target: lockIcon
                        property: "color"
                        to: Colours.m3Colors.m3Red
                        duration: Appearance.animations.durations.small
                        easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
                    }
                }
            }

            StyledText {
                id: errorLabel

                Layout.alignment: Qt.AlignCenter
                text: "WRONG"
                color: Colours.m3Colors.m3Error
                font.pixelSize: Appearance.fonts.size.medium
                font.bold: true
                opacity: root.showErrorMessage ? 1 : 0
                visible: root.showErrorMessage

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

            StyledRect {
                id: submitBtn

                readonly property bool loading: root.pam.unlockInProgress
                readonly property bool canSubmit: root.pam && root.inputBuffer.length > 0

                implicitWidth: 34
                implicitHeight: 34
                radius: Appearance.rounding.full
                color: canSubmit ? root.pam.isUnlock ? Qt.alpha(Colours.m3Colors.m3Primary, 0.4) : Colours.m3Colors.m3Primary : Qt.alpha(Colours.m3Colors.m3Primary, 0.4)
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
                    onTapped: {
                        root.pam.currentText = root.inputBuffer;
                        root.pam.tryUnlock();
                    }
                }
            }
        }
    }
}

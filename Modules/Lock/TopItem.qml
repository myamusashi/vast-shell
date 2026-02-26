import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Item {
    id: root

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
    }

    property alias lockIcon: lockIcon
    property alias leftCorner: topLeftCorner
    property alias rightCorner: topRightCorner

    required property bool isLockscreenOpen
    required property color drawerColors
    required property bool locked
    required property bool showErrorMessage

    property string iconName: "lock"

    implicitWidth: isLockscreenOpen ? topWrapperRect.implicitWidth : lockIcon.contentWidth
    implicitHeight: 0

    Behavior on implicitWidth {
        NAnim {}
    }

    Corner {
        id: topRightCorner

        location: Qt.TopRightCorner
        extensionSide: Qt.Horizontal
        radius: 0
        color: root.drawerColors
    }

    Corner {
        id: topLeftCorner

        location: Qt.TopLeftCorner
        extensionSide: Qt.Horizontal
        radius: 0
        color: root.drawerColors
    }

    WrapperRectangle {
        id: topWrapperRect

        anchors.fill: parent
        color: root.drawerColors
        clip: true
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
                icon: root.iconName
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.extraLarge
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

            WrapperRectangle {
                id: errorWrapper

                implicitWidth: root.showErrorMessage ? failText.implicitWidth : 0
                implicitHeight: 40
                color: "transparent"
                clip: true

                Behavior on implicitWidth {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                // Watch for hide trigger
                onImplicitWidthChanged: {
                    if (!root.showErrorMessage) {
                        wordHideAnim.start();
                    }
                }

                Item {
                    id: failText

                    implicitWidth: wordRow.implicitWidth
                    implicitHeight: wordRow.implicitHeight

                    Row {
                        id: wordRow

                        spacing: Appearance.spacing.small

                        Repeater {
                            id: wordRepeater

                            model: [qsTr("Password"), qsTr("Invalid")]

                            StyledText {
                                id: wordText

                                required property string modelData
                                required property int index

                                text: modelData
                                color: Colours.m3Colors.m3Error
                                font.pixelSize: Appearance.fonts.size.large * 1.5
                                transformOrigin: Item.Left
                            }
                        }
                    }
                }

                SequentialAnimation {
                    id: wordHideAnim

                    // Hide "Invalid"
                    ParallelAnimation {
                        NAnim {
                            target: wordRepeater.itemAt(1)
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                        NAnim {
                            target: wordRepeater.itemAt(1)
                            property: "scale"
                            from: 1
                            to: 0.8
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }

                    PauseAnimation {
                        duration: Appearance.animations.durations.small
                    }

                    // hide "password"
                    ParallelAnimation {
                        NAnim {
                            target: wordRepeater.itemAt(0)
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                        NAnim {
                            target: wordRepeater.itemAt(0)
                            property: "scale"
                            from: 1
                            to: 0.8
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }
                }

                // Reset opacity when shown again
                onVisibleChanged: {
                    if (root.showErrorMessage) {
                        if (wordRepeater.itemAt(0))
                            wordRepeater.itemAt(0).opacity = 1;
                        if (wordRepeater.itemAt(1))
                            wordRepeater.itemAt(1).opacity = 1;
                        if (wordRepeater.itemAt(0))
                            wordRepeater.itemAt(0).scale = 1;
                        if (wordRepeater.itemAt(1))
                            wordRepeater.itemAt(1).scale = 1;
                    }
                }
            }
        }
    }
}

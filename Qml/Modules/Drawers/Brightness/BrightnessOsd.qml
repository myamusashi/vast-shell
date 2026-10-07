pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property bool onFocusedMonitor: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) // qmllint disable
    readonly property int  pillHeight: 104
    readonly property int  pillWidth: 260
    readonly property bool shouldShow: Brightness.available && GlobalStates.isOSDVisible("brightness")

    property bool          primed: false

    implicitHeight: pillHeight
    implicitWidth: shouldShow && onFocusedMonitor ? pillWidth : 0
    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    anchors {
        bottom: parent.bottom
        bottomMargin: 50
        horizontalCenter: parent.horizontalCenter
    }

    Connections {
        function onValueChanged() {
            if (!Brightness.available)
                return;
            if (!root.primed) {
                root.primed = true;
                return;
            }
            GlobalStates.showOSD("brightness");
        }

        target: Brightness
    }

    Loader {
        active: root.shouldShow && root.onFocusedMonitor
        anchors.fill: parent
        asynchronous: true
        sourceComponent: StyledRect {
            id: pill

            readonly property real levelRatio: Brightness.value / (Brightness.maxValue || 1)

            property bool          showLevel: false

            anchors.fill: parent
            clip: true
            color: GlobalStates.drawerColors
            radius: Appearance.rounding.small

            Timer {
                id: levelHideTimer

                interval: 500
                onTriggered: pill.showLevel = false
            }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        GlobalStates.pauseOSD("brightness");
                    else
                        GlobalStates.resumeOSD("brightness");
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: Appearance.spacing.small

                Item {
                    id: levelDisplay

                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitHeight: 48
                    implicitWidth: 48

                    Item {
                        id: iconSwap

                        anchors.fill: parent
                        opacity: pill.showLevel ? 0 : 1
                        scale: pill.showLevel ? 0.5 : 1
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

                        Icon {
                            id: brightnessIcon

                            anchors.centerIn: parent
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge * 1.4
                            icon: "brightness_5"

                            // Lower brightness -> darker icon
                            opacity: 0.25 + 0.75 * pill.levelRatio
                            type: Icon.Material
                            Behavior on opacity {
                                NAnim {
                                    duration: Appearance.animations.durations.normal
                                }
                            }
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.extraLarge * 0.8
                        font.weight: Font.DemiBold
                        opacity: pill.showLevel ? 1 : 0
                        scale: pill.showLevel ? 1 : 0.5
                        text: Brightness.value.toFixed(0)
                        Behavior on opacity {
                            NAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }
                        Behavior on scale {
                            NAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }
                    }
                }

                SegmentBar {
                    anchors.horizontalCenter: parent.horizontalCenter
                    onInteractEnded: {
                        GlobalStates.resumeOSD("brightness");
                        levelHideTimer.restart();
                    }
                    onInteractStarted: {
                        GlobalStates.pauseOSD("brightness");
                        levelHideTimer.stop();
                        pill.showLevel = true;
                    }
                }
            }
        }
    }
}

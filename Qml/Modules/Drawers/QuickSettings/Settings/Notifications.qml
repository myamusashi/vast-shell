pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Modules.Drawers.Notifications.Components as N

StyledRect {
    property alias loader: loader

    color: Qt.alpha(Colours.m3Colors.m3SurfaceContainer, 0.4)
    radius: Appearance.rounding.normal

    RowLayout {
        implicitHeight: 50
        implicitWidth: parent.width
        spacing: Appearance.spacing.small

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 10
        }

        Item {
            Layout.fillWidth: true
        }

        StyledRect {
            color: Colours.m3Colors.m3SurfaceContainer
            implicitHeight: 30
            implicitWidth: clearMetrics.advanceWidth(textClear.text) + 100

            FontMetrics {
                id: clearMetrics

                font: textClear.font
            }

            StyledText {
                id: textClear

                anchors.centerIn: parent
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                text: qsTr("Clear all")
            }

            MArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: Notifs.clearAll()
            }
        }

        StyledRect {
            color: Colours.m3Colors.m3SurfaceContainer
            implicitHeight: 30
            implicitWidth: 30

            Icon {
                id: iconDnD

                anchors.centerIn: parent
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                icon: Notifs.dnd ? "notifications_off" : "notifications_active"
                type: Icon.Material
            }

            MArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: Notifs.dnd = !Notifs.dnd
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Loader {
        id: loader

        active: GlobalStates.isQuickSettingsOpen
        asynchronous: true
        sourceComponent: StyledRect {
            anchors.fill: parent
            clip: true
            color: "transparent"

            ListView {
                id: notifListView

                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 0
                spacing: Appearance.spacing.normal
                delegate: WrapperItem {
                    id: root

                    required property var modelData

                    clip: true
                    implicitHeight: contentLayout.height * 1.3
                    implicitWidth: notifListView.width
                    leftMargin: 10

                    NAnim {
                        id: swipeOutAnim

                        duration: Appearance.animations.durations.small
                        property: "x"
                        target: root
                        onFinished: {
                            fadeOutAnim.start();
                        }
                    }

                    NAnim {
                        id: fadeOutAnim

                        duration: Appearance.animations.durations.small
                        from: 1.0
                        property: "opacity"
                        target: root
                        to: 0.0
                    }

                    SpringAnimation {
                        id: springBackAnim

                        damping: 0.3
                        property: "x"
                        spring: 2
                        target: root
                        to: 0
                    }

                    Timer {
                        id: closeTimer

                        interval: swipeOutAnim.duration + fadeOutAnim.duration
                        onTriggered: root.modelData.close()
                    }

                    WrapperRectangle {
                        clip: true
                        color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3ErrorContainer : Colours.m3Colors.m3SurfaceContainer
                        margin: Appearance.margin.normal
                        radius: Appearance.rounding.normal

                        border {
                            color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : "transparent"
                            width: root.modelData.urgency === NotificationUrgency.Critical ? 1 : 0
                        }

                        Item {

                            MArea {
                                id: delegateMouseNotif

                                anchors.fill: parent
                                hoverEnabled: true

                                drag {
                                    axis: Drag.XAxis
                                    maximumX: root.width
                                    minimumX: -root.width
                                    target: root
                                    onActiveChanged: {
                                        if (drag.active)
                                            return;
                                        const swipeThreshold = root.width * 0.35;

                                        if (Math.abs(root.x) > swipeThreshold) {
                                            swipeOutAnim.to = root.x > 0 ? root.width * 1.2 : -root.width * 1.2;
                                            swipeOutAnim.start();
                                            closeTimer.start();
                                        } else {
                                            springBackAnim.start();
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: Appearance.spacing.normal

                                anchors {
                                    fill: parent
                                    leftMargin: 10
                                    rightMargin: 10
                                    topMargin: 10
                                }

                                N.NotifIcon {
                                    id: iconLayout

                                    modelData: root.modelData
                                }

                                N.Content {
                                    id: contentLayout

                                    modelData: root.modelData
                                    width: parent.width - iconLayout.width
                                }
                            }
                        }
                    }
                }
                model: ScriptModel {
                    values: [...Notifs.notClosed]
                }

                anchors {
                    fill: parent
                    rightMargin: 10
                }
            }

            StyledText {
                anchors.centerIn: parent
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.medium
                opacity: 0.6
                text: qsTr("No notifications")
                visible: Notifs.notClosed.length === 0
            }
        }

        anchors {
            bottomMargin: 10
            fill: parent
            topMargin: 50
        }
    }
}

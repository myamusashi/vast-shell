pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Configs
import qs.Services
import qs.Components

Item {
    id: root

    readonly property int itemsPerPage: maxColumns * maxRows
    readonly property int totalPages: Math.ceil(widgetsList.length / itemsPerPage)
    readonly property int currentPageIndex: Math.floor(swipeView.contentX / swipeView.width)

    readonly property int widgetWidth: 165
    readonly property int widgetHeight: 50

    property int maxColumns: {
        const w = Hypr.focusedMonitor.width / Hypr.focusedMonitor.scale;
        return Math.max(1, Math.min(5, Math.floor(w / 512) + 1));
    }
    property int maxRows: 3
    property int itemSpacing: Appearance.spacing.normal
    property int pageSpacing: 20
    property var widgetsList: Configs.widgets

    implicitWidth: parent.width
    implicitHeight: calculateHeight()

    function calculateHeight() {
        if (widgetsList.length === 0)
            return widgetHeight;

        const availableWidth = implicitWidth - itemSpacing;
        const widgetWithSpacing = widgetWidth + itemSpacing;
        const actualColumns = Math.floor(availableWidth / widgetWithSpacing);
        const rows = Math.ceil(widgetsList.length / Math.max(1, actualColumns));

        return rows * widgetHeight + (rows - 1) * itemSpacing + 40;
    }

    Flickable {
        id: swipeView

        anchors.fill: parent
        contentWidth: root.totalPages * implicitWidth
        contentHeight: implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 5000
        maximumFlickVelocity: 2500

        onMovementEnded: {
            var targetPage = Math.round(contentX / implicitWidth);
            snapAnimation.to = targetPage * implicitWidth;
            snapAnimation.start();
        }

        onFlickEnded: {
            var targetPage = Math.round(contentX / implicitWidth);
            snapAnimation.to = targetPage * implicitWidth;
            snapAnimation.start();
        }

        NAnim {
            id: snapAnimation

            target: swipeView
            property: "contentX"
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }

        Flow {
            anchors {
                left: parent.left
                top: parent.top
                right: parent.right
            }
            spacing: root.itemSpacing

            StyledRect {
                implicitWidth: root.widgetWidth
                implicitHeight: root.widgetHeight
                color: Colours.m3Colors.m3Primary
            }
            StyledRect {
                implicitWidth: root.widgetWidth
                implicitHeight: root.widgetHeight
                color: Colours.m3Colors.m3Primary
            }

            StyledRect {
                implicitWidth: root.widgetWidth
                implicitHeight: root.widgetHeight
                color: Colours.m3Colors.m3Primary
            }

            StyledRect {
                implicitWidth: root.widgetWidth
                implicitHeight: root.widgetHeight
                color: Colours.m3Colors.m3Primary
            }
        }
    }

    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: swipeView.implicitHeight + 12
        anchors.leftMargin: (parent.implicitWidth - implicitWidth) / 2
        width: childrenRect.width
        height: childrenRect.height
        spacing: 8

        Repeater {
            model: root.totalPages

            delegate: Rectangle {
                required property int index

                implicitWidth: root.currentPageIndex === index ? 24 : 8
                implicitHeight: 8
                radius: Appearance.rounding.small

                color: root.currentPageIndex === index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OutlineVariant
                opacity: root.currentPageIndex === index ? 1.0 : 0.5

                Behavior on implicitWidth {
                    NAnim {
                        duration: Appearance.animations.durations.emphasized
                        easing.bezierCurve: Appearance.animations.curves.emphasized
                    }
                }

                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.emphasized
                        easing.bezierCurve: Appearance.animations.curves.emphasized
                    }
                }
            }
        }
    }
}

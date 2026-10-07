pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Services
import qs.Components.Base

WrapperRectangle {
    id: root

    required property Component content

    property bool               clipContent: false
    property bool               closing: false
    property int                contentMargin: Appearance.margin.small
    property bool               deferContent: true
    property bool               enableScroll: true
    property alias              icon: header.icon
    property bool               isVisible: false
    property alias              text: header.text
    property real               zoomOriginX: parent.width / 2
    property real               zoomOriginY: parent.height / 2

    signal                      closed
    signal                      opened

    function                    openFrom(sourceItem) {
        if (!sourceItem || !parent)
            return;
        const p          = sourceItem.mapToItem(parent, sourceItem.width / 2, sourceItem.height / 2);
        root.zoomOriginX = p.x;
        root.zoomOriginY = p.y;
        root.isVisible   = true;
    }

    color: Colours.m3Colors.m3SurfaceContainer
    enabled: root.isVisible
    implicitHeight: Math.min((header.visible ? header.implicitHeight + bodyColumn.spacing : 0) + (root.enableScroll ? scrollLoader.implicitHeight : staticLoader.implicitHeight) + root.contentMargin * 2, parent.height * 0.8)
    implicitWidth: parent.width * 0.8
    margin: Appearance.margin.small
    opacity: isVisible ? 1.0 : 0.0
    radius: Appearance.rounding.small
    scale: isVisible ? 1.0 : 0.5
    transformOrigin: Item.Center
    visible: root.isVisible || root.closing
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
    transform: Translate {
        x: root.isVisible ? 0 : root.zoomOriginX - root.width / 2
        y: root.isVisible ? 0 : root.zoomOriginY - root.height / 2
        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on y {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }
    onIsVisibleChanged: {
        if (!root.isVisible) {
            root.closing = true;
            hideTimer.restart();
            root.closed();
        } else {
            root.opened();
        }
    }

    border {
        color: Colours.m3Colors.m3Outline
        width: 1
    }

    Timer {
        id: hideTimer

        interval: Appearance.animations.durations.expressiveDefaultSpatial + 50
        onTriggered: root.closing = false
    }

    ColumnLayout {
        id: bodyColumn

        spacing: Appearance.spacing.small

        anchors {
            fill: parent
            margins: root.contentMargin
        }

        Header {
            id: header

            Layout.fillWidth: true
            icon: ""
            text: ""
            visible: header.text !== "" || header.icon !== ""
        }

        Item {
            id: bodyHost

            Layout.fillHeight: true
            Layout.fillWidth: true

            ScrollView {
                id: scrollView

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                anchors.fill: parent
                clip: true
                contentWidth: availableWidth
                visible: root.enableScroll

                Loader {
                    id: scrollLoader

                    active: (root.deferContent ? root.isVisible : true) && root.enableScroll
                    asynchronous: true
                    clip: root.clipContent
                    sourceComponent: root.content
                    width: scrollView.availableWidth
                }
            }

            Loader {
                id: staticLoader

                active: (root.deferContent ? root.isVisible : true) && !root.enableScroll
                anchors.fill: parent
                asynchronous: true
                clip: root.clipContent
                sourceComponent: root.content
                visible: !root.enableScroll
            }
        }
    }
}

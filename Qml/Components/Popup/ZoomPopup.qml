pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

import qs.Core.Configs
import qs.Services
import qs.Components.Base

WrapperRectangle {
    id: root

    property alias text: header.text
    property alias icon: header.icon
    required property Component content
    property bool isVisible: false
    property bool closing: false
    property real zoomOriginX: parent.width / 2
    property real zoomOriginY: parent.height / 2
    property int contentMargin: Appearance.margin.small
    property bool clipContent: false
    property bool deferContent: true
    property bool enableScroll: true

    signal opened
    signal closed

    function openFrom(sourceItem) {
        if (!sourceItem || !parent)
            return;
        const p = sourceItem.mapToItem(parent, sourceItem.width / 2, sourceItem.height / 2);
        root.zoomOriginX = p.x;
        root.zoomOriginY = p.y;
        root.isVisible = true;
    }

    border {
        width: 1
        color: Colours.m3Colors.m3Outline
    }
    implicitWidth: parent.width * 0.8
    implicitHeight: Math.min((header.visible ? header.implicitHeight + bodyColumn.spacing : 0) + (root.enableScroll ? scrollLoader.implicitHeight : staticLoader.implicitHeight) + root.contentMargin * 2, parent.height * 0.8)
    margin: Appearance.margin.small
    radius: Appearance.rounding.small
    color: Colours.m3Colors.m3SurfaceContainer
    visible: root.isVisible || root.closing
    enabled: root.isVisible
    scale: isVisible ? 1.0 : 0.5
    opacity: isVisible ? 1.0 : 0.0
    transformOrigin: Item.Center

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

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
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

    Timer {
        id: hideTimer

        interval: Appearance.animations.durations.expressiveDefaultSpatial + 50
        onTriggered: root.closing = false
    }

    ColumnLayout {
        id: bodyColumn

        anchors {
            fill: parent
            margins: root.contentMargin
        }
        spacing: Appearance.spacing.small

        Header {
            id: header

            Layout.fillWidth: true
            visible: header.text !== "" || header.icon !== ""
            text: ""
            icon: ""
        }

        Item {
            id: bodyHost

            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                id: scrollView

                anchors.fill: parent
                visible: root.enableScroll
                clip: true
                contentWidth: availableWidth

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Loader {
                    id: scrollLoader

                    width: scrollView.availableWidth
                    active: (root.deferContent ? root.isVisible : true) && root.enableScroll
                    asynchronous: true
                    clip: root.clipContent
                    sourceComponent: root.content
                }
            }

            Loader {
                id: staticLoader

                anchors.fill: parent
                visible: !root.enableScroll
                active: (root.deferContent ? root.isVisible : true) && !root.enableScroll
                asynchronous: true
                clip: root.clipContent
                sourceComponent: root.content
            }
        }
    }
}

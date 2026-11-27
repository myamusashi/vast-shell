pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Scope {
    id: root

    required property Item anchorItem

    readonly property bool active: root.alive && root.enabled && root.anchorItem !== null && root.anchorItem.visible && root.text.length > 0
    readonly property int  gap: 4
    readonly property bool isHorizontal: root.position === Edges.Left || root.position === Edges.Right

    property bool          alive: true
    property bool          enabled: true
    property Item          latchedAnchor: null
    property string        latchedText: ""
    property bool          mapped: false
    property real          maxWidth: 320
    property int           position: Edges.Bottom
    property Item          sensor: null
    property int           showDelay: 500
    property bool          shown: false
    property string        text: ""

    function               close(): void {
        if (!root.shown && !root.mapped)
            return;

        root.shown = false;
        if (root.mapped)
            hideTimer.restart();
    }

    function               destroySensors(): void {
        if (root.sensor) {
            root.sensor.visible = false;
            root.sensor.parent  = null;
            root.sensor.destroy();
            root.sensor = null;
        }
    }

    function               open(): void {
        if (!root.active || root.shown)
            return;

        root.latchedAnchor = root.anchorItem;
        root.latchedText   = root.text;
        root.shown         = true;
    }

    function               syncSensors(): void {
        root.destroySensors();
        if (!root.alive || !root.anchorItem)
            return;

        root.sensor = sensorComponent.createObject(root.anchorItem, {
            parent: root.anchorItem
        });
    }

    Component.onCompleted: {
        if (root.alive)
            syncTimer.restart();
    }
    Component.onDestruction: {
        syncTimer.stop();
        showTimer.stop();
        hideTimer.stop();
        unmapTimer.stop();
        root.mapped = false;
        root.shown  = false;
        root.alive  = false;
        root.destroySensors();
    }
    onActiveChanged: {
        if (!root.active) {
            showTimer.stop();
            root.close();
        }
    }
    onAnchorItemChanged: {
        showTimer.stop();
        root.close();
        if (root.alive)
            syncTimer.restart();
    }
    onMappedChanged: {
        if (!root.mapped) {
            unmapTimer.stop();
            hideTimer.stop();
            root.latchedAnchor = null;
            root.latchedText   = "";
        }
    }
    onShownChanged: {
        if (root.shown && root.active) {
            unmapTimer.stop();
            hideTimer.stop();
            root.mapped = true;
        } else if (root.mapped) {
            hideTimer.restart();
        }
    }
    onTextChanged: {
        if (root.shown && root.text.length > 0)
            root.latchedText = root.text;
    }

    Timer {
        id: hideTimer

        interval: Appearance.animations.durations.small + 50
        onTriggered: root.mapped = false
    }

    Timer {
        id: unmapTimer

        interval: 16
        onTriggered: {
            if (!root.shown)
                root.mapped = false;
        }
    }

    Timer {
        id: showTimer

        interval: root.showDelay
        onTriggered: root.open()
    }

    // Coalesce initial anchorItemChanged + Component.onCompleted and cancel
    // automatically when root is destroyed (unlike Qt.callLater).
    Timer {
        id: syncTimer

        interval: 0
        onTriggered: root.syncSensors()
    }

    Component {
        id: sensorComponent

        Item {
            anchors.fill: parent

            HoverHandler {
                enabled: root.active
                onHoveredChanged: {
                    if (hovered) {
                        showTimer.restart();
                    } else {
                        showTimer.stop();
                        root.close();
                    }
                }
            }

            PointHandler {
                acceptedButtons: Qt.AllButtons
                enabled: root.active
                onActiveChanged: {
                    if (active) {
                        showTimer.stop();
                        root.close();
                    }
                }
            }
        }
    }

    LazyLoader {
        active: root.mapped
        component: PopupWindow {
            id: tooltipWindow

            property bool appeared: false

            anchor {
                // qmllint disable incompatible-type
                adjustment: root.isHorizontal ? (PopupAdjustment.Flip | PopupAdjustment.SlideY) : (PopupAdjustment.Flip | PopupAdjustment.SlideX)
                edges: root.position
                gravity: root.position
                // qmllint enable incompatible-type
                item: root.latchedAnchor ?? root.anchorItem

                margins {
                    bottom: root.gap
                    left: root.gap
                    right: root.gap
                    top: root.gap
                }
            }

            color: "transparent"
            grabFocus: false
            implicitHeight: container.implicitHeight
            implicitWidth: container.implicitWidth
            mask: Region {}
            visible: root.mapped
            BackgroundEffect.blurRegion: Region {
                item: tooltipWindow.contentItem
            }
            HyprlandWindow.visibleMask: Region {
                item: tooltipWindow.contentItem
            }
            Component.onCompleted: appeared = true

            StyledRect {
                id: container

                anchors.fill: parent
                color: Colours.m3Colors.m3InverseSurface
                implicitHeight: Math.max(24, label.implicitHeight + 8)
                implicitWidth: Math.min(root.maxWidth, Math.max(40, label.implicitWidth + 16))
                opacity: root.shown && tooltipWindow.appeared ? 1 : 0
                radius: 4
                visible: opacity > 0
                onOpacityChanged: {
                    if (!root.shown && opacity === 0)
                        unmapTimer.restart();
                }
                Behavior on opacity {
                    NAnim {
                        duration: Appearance.animations.durations.small
                    }
                }

                StyledText {
                    id: label

                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3InverseOnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.small
                    maximumLineCount: 1
                    text: root.latchedText.length > 0 ? root.latchedText : root.text
                    width: Math.min(implicitWidth, root.maxWidth - 16)
                }
            }
        }
    }
}

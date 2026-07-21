pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "."

Item {
    id: root

    anchors {
        top: bar.bottom
        horizontalCenter: bar.horizontalCenter
    }

    enum State {
        Idle,
        Dragging,
        FilesDropped,
        SelectingDevice,
        ConfirmDevice,
        Transferring,
        Completed
    }

    readonly property bool islandVisible: root.hovered || root.currentState !== DynamicIsland.State.Idle

    property bool hovered: false
    property int currentState: DynamicIsland.State.Idle
    property var droppedFiles: []
    property var selectedDevice: null
    property bool transferSuccess: false

    implicitWidth: root.islandVisible ? island.contentWidth : bar.width * 0.35
    implicitHeight: root.islandVisible ? island.contentHeight + Configs.bar.barHeight + 20 : Configs.bar.barHeight + 40

    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name

    function startTransfer() {
        root.currentState = DynamicIsland.State.Transferring;
        for (var i = 0; i < root.droppedFiles.length; i++)
            KDEConnect.shareFile(root.selectedDevice.id, root.droppedFiles[i]);
        transferTimer.start();
    }

    function cancelTransfer() {
        transferTimer.stop();
        root.transferSuccess = false;
        root.currentState = DynamicIsland.State.Completed;
        resetTimer.start();
    }

    function dismiss() {
        root.currentState = DynamicIsland.State.Idle;
        root.droppedFiles = [];
        root.selectedDevice = null;
        root.transferSuccess = false;
    }

    function goBack() {
        if (root.currentState === DynamicIsland.State.SelectingDevice || root.currentState === DynamicIsland.State.ConfirmDevice)
            root.currentState = DynamicIsland.State.FilesDropped;
    }

    function goToDeviceSelection() {
        root.currentState = DynamicIsland.State.SelectingDevice;
    }

    function goToConfirmation() {
        root.currentState = DynamicIsland.State.ConfirmDevice;
    }

    function updateContentSize() {
        var childIndex = stackLayout.currentIndex;
        var children = stackLayout.children;
        if (childIndex >= 0 && childIndex < children.length) {
            var child = children[childIndex];
            island.contentWidth = Math.max(120, child.implicitWidth + 24);
            island.contentHeight = Math.max(44, child.implicitHeight + 16);
        }
    }

    Timer {
        id: transferTimer

        interval: Math.min(root.droppedFiles.length * 2000, 15000)
        onTriggered: {
            root.transferSuccess = true;
            root.currentState = DynamicIsland.State.Completed;
            resetTimer.start();
        }
    }

    Timer {
        id: resetTimer

        interval: 3000
        onTriggered: root.dismiss()
    }

    Rectangle {
        id: hitZone

        anchors {
            fill: parent
            topMargin: -20
        }

        color: "transparent"

        HoverHandler {
            id: hoverHandler

            margin: 12
            onHoveredChanged: root.hovered = hovered
        }
    }

    DropArea {
        id: dropArea

        anchors.fill: hitZone

        onEntered: drag => {
            if (drag.hasUrls && (root.currentState === DynamicIsland.State.Idle || root.currentState === DynamicIsland.State.FilesDropped))
                root.currentState = DynamicIsland.State.Dragging;
        }
        onExited: {
            if (root.currentState === DynamicIsland.State.Dragging)
                root.currentState = root.droppedFiles.length > 0 ? DynamicIsland.State.FilesDropped : DynamicIsland.State.Idle;
        }

        onPositionChanged: drag => {
            if (!drag.hasUrls && root.currentState === DynamicIsland.State.Dragging)
                root.currentState = root.droppedFiles.length > 0 ? DynamicIsland.State.FilesDropped : DynamicIsland.State.Idle;
        }
        onDropped: drop => {
            if (root.currentState !== DynamicIsland.State.Dragging)
                return;
            var incoming = [];
            for (var i = 0; i < drop.urls.length; i++)
                incoming.push(String(drop.urls[i]).replace("file://", ""));
            root.droppedFiles = root.droppedFiles.concat(incoming);
            root.currentState = DynamicIsland.State.FilesDropped;
        }
    }

    WrapperRectangle {
        id: island

        anchors {
            top: hitZone.top
            topMargin: Configs.bar.barHeight
            horizontalCenter: parent.horizontalCenter
        }

        property real contentWidth: 0
        property real contentHeight: 44

        implicitWidth: root.islandVisible ? island.contentWidth : 0
        implicitHeight: root.islandVisible ? island.contentHeight : 0

        radius: root.currentState > DynamicIsland.State.Dragging ? Appearance.rounding.normal : Appearance.rounding.full
        color: GlobalStates.drawerColors
        clip: true

        Behavior on implicitWidth {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Behavior on implicitHeight {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Behavior on radius {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        StackLayout {
            id: stackLayout

            implicitWidth: island.contentWidth
            implicitHeight: island.contentHeight
            currentIndex: {
                switch (root.currentState) {
                case DynamicIsland.State.Dragging:
                    return 1;
                case DynamicIsland.State.FilesDropped:
                    return 2;
                case DynamicIsland.State.SelectingDevice:
                    return 3;
                case DynamicIsland.State.ConfirmDevice:
                    return 4;
                case DynamicIsland.State.Transferring:
                    return 5;
                case DynamicIsland.State.Completed:
                    return 6;
                default:
                    return 0;
                }
            }

            onCurrentIndexChanged: root.updateContentSize()

            Item {
                implicitWidth: 0
                implicitHeight: 0
            }

            DraggingContent {
                onImplicitWidthChanged: root.updateContentSize()
                onImplicitHeightChanged: root.updateContentSize()
            }
            FilesDroppedContent {
                island: root
                onImplicitWidthChanged: root.updateContentSize()
                onImplicitHeightChanged: root.updateContentSize()
            }
            DeviceListContent {
                island: root
                onImplicitWidthChanged: root.updateContentSize()
                onImplicitHeightChanged: root.updateContentSize()
            }
            ConfirmDeviceContent {
                island: root
                onImplicitWidthChanged: root.updateContentSize()
                onImplicitHeightChanged: root.updateContentSize()
            }
            ProgressContent {
                island: root
                onImplicitWidthChanged: root.updateContentSize()
                onImplicitHeightChanged: root.updateContentSize()
            }
            DoneContent {
                island: root
                onImplicitWidthChanged: root.updateContentSize()
                onImplicitHeightChanged: root.updateContentSize()
            }
        }
    }
}

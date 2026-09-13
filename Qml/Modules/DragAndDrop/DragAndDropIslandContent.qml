pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services

Item {
    id: root

    property real islandRadius: DragAndDropServices.currentState > DragAndDropServices.State.Dragging ? Appearance.rounding.normal : Appearance.rounding.full

    implicitWidth: {
        if (DragAndDropServices.currentState === DragAndDropServices.State.Idle)
            return DragAndDropServices.dotSize;
        var child = stackLayout.children[stackLayout.currentIndex];
        return Math.max(120, (child ? child.implicitWidth : 0) + 24);
    }
    implicitHeight: {
        if (DragAndDropServices.currentState === DragAndDropServices.State.Idle)
            return DragAndDropServices.dotSize;
        var child = stackLayout.children[stackLayout.currentIndex];
        return Math.max(44, (child ? child.implicitHeight : 0) + 16);
    }
    anchors.fill: parent

    DropArea {
        id: dropArea

        anchors.fill: parent

        onEntered: drag => {
            if (drag.hasUrls && (DragAndDropServices.currentState === DragAndDropServices.State.Idle || DragAndDropServices.currentState === DragAndDropServices.State.FilesDropped))
                DragAndDropServices.currentState = DragAndDropServices.State.Dragging;
        }
        onExited: {
            if (DragAndDropServices.currentState === DragAndDropServices.State.Dragging)
                DragAndDropServices.currentState = DragAndDropServices.droppedFiles.length > 0 ? DragAndDropServices.State.FilesDropped : DragAndDropServices.State.Idle;
        }
        onPositionChanged: drag => {
            if (!drag.hasUrls && DragAndDropServices.currentState === DragAndDropServices.State.Dragging)
                DragAndDropServices.currentState = DragAndDropServices.droppedFiles.length > 0 ? DragAndDropServices.State.FilesDropped : DragAndDropServices.State.Idle;
        }
        onDropped: drop => {
            if (DragAndDropServices.currentState !== DragAndDropServices.State.Dragging)
                return;
            var incoming = [];
            for (var i = 0; i < drop.urls.length; i++)
                incoming.push(String(drop.urls[i]).replace("file://", ""));
            DragAndDropServices.droppedFiles = DragAndDropServices.droppedFiles.concat(incoming);
            DragAndDropServices.currentState = DragAndDropServices.State.FilesDropped;
        }
    }

    StackLayout {
        id: stackLayout

        anchors.fill: parent
        currentIndex: {
            switch (DragAndDropServices.currentState) {
            case DragAndDropServices.State.Dragging:
                return 1;
            case DragAndDropServices.State.FilesDropped:
                return 2;
            case DragAndDropServices.State.SelectingDevice:
                return 3;
            case DragAndDropServices.State.ConfirmDevice:
                return 4;
            case DragAndDropServices.State.Transferring:
                return 5;
            case DragAndDropServices.State.Completed:
                return 6;
            default:
                return 0;
            }
        }

        Item {
            implicitWidth: DragAndDropServices.dotSize
            implicitHeight: DragAndDropServices.dotSize

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: width / 2
                color: Colours.m3Colors.m3Green
            }
        }

        DraggingContent {
            active: DragAndDropServices.isDragging
        }
        FilesDroppedContent {
            island: DragAndDropServices
            active: DragAndDropServices.isFilesDropped
        }
        DeviceListContent {
            island: DragAndDropServices
            active: DragAndDropServices.isSelectingDevice
        }
        ConfirmDeviceContent {
            island: DragAndDropServices
            active: DragAndDropServices.isConfirmDevice
        }
        ProgressContent {
            island: DragAndDropServices
            active: DragAndDropServices.isTransferring
        }
        DoneContent {
            island: DragAndDropServices
            active: DragAndDropServices.isCompleted
        }
    }
}

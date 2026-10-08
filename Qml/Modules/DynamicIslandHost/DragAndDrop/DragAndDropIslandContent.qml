pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services

Item {
    id: root

    property real islandRadius: DragAndDropServices.currentState > DragAndDropServices.State.Dragging ? Appearance.rounding.normal : Appearance.rounding.full

    anchors.fill: parent
    implicitHeight: {
        if (DragAndDropServices.currentState === DragAndDropServices.State.Idle)
            return DragAndDropServices.dotSize;
        var child = stackLayout.children[stackLayout.currentIndex];
        return Math.max(44, (child ? child.implicitHeight : 0) + 16);
    }
    implicitWidth: {
        if (DragAndDropServices.currentState === DragAndDropServices.State.Idle)
            return DragAndDropServices.dotSize;
        var child = stackLayout.children[stackLayout.currentIndex];
        return Math.max(120, (child ? child.implicitWidth : 0) + 24);
    }

    DropArea {
        id: dropArea

        anchors.fill: parent
        onDropped: drop => {
            if (DragAndDropServices.currentState !== DragAndDropServices.State.Dragging)
                return;
            var incoming = [];
            for (var i = 0; i < drop.urls.length; i++)
                incoming.push(String(drop.urls[i]).replace("file://", ""));
            DragAndDropServices.droppedFiles = DragAndDropServices.droppedFiles.concat(incoming);
            DragAndDropServices.currentState = DragAndDropServices.State.FilesDropped;
        }
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
            implicitHeight: DragAndDropServices.dotSize
            implicitWidth: DragAndDropServices.dotSize

            Rectangle {
                anchors.centerIn: parent
                color: Colours.m3Colors.m3Green
                height: 10
                radius: width / 2
                width: 10
            }
        }

        DraggingContent {
            active: DragAndDropServices.isDragging
        }

        FilesDroppedContent {
            active: DragAndDropServices.isFilesDropped
            island: DragAndDropServices
        }

        DeviceListContent {
            active: DragAndDropServices.isSelectingDevice
            island: DragAndDropServices
        }

        ConfirmDeviceContent {
            active: DragAndDropServices.isConfirmDevice
            island: DragAndDropServices
        }

        ProgressContent {
            active: DragAndDropServices.isTransferring
            island: DragAndDropServices
        }

        DoneContent {
            active: DragAndDropServices.isCompleted
            island: DragAndDropServices
        }
    }
}

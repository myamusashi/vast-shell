pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Core.States
import qs.Services

Scope {
    Component {
        id: islandContent

        DragAndDropIslandContent {}
    }

    Binding {
        target: DragAndDropServices
        property: "islandContent"
        value: islandContent
    }

    Connections {
        target: DragAndDropServices

        function onIslandContentChanged(): void {
            if (GlobalStates.isDragAndDropActive)
                DragAndDropServices.openIsland();
        }
    }

    Component.onCompleted: {
        if (GlobalStates.isDragAndDropActive)
            DragAndDropServices.openIsland();
    }
}

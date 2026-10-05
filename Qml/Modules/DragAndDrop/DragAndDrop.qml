pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Components.Feedback
import qs.Core.States
import qs.Services

Scope {
    Component.onCompleted: {
        if (GlobalStates.isDragAndDropActive)
            DragAndDropServices.openIsland();
    }

    Component {
        id: islandContent

        DragAndDropIslandContent {
        }
    }
    IslandHost {
        content: islandContent
        propertyName: "islandContent"
        service: DragAndDropServices
    }
    Connections {
        function onIslandContentChanged(): void {
            if (GlobalStates.isDragAndDropActive)
                DragAndDropServices.openIsland();
        }

        target: DragAndDropServices
    }
}

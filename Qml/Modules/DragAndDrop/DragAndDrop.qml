pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Components.Feedback
import qs.Core.States
import qs.Services

Scope {
    Component {
        id: islandContent

        DragAndDropIslandContent {}
    }

    IslandHost {
        service: DragAndDropServices
        propertyName: "islandContent"
        content: islandContent
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

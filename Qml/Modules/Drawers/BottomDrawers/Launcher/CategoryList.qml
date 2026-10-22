pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

ListView {
    id: root

    signal categorySelected(string categoryId)

    clip: true
    implicitWidth: 180
    spacing: Appearance.spacing.small
    add: Transition {

        NAnim {
            from: 0
            properties: "opacity"
            to: 1
        }
    }
    delegate: CategoryItem {
        implicitWidth: root.width
        onCategoryClicked: categoryId => root.categorySelected(categoryId)
        selected: categoryId === LauncherServices.activeCategory
    }
    displaced: Transition {

        NAnim {
            duration: Appearance.animations.durations.small
            property: "y"
        }

        NAnim {
            properties: "opacity"
            to: 1
        }
    }
    model: LauncherServices.categoriesModel
    remove: Transition {

        NAnim {
            from: 1
            properties: "opacity"
            to: 0
        }
    }

    Connections {
        function onActiveCategoryChanged() {
            const index = LauncherServices.categoryIndex(LauncherServices.activeCategory);

            if (index >= 0)
                root.positionViewAtIndex(index, ListView.Contain);
        }

        target: LauncherServices
    }
}

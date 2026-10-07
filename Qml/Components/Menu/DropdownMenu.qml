pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell

import qs.Components.Menu

Popup {
    id: root

    readonly property int  gap: 4
    readonly property bool openingUpward: openUpward

    property Item          anchorItem: null
    property int           currentIndex: -1
    property var           disabledLabel: modelData => ""
    property var           isItemActive: (modelData, itemIndex) => itemIndex === currentIndex
    property var           isItemEnabled: modelData => true
    property real          maxWidth: 280
    property int           minVisibleRows: 3
    property alias         model: itemRepeater.model
    property bool          openUpward: false
    property string        preferredDirection: "auto"
    property real          resolvedMaxHeight: 336
    property bool          resolveGuard: false
    property bool          showScrollBar: false
    property var           textRole: "text"

    signal                 activated(int index)

    function               availableSpaceAbove(): real {
        const win = anchorItem ? anchorItem.QsWindow.window : null;
        if (!win)
            return 336 + 200;
        // qmllint disable missing-property
        const contentItem = win.contentItem;
        if (contentItem) {
            const p = anchorItem.mapToItem(contentItem, 0, 0);
            if (isFinite(p.y))
                return p.y - gap;
        }
        return win.height;
        // qmllint enable missing-property
    }
    function               availableSpaceBelow(): real {
        const win = anchorItem ? anchorItem.QsWindow.window : null;
        if (!win)
            return 336 + 200;
        // qmllint disable missing-property
        const contentItem = win.contentItem;
        if (contentItem) {
            const p = anchorItem.mapToItem(contentItem, 0, anchorItem.height);
            if (isFinite(p.y))
                return win.height - p.y - gap;
        }
        return win.height - (anchorItem.height + gap);
        // qmllint enable missing-property
    }
    function               resolvePlacement() {
        if (!anchorItem || !anchorItem.QsWindow.window || resolveGuard)
            return;
        resolveGuard      = true;

        // qmllint disable missing-property
        const win         = anchorItem.QsWindow.window;
        const placement   = PopupPlacement.resolve(preferredDirection, availableSpaceAbove(), availableSpaceBelow(), menuSurface.contentImplicitHeight, 336, minVisibleRows, 48, gap, win.height);
        openUpward        = placement.openUpward;
        resolvedMaxHeight = placement.maxHeight;
        // qmllint enable missing-property

        resolveGuard      = false;
    }

    background: null
    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape
    focus: true
    height: Math.min(resolvedMaxHeight, menuSurface.contentImplicitHeight)
    padding: 0
    transformOrigin: openUpward ? Popup.BottomLeft : Popup.TopLeft
    width: anchorItem ? Math.max(menuSurface.minWidth, Math.min(maxWidth, anchorItem.width)) : menuSurface.implicitWidth
    y: openUpward ? -height - gap : (anchorItem ? anchorItem.height + gap : 0)
    enter: MenuTransitions {
        opening: true
    }
    exit: MenuTransitions {
        opening: false
    }
    onAboutToShow: resolvePlacement()
    onAnchorItemChanged: {
        if (anchorItem)
            parent = anchorItem;
    }
    onOpened: resolvePlacement()

    Connections {
        function onHeightChanged() {
            root.resolvePlacement();
        }
        function onWidthChanged() {
            root.resolvePlacement();
        }
        function onXChanged() {
            root.resolvePlacement();
        }
        function onYChanged() {
            root.resolvePlacement();
        }

        ignoreUnknownSignals: true
        target: root.anchorItem && root.anchorItem.QsWindow.window ? root.anchorItem.QsWindow.window : null
    }

    MenuSurface {
        id: menuSurface

        anchors.fill: parent
        maxHeight: root.resolvedMaxHeight
        maxWidth: root.maxWidth
        showScrollBar: root.showScrollBar

        Repeater {
            id: itemRepeater

            model: root.model
            delegate: MenuItem {
                required property int index
                required property var modelData

                disabledLabel: root.disabledLabel(modelData)
                enabled: root.isItemEnabled(modelData)
                label: typeof modelData === "string" ? modelData : modelData[root.textRole] ?? ""
                // qmllint disable
                selected: root.isItemActive(modelData, index)

                // qmllint enable

                onTriggered: {
                    root.activated(index);
                    root.close();
                }
            }
        }
    }
}

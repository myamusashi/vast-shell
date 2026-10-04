pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States

Drawer {
    id: root

    property real maxHeight: 480
    property real menuWidth: 280
    property var pages: []

    signal entered
    signal entryActivated(var entry)
    signal exited

    readonly property var currentPage: stackLayout.currentIndex >= 0 && stackLayout.currentIndex < root.pages.length ? root.pages[stackLayout.currentIndex] : null
    readonly property real contentHeight: root.currentPage ? root.currentPage.contentHeight : 0

    edge: Qt.TopEdge
    alignment: Qt.AlignRight
    length: menuWidth
    depth: Math.min(contentHeight, maxHeight)
    cornerRadius: Appearance.rounding.normal
    filletRadius: 40
    color: GlobalStates.drawerColors
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial

    function openMenu(handle: var): void {
        const page = root.pageAt(0);
        if (!page) {
            root.createPage(handle, "");
            return;
        }
        for (let index = 0; index < root.pages.length; index++)
            root.pages[index].handle = index === 0 ? handle : null;
        page.title = "";
        page.highlightedEntry = null;
        stackLayout.currentIndex = 0;
    }

    function pushSubmenu(entry: var): void {
        if (!entry || !entry.hasChildren)
            return;
        const parentPage = root.pageAt(stackLayout.currentIndex);
        if (parentPage && parentPage.handle === entry) {
            root.popSubmenu();
            return;
        }
        const level = stackLayout.currentIndex + 1;
        const page = root.pageAt(level);
        if (page) {
            page.handle = entry;
            page.title = entry.text ?? "";
        } else {
            root.createPage(entry, entry.text ?? "");
        }
        if (parentPage)
            parentPage.highlightedEntry = entry;
        stackLayout.currentIndex = level;
    }

    function popSubmenu(): void {
        if (stackLayout.currentIndex <= 0)
            return;
        stackLayout.currentIndex -= 1;
    }

    function pageAt(level: int): var {
        return level >= 0 && level < root.pages.length ? root.pages[level] : null;
    }

    function createPage(handle: var, pageTitle: string): void {
        const page = pageComponent.createObject(stackLayout, {
            handle: handle,
            level: root.pages.length,
            title: pageTitle
        });
        if (!page)
            return;
        root.pages = root.pages.concat(page);
    }

    Item {
        id: stackHost

        anchors.fill: parent
        clip: true

        StackLayout {
            id: stackLayout

            width: stackHost.width
            height: stackHost.height
        }
    }

    HoverHandler {
        id: hoverHandler

        onHoveredChanged: {
            if (hovered)
                root.entered();
            else
                root.exited();
        }
    }

    Component {
        id: pageComponent

        TrayMenu {
            Layout.fillHeight: true
            Layout.maximumHeight: root.maxHeight

            currentIndex: stackLayout.currentIndex

            onBackRequested: root.popSubmenu()
            onEntryActivated: entry => root.entryActivated(entry)
            onSubmenuRequested: entry => root.pushSubmenu(entry)
            onEntered: root.entered()
            onExited: root.exited()
        }
    }
}

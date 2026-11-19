pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States

Drawer {
    id: root

    property var  activeMenu: null
    property real maxHeight: 500
    property bool menuMapped: false
    property real menuWidth: 280

    signal        entered
    signal        entryActivated(var entry)
    signal        exited

    function      syncMenu(): void {
        if (root.open && root.activeMenu !== null && loader.item)
            loader.item.openMenu(root.activeMenu); // qmllint disable missing-property
    }

    onActiveMenuChanged: root.syncMenu()
    onOpenChanged: {
        if (open)
            root.syncMenu();
    }
    alignment: Qt.AlignRight
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: Math.min(loader.item?.contentHeight ?? 0, maxHeight) // qmllint disable
    edge: Qt.TopEdge
    filletRadius: 40
    length: menuWidth

    Loader {
        id: loader

        active: root.open || root.menuMapped || root.visible
        anchors.fill: parent
        onLoaded: root.syncMenu()
        sourceComponent: Item {
            id: itemLoader

            readonly property real contentHeight: currentPage ? currentPage.contentHeight : 0
            readonly property var  currentPage: stackLayout.currentIndex >= 0 && stackLayout.currentIndex < pages.length ? pages[stackLayout.currentIndex] : null

            property var           pages: []

            function               createPage(handle: var, pageTitle: string): void {
                const page = pageComponent.createObject(stackLayout, {
                    handle: handle,
                    level: pages.length,
                    title: pageTitle
                });
                if (!page)
                    return;
                pages = pages.concat(page);
            }

            function               destroyPagesFrom(startIndex: int): void {
                if (startIndex >= pages.length)
                    return;
                const remaining = pages.slice(0, startIndex);
                const removed   = pages.slice(startIndex);
                pages           = remaining;
                for (let index = 0; index < removed.length; index++) {
                    removed[index].handle = null;
                    removed[index].destroy();
                }
            }

            function               openMenu(handle: var): void {
                destroyPagesFrom(1);
                const page = pageAt(0);
                if (!page) {
                    createPage(handle, "");
                    return;
                }
                page.handle              = handle;
                page.title               = "";
                stackLayout.currentIndex = 0;
            }

            function               pageAt(level: int): var {
                return level >= 0 && level < pages.length ? pages[level] : null;
            }

            function               popSubmenu(): void {
                if (stackLayout.currentIndex <= 0)
                    return;
                stackLayout.currentIndex -= 1;
                destroyPagesFrom(stackLayout.currentIndex + 1);
            }

            function               pushSubmenu(entry: var): void {
                if (!entry || !entry.hasChildren)
                    return;
                const parentPage = pageAt(stackLayout.currentIndex);
                if (parentPage && parentPage.handle === entry) {
                    popSubmenu();
                    return;
                }
                const level = stackLayout.currentIndex + 1;
                destroyPagesFrom(level + 1);
                const page = pageAt(level);
                if (page) {
                    page.handle = entry;
                    page.title  = entry.text ?? "";
                } else {
                    createPage(entry, entry.text ?? "");
                }
                stackLayout.currentIndex = level;
            }

            anchors.fill: parent

            StackLayout {
                id: stackLayout

                anchors.fill: parent
            }

            HoverHandler {
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
                    onBackRequested: itemLoader.popSubmenu()
                    onEntryActivated: entry => root.entryActivated(entry)
                    onSubmenuRequested: entry => itemLoader.pushSubmenu(entry)
                }
            }
        }
    }
}

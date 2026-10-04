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

    property var openMenu: (menu) => Qt.callLater(() => {
        loader.item?.openMenu(menu) // qmllint disable
    })

    signal entered
    signal entryActivated(var entry)
    signal exited

    edge: Qt.TopEdge
    alignment: Qt.AlignRight
    length: menuWidth
    depth: Math.min(loader.item?.contentHeight, maxHeight) // qmllint disable
    cornerRadius: Appearance.rounding.normal
    filletRadius: 40
    color: GlobalStates.drawerColors
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial

    Loader {
        id: loader

        anchors.fill: parent
        active: root.open
        sourceComponent: Item {
            id: itemLoader

            anchors.fill: parent

            property var pages: []

            readonly property var currentPage: stackLayout.currentIndex >= 0 && stackLayout.currentIndex < pages.length ? pages[stackLayout.currentIndex] : null
            readonly property real contentHeight: currentPage ? currentPage.contentHeight : 0

            function openMenu(handle: var): void {
                const page = pageAt(0);
                if (!page) {
                    createPage(handle, "");
                    return;
                }
                for (let index = 0; index < pages.length; index++)
                    pages[index].handle = index === 0 ? handle : null;
                page.title = "";
                page.highlightedEntry = null;
                stackLayout.currentIndex = 0;
            }

            function pushSubmenu(entry: var): void {
                if (!entry || !entry.hasChildren)
                    return;
                const parentPage = pageAt(stackLayout.currentIndex);
                if (parentPage && parentPage.handle === entry) {
                    popSubmenu();
                    return;
                }
                const level = stackLayout.currentIndex + 1;
                const page = pageAt(level);
                if (page) {
                    page.handle = entry;
                    page.title = entry.text ?? "";
                } else {
                    createPage(entry, entry.text ?? "");
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
                return level >= 0 && level < pages.length ? pages[level] : null;
            }

            function createPage(handle: var, pageTitle: string): void {
                const page = pageComponent.createObject(stackLayout, {
                    handle: handle,
                    level: pages.length,
                    title: pageTitle
                });
                if (!page)
                    return;
                pages = pages.concat(page);
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
                    onEntered: root.entered()
                    onExited: root.exited()
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Core.Configs

Scope {
    id: root

    required property Item      container
    required property Flickable target

    property int                pendingIndex: -1
    property string             pendingTitle: ""
    property var                pendingView: null

    function                    clearPending(): void {
        settleTimer.stop();
        root.pendingIndex = -1;
        root.pendingTitle = "";
        root.pendingView  = null;
    }

    function                    findCard(item, cardTitle) {
        if (item.title === cardTitle)
            return item;

        for (let i = 0; i < item.children.length; i++) {
            const found = findCard(item.children[i], cardTitle);
            if (found)
                return found;
        }
        return null;
    }

    function                    refreshPending() {
        if (pendingTitle !== "")
            scrollToItem(findCard(container, pendingTitle));
        else if (pendingView)
            scrollToItem(pendingItem(pendingView, pendingIndex));
        else
            return;

        settleTimer.restart();
    }

    // Repeater exposes itemAt(), ListView exposes itemAtIndex(); probing the
    // view keeps callers from having to care which one they handed over.

    function                    pendingItem(view, index) {
        if (index < 0)
            return null;
        if (typeof view.itemAt === "function")
            return view.itemAt(index);
        if (typeof view.itemAtIndex === "function")
            return view.itemAtIndex(index);
        return null;
    }

    // The page layout may still be settling right after a page switch, or a
    // freshly created row may still report zero height, so the scroll target
    // is re-applied on every contentHeight change until that stays quiet,
    // keeping the target pinned below the top margin.

    function                    reveal(cardTitle: string): bool {
        const card = findCard(container, cardTitle);

        if (!card || !card.visible)
            return false;

        pendingTitle = cardTitle;
        pendingView  = null;
        scrollToItem(card);

        if (card.flash)
            card.flash();

        settleTimer.restart();
        return true;
    }

    function                    revealItem(view, index): void {
        if (!view || index < 0)
            return;

        pendingTitle = "";
        pendingView  = view;
        pendingIndex = index;
        refreshPending();
    }

    function                    scrollToBottom(): void {
        root.clearPending();
        scrollAnim.to = Math.max(0, root.target.contentHeight - root.target.height);
        scrollAnim.restart();
    }

    function                    scrollToItem(item) {
        if (!item || !item.visible)
            return;

        const y       = item.mapToItem(target.contentItem, 0, 0).y - Appearance.margin.large;
        const maxY    = Math.max(0, target.contentHeight - target.height);

        scrollAnim.to = Math.max(0, Math.min(y, maxY));
        scrollAnim.restart();
    }

    function                    scrollToTop(): void {
        root.clearPending();
        scrollAnim.to = 0;
        scrollAnim.restart();
    }

    Connections {

        function onContentHeightChanged() {
            root.refreshPending();
        }

        target: root.target
    }

    Timer {
        id: settleTimer

        interval: 120
        onTriggered: {
            root.pendingIndex = -1;
            root.pendingTitle = "";
            root.pendingView  = null;
        }
    }

    NumberAnimation {
        id: scrollAnim

        duration: 350
        easing.type: Easing.OutCubic
        property: "contentY"
        target: root.target
    }
}

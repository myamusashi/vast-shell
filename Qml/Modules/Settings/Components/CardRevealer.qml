pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Core.Configs

Scope {
    id: root

    required property Item container
    property string pendingTitle: ""
    required property Flickable target

    function findCard(item, cardTitle) {
        if (item.title === cardTitle)
            return item;

        for (let i = 0; i < item.children.length; i++) {
            const found = findCard(item.children[i], cardTitle);
            if (found)
                return found;
        }
        return null;
    }
    function refreshPending() {
        if (pendingTitle === "")
            return;

        const card = findCard(container, pendingTitle);

        if (card && card.visible)
            scrollToCard(card);
        settleTimer.restart();
    }

    // The page layout may still be settling right after a page switch, so
    // the scroll target is re-applied on every contentHeight change until
    // it stays quiet, keeping the card pinned below the top margin.
    function reveal(cardTitle: string): bool {
        const card = findCard(container, cardTitle);

        if (!card || !card.visible)
            return false;

        pendingTitle = cardTitle;
        scrollToCard(card);

        if (card.flash)
            card.flash();

        settleTimer.restart();
        return true;
    }
    function scrollToCard(card) {
        const y = card.mapToItem(target.contentItem).y - Appearance.margin.large;

        scrollAnim.to = Math.max(0, Math.min(y, target.contentHeight - target.height));
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

        onTriggered: root.pendingTitle = ""
    }
    NumberAnimation {
        id: scrollAnim

        duration: 350
        easing.type: Easing.OutCubic
        property: "contentY"
        target: root.target
    }
}

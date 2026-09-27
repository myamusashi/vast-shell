pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    property Item scope: null
    property Item defaultItem: null

    function focusables() {
        const list = [];
        collect(scope, list);
        list.sort((a, b) => {
            const ap = a.mapToItem(scope, 0, 0);
            const bp = b.mapToItem(scope, 0, 0);
            if (ap.y !== bp.y)
                return ap.y - bp.y;
            return ap.x - bp.x;
        });
        return list;
    }

    function collect(item, out) {
        walk(item, out, []);
    }

    function walk(item, out, seen) {
        if (item === null || item === undefined || seen.indexOf(item) !== -1)
            return;
        seen.push(item);

        if (typeof item.keyboardFocusable === "boolean" && item.keyboardFocusable === true && item.enabled !== false && item.visible !== false)
            out.push(item);

        if (item.contentItem !== undefined && item.contentItem !== null && item.contentItem !== item) {
            walk(item.contentItem, out, seen);
            return;
        }

        walkList(item.children, out, seen);
        walkList(item.data, out, seen);
    }

    function walkList(list, out, seen) {
        if (list === null || list === undefined)
            return;
        for (let i = 0; i < list.length; ++i)
            walk(list[i], out, seen);
    }

    function isFocused(item) {
        if (!item)
            return false;
        if (item.activeFocus)
            return true;
        const winItem = item.window ? item.window.activeFocusItem : null;
        return winItem !== null && item.isAncestorOf(winItem);
    }

    function move(delta) {
        const list = focusables();
        if (list.length === 0)
            return;

        let index = list.findIndex(i => isFocused(i));
        if (index < 0)
            index = delta > 0 ? -1 : 0;

        const target = ((index + delta) % list.length + list.length) % list.length;
        activate(list[target]);
    }

    function next() {
        move(1);
    }

    function previous() {
        move(-1);
    }

    function activate(item) {
        if (typeof item.requestKeyboardFocus === "function")
            item.requestKeyboardFocus();
        else
            item.forceActiveFocus();
    }

    // Always moves focus: defaultItem when it is part of the scope,
    // otherwise the first focusable. Re-runnable on purpose, so a caller
    // can pull focus back after a popup or another item took it. Making
    // this conditional on nothing being focused would silently turn
    // every later call into a no-op.
    function firstFocus() {
        const list = focusables();
        if (list.length === 0)
            return;
        if (defaultItem !== null && defaultItem !== undefined && list.indexOf(defaultItem) >= 0)
            activate(defaultItem);
        else
            activate(list[0]);
    }
}

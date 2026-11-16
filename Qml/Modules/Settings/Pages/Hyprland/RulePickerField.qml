pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Components.Base
import qs.Components.Menu

Item {
    id: root

    readonly property var filteredItems: {
        const query = textField.text.trim().toLowerCase();
        if (query === "")
            return root.items;
        return root.items.filter(entry => {
            const label  = String(entry.text ?? "").toLowerCase();
            const search = String(entry.searchText ?? "").toLowerCase();
            return label.includes(query) || search.includes(query);
        });
    }

    property var          items: []
    property string       placeholderText: ""
    property bool         showScrollBar: false

    signal                itemActivated(var item)

    function              activateItem(entry: var): void {
        if (!entry)
            return;
        dropdownMenu.close();
        textField.text = "";
        root.itemActivated(entry.item);
    }

    function              openIfAvailable(): void {
        if (root.filteredItems.length > 0) {
            dropdownMenu.open();
            dropdownMenu.resolvePlacement();
        } else {
            dropdownMenu.close();
        }
    }

    implicitHeight: textField.implicitHeight
    implicitWidth: 260
    onFilteredItemsChanged: {
        if (textField.activeFocus)
            root.openIfAvailable();
        else if (dropdownMenu.opened)
            dropdownMenu.resolvePlacement();
    }

    MaterialTextField {
        id: textField

        anchors.fill: parent
        placeholderText: root.placeholderText
        trailingIcon.name: dropdownMenu.opened ? "keyboard_arrow_up" : "keyboard_arrow_down"
        Keys.onEscapePressed: event => {
            if (dropdownMenu.opened) {
                dropdownMenu.close();
                event.accepted = true;
            }
        }
        onAccepted: {
            if (root.filteredItems.length > 0)
                root.activateItem(root.filteredItems[0]);
        }
        onActiveFocusChanged: {
            if (activeFocus)
                root.openIfAvailable();
        }
        onTextEdited: root.openIfAvailable()
        onTrailingIconClicked: {
            if (dropdownMenu.opened) {
                dropdownMenu.close();
            } else {
                textField.forceActiveFocus();
                root.openIfAvailable();
            }
        }
    }

    DropdownMenu {
        id: dropdownMenu

        anchorItem: textField
        closePolicy: Popup.CloseOnPressOutsideParent | Popup.CloseOnEscape
        focus: false
        maxWidth: textField.width
        model: root.filteredItems
        popupParent: root
        showScrollBar: root.showScrollBar
        textRole: "text"
        onActivated: index => {
            if (index >= 0 && index < root.filteredItems.length)
                root.activateItem(root.filteredItems[index]);
        }
    }
}

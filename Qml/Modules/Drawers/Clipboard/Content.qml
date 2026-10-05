pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Clipboard

import qs.Core.Configs
import qs.Core.States
import qs.Services

ColumnLayout {
    id: root

    readonly property int currentId: {
        if (!entryGrid || !entryGrid.entryList || entryGrid.entryList.currentIndex < 0 || !entryGrid.entryList.currentItem)
            return -1;
        return entryGrid.entryList.currentItem.entryId; // qmllint disable
    }
    readonly property Item defaultFocusItem: Configs.clipboard.enableVimKeybinds ? root : searchBar.searchField
    property alias entryList: entryGrid.entryList
    property alias searchField: searchBar.searchField
    required property var uiState

    function focusDefault(): void {
        if (defaultFocusItem)
            defaultFocusItem.forceActiveFocus();
    }
    function handleKey(event: var): void {
        if (!entryGrid || !entryGrid.entryList)
            return;

        if (searchBar.searchField.isFocused) {
            if (!searchBar.searchField.hasSelection && event.key === Qt.Key_Escape) {
                root.forceActiveFocus();
                event.accepted = true;
                return;
            }
            const navKeys = [Qt.Key_Up, Qt.Key_Down, Qt.Key_Left, Qt.Key_Right, Qt.Key_Tab];
            if (navKeys.indexOf(event.key) === -1)
                return;
        }

        const vim = Configs.clipboard.enableVimKeybinds;
        const item = entryGrid.entryList.currentItem;

        switch (event.key) {
        case Qt.Key_Slash:
            if (vim) {
                searchBar.searchField.requestKeyboardFocus();
                event.accepted = true;
            }
            break;
        case Qt.Key_Escape:
            if (vim && uiState.visualActive) {
                uiState.visualActive = false;
                event.accepted = true;
            }
            break;
        case Qt.Key_V:
            if (vim) {
                uiState.visualActive = !uiState.visualActive;
                if (uiState.visualActive)
                    uiState.visualAnchor = entryGrid.entryList.currentIndex;
                event.accepted = true;
            }
            break;
        case Qt.Key_J:
            if (vim) {
                entryGrid.entryList.moveCurrentIndexDown();
                event.accepted = true;
            }
            break;
        case Qt.Key_K:
            if (vim) {
                entryGrid.entryList.moveCurrentIndexUp();
                event.accepted = true;
            }
            break;
        case Qt.Key_H:
            if (vim) {
                entryGrid.entryList.moveCurrentIndexLeft();
                event.accepted = true;
            }
            break;
        case Qt.Key_L:
            if (vim) {
                entryGrid.entryList.moveCurrentIndexRight();
                event.accepted = true;
            }
            break;
        case Qt.Key_Y:
            if (vim) {
                if (uiState.visualActive) {
                    const ids = entryGrid.entryList.visualSelectedIds();
                    const copied = ids.length > 0 && ClipboardManager.copySelection(ids);
                    if (copied) {
                        const n = ids.length === 1 ? qsTr("entry") : qsTr("entries");
                        ToastService.show(qsTr("Copied %1 %2").arg(ids.length).arg(n), qsTr("Clipboard"), "edit-paste");
                        if (!Configs.clipboard.keepOpenAfterCopy)
                            GlobalStates.isClipboardOpen = false;
                    }
                    uiState.visualActive = false;
                } else if (currentId >= 0) {
                    ClipboardManager.copyToClipboard(currentId);
                    if (!Configs.clipboard.keepOpenAfterCopy)
                        GlobalStates.isClipboardOpen = false;
                }
                event.accepted = true;
            }
            break;
        case Qt.Key_D:
            if (vim) {
                if (uiState.visualActive)
                    uiState.requestDelete(entryGrid.entryList.visualSelectedIds());
                else if (currentId >= 0 && item && !item.pinned) // qmllint disable
                    uiState.requestDelete([currentId]);
                event.accepted = true;
            }
            break;
        case Qt.Key_P:
            if (vim) {
                if (currentId >= 0 && item)
                    ClipboardManager.pin(currentId, !item.pinned); // qmllint disable
                event.accepted = true;
            } else if ((event.modifiers & Qt.ControlModifier) && !vim) {
                if (currentId >= 0 && item)
                    ClipboardManager.pin(currentId, !item.pinned); // qmllint disable
                event.accepted = true;
            }
            break;
        case Qt.Key_Q:
            GlobalStates.isClipboardOpen = false;
            event.accepted = true;
            break;
        case Qt.Key_Up:
            entryGrid.entryList.moveCurrentIndexUp();
            event.accepted = true;
            break;
        case Qt.Key_Down:
            entryGrid.entryList.moveCurrentIndexDown();
            event.accepted = true;
            break;
        case Qt.Key_Left:
            entryGrid.entryList.moveCurrentIndexLeft();
            event.accepted = true;
            break;
        case Qt.Key_Right:
            entryGrid.entryList.moveCurrentIndexRight();
            event.accepted = true;
            break;
        case Qt.Key_T:
            if (event.modifiers & Qt.ControlModifier) {
                Configs.clipboard.enablePreview = !Configs.clipboard.enablePreview;
                event.accepted = true;
            }
            break;
        case Qt.Key_Delete:
            if (!vim) {
                if (currentId >= 0 && item && !item.pinned) // qmllint disable
                    uiState.requestDelete([currentId]);
                event.accepted = true;
            }
            break;
        case Qt.Key_Tab:
            uiState.previewFocused = true;
            event.accepted = true;
            break;
        default:
            break;
        }
    }
    function restoreFocus(): void {
        focusRestore.attempts = 0;
        focusRestore.restart();
    }

    focus: true
    spacing: 0

    Keys.onPressed: event => handleKey(event)

    Timer {
        id: focusRestore

        property int attempts: 0

        interval: 30
        repeat: true

        onTriggered: {
            root.focusDefault();
            if (root.defaultFocusItem.activeFocus || ++focusRestore.attempts >= 10)
                focusRestore.running = false;
        }
    }
    Connections {
        function onDeleteConfirmed(ids: var): void {
            const removed = ClipboardManager.removeMany(ids);
            if (removed > 0) {
                const n = removed === 1 ? qsTr("entry") : qsTr("entries");
                ToastService.show(qsTr("Deleted %1 %2").arg(removed).arg(n), qsTr("Clipboard"), "edit-delete");
            }

            root.uiState.visualActive = false;
            entryGrid.entryList.currentIndex = Math.min(entryGrid.entryList.currentIndex, entryGrid.entryList.count - 1);
        }
        function onIsDeletePendingChanged() {
            if (root.uiState.isDeletePending || !GlobalStates.isClipboardOpen)
                return;
            root.restoreFocus();
        }

        target: root.uiState
    }
    SearchBar {
        id: searchBar

        Layout.fillWidth: true
        currentId: root.currentId
        entryList: entryGrid.entryList
        uiState: root.uiState

        onKeyPressed: event => root.handleKey(event)
    }
    RowLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        EntryGrid {
            id: entryGrid

            Layout.fillHeight: true
            Layout.preferredWidth: root.uiState.listWidth
            searchText: searchBar.searchField.text
            uiState: root.uiState
        }
        Loader {
            id: previewLoader

            Layout.fillHeight: true
            Layout.fillWidth: true
            active: Configs.clipboard.enablePreview
            visible: active

            sourceComponent: RowLayout {
                anchors.fill: parent
                spacing: Appearance.spacing.small

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
                }
                Preview {
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.uiState.previewWidth
                    entryId: root.currentId

                    onCopyRequested: id => ClipboardManager.copyToClipboard(id)
                    onPinToggled: (id, pinned) => ClipboardManager.pin(id, pinned)
                }
            }
        }
    }
}

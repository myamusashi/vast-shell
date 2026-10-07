pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Vast.Clipboard

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Singleton {
    property alias uiState: uiState

    Binding {
        property: "activeWindow"
        target: ClipboardManager
        value: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.appId : ""
    }

    IpcHandler {
        function clear(): bool {
            return ClipboardManager.clearAll();
        }
        function list(): string {
            return JSON.stringify(ClipboardManager.model.entries());
        }
        function remove(id: int): void {
            ClipboardManager.remove(id);
        }
        function search(query: string): void {
            ClipboardManager.model.setFilter(query);
        }
        function status(): string {
            return JSON.stringify({
                enabled: ClipboardManager.enabled,
                count: ClipboardManager.model.count,
                maxEntries: ClipboardManager.maxEntries
            });
        }

        target: "clipboardHistory"
    }

    QtObject {
        id: uiState

        readonly property bool isDeletePending: pendingDeleteIds.length > 0
        readonly property int  listWidth: Configs.clipboard.width
        readonly property int  previewWidth: 400

        property var           pendingDeleteIds: []
        property bool          previewFocused: false
        property bool          visualActive: false
        property int           visualAnchor: 0

        signal                 deleteConfirmed(var ids)

        function               cancelDelete(): void {
            pendingDeleteIds = [];
        }
        function               confirmDelete(): void {
            const ids        = pendingDeleteIds;
            pendingDeleteIds = [];
            if (ids.length > 0)
                deleteConfirmed(ids);
        }
        function               requestDelete(ids: var): void {
            if (ids.length === 0)
                return;
            pendingDeleteIds = ids;
        }
    }

    Connections {
        function onIsClipboardOpenChanged() {
            if (GlobalStates.isClipboardOpen)
                return;

            uiState.visualActive = false;
            ClipboardManager.model.setFilter("");
            uiState.cancelDelete();
        }

        target: GlobalStates
    }

    FileView {
        path: `${Paths.cacheDir}/clipboard.db`
        watchChanges: false
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                ToastService.show(qsTr("Clipboard database not found, created it"), qsTr("Clipboard"), "edit-paste");
                ClipboardManager.initialize(`${Paths.cacheDir}/clipboard.db`);
            }
        }
        onLoaded: ClipboardManager.initialize(`${Paths.cacheDir}/clipboard.db`)
    }
}

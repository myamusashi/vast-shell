pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Dialog

WrapperRectangle {
    id: root

    signal closeRequested

    anchors.centerIn: parent
    clip: true
    color: GlobalStates.drawerColors
    implicitHeight: GlobalStates.isClipboardOpen ? Configs.clipboard.height : 0
    implicitWidth: ClipboardServices.uiState.listWidth + (Configs.clipboard.enablePreview ? (ClipboardServices.uiState.previewWidth + Appearance.spacing.small * 2) : 0)
    radius: Appearance.rounding.normal
    visible: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) // qmllint disable
    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        active: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && GlobalStates.isClipboardOpen // qmllint disable
        asynchronous: true
        sourceComponent: FocusCage {
            active: GlobalStates.isClipboardOpen
            anchors.fill: parent
            defaultFocus: content.defaultFocusItem

            Content {
                id: content

                anchors.fill: parent
                uiState: ClipboardServices.uiState
            }
        }
    }

    ConfirmDialog {
        id: deleteConfirmation

        active: ClipboardServices.uiState.isDeletePending
        bodyText: {
            const count = ClipboardServices.uiState.pendingDeleteIds.length;
            if (count <= 1)
                return qsTr("Delete this entry? This cannot be undone.");
            return qsTr("Delete %1 entries? This cannot be undone.").arg(count);
        }
        cancelText: qsTr("Cancel")
        confirmText: qsTr("Delete")
        title: qsTr("Clipboard")
        onAccepted: ClipboardServices.uiState.confirmDelete()
        onRejected: ClipboardServices.uiState.cancelDelete()
    }
}

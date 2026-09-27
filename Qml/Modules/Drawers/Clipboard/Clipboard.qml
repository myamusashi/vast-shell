pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.States
import qs.Services
import qs.Components.Base
import qs.Components.Dialog

WrapperRectangle {
    id: root

    anchors.centerIn: parent

    signal closeRequested

    implicitWidth: ClipboardServices.uiState.listWidth + (Configs.clipboard.enablePreview ? (ClipboardServices.uiState.previewWidth + Appearance.spacing.small * 2) : 0)
    implicitHeight: GlobalStates.isClipboardOpen ? Configs.clipboard.height : 0
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name // qmllint disable
    radius: Appearance.rounding.normal
    color: Colours.m3Colors.m3SurfaceContainerLow
    clip: true

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isClipboardOpen // qmllint disable
        asynchronous: true
        sourceComponent: FocusCage {
            active: GlobalStates.isClipboardOpen
            defaultFocus: content.defaultFocusItem
            anchors.fill: parent

            Content {
                id: content

                anchors.fill: parent
                uiState: ClipboardServices.uiState
            }
        }
    }

    ConfirmDialog {
        id: deleteConfirmation

        title: qsTr("Clipboard")
        bodyText: {
            const count = ClipboardServices.uiState.pendingDeleteIds.length;
            if (count <= 1)
                return qsTr("Delete this entry? This cannot be undone.");
            return qsTr("Delete %1 entries? This cannot be undone.").arg(count);
        }
        confirmText: qsTr("Delete")
        cancelText: qsTr("Cancel")
        active: ClipboardServices.uiState.isDeletePending

        onAccepted: ClipboardServices.uiState.confirmDelete()
        onRejected: ClipboardServices.uiState.cancelDelete()
    }
}

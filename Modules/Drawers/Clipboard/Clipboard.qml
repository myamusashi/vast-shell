pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Vast

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base

WrapperRectangle {
    id: root

    anchors.centerIn: parent

    readonly property int currentId: {
        if (entryList.currentIndex < 0 || !entryList.currentItem)
            return -1;
        return entryList.currentItem.entryId;
    }

    signal closeRequested

    implicitWidth: d.listWidth + (Configs.clipboard.enablePreview ? (d.previewWidth + Appearance.spacing.small * 2) : 0)
    implicitHeight: GlobalStates.isClipboardOpen ? 520 : 0
    radius: Appearance.rounding.normal
    color: Colours.m3Colors.m3SurfaceContainerLow
    clip: true

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Binding {
        target: ClipboardManager
        property: "activeWindow"
        value: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.appId : ""
    }

    QtObject {
        id: d

        readonly property int listWidth: 320
        readonly property int previewWidth: 400

        property bool previewFocused: false
    }

    FileView {
        path: `${Paths.cacheDir}/clipboard.db`
        watchChanges: false
        onLoaded: ClipboardManager.initialize(`${Paths.cacheDir}/clipboard.db`)
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                ToastService.show(qsTr("Clipboard database not found, created it"), qsTr("Clipboard"), "edit-paste");
                ClipboardManager.initialize(`${Paths.cacheDir}/clipboard.db`);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Appearance.margin.large
                    rightMargin: Appearance.margin.large
                    topMargin: Appearance.margin.smaller
                    bottomMargin: Appearance.margin.smaller
                }
                spacing: Appearance.spacing.smaller

                Icon {
                    icon: "search"
                    font.pixelSize: Appearance.fonts.size.larger
                    color: searchField.activeFocus ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant

                    Behavior on color {
                        CAnim {}
                    }
                }

                StyledTextInput {
                    id: searchField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 35

                    placeHolderText: qsTr("Search clipboard…")
                    onTextChanged: {
                        ClipboardManager.search(text);
                        if (text.length === 0)
                            ClipboardManager.search("");
                    }
                    toggleButtonVisible: false

                    onAccepted: {
                        if (root.currentId >= 0)
                            ClipboardManager.copyToClipboard(root.currentId);
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            GlobalStates.isClipboardOpen = false;
                            event.accepted = true;
                        }

                        if (event.key === Qt.Key_Up) {
                            entryList.decrementCurrentIndex();
                            event.accepted = true;
                        }

                        if (event.key === Qt.Key_Down) {
                            entryList.incrementCurrentIndex();
                            event.accepted = true;
                        }

                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_T) {
                            Configs.clipboard.enablePreview = !Configs.clipboard.enablePreview;
                            event.accepted = true;
                            return;
                        }

                        if (event.key === Qt.Key_Delete) {
                            const item = entryList.currentItem;
                            if (root.currentId >= 0 && item && !item.pinned)
                                ClipboardManager.remove(root.currentId);
                            event.accepted = true;
                        }

                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) {
                            const item = entryList.currentItem;
                            if (root.currentId >= 0 && item)
                                ClipboardManager.pin(root.currentId, !item.pinned);
                            event.accepted = true;
                            return;
                        }

                        if (event.key === Qt.Key_Tab) {
                            d.previewFocused = true;
                            event.accepted = true;
                        }
                    }
                }

                StyledText {
                    text: ClipboardManager.model.count
                    font.pixelSize: Appearance.fonts.size.small
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    visible: searchField.text.length === 0
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Appearance.spacing.small

            Item {
                Layout.preferredWidth: d.listWidth
                Layout.fillHeight: true

                ListView {
                    id: entryList

                    anchors {
                        fill: parent
                        topMargin: Appearance.margin.small
                        bottomMargin: Appearance.margin.small
                    }

                    clip: true
                    currentIndex: 0
                    model: ClipboardManager.model
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
					maximumFlickVelocity: 1000
					highlightMoveDuration: 200
					highlightMoveVelocity: -1
                    highlightFollowsCurrentItem: true
                    highlightRangeMode: ListView.ApplyRange
                    highlight: StyledRect {
                        color: Colours.m3Colors.m3SurfaceContainerHigh
                        width: entryList.width
                    }

                    rebound: Transition {
                        NAnim {
                            properties: "x,y"
                        }
                    }

                    add: Transition {
                        NAnim {
                            properties: "opacity,scale"
                            from: 0
                            to: 1
                        }
                    }

                    remove: Transition {
                        NAnim {
                            properties: "opacity,scale"
                            from: 1
                            to: 0
                        }
                    }

                    move: Transition {
                        NAnim {
                            property: "y"
                        }
                        NAnim {
                            properties: "opacity,scale"
                            to: 1
                        }
                    }

                    addDisplaced: Transition {
                        NAnim {
                            property: "y"
                            duration: Appearance.animations.durations.small
                        }
                        NAnim {
                            properties: "opacity,scale"
                            to: 1
                        }
                    }

                    displaced: Transition {
                        NAnim {
                            property: "y"
                        }
                        NAnim {
                            properties: "opacity,scale"
                            to: 1
                        }
                    }

                    delegate: ClipboardItemDelegate {
                        required property var modelData

                        entryId: modelData.entryId
                        type: modelData.type
                        preview: modelData.preview
                        timestamp: modelData.timestamp
                        pinned: modelData.pinned
                        sourceApp: modelData.sourceApp
                        isSelected: ListView.isCurrentItem
                        implicitWidth: ListView.view.width

                        onActivated: {
                            ClipboardManager.copyToClipboard(entryId);
                            GlobalStates.isClipboardOpen = false;
                        }
                        onPinToggled: (id, s) => ClipboardManager.pin(id, s)
                        onRemoveRequested: id => ClipboardManager.remove(id)
                    }

                    StyledText {
                        anchors.centerIn: parent
                        visible: entryList.count === 0
                        text: searchField.text.length > 0 ? qsTr("No results for ") + searchField.text : qsTr("Clipboard is empty")
                        font.pixelSize: Appearance.fonts.size.medium
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                }
            }

            Loader {
                id: previewLoader

                Layout.fillWidth: true
                Layout.fillHeight: true
                active: Configs.clipboard.enablePreview
                visible: active

                sourceComponent: RowLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.small

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
                    }

                    ClipboardPreview {
                        Layout.preferredWidth: d.previewWidth
                        Layout.fillHeight: true
                        entryId: root.currentId

                        onCopyRequested: id => {
                            ClipboardManager.copyToClipboard(id);
                            GlobalStates.isClipboardOpen = false;
                        }
                        onPinToggled: (id, pinned) => ClipboardManager.pin(id, pinned)
                    }
                }
            }
        }
    }
}

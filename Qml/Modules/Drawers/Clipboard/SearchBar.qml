pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Clipboard

import qs.Components.Effects
import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property int currentId
    required property var entryList
    property alias searchField: searchField
    required property var uiState

    signal keyPressed(var event)

    implicitHeight: 48

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
        height: 1
    }
    RowLayout {
        anchors.bottomMargin: Appearance.margin.smaller
        anchors.fill: parent
        anchors.leftMargin: Appearance.margin.large
        anchors.rightMargin: Appearance.margin.large
        anchors.topMargin: Appearance.margin.smaller
        spacing: Appearance.spacing.smaller

        Icon {
            id: searchIcon

            property color target: searchField.isFocused ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant

            font.pixelSize: Appearance.fonts.size.larger
            icon: "search"

            BlendColor {
                host: searchIcon
                target: searchIcon.target
            }
        }
        StyledTextInput {
            id: searchField

            Layout.fillWidth: true
            Layout.preferredHeight: 35
            autoFocus: !Configs.clipboard.enableVimKeybinds
            placeHolderText: qsTr("Search clipboard…")
            toggleButtonVisible: false

            onAccepted: {
                if (Configs.clipboard.enableVimKeybinds && !searchField.isFocused) {
                    return;
                }
                if (root.currentId >= 0) {
                    ClipboardManager.copyToClipboard(root.currentId);
                    if (!Configs.clipboard.keepOpenAfterCopy)
                        GlobalStates.isClipboardOpen = false;
                }
            }
            onKeyPressed: event => root.keyPressed(event)

            DebouncedValue {
                id: searchDebounce

                interval: 150
                value: searchField.text

                onDebouncedValueChanged: {
                    if (searchField.text.length === 0)
                        ClipboardManager.model.setFilter("");
                    else
                        ClipboardManager.model.setFilter(searchField.text);
                }
            }
        }
        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
            text: (root.entryList.currentPage + 1) + " / " + root.entryList.totalPages
            visible: root.entryList.totalPages > 0 && searchField.text.length === 0 && !root.uiState.visualActive
        }
        StyledText {
            color: Colours.m3Colors.m3Primary
            font.bold: true
            font.pixelSize: Appearance.fonts.size.small
            text: qsTr("VISUAL") + " " + root.entryList.visualSelectableCount
            visible: root.uiState.visualActive
        }
    }
}

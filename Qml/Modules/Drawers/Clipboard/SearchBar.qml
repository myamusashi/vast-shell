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
    required property var uiState

    property alias        searchField: searchField

    signal                keyPressed(var event)

    implicitHeight: 48

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Appearance.margin.large
            Layout.topMargin: Appearance.margin.smaller
            Layout.bottomMargin: Appearance.margin.smaller
            Layout.rightMargin: Appearance.margin.large
            spacing: Appearance.spacing.smaller

            Icon {
                id: searchIcon

                property color target: searchField.activeFocus ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant

                font.pixelSize: Appearance.fonts.size.larger
                icon: "search"

                BlendColor {
                    host: searchIcon
                    target: searchIcon.target
                }
            }

            MaterialTextField {
                id: searchField

                Layout.fillWidth: true
                placeholderText: qsTr("Search clipboard…")
                onAccepted: {
                    if (Configs.clipboard.enableVimKeybinds && !searchField.activeFocus) {
                        return;
                    }
                    if (root.currentId >= 0) {
                        ClipboardManager.copyToClipboard(root.currentId);
                        if (!Configs.clipboard.keepOpenAfterCopy)
                            GlobalStates.isClipboardOpen = false;
                    }
                }
                Keys.onPressed: event => root.keyPressed(event)
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

        Rectangle {
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Layout.preferredHeight: 1
            color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.6)
        }
    }

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

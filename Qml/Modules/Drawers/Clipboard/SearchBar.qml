pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Clipboard

import qs.Components.Base
import qs.Components.Tooltip
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

                color: searchField.activeFocus ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.larger
                icon: "search"
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

            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Appearance.spacing.small

                StyledRect {
                    id: filterIndicator

                    readonly property string filterIcon: {
                        switch (ClipboardManager.model.typeFilter) {
                        case ClipboardModel.Text:
                            return "notes";
                        case ClipboardModel.Html:
                            return "code";
                        case ClipboardModel.LinksAndFiles:
                            return "link";
                        case ClipboardModel.Image:
                            return "image";
                        default:
                            return "filter_list";
                        }
                    }
                    readonly property string filterLabel: {
                        switch (ClipboardManager.model.typeFilter) {
                        case ClipboardModel.Text:
                            return qsTr("Text");
                        case ClipboardModel.Html:
                            return qsTr("HTML");
                        case ClipboardModel.LinksAndFiles:
                            return qsTr("Links & Files");
                        case ClipboardModel.Image:
                            return qsTr("Image");
                        default:
                            return qsTr("All");
                        }
                    }
                    readonly property bool   isFiltered: ClipboardManager.model.typeFilter !== ClipboardModel.All

                    Layout.alignment: Qt.AlignCenter
                    color: isFiltered ? Colours.m3Colors.m3SecondaryContainer : Colours.m3Colors.m3SurfaceContainerHigh
                    implicitHeight: 26
                    implicitWidth: filterIndicatorRow.implicitWidth + Appearance.padding.normal * 2
                    radius: Appearance.rounding.small

                    RowLayout {
                        id: filterIndicatorRow

                        anchors.centerIn: parent
                        spacing: Appearance.spacing.smaller

                        Icon {
                            color: filterIndicator.isFiltered ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.small
                            icon: filterIndicator.filterIcon
                        }

                        StyledText {
                            color: filterIndicator.isFiltered ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.small
                            font.weight: filterIndicator.isFiltered ? Font.Medium : Font.Normal
                            text: filterIndicator.filterLabel
                        }
                    }

                    TapHandler {
                        onTapped: {
                            root.uiState.visualActive = false;
                            ClipboardManager.model.cycleTypeFilter();
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    Tooltip {
                        anchorItem: filterIndicator
                        text: qsTr("Filter: %1 (Click or press Tab to cycle)").arg(filterIndicator.filterLabel)
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignCenter
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small
                    text: (root.entryList.currentPage + 1) + " / " + root.entryList.totalPages
                    visible: root.entryList.totalPages > 0 && searchField.text.length === 0 && !root.uiState.visualActive
                }

                StyledText {
                    Layout.alignment: Qt.AlignCenter
                    color: Colours.m3Colors.m3Primary
                    font.bold: true
                    font.pixelSize: Appearance.fonts.size.small
                    text: qsTr("VISUAL") + " " + root.entryList.visualSelectableCount
                    visible: root.uiState.visualActive
                }
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

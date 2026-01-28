pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
    }

    property bool isWallpaperSwitcherOpen: GlobalStates.isWallpaperSwitcherOpen

    implicitWidth: parent.width * 0.6
    implicitHeight: GlobalStates.isWallpaperSwitcherOpen ? parent.height * 0.3 : 0
    visible: window.modelData.name === Hypr.focusedMonitor.name

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Corner {
        location: Qt.BottomRightCorner
        extensionSide: Qt.Horizontal
        radius: GlobalStates.isWallpaperSwitcherOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomLeftCorner
        extensionSide: Qt.Horizontal
        radius: GlobalStates.isWallpaperSwitcherOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    WrapperRectangle {
        anchors.fill: parent
        color: GlobalStates.drawerColors
        radius: 0
        topLeftRadius: Appearance.rounding.normal
        topRightRadius: Appearance.rounding.normal

        Loader {
            active: {
                if (GlobalStates.isWallpaperSwitcherOpen) {
                    if (window.modelData.name === Hypr.focusedMonitor.name)
                        return true;
                } else if (!GlobalStates.isWallpaperSwitcherOpen && root.implicitHeight === 0)
                    return false;
                else
                    return false;
            }
            asynchronous: true
            sourceComponent: ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.spacing.normal
                spacing: Appearance.spacing.normal

                focus: GlobalStates.isWallpaperSwitcherOpen
                onFocusChanged: {
                    if (GlobalStates.isWallpaperSwitcherOpen)
                        searchField.forceActiveFocus();
                }

                StyledTextField {
                    id: searchField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    placeholderText: qsTr("Search wallpapers")
                    text: WallpaperFileModels.searchQuery
                    focus: true

                    onTextChanged: {
                        root.searchQuery = text;
                        searchDebounceTimer.restart();

                        if (wallpaperPath.count > 0)
                            wallpaperPath.currentIndex = 0;
                    }

                    Keys.onDownPressed: wallpaperPath.focus = true
                    Keys.onEscapePressed: GlobalStates.isWallpaperSwitcherOpen = false
                    Keys.onTabPressed: wallpaperPath.forceActiveFocus()
                }

                Timer {
                    id: searchDebounceTimer

                    interval: 300
                    repeat: false
                    onTriggered: WallpaperFileModels.debouncedSearchQuery = WallpaperFileModels.searchQuery
                }

                PathView {
                    id: wallpaperPath

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: ScriptModel {
                        values: [...WallpaperFileModels.filteredWallpaperList]
                    }
                    pathItemCount: 5
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5

                    clip: true
                    cacheItemCount: 7

                    Component.onCompleted: {
                        const idx = WallpaperFileModels.wallpaperList.indexOf(Paths.currentWallpaper);
                        currentIndex = idx !== -1 ? idx : 0;
                    }

                    onModelChanged: {
                        if (WallpaperFileModels.debouncedSearchQuery === "" && currentIndex >= 0) {
                            Qt.callLater(() => {
                                if (currentIndex < count)
                                    currentIndex = currentIndex;
                            });
                        }
                    }

                    path: Path {
                        startX: 0
                        startY: wallpaperPath.height / 2

                        PathLine {
                            x: wallpaperPath.width
                            y: wallpaperPath.height / 2
                        }
                    }

                    delegate: Item {
                        id: delegateItem

                        required property var modelData
                        required property int index

                        implicitWidth: wallpaperPath.width / 5 - 16
                        implicitHeight: wallpaperPath.height - 16
                        scale: PathView.isCurrentItem ? 1.1 : 0.85
                        z: PathView.isCurrentItem ? 100 : 1
                        opacity: PathView.isCurrentItem ? 1.0 : 0.6

                        Behavior on scale {
                            NAnim {}
                        }

                        Behavior on opacity {
                            NAnim {}
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 8
                            radius: Appearance.rounding.normal
                            color: "transparent"

                            Image {
                                anchors.fill: parent
                                source: "file://" + delegateItem.modelData
                                sourceSize: Qt.size(200, 200)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }

                            MArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    wallpaperPath.currentIndex = delegateItem.index;
                                    Quickshell.execDetached({
                                        "command": ["sh", "-c", `shell ipc call img set ${delegateItem.modelData}`]
                                    });
                                }
                            }
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            Quickshell.execDetached({
                                "command": ["sh", "-c", `shell ipc call img set ${WallpaperFileModels.filteredWallpaperList[currentIndex]}`]
                            });
                            event.accepted = true;
                        }
                        if (event.key === Qt.Key_Escape) {
                            GlobalStates.isWallpaperSwitcherOpen = false;
                            event.accepted = true;
                        }
                        if (event.key === Qt.Key_Tab) {
                            searchField.forceActiveFocus();
                            event.accepted = true;
                        }
                        if (event.key === Qt.Key_Left) {
                            decrementCurrentIndex();
                            event.accepted = true;
                        }
                        if (event.key === Qt.Key_Right) {
                            incrementCurrentIndex();
                            event.accepted = true;
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: wallpaperPath.count > 0 ? (wallpaperPath.currentIndex + 1) + " / " + wallpaperPath.count : "0 / 0"
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                }
            }
        }
    }
}

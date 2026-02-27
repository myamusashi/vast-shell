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
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name

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
                    if (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name)
                        return true;
                } else if (!GlobalStates.isWallpaperSwitcherOpen && root.implicitHeight === 0)
                    return false;
                else
                    return false;
            }
            asynchronous: false
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
                        WallpaperFileModels.searchQuery = text;
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

                    // Center card gets 2 "units", each side card gets 1 "unit"
                    // Total units = Configs.wallpaper.visibleWallpaper + 1 (center counts double)
                    readonly property real unitWidth: width / (Configs.wallpaper.visibleWallpaper + 1)

                    model: ScriptModel {
                        values: [...WallpaperFileModels.filteredWallpaperList]
                    }
                    pathItemCount: Configs.wallpaper.visibleWallpaper
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5
                    clip: true
                    cacheItemCount: Configs.wallpaper.visibleWallpaper + 2

                    Component.onCompleted: {
                        Qt.callLater(() => {
                            const idx = WallpaperFileModels.wallpaperList.indexOf(Paths.currentWallpaper);
                            currentIndex = idx !== -1 ? idx : 0;
                        });
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

                        readonly property bool isCurrent: PathView.isCurrentItem

                        // Center card = 2 units wide, side cards = 1 unit wide
                        implicitWidth: isCurrent ? wallpaperPath.unitWidth * 2 : wallpaperPath.unitWidth
                        implicitHeight: wallpaperPath.height

                        z: isCurrent ? 100 : 1
                        opacity: isCurrent ? 1.0 : 0.92

                        Behavior on implicitWidth {
                            NAnim {
                                duration: Appearance.animations.durations.normal
                                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                            }
                        }

                        Behavior on opacity {
                            NAnim {
                                duration: Appearance.animations.durations.normal
                                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                            }
                        }

                        ClippingRectangle {
                            id: cardRect

                            anchors.centerIn: parent

                            // Gap between cards scales with unit width so it looks proportional at any count
                            implicitWidth: parent.width - (delegateItem.isCurrent ? Math.max(20, wallpaperPath.unitWidth * 0.3) : Math.max(12, wallpaperPath.unitWidth * 0.2))
                            implicitHeight: parent.height

                            // Center: soft rect | Side: pill — pill radius needs card height not parent
                            radius: delegateItem.isCurrent ? Appearance.rounding.large ?? 24 : 20

                            color: "transparent"

                            Behavior on implicitWidth {
                                NAnim {
                                    duration: Appearance.animations.durations.normal
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }
                            Behavior on implicitHeight {
                                NAnim {
                                    duration: Appearance.animations.durations.normal
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }
                            Behavior on radius {
                                NAnim {
                                    duration: Appearance.animations.durations.normal
                                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                                }
                            }

                            Image {
                                anchors.fill: parent
                                source: "file://" + delegateItem.modelData
                                sourceSize: Qt.size(200, 200)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true

                                Elevation {
                                    anchors.fill: parent
                                    z: -1
                                    level: 3
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: cardRect.radius
                                color: Qt.rgba(0, 0, 0, delegateItem.isCurrent ? 0.0 : 0.22)

                                Behavior on color {
                                    CAnim {
                                        duration: Appearance.animations.durations.normal
                                    }
                                }
                            }

                            MArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (!delegateItem.isCurrent) {
                                        wallpaperPath.currentIndex = delegateItem.index;
                                    } else {
                                        Quickshell.execDetached({
                                            "command": ["sh", "-c", `shell ipc call img set ${delegateItem.modelData}`]
                                        });
                                    }
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

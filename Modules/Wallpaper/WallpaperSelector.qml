pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import qs.Configs
import qs.Services
import qs.Helpers
import qs.Components

Scope {
    id: scope

    property bool isWallpaperSwitcherOpen: false
    property string currentWallpaper: Paths.currentWallpaper
    property var wallpaperList: []
    property string searchQuery: ""
    property string debouncedSearchQuery: ""
    property bool triggerAnimation: false
    property bool shouldDestroy: false

    Timer {
        id: searchDebounceTimer

        interval: 300
        repeat: false
        onTriggered: scope.debouncedSearchQuery = scope.searchQuery
    }

    property var filteredWallpaperList: {
        if (debouncedSearchQuery === "")
            return wallpaperList;

        const query = debouncedSearchQuery.toLowerCase();
        return wallpaperList.filter(path => {
            const fileName = path.split('/').pop().toLowerCase();
            return fileName.includes(query);
        });
    }

    Process {
        id: listWallpaper

        workingDirectory: Paths.wallpaperDir
        command: ["sh", "-c", `find -L ${Paths.wallpaperDir} -type d -path */.* -prune -o -not -name .* -type f -print`]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const wallList = text.trim().split('\n').filter(path => path.length > 0);
                scope.wallpaperList = wallList;
            }
        }
    }

    onIsWallpaperSwitcherOpenChanged: {
        if (isWallpaperSwitcherOpen) {
            shouldDestroy = false;
            triggerAnimation = false;
            animationTriggerTimer.restart();
        } else {
            triggerAnimation = false;
            destroyTimer.restart();
        }
    }

    Timer {
        id: animationTriggerTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (scope.isWallpaperSwitcherOpen)
                scope.triggerAnimation = true;
        }
    }

    Timer {
        id: destroyTimer
        interval: Appearance.animations.durations.small + 50
        repeat: false
        onTriggered: scope.shouldDestroy = true
    }

    LazyLoader {
        id: lazyLoader

        loading: scope.isWallpaperSwitcherOpen
        activeAsync: scope.isWallpaperSwitcherOpen || !scope.shouldDestroy

        component: OuterShapeItem {
            id: root

            content: container
            needKeyboardFocus: scope.isWallpaperSwitcherOpen

            StyledRect {
                id: container

                implicitWidth: Hypr.focusedMonitor.width * 0.6
                implicitHeight: scope.triggerAnimation ? Hypr.focusedMonitor.height * 0.3 : 0
                color: Themes.m3Colors.m3Surface
                radius: 0
                topLeftRadius: Appearance.rounding.normal
                topRightRadius: Appearance.rounding.normal

                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }

                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.spacing.normal
                    spacing: Appearance.spacing.normal

                    StyledTextField {
                        id: searchField

                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        placeholderText: "Search wallpapers..."
                        text: scope.searchQuery
                        focus: true

                        onTextChanged: {
                            scope.searchQuery = text;
                            searchDebounceTimer.restart();

                            if (wallpaperPath.count > 0)
                                wallpaperPath.currentIndex = 0;
                        }

                        Keys.onDownPressed: wallpaperPath.focus = true
                        Keys.onEscapePressed: scope.isWallpaperSwitcherOpen = false
                    }

                    PathView {
                        id: wallpaperPath

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        model: scope.filteredWallpaperList
                        pathItemCount: 5
                        preferredHighlightBegin: 0.5
                        preferredHighlightEnd: 0.5

                        clip: true
                        cacheItemCount: 7

                        Component.onCompleted: {
                            const idx = scope.wallpaperList.indexOf(Paths.currentWallpaper);
                            currentIndex = idx !== -1 ? idx : 0;
                        }

                        onModelChanged: {
                            if (scope.debouncedSearchQuery === "" && currentIndex >= 0) {
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

                            width: wallpaperPath.width / 5 - 16
                            height: wallpaperPath.height - 16

                            required property var modelData
                            required property int index

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
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    smooth: true
									cache: false
                                }

                                MArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        wallpaperPath.currentIndex = delegateItem.index;
                                        Quickshell.execDetached({
                                            command: ["sh", "-c", `shell ipc call img set ${delegateItem.modelData}`]
                                        });
                                    }
                                }
                            }
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                Quickshell.execDetached({
                                    command: ["sh", "-c", `shell ipc call img set ${scope.filteredWallpaperList[currentIndex]}`]
                                });
                            }
                            if (event.key === Qt.Key_Escape)
                                scope.isWallpaperSwitcherOpen = false;
                            if (event.key === Qt.Key_Tab)
                                searchField.focus = true;
                            if (event.key === Qt.Key_Left)
                                decrementCurrentIndex();
                            if (event.key === Qt.Key_Right)
                                incrementCurrentIndex();
                        }
                    }

                    StyledLabel {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: Appearance.spacing.small
                        text: wallpaperPath.count > 0 ? (wallpaperPath.currentIndex + 1) + " / " + wallpaperPath.count : "0 / 0"
                        color: Themes.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.small
                    }
                }
            }
        }
    }

    Timer {
        id: cleanupTimer

        interval: 500
        repeat: false
        onTriggered: gc()
    }
}

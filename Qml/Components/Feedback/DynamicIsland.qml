pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Scope {
    LazyLoader {
        activeAsync: DynamicIslandService.hasContent || DynamicIslandService.closing

        component: PanelWindow {
            id: targetWindow

            readonly property real dotSize: 24

            // qmllint enable

            // qmllint disable
            function updateContentSize(): void {
                var item = overlayLoader.item ?? baseLoader.item;
                if (!item)
                    return;
                islandBox.contentWidth = Math.max(1, item.implicitWidth);
                islandBox.contentHeight = Math.max(1, item.implicitHeight);
                var radius = item["islandRadius"];
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:dynamicIsland"
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            // qmllint disable
            HyprlandWindow.visibleMask: Region {
                item: islandBox
            }
            mask: Region {
                item: islandBox
            }

            // qmllint enable

            Component.onCompleted: Qt.callLater(updateContentSize)

            anchors {
                bottom: true
                left: true
                right: true
                top: true
            }
            Connections {
                function onClosingChanged(): void {
                    if (DynamicIslandService.closing) {
                        islandBox.contentWidth = targetWindow.dotSize;
                        islandBox.contentHeight = targetWindow.dotSize;
                    }
                }
                function onCurrentChanged(): void {
                    if (DynamicIslandService.closing)
                        return;
                    Qt.callLater(targetWindow.updateContentSize);
                }
                function onOverlayChanged(): void {
                    if (DynamicIslandService.closing)
                        return;
                    Qt.callLater(targetWindow.updateContentSize);
                }

                target: DynamicIslandService
            }
            Connections {
                function onImplicitHeightChanged(): void {
                    if (DynamicIslandService.closing)
                        return;
                    targetWindow.updateContentSize();
                }
                function onImplicitWidthChanged(): void {
                    if (DynamicIslandService.closing)
                        return;
                    targetWindow.updateContentSize();
                }

                target: baseLoader.item
            }
            Connections {
                function onImplicitHeightChanged(): void {
                    if (DynamicIslandService.closing)
                        return;
                    targetWindow.updateContentSize();
                }
                function onImplicitWidthChanged(): void {
                    if (DynamicIslandService.closing)
                        return;
                    targetWindow.updateContentSize();
                }

                target: overlayLoader.item
            }
            Item {
                id: islandHost

                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: islandBox.contentHeight
                implicitWidth: islandBox.contentWidth
                y: {
                    if (DynamicIslandService.slidingUp)
                        return -targetWindow.dotSize - Configs.generals.outerBorderSize;
                    else
                        return Configs.generals.outerBorderSize + Configs.bar.barHeight + Appearance.spacing.small;
                }

                Behavior on y {
                    NAnim {
                        duration: DynamicIslandService.slideDuration
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                WrapperRectangle {
                    id: islandBox

                    property real contentHeight: targetWindow.dotSize
                    property real contentWidth: targetWindow.dotSize

                    clip: true
                    color: GlobalStates.drawerColors
                    implicitHeight: contentHeight
                    implicitWidth: contentWidth
                    opacity: DynamicIslandService.slidingUp ? 0 : (DynamicIslandService.hasContent ? 1 : 0)
                    radius: {
                        var item = overlayLoader.item ?? baseLoader.item; // qmllint disable
                        var r = item?.["islandRadius"]; // qmllint disable
                        return r === undefined ? Appearance.rounding.normal : r;
                    }

                    Behavior on implicitHeight {
                        SpringAnimation {
                            damping: 0.3
                            mass: 1
                            spring: 3
                        }
                    }
                    Behavior on implicitWidth {
                        SpringAnimation {
                            damping: 0.3
                            mass: 1
                            spring: 3
                        }
                    }
                    Behavior on opacity {
                        NAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }
                    Behavior on radius {
                        NAnim {
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                    }
                    Item {
                        Loader {
                            id: baseLoader

                            active: DynamicIslandService.current !== null
                            anchors.fill: parent
                            opacity: DynamicIslandService.overlay === null ? 1 : 0
                            sourceComponent: DynamicIslandService.current ? DynamicIslandService.current.content : null
                            visible: baseLoader.opacity > 0

                            Behavior on opacity {
                                NAnim {
                                    duration: Appearance.animations.durations.small
                                }
                            }

                            onItemChanged: Qt.callLater(targetWindow.updateContentSize)
                        }
                        Loader {
                            id: overlayLoader

                            active: DynamicIslandService.overlay !== null
                            anchors.fill: parent
                            sourceComponent: DynamicIslandService.overlay ? DynamicIslandService.overlay.content : null
                            visible: DynamicIslandService.overlay !== null

                            onItemChanged: Qt.callLater(targetWindow.updateContentSize)
                        }
                    }
                }
            }
        }
    }
}

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

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "shell:dynamicIsland"
            WlrLayershell.layer: WlrLayer.Overlay

            mask: Region {
                item: islandBox
            }

            // qmllint disable
            HyprlandWindow.visibleMask: Region {
                item: islandBox
            }
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
            // qmllint enable

            Component.onCompleted: Qt.callLater(updateContentSize)

            Connections {
                target: DynamicIslandService

                function onCurrentChanged(): void {
                    Qt.callLater(targetWindow.updateContentSize);
                }
                function onOverlayChanged(): void {
                    Qt.callLater(targetWindow.updateContentSize);
                }
            }

            Connections {
                target: baseLoader.item

                function onImplicitWidthChanged(): void {
                    targetWindow.updateContentSize();
                }
                function onImplicitHeightChanged(): void {
                    targetWindow.updateContentSize();
                }
            }

            Connections {
                target: overlayLoader.item

                function onImplicitWidthChanged(): void {
                    targetWindow.updateContentSize();
                }
                function onImplicitHeightChanged(): void {
                    targetWindow.updateContentSize();
                }
            }

            Item {
                id: islandHost

                anchors.horizontalCenter: parent.horizontalCenter

                y: {
                    if (DynamicIslandService.slidingUp)
                        return -targetWindow.dotSize - Configs.generals.outerBorderSize;
                    else
                        // else if (!GlobalStates.isBarOpen)
                        //     return Configs.generals.outerBorderSize + Appearance.spacing.small;
                        return Configs.generals.outerBorderSize + Configs.bar.barHeight + Appearance.spacing.small;
                }

                implicitWidth: islandBox.contentWidth
                implicitHeight: islandBox.contentHeight

                Behavior on y {
                    NAnim {
                        duration: DynamicIslandService.slideDuration
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                WrapperRectangle {
                    id: islandBox

                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                    }

                    property real contentWidth: targetWindow.dotSize
                    property real contentHeight: targetWindow.dotSize

                    implicitWidth: contentWidth
                    implicitHeight: contentHeight

                    opacity: DynamicIslandService.slidingUp ? 0 : (DynamicIslandService.hasContent ? 1 : 0)

                    radius: {
                        var item = overlayLoader.item ?? baseLoader.item; // qmllint disable
                        var r = item?.["islandRadius"]; // qmllint disable
                        return r === undefined ? Appearance.rounding.normal : r;
                    }
                    color: GlobalStates.drawerColors
                    clip: true

                    Behavior on implicitWidth {
                        SpringAnimation {
                            spring: 3
                            damping: 0.3
                            mass: 1
                        }
                    }
                    Behavior on implicitHeight {
                        SpringAnimation {
                            spring: 3
                            damping: 0.3
                            mass: 1
                        }
                    }
                    Behavior on radius {
                        NAnim {
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }
                    Behavior on opacity {
                        NAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }
                    Item {
                        Loader {
                            id: baseLoader

                            anchors.fill: parent
                            active: DynamicIslandService.current !== null
                            visible: baseLoader.opacity > 0
                            sourceComponent: DynamicIslandService.current ? DynamicIslandService.current.content : null
                            opacity: DynamicIslandService.overlay === null ? 1 : 0

                            Behavior on opacity {
                                NAnim {
                                    duration: Appearance.animations.durations.small
                                }
                            }

                            onItemChanged: Qt.callLater(targetWindow.updateContentSize)
                        }

                        Loader {
                            id: overlayLoader

                            anchors.fill: parent
                            active: DynamicIslandService.overlay !== null
                            visible: DynamicIslandService.overlay !== null
                            sourceComponent: DynamicIslandService.overlay ? DynamicIslandService.overlay.content : null
                            onItemChanged: Qt.callLater(targetWindow.updateContentSize)
                        }
                    }
                }
            }
        }
    }
}

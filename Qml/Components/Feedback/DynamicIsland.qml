pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Core.Configs
import qs.Services

LazyLoader {
    loading: true
    component: PanelWindow {
        id: targetWindow

        readonly property bool islandVisible: DynamicIslandService.hasContent || DynamicIslandService.closing

        // qmllint disable
        function               updateContentSize(): void {
            if (DynamicIslandService.closing)
                return;
            var item = overlayLoader.item ?? baseLoader.item;
            if (!item)
                return;
            var newWidth           = Math.max(1, Math.ceil(item.implicitWidth));
            var newHeight          = Math.max(1, Math.ceil(item.implicitHeight));
            islandBox.sizeAnimated = islandBox.measured;
            if (islandBox.measuredWidth !== newWidth)
                islandBox.measuredWidth = newWidth;
            if (islandBox.measuredHeight !== newHeight)
                islandBox.measuredHeight = newHeight;
            if (islandBox.contentWidth !== newWidth)
                islandBox.contentWidth = newWidth;
            if (islandBox.contentHeight !== newHeight)
                islandBox.contentHeight = newHeight;
            islandBox.measured = true;
        }
        // qmllint enable
        function               onClosingChanged(): void {
            if (DynamicIslandService.closing) {
                islandBox.contentWidth  = 0;
                islandBox.contentHeight = 0;
            }
        }

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shell:dynamicIsland"
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        // qmllint disable
        HyprlandWindow.visibleMask: Region {
            item: targetWindow.islandVisible ? islandBox : null
        }
        // qmllint enable
        mask: Region {
            item: targetWindow.islandVisible ? islandBox : null
        }
        Component.onCompleted: Qt.callLater(updateContentSize)

        Connections {
            function onClosingChanged(): void {
                if (DynamicIslandService.closing) {
                    islandBox.contentWidth  = 0;
                    islandBox.contentHeight = 0;
                }
            }
            function onCurrentChanged(): void {
                Qt.callLater(targetWindow.updateContentSize);
            }
            function onOverlayChanged(): void {
                Qt.callLater(targetWindow.updateContentSize);
            }

            target: DynamicIslandService
        }

        Connections {
            function onImplicitHeightChanged(): void {
                Qt.callLater(targetWindow.updateContentSize);
            }
            function onImplicitWidthChanged(): void {
                Qt.callLater(targetWindow.updateContentSize);
            }

            target: baseLoader.item
        }

        Connections {
            function onImplicitHeightChanged(): void {
                targetWindow.updateContentSize();
            }
            function onImplicitWidthChanged(): void {
                targetWindow.updateContentSize();
            }

            target: overlayLoader.item
        }

        Item {
            id: islandHost

            anchors.left: parent.left
            anchors.right: parent.right
            height: islandBox.height
            y: Configs.generals.outerBorderSize + Configs.bar.barHeight + Appearance.spacing.small

            ClippingRectangle {
                id: islandBox

                readonly property real maximumRadius: 32
                readonly property real targetRadius: {
                    var item            = overlayLoader.item ?? baseLoader.item; // qmllint disable
                    var requestedRadius = item?.["islandRadius"]; // qmllint disable
                    return requestedRadius === undefined ? maximumRadius : requestedRadius;
                }

                property real          animatedHeight: contentHeight
                property real          animatedWidth: contentWidth
                property real          contentHeight
                property real          contentWidth
                property bool          measured: false
                property real          measuredHeight
                property real          measuredWidth
                property bool          sizeAnimated: false

                antialiasing: true
                color: "black"
                opacity: DynamicIslandService.hasContent || DynamicIslandService.closing ? 1 : 0
                radius: Math.min(height / 2, targetRadius)
                implicitHeight: Math.round(animatedHeight)
                implicitWidth: Math.round(animatedWidth)
                x: Math.round((islandHost.width - width) / 2)
                Behavior on animatedHeight {
                    enabled: islandBox.sizeAnimated

                    SpringAnimation {
                        damping: 0.4
                        epsilon: 0.5
                        mass: 0.6
                        spring: 7
                    }
                }
                Behavior on animatedWidth {
                    enabled: islandBox.sizeAnimated

                    SpringAnimation {
                        spring: 7.5
                        damping: 0.55
                        mass: 0.7
                        epsilon: 0.5
                    }
                }

                Item {
                    id: contentFrame

                    height: islandBox.measuredHeight
                    width: islandBox.measuredWidth
                    x: Math.round((islandHost.width - width) / 2) - islandBox.x
                    y: 0

                    Loader {
                        id: baseLoader

                        active: DynamicIslandService.current !== null
                        anchors.fill: parent
                        opacity: DynamicIslandService.overlay === null ? 1 : 0
                        sourceComponent: DynamicIslandService.current ? DynamicIslandService.current.content : null
                        visible: opacity > 0
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

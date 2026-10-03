pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property QsMenuHandle handle: null
    property int currentIndex: 0
    property var highlightedEntry: null
    property int level: 0
    property string title: ""

    signal backRequested
    signal entered
    signal exited
    signal entryActivated(var entry)
    signal submenuRequested(var entry)

    readonly property bool backVisible: level > 0
    readonly property real contentHeight: (backVisible ? headerRow.height : 0) + menuColumn.implicitHeight

    readonly property int distance: currentIndex - level
    readonly property real restScale: distance > 0 ? 1.08 : (distance < 0 ? 0.92 : 1)

    implicitHeight: contentHeight

    function handleEntryClicked(entry: var): void {
        if (!entry || entry.isSeparator)
            return;
        if (entry.hasChildren) {
            root.submenuRequested(entry);
            return;
        }
        entry.triggered(); // qmllint disable
        root.entryActivated(entry);
    }

    QsMenuOpener {
        id: menuOpener

        menu: root.handle
    }

    Item {
        id: pageContent

        width: root.width
        height: root.height
        scale: root.restScale
        opacity: 1 - Math.min(Math.abs(root.distance), 1)

        Behavior on scale {
            NAnim {
                duration: Appearance.animations.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Row {
            id: headerRow

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: Appearance.margin.larger
                rightMargin: Appearance.margin.larger
            }
            visible: root.backVisible
            height: visible ? 40 : 0
            spacing: Appearance.spacing.smaller

            Icon {
                id: backIcon

                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                icon: "chevron_left"
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.large
            }

            Text {
                width: Math.max(headerRow.width - backIcon.width - headerRow.spacing, 0)
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.family: Fonts.sans
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Medium
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        MArea {
            anchors.fill: headerRow
            visible: headerRow.visible
            layerRadius: Appearance.rounding.small
            cursorShape: Qt.PointingHandCursor

            onClicked: root.backRequested()
        }

        Flickable {
            id: entryFlickable

            anchors {
                top: root.backVisible ? headerRow.bottom : parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            clip: true
            contentWidth: width
            contentHeight: menuColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
                id: menuColumn

                width: parent.width
                padding: Appearance.padding.smaller
                spacing: 2

                Repeater {
                    model: menuOpener.children

                    delegate: TrayMenuItem {
                        id: itemRow

                        width: menuColumn.width - menuColumn.padding * 2
                        active: root.highlightedEntry === itemRow.modelData

                        onClicked: root.handleEntryClicked(itemRow.modelData)
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                visible: entryFlickable.interactive
                policy: entryFlickable.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

                contentItem: StyledRect {
                    implicitWidth: 4
                    radius: 2
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                }
            }
        }
    }
}

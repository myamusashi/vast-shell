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

    readonly property bool backVisible: level > 0
    readonly property real contentHeight: (backVisible ? headerRow.height : 0) + menuColumn.implicitHeight
    readonly property int  distance: currentIndex - level
    readonly property real restScale: distance > 0 ? 1.08 : (distance < 0 ? 0.92 : 1)

    property int           currentIndex: 0
    property QsMenuHandle  handle: null
    property var           highlightedEntry: null
    property int           level: 0
    property string        title: ""

    signal                 backRequested
    signal                 entered
    signal                 entryActivated(var entry)
    signal                 exited
    signal                 submenuRequested(var entry)

    function               handleEntryClicked(entry: var): void {
        if (!entry || entry.isSeparator)
            return;
        if (entry.hasChildren) {
            root.submenuRequested(entry);
            return;
        }
        entry.triggered(); // qmllint disable
        root.entryActivated(entry);
    }

    implicitHeight: contentHeight

    QsMenuOpener {
        id: menuOpener

        menu: root.handle
    }

    Item {
        id: pageContent

        height: root.height
        opacity: 1 - Math.min(Math.abs(root.distance), 1)
        scale: root.restScale
        width: root.width
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on scale {
            NAnim {
                duration: Appearance.animations.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Row {
            id: headerRow

            height: visible ? 40 : 0
            spacing: Appearance.spacing.smaller
            visible: root.backVisible

            anchors {
                left: parent.left
                leftMargin: Appearance.margin.larger
                right: parent.right
                rightMargin: Appearance.margin.larger
                top: parent.top
            }

            Icon {
                id: backIcon

                anchors.verticalCenter: parent.verticalCenter
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.large
                height: 20
                icon: "chevron_left"
                width: 20
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                font.family: Fonts.sans
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Medium
                height: parent.height
                text: root.title
                verticalAlignment: Text.AlignVCenter
                width: Math.max(headerRow.width - backIcon.width - headerRow.spacing, 0)
            }
        }

        MArea {
            anchors.fill: headerRow
            cursorShape: Qt.PointingHandCursor
            layerRadius: Appearance.rounding.small
            visible: headerRow.visible
            onClicked: root.backRequested()
        }

        Flickable {
            id: entryFlickable

            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: menuColumn.implicitHeight
            contentWidth: width
            interactive: contentHeight > height
            ScrollBar.vertical: ScrollBar {
                policy: entryFlickable.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                visible: entryFlickable.interactive
                contentItem: StyledRect {
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    implicitWidth: 4
                    radius: 2
                }
            }

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                top: root.backVisible ? headerRow.bottom : parent.top
            }

            Column {
                id: menuColumn

                padding: Appearance.padding.smaller
                spacing: 2
                width: parent.width

                Repeater {
                    model: menuOpener.children
                    delegate: TrayMenuItem {
                        id: itemRow

                        active: root.highlightedEntry === itemRow.modelData
                        width: menuColumn.width - menuColumn.padding * 2
                        onClicked: root.handleEntryClicked(itemRow.modelData)
                    }
                }
            }
        }
    }
}

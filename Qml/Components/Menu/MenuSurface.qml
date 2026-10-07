pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    readonly property real contentImplicitHeight: itemColumn.implicitHeight
    readonly property real minWidth: 112

    default property alias content: itemColumn.data
    property int           elevationLevel: 2
    property real          maxHeight: 336
    property real          maxWidth: 280
    property bool          showScrollBar: false

    implicitHeight: Math.min(maxHeight, itemColumn.implicitHeight)
    implicitWidth: Math.max(minWidth, Math.min(maxWidth, itemColumn.implicitWidth))

    Elevation {
        anchors.fill: surfaceBg
        level: root.elevationLevel
        radius: surfaceBg.radius
    }

    WrapperRectangle {
        id: surfaceBg

        anchors.fill: parent
        clip: true
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.small

        Flickable {
            id: itemFlickable

            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: itemColumn.implicitHeight
            contentWidth: width
            interactive: contentHeight > height
            pressDelay: 0
            ScrollBar.vertical: ScrollBar {
                policy: root.showScrollBar ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                visible: root.showScrollBar
                contentItem: StyledRect {
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                    implicitWidth: 4
                    radius: 2
                }
            }

            Column {
                id: itemColumn

                padding: Appearance.padding.smaller
                width: parent.width
            }
        }
    }
}

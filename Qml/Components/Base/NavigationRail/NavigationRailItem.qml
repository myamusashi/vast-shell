pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

WrapperItem {
    id: root

    property bool badgeDot: false
    property string badgeText: ""
    readonly property real compactLabelGap: 5
    readonly property real compactPillHeight: 32
    readonly property real compactPillWidth: 56
    property bool expanded: false
    readonly property real expandedItemHeight: 56
    readonly property real expandedLabelWidth: 124
    property string icon: ""
    readonly property real iconCellSize: 24
    readonly property real iconCellX: Appearance.margin.normal
    property string label: ""
    property bool selected: false

    signal triggered

    implicitHeight: compactPillHeight + (Math.max(expandedItemHeight, labelText.implicitHeight) - compactPillHeight) * labelText.progress
    implicitWidth: compactPillWidth
    leftMargin: expanded ? Appearance.margin.normal : Math.max(0, (width - compactPillWidth) / 2)
    rightMargin: leftMargin

    MArea {
        id: area

        layerRadius: root.expanded ? Appearance.rounding.large : Appearance.rounding.full
        layerRect.anchors.fill: undefined
        layerRect.height: background.height
        layerRect.width: background.width
        layerRect.x: background.x
        layerRect.y: background.y

        onClicked: root.triggered()

        StyledRect {
            id: background

            color: root.selected ? Colours.m3Colors.m3SecondaryContainer : "transparent"
            height: root.expanded ? root.expandedItemHeight : root.compactPillHeight
            radius: root.expanded ? Appearance.rounding.large : Appearance.rounding.full
            width: root.expanded ? parent.width : parent.width - Appearance.margin.normal
            x: root.expanded ? 0 : root.iconCellX + root.iconCellSize / 2 - root.compactPillWidth / 2
            y: 0

            Behavior on color {
                CAnim {
                }
            }
            Behavior on height {
                SpringAnimation {
                    damping: 0.2
                    spring: 2
                }
            }
            Behavior on x {
                SpringAnimation {
                    damping: 0.2
                    spring: 2
                }
            }
        }
        Item {
            id: iconCell

            anchors.verticalCenter: background.verticalCenter
            height: root.iconCellSize
            width: root.iconCellSize
            x: root.iconCellX

            Icon {
                anchors.centerIn: parent
                color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.larger
                icon: root.icon

                Behavior on color {
                    CAnim {
                    }
                }
            }
            RailBadge {
                anchors.right: parent.right
                anchors.rightMargin: root.expanded ? -6 : -4
                anchors.top: parent.top
                anchors.topMargin: -4
                dot: root.badgeDot
                text: root.badgeText
            }
        }
        StyledText {
            id: labelText

            readonly property real compactX: (parent.width - root.compactPillWidth) / 2
            readonly property real compactY: root.compactPillHeight + root.compactLabelGap
            readonly property real expandedLabelHeight: font.pixelSize * 1.2
            readonly property real expandedLabelX: iconCell.x + iconCell.width + Appearance.spacing.normal
            readonly property real expandedX: expandedLabelX
            readonly property real expandedY: (root.expandedItemHeight - expandedLabelHeight) / 2
            property real progress: root.expanded ? 1 : 0

            color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: root.selected ? Font.Medium : Font.Normal
            horizontalAlignment: Text.AlignLeft
            opacity: progress
            text: root.label
            width: root.compactPillWidth + (root.expandedLabelWidth - root.compactPillWidth) * progress
            wrapMode: Text.Wrap
            x: compactX + (expandedX - compactX) * progress
            y: compactY + (expandedY - compactY) * progress

            Behavior on color {
                CAnim {
                }
            }
            Behavior on progress {
                NAnim {
                    duration: Appearance.animations.durations.normal
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property real expandedItemHeight: 56
    readonly property real iconCellSize: 24
    readonly property real iconCellX: Appearance.margin.normal

    property bool          badgeDot: false
    property string        badgeText: ""
    property bool          expanded: true
    property string        icon: ""
    property string        label: ""
    property bool          selected: false

    signal                 triggered

    implicitHeight: expandedItemHeight
    implicitWidth: parent ? parent.width : 200

    MArea {
        id: area

        anchors.fill: parent
        anchors.leftMargin: Appearance.margin.normal
        anchors.rightMargin: Appearance.margin.normal
        layerRadius: Appearance.rounding.large
        layerRect.height: background.height
        layerRect.width: background.width
        layerRect.x: background.x
        layerRect.y: background.y
        onClicked: root.triggered()

        StyledRect {
            id: background

            color: root.selected ? Colours.m3Colors.m3SecondaryContainer : "transparent"
            height: root.expandedItemHeight
            radius: Appearance.rounding.large
            width: parent.width
            x: 0
            y: 0
            Behavior on color {
                CAnim {}
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
                    CAnim {}
                }
            }

            Loader {
                anchors.right: parent.right
                anchors.rightMargin: -6
                anchors.top: parent.top
                anchors.topMargin: -4
                active: root.badgeDot || root.badgeText !== ""
                visible: active
                sourceComponent: RailBadge {
                    dot: root.badgeDot
                    text: root.badgeText
                }
            }
        }

        StyledText {
            anchors.left: iconCell.right
            anchors.leftMargin: Appearance.spacing.normal
            anchors.right: parent.right
            anchors.rightMargin: Appearance.margin.normal
            anchors.verticalCenter: background.verticalCenter
            color: root.selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: root.selected ? Font.Medium : Font.Normal
            horizontalAlignment: Text.AlignLeft
            text: root.label
            wrapMode: Text.NoWrap
            Behavior on color {
                CAnim {}
            }
        }
    }
}

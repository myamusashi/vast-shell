pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ItemDelegate {
    id: root

    required property string categoryId
    required property string glyph
    required property string label
    required property int    resultCount

    readonly property color  primaryTextColor: selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
    readonly property color  secondaryTextColor: selected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

    property bool            selected: false

    signal                   categoryClicked(string categoryId)

    implicitHeight: 40
    implicitWidth: 160
    background: Item {}
    contentItem: StyledRect {
        color: root.selected ? Colours.m3Colors.m3SecondaryContainer : "transparent"
        radius: Appearance.rounding.large
        Behavior on color {
            CAnim {}
        }

        RowLayout {
            spacing: Appearance.spacing.normal

            anchors {
                fill: parent
                leftMargin: Appearance.margin.normal
                rightMargin: Appearance.margin.normal
            }

            Icon {
                Layout.minimumHeight: 24
                Layout.minimumWidth: 24
                color: root.secondaryTextColor
                font.pixelSize: Appearance.fonts.size.larger
                icon: root.glyph
                Behavior on color {
                    CAnim {}
                }
            }

            StyledText {
                Layout.fillWidth: true
                color: root.primaryTextColor
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: root.selected ? Font.Medium : Font.Normal
                text: root.label
            }

            StyledText {
                color: root.secondaryTextColor
                font.pixelSize: Appearance.fonts.size.small
                text: root.resultCount
            }
        }
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.categoryClicked(root.categoryId)
    }
}

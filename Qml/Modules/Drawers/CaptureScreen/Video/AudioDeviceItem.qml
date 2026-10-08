pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    required property string audioDescription
    required property string audioName
    required property string iconName

    property bool            isSelected: false

    signal                   select(string name)

    Layout.fillWidth: true
    Layout.preferredHeight: Appearance.margin.normal + Appearance.fonts.size.normal
    color: "transparent"
    radius: Appearance.rounding.small

    RowLayout {
        spacing: Appearance.spacing.small

        anchors {
            fill: parent
            leftMargin: Appearance.margin.smaller
            rightMargin: Appearance.margin.smaller
        }

        Icon {
            color: root.isSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            icon: root.iconName
            type: Icon.Material
        }

        StyledText {
            id: audioDescriptionText

            color: root.isSelected ? Colours.m3Colors.m3Primary : audioDeviceMouseArea.containsMouse ? Colours.m3Colors.m3OnSurface : Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.normal
            text: root.audioDescription
        }

        Icon {
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.normal
            icon: "check"
            type: Icon.Material
            visible: root.isSelected
        }

        Item {
            Layout.fillWidth: true
        }
    }

    MArea {
        id: audioDeviceMouseArea

        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        implicitHeight: parent.height
        implicitWidth: audioDescriptionText.contentWidth
        onClicked: root.select(root.audioName)
    }
}

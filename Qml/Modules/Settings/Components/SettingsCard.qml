import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Rectangle {
    id: root

    default property alias content: contentLayout.data
    property alias         title: titleText.text

    function               flash() {
        flashSeq.restart();
    }

    Layout.fillWidth: true
    color: Colours.m3Colors.m3SurfaceContainerLow
    implicitHeight: layout.implicitHeight + (Appearance.margin.large * 2)
    radius: Appearance.rounding.large

    Elevation {
        anchors.fill: parent
        level: 1
        radius: root.radius
        z: -1
    }

    Rectangle {
        id: flashBorder

        anchors.fill: parent
        border.color: Colours.m3Colors.m3Primary
        border.width: 2
        color: "transparent"
        opacity: 0
        radius: root.radius
    }

    ColumnLayout {
        id: layout

        spacing: Appearance.spacing.larger

        anchors {
            left: parent.left
            margins: Appearance.margin.large
            right: parent.right
            top: parent.top
        }

        StyledText {
            id: titleText

            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            visible: text !== ""
        }

        ColumnLayout {
            id: contentLayout

            Layout.fillWidth: true
            spacing: Appearance.spacing.normal
        }
    }

    SequentialAnimation {
        id: flashSeq

        NumberAnimation {
            duration: 150
            property: "opacity"
            target: flashBorder
            to: 1
        }

        PauseAnimation {
            duration: 900
        }

        NumberAnimation {
            duration: 450
            property: "opacity"
            target: flashBorder
            to: 0
        }
    }
}

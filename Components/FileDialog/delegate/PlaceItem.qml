import AnotherRipple
import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property bool isSelected: false

    signal clicked

    implicitHeight: 48
    radius: 28
    clip: true
    color: isSelected ? Colours.m3Colors.m3SecondaryContainer : "transparent"

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    SimpleRipple {
        anchors.fill: parent
        clipRadius: 28
        color: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
        acceptEvent: false
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 12
        }
        spacing: 12

        StyledText {
            text: root.icon
            font.pixelSize: 16
        }

        StyledText {
            text: root.label
            color: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: 13
            font.bold: root.isSelected
            Layout.fillWidth: true
            elide: Text.ElideRight
            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            if (!root.isSelected)
                root.color = Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.08);
        }
        onExited: {
            if (!root.isSelected)
                root.color = "transparent";
        }
        onClicked: root.clicked()
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Helpers

Button {
    id: root

    required property string buttonTitle
    property string iconButton: ""
    property color buttonColor: Colors.colors.surface_container_high
    property color buttonHoverColor: Colors.withAlpha(Colors.colors.primary, 0.08)
    property color buttonPressedColor: Colors.withAlpha(Colors.colors.primary, 0.1)
    property color buttonTextColor: Colors.colors.primary
    property color buttonHoverTextColor: Colors.withAlpha(Colors.colors.primary, 0.08)
    property color buttonPressedTextColor: Colors.withAlpha(Colors.colors.primary, 0.1)

    hoverEnabled: true

    contentItem: RowLayout {
        anchors.centerIn: parent

        MatIcon {
            icon: root.iconButton
            font.pixelSize: 24
            font.bold: true
            color: {
                if (root.pressed)
                    root.buttonPressedTextColor;
                else if (root.hovered)
                    root.buttonHoverTextColor;
                else
                    root.buttonTextColor;
            }
        }

        StyledText {
            text: root.buttonTitle
            font.pixelSize: 14
            font.bold: true
            color: {
                if (root.pressed)
                    root.buttonPressedTextColor;
                else if (root.hovered)
                    root.buttonHoverTextColor;
                else
                    root.buttonTextColor;
            }
        }
    }

    background: StyledRect {
        radius: Appearance.rounding.large
        color: {
            if (root.pressed)
                root.buttonPressedColor;
            else if (root.hovered)
                root.buttonHoverColor;
            else
                root.buttonColor;
        }
    }
}

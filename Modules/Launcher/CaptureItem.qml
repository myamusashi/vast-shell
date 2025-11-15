import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

StyledRect {
    id: root

    required property var optionData
    required property int optionIndex
    required property bool isSelected
    required property int maxIndex

    signal executed
    signal indexChanged(int newIndex)
    signal closed

    RowLayout {
        id: content

        anchors.fill: parent
        anchors.leftMargin: Appearance.spacing.small
        anchors.rightMargin: Appearance.spacing.small
        spacing: Appearance.spacing.normal

        focus: root.isSelected

        Keys.onEnterPressed: root.executeAction()
        Keys.onReturnPressed: root.executeAction()
        Keys.onUpPressed: {
            if (root.optionIndex > 0)
                root.indexChanged(root.optionIndex - 1);
        }
        Keys.onDownPressed: {
            if (root.optionIndex < root.maxIndex)
                root.indexChanged(root.optionIndex + 1);
        }
        Keys.onEscapePressed: root.closed()

        transform: Scale {
            origin.x: content.width / 2
            origin.y: content.height / 2
            xScale: root.isSelected ? 1.03 : 1.0
            yScale: root.isSelected ? 1.03 : 1.0

            Behavior on xScale {
                NumbAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            Behavior on yScale {
                NumbAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }

        MatIcon {
            icon: root.optionData.icon
            color: root.isSelected ? Themes.colors.primary : Themes.colors.outline
            font.pixelSize: Appearance.fonts.large
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColAnim {
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
        }

        StyledText {
            color: root.isSelected ? Themes.colors.primary : Themes.colors.outline
            font.pixelSize: Appearance.fonts.normal
            text: root.optionData.name
            Layout.fillWidth: true
        }
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: root.executeAction()
        onEntered: content.focus = true
    }

    function executeAction() {
        content.focus = true;
        root.optionData.action();
        root.executed();
    }
}

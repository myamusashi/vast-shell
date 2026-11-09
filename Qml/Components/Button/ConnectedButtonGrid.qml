pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

GridLayout {
    id: connectedGrid

    property bool  checkable: false
    property color checkedColor: Colours.m3Colors.m3Primary
    property int   checkedIndex: -1
    property color checkedTextColor: Colours.m3Colors.m3OnPrimary
    property color hoverColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.45)
    property int   iconType: Icon.Weather
    property color idleColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.3)
    property real  innerRadius: 4
    property bool  interactive: true
    property var   model: []
    property real  outerRadius: 28
    property color pressedColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.6)
    property color textColor: Colours.m3Colors.m3Primary

    signal         buttonClicked(int buttonIndex)

    Layout.fillHeight: false
    Layout.fillWidth: true
    columnSpacing: 2
    columns: 2
    rowSpacing: 2

    Repeater {
        model: connectedGrid.model
        delegate: Rectangle {
            id: button

            required property int  index
            required property var  modelData

            readonly property int  columnIndex: index % connectedGrid.columns
            readonly property bool isChecked: connectedGrid.checkable && connectedGrid.checkedIndex === index
            readonly property bool isFirstColumn: columnIndex === 0
            readonly property bool isFirstRow: rowIndex === 0
            readonly property bool isLastColumn: columnIndex === connectedGrid.columns - 1 || index === connectedGrid.model.length - 1
            readonly property bool isLastRow: rowIndex === lastRowIndex
            readonly property int  lastRowIndex: Math.ceil(connectedGrid.model.length / connectedGrid.columns) - 1
            readonly property int  rowIndex: Math.floor(index / connectedGrid.columns)

            function               cornerRadius(isOuterCorner: bool): real {
                return isOuterCorner ? connectedGrid.outerRadius : connectedGrid.innerRadius;
            }

            Layout.fillWidth: true
            Layout.preferredHeight: buttonContent.implicitHeight + Appearance.spacing.large
            bottomLeftRadius: cornerRadius(isLastRow && isFirstColumn)
            bottomRightRadius: cornerRadius(isLastRow && isLastColumn)
            color: {
                if (isChecked)
                    return connectedGrid.checkedColor;
                if (mouseArea.pressed)
                    return connectedGrid.pressedColor;
                if (mouseArea.containsMouse)
                    return connectedGrid.hoverColor;
                return connectedGrid.idleColor;
            }
            topLeftRadius: cornerRadius(isFirstRow && isFirstColumn)
            topRightRadius: cornerRadius(isFirstRow && isLastColumn)
            Behavior on color {
                CAnim {}
            }

            Row {
                id: buttonContent

                anchors.centerIn: parent
                spacing: 4

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    color: {
                        if (button.modelData.iconColor !== undefined)
                            return button.modelData.iconColor;
                        return button.isChecked ? connectedGrid.checkedTextColor : connectedGrid.textColor;
                    }
                    font.pixelSize: Appearance.fonts.size.larger
                    icon: button.modelData.icon
                    type: connectedGrid.iconType
                    visible: button.modelData.icon !== undefined
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    color: button.isChecked ? connectedGrid.checkedTextColor : connectedGrid.textColor
                    font.pixelSize: Appearance.fonts.size.normal
                    text: button.modelData.label
                    visible: button.modelData.label !== undefined
                }
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                cursorShape: connectedGrid.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: connectedGrid.interactive
                hoverEnabled: true
                onClicked: {
                    if (connectedGrid.checkable)
                        connectedGrid.checkedIndex = button.index;
                    connectedGrid.buttonClicked(button.index);
                }
            }
        }
    }
}

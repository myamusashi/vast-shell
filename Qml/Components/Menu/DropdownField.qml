pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property string displayText: ModelAdapter.displayText(model, currentIndex, textRole, placeholderText)

    property int             currentIndex: -1
    property var             currentValue: null
    property var             disabledLabel: model => qsTr("N/A")
    property var             isItemActive: (model, itemIndex) => itemIndex === currentIndex
    property var             isItemEnabled: model => true
    property alias           model: dropdownMenu.model
    property string          placeholderText: qsTr("Select…")
    property bool            showScrollBar: false
    property string          textRole: "display"
    property string          valueRole: ""

    signal                   activated(int index)

    function                 syncIndex() {
        if (valueRole === "" || currentValue === null || currentValue === undefined)
            return;
        const index = ModelAdapter.indexOfValue(model, valueRole, currentValue);
        if (index >= 0)
            currentIndex = index;
    }

    implicitHeight: 48
    implicitWidth: 280
    Component.onCompleted: syncIndex()
    onCurrentValueChanged: syncIndex()
    onModelChanged: syncIndex()
    onValueRoleChanged: syncIndex()

    StyledRect {
        id: fieldSurface

        anchors.fill: parent
        border.color: Qt.alpha(Colours.m3Colors.m3Outline, 0.5)
        border.width: 1
        color: Colours.m3Colors.m3Surface
        radius: Appearance.rounding.normal
    }

    MArea {
        layerRadius: Appearance.rounding.large
        onClicked: {
            if (dropdownMenu.opened)
                dropdownMenu.close();
            else
                dropdownMenu.open();
        }
        onWheel: wheel => wheel.accepted = false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.margin.normal
            anchors.rightMargin: Appearance.margin.normal
            spacing: Appearance.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                color: root.currentIndex < 0 ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Medium
                text: root.displayText
            }

            Item {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                rotation: dropdownMenu.opened ? 180 : 0
                transformOrigin: Item.Center
                Behavior on rotation {
                    NAnim {}
                }

                Icon {
                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.extraLarge
                    horizontalAlignment: Text.AlignHCenter
                    icon: "keyboard_arrow_down"
                }
            }
        }
    }

    DropdownMenu {
        id: dropdownMenu

        anchorItem: root
        currentIndex: root.currentIndex
        disabledLabel: root.disabledLabel
        isItemActive: root.isItemActive
        isItemEnabled: root.isItemEnabled
        showScrollBar: root.showScrollBar
        textRole: root.textRole
        onActivated: index => {
            root.currentIndex = index;
            root.activated(index);
        }
    }
}

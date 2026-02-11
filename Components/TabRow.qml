pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components
import qs.Configs
import qs.Services

StyledRect {
    id: root

    property int currentIndex: 0
    property var tabs: []
    property real scaleFactor: 0.2
    property int tabSpacing: 15
    property real widthRatio: 0.95
    property int preferredHeight: 60
    property color backgroundColor: Colours.m3Colors.m3Surface
    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3OnBackground
    property color indicatorColor: Colours.m3Colors.m3Primary
    property int indicatorHeight: 2
    property int indicatorRadius: Appearance.rounding.large
    property bool showIndicator: true
    radius: 0

    signal tabClicked(int index, var tabData)

    implicitWidth: parent.width
    implicitHeight: preferredHeight
    color: backgroundColor

    RowLayout {
        id: tabLayout

        anchors.centerIn: parent
        spacing: root.tabSpacing
        width: parent.width * root.widthRatio

        Repeater {
            id: tabRepeater

            model: root.tabs

            StyledButton {
                id: tabButton

                required property var modelData
                required property int index

                Layout.fillWidth: true
                text: modelData.title || ""
                icon.name: modelData.icon || ""
                enabled: modelData.enabled !== undefined ? modelData.enabled : true

                onClicked: {
                    root.currentIndex = index;
                    root.tabClicked(index, modelData);
                }
            }
        }
    }
}

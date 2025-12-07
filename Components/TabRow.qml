pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Components

StyledRect {
    id: root

    property int currentIndex: 0
    property var tabs: []
    property real scaleFactor: 0.2
    property int tabSpacing: 15
    property real widthRatio: 0.95
    property int preferredHeight: 60
    property color backgroundColor: Themes.m3Colors.m3Surface
    property color activeColor: Themes.m3Colors.m3Primary
    property color inactiveColor: Themes.m3Colors.m3OnBackground
    property color indicatorColor: Themes.m3Colors.m3Primary
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

                buttonTitle: modelData.title || ""
                iconButton: modelData.icon || ""
                iconSize: modelData.iconSize || (Appearance.fonts.large * root.scaleFactor)
                Layout.fillWidth: true
                buttonTextColor: root.currentIndex === index ? root.activeColor : root.inactiveColor
                buttonColor: modelData.backgroundColor || "transparent"
                enabled: modelData.enabled !== undefined ? modelData.enabled : true

                onClicked: {
                    root.currentIndex = index;
                    root.tabClicked(index, modelData);
                }
            }
        }
    }

    StyledRect {
        id: indicator

        visible: root.showIndicator
        anchors.bottom: tabLayout.bottom
        width: tabRepeater.itemAt(root.currentIndex) ? tabRepeater.itemAt(root.currentIndex).width : 0
        height: root.indicatorHeight
        color: root.indicatorColor
        radius: root.indicatorRadius

        x: {
            if (tabRepeater.itemAt(root.currentIndex))
            return tabRepeater.itemAt(root.currentIndex).x + tabLayout.x;
            return 0;
        }

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        Behavior on width {
            NAnim {
                easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            }
        }
    }
}

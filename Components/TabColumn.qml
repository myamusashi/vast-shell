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
    property real heightRatio: 0.95
    property int preferredWidth: 60
    property color backgroundColor: Colours.m3Colors.m3Surface
    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3OnBackground
    property color indicatorColor: Colours.m3Colors.m3Primary
    property int indicatorWidth: 2
    property int indicatorRadius: Appearance.rounding.large
    property bool showIndicator: true
    radius: 0
    signal tabClicked(int index, var tabData)
    implicitWidth: preferredWidth
    implicitHeight: parent.height
    color: backgroundColor

    ColumnLayout {
        id: tabLayout

        anchors.centerIn: parent
        spacing: root.tabSpacing
        height: parent.height * root.heightRatio

        Repeater {
            id: tabRepeater

            model: root.tabs

            StyledButton {
                id: tabButton

                required property var modelData
                required property int index
                Layout.fillHeight: true
                buttonWidth: root.preferredWidth
                showIconBackground: true
                iconBackgroundColor: "transparent"
                buttonTitle: modelData.title || ""
                iconButton: modelData.icon || ""
                iconSize: modelData.iconSize || (Appearance.fonts.size.large * root.scaleFactor)
                iconColor: Colours.m3Colors.m3OnSurface
                buttonTextColor: root.currentIndex === index ? root.activeColor : root.inactiveColor
                buttonColor: root.backgroundColor
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

        anchors.right: tabLayout.right
        implicitWidth: root.indicatorWidth
        implicitHeight: tabRepeater.itemAt(root.currentIndex) ? tabRepeater.itemAt(root.currentIndex).height : 0
        color: root.indicatorColor
        radius: root.indicatorRadius
        visible: root.showIndicator

        y: {
            if (tabRepeater.itemAt(root.currentIndex))
                return tabRepeater.itemAt(root.currentIndex).y + tabLayout.y;
            return 0;
        }

        Behavior on y {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        Behavior on height {
            NAnim {
                easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            }
        }
    }
}

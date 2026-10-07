pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property real distributedSegmentWidth: model.length > 0 ? (width - (model.length - 1) * 2) / model.length : 0
    readonly property real segmentWidth: {
        let maxWidth = 0;
        for (let i = 0; i < reportedSegmentWidths.length; ++i)
            maxWidth = Math.max(maxWidth, reportedSegmentWidths[i]);
        return maxWidth;
    }

    property int           currentIndex: 0
    property bool          fillWidth: false
    property var           model: []
    property var           reportedSegmentWidths: []
    property color         selectedColor: Colours.m3Colors.m3SecondaryContainer
    property color         selectedContentColor: Colours.m3Colors.m3OnSecondaryContainer
    property int           textSize: Appearance.fonts.size.normal
    property color         unselectedColor: Colours.m3Colors.m3SurfaceContainerHigh
    property color         unselectedContentColor: Colours.m3Colors.m3OnSurfaceVariant

    signal                 clicked(int index)

    function               reportSegmentWidth(index, width) {
        const widths = reportedSegmentWidths.slice();
        if (widths[index] === width)
            return;
        widths[index]         = width;
        reportedSegmentWidths = widths;
    }

    implicitHeight: 40
    implicitWidth: segmentRow.implicitWidth
    opacity: enabled ? 1 : 0.38

    Row {
        id: segmentRow

        spacing: 2

        Repeater {
            id: segmentRepeater

            model: root.model
            delegate: Segment {}
        }
    }

    component Segment: Item {
        id: segment

        required property int    index
        required property var    modelData

        readonly property color  contentColor: isSelected ? root.selectedContentColor : root.unselectedContentColor
        readonly property bool   isFirst: index === 0
        readonly property bool   isLast: index === root.model.length - 1
        readonly property bool   isSelected: root.currentIndex === index
        readonly property string label: typeof modelData === "string" ? modelData : (modelData.label ?? "")
        readonly property real   preferredWidth: contentRow.implicitWidth + 32
        readonly property string segmentIconName: typeof modelData === "string" ? "" : (modelData.icon ?? "")
        readonly property real   targetInnerRadius: isSelected ? height * 0.5 : pressed ? 4 : 8

        property bool            hovered: segmentHoverHandler.hovered
        property bool            pressed: segmentTapHandler.pressed

        function                 moveFocus(delta) {
            const target = segmentRepeater.itemAt(index + delta);
            if (target)
                target.forceActiveFocus();
        }
        function                 select() {
            if (!root.enabled)
                return;
            root.clicked(index);
        }

        activeFocusOnTab: root.enabled
        height: root.height
        width: root.fillWidth ? root.distributedSegmentWidth : root.segmentWidth
        Component.onCompleted: root.reportSegmentWidth(index, preferredWidth)
        Component.onDestruction: root.reportSegmentWidth(index, 0)
        Keys.onLeftPressed: event => {
            moveFocus(-1);
            event.accepted = true;
        }
        Keys.onReturnPressed: event => {
            select();
            event.accepted = true;
        }
        Keys.onRightPressed: event => {
            moveFocus(1);
            event.accepted = true;
        }
        Keys.onSpacePressed: event => {
            select();
            event.accepted = true;
        }
        onPreferredWidthChanged: root.reportSegmentWidth(index, preferredWidth)

        StyledRect {
            id: segmentBackground

            anchors.fill: parent
            bottomLeftRadius: segment.isFirst ? Appearance.rounding.full : segment.targetInnerRadius
            bottomRightRadius: segment.isLast ? Appearance.rounding.full : segment.targetInnerRadius
            color: segment.isSelected ? root.selectedColor : root.unselectedColor
            topLeftRadius: segment.isFirst ? Appearance.rounding.full : segment.targetInnerRadius
            topRightRadius: segment.isLast ? Appearance.rounding.full : segment.targetInnerRadius
            Behavior on bottomLeftRadius {
                NAnim {}
            }
            Behavior on bottomRightRadius {
                NAnim {}
            }
            Behavior on color {
                CAnim {}
            }
            Behavior on topLeftRadius {
                NAnim {}
            }
            Behavior on topRightRadius {
                NAnim {}
            }
        }

        StateLayer {
            anchors.fill: parent
            bottomLeftRadius: segmentBackground.bottomLeftRadius
            bottomRightRadius: segmentBackground.bottomRightRadius
            color: segment.contentColor
            layerEnabled: segment.enabled
            layerHovered: segment.hovered
            layerPressed: segment.pressed
            topLeftRadius: segmentBackground.topLeftRadius
            topRightRadius: segmentBackground.topRightRadius
        }

        Rectangle {
            id: focusRing

            anchors.fill: parent
            border.color: Colours.m3Colors.m3Primary
            border.width: 2
            bottomLeftRadius: segmentBackground.bottomLeftRadius
            bottomRightRadius: segmentBackground.bottomRightRadius
            color: "transparent"
            opacity: segment.activeFocus ? 1 : 0
            topLeftRadius: segmentBackground.topLeftRadius
            topRightRadius: segmentBackground.topRightRadius
        }

        RowLayout {
            id: contentRow

            anchors.centerIn: parent
            spacing: 8

            Icon {
                color: segment.contentColor
                font.pixelSize: Appearance.fonts.size.large * 1.2
                icon: segment.segmentIconName
                visible: segment.segmentIconName !== ""
                Behavior on color {
                    CAnim {}
                }
            }

            StyledText {
                color: segment.contentColor
                font.pixelSize: root.textSize
                font.weight: segment.isSelected ? Font.DemiBold : Font.Medium
                text: segment.label
                Behavior on color {
                    CAnim {}
                }
            }
        }

        HoverHandler {
            id: segmentHoverHandler

            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            id: segmentTapHandler

            enabled: root.enabled
            onTapped: segment.select()
        }
    }
}

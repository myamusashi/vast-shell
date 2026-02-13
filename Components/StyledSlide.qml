pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Services

Slider {
    id: root

    enum ContainerSize {
        XS = 16,
        S = 24,
        M = 40,
        L = 56,
        XL = 96
    }

    enum HandleSize {
        XS = 44,
        S = 44,
        M = 44,
        L = 68,
        XL = 108
    }

    readonly property real availableTrackSize: orientation === Qt.Horizontal ? availableWidth - handleGap * 2 : availableHeight - handleGap * 2
    readonly property real trackSize: orientation === Qt.Horizontal ? height - trackSizeDiff : width - trackSizeDiff
    readonly property real handleSize: pressed ? 2 : 4
    readonly property real invertedVisualPosition: 1 - visualPosition
    readonly property int dotCount: stepSize > 0 ? Math.floor((to - from) / stepSize) + 1 : 0

    property bool dotEnd: true
    property bool useAnim: true
    property string icon: ""
    property int iconSize: 0
    property int valueWidth: orientation === Qt.Horizontal ? 200 : StyledSlide.ContainerSize.M
    property int valueHeight: orientation === Qt.Horizontal ? StyledSlide.ContainerSize.M : 200

    property real trackSizeDiff: 15
    property real handleGap: 6
    property real trackDotSize: 4

    Layout.alignment: orientation === Qt.Horizontal ? Qt.AlignHCenter : Qt.AlignVCenter
    hoverEnabled: true
    implicitWidth: valueWidth
    implicitHeight: valueHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        onPressed: function (mouse) {
            if (root.orientation === Qt.Vertical) {
                var pos = 1 - (mouse.y / height);
                pos = Math.max(0, Math.min(1, pos));
                var newValue = root.from + (pos * (root.to - root.from));

                if (root.stepSize > 0)
                    newValue = Math.round(newValue / root.stepSize) * root.stepSize;

                root.value = newValue;
            }
            mouse.accepted = false;
        }
    }

    background: Item {
        implicitWidth: root.valueWidth
        implicitHeight: root.valueHeight
        width: root.availableWidth
        height: root.availableHeight
        x: root.leftPadding
        y: root.topPadding

        Loader {
            active: root.icon !== ""
            z: 10
            anchors {
                left: root.orientation === Qt.Horizontal ? parent.left : undefined
                leftMargin: root.orientation === Qt.Horizontal ? 10 : 0
                top: root.orientation === Qt.Vertical ? parent.top : undefined
                topMargin: root.orientation === Qt.Vertical ? 10 : 0
                horizontalCenter: root.orientation === Qt.Vertical ? parent.horizontalCenter : undefined
                verticalCenter: root.orientation === Qt.Horizontal ? parent.verticalCenter : undefined
            }
            sourceComponent: Icon {
                icon: root.icon
                color: root.orientation === Qt.Horizontal ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3Primary
                font.pixelSize: root.iconSize || Appearance.fonts.size.large
            }
        }

        // Filled portion (before handle)
        StyledRect {
            anchors {
                verticalCenter: root.orientation === Qt.Horizontal ? parent.verticalCenter : undefined
                left: root.orientation === Qt.Horizontal ? parent.left : undefined
                horizontalCenter: root.orientation === Qt.Vertical ? parent.horizontalCenter : undefined
                bottom: root.orientation === Qt.Vertical ? parent.bottom : undefined
            }
            width: root.orientation === Qt.Horizontal ? root.handleGap + (root.visualPosition * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap) : root.trackSize
            height: root.orientation === Qt.Horizontal ? root.trackSize : root.handleGap + (root.invertedVisualPosition * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            color: Colours.m3Colors.m3Primary
            radius: Appearance.rounding.small * 0.5
        }

        // Empty portion (after handle)
        StyledRect {
            anchors {
                verticalCenter: root.orientation === Qt.Horizontal ? parent.verticalCenter : undefined
                right: root.orientation === Qt.Horizontal ? parent.right : undefined
                horizontalCenter: root.orientation === Qt.Vertical ? parent.horizontalCenter : undefined
                top: root.orientation === Qt.Vertical ? parent.top : undefined
            }
            width: root.orientation === Qt.Horizontal ? root.handleGap + ((1 - root.visualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap) : root.trackSize
            height: root.orientation === Qt.Horizontal ? root.trackSize : root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            color: Colours.m3Colors.m3SurfaceContainerHighest
            radius: Appearance.rounding.small * 0.5
        }
    }

    handle: StyledRect {
        width: root.orientation === Qt.Horizontal ? root.handleSize : root.width
        height: root.orientation === Qt.Horizontal ? root.height : root.handleSize
        x: root.orientation === Qt.Horizontal ? root.handleGap + (root.visualPosition * root.availableTrackSize) - width / 2 : 0
        y: root.orientation === Qt.Vertical ? root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - height / 2 : 0
        anchors.verticalCenter: root.orientation === Qt.Horizontal ? parent.verticalCenter : undefined
        anchors.horizontalCenter: root.orientation === Qt.Vertical ? parent.horizontalCenter : undefined
        color: Colours.m3Colors.m3Primary

        Behavior on width {
            enabled: root.useAnim
            NAnim {}
        }
        Behavior on height {
            enabled: root.useAnim
            NAnim {}
        }
    }
}

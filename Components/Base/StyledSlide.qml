pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls

import qs.Core.Configs
import qs.Core.Utils
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

    property alias filledRectColor: filledRect.color
    property alias emptyRectColor: emptyRect.color
    property alias handleColor: handle.color
    property alias filledRectOpacity: filledRect.opacity
    property alias emptyRectOpacity: emptyRect.opacity
    property alias handleOpacity: handle.opacity

    readonly property bool _popupVisible: showValuePopup && (pressed || (popupOnHoverToo && hovered))

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

    property bool snapEnabled: false
    property real snapDotSize: 4
    property color snapDotFilledColor: Colours.m3Colors.m3OnPrimary
    property color snapDotEmptyColor: Colours.m3Colors.m3OnSurfaceVariant

    property bool showValuePopup: true
    property bool popupOnHoverToo: false
    property var popupValueFormat: v => Math.round(v)

    snapMode: (snapEnabled && stepSize > 0) ? Slider.SnapAlways : Slider.NoSnap
    Layout.alignment: orientation === Qt.Horizontal ? Qt.AlignHCenter : Qt.AlignVCenter
    hoverEnabled: true
    implicitWidth: valueWidth
    implicitHeight: valueHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        onPressed: mouse => {
            if (root.orientation === Qt.Vertical) {
                var pos = 1 - ((mouse.y - root.topPadding) / root.availableHeight);
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
            id: iconLoader

            readonly property real effectiveIconSize: root.iconSize || Appearance.fonts.size.large
            readonly property real iconSpaceNeeded: effectiveIconSize + 20
            readonly property real emptyWidthH: root.handleGap + ((1 - root.visualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            readonly property real emptyHeightV: root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            readonly property bool iconInEmpty: root.orientation === Qt.Horizontal ? emptyWidthH > iconSpaceNeeded : emptyHeightV > iconSpaceNeeded

            active: root.icon !== ""
            z: 10

            states: [
                State {
                    name: "hFilled"
                    when: root.orientation === Qt.Horizontal && !iconLoader.iconInEmpty
                    AnchorChanges {
                        target: iconLoader
                        anchors.left: parent.left
                        anchors.right: undefined
                        anchors.top: undefined
                        anchors.bottom: undefined
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: undefined
                    }
                    PropertyChanges {
                        target: iconLoader
                        anchors.leftMargin: 10
                    }
                },
                State {
                    name: "hEmpty"
                    when: root.orientation === Qt.Horizontal && iconLoader.iconInEmpty
                    AnchorChanges {
                        target: iconLoader
                        anchors.left: undefined
                        anchors.right: parent.right
                        anchors.top: undefined
                        anchors.bottom: undefined
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: undefined
                    }
                    PropertyChanges {
                        target: iconLoader
                        anchors.rightMargin: 10
                    }
                },
                State {
                    name: "vFilled"
                    when: root.orientation === Qt.Vertical && !iconLoader.iconInEmpty
                    AnchorChanges {
                        target: iconLoader
                        anchors.left: undefined
                        anchors.right: undefined
                        anchors.top: undefined
                        anchors.bottom: parent.bottom
                        anchors.verticalCenter: undefined
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    PropertyChanges {
                        target: iconLoader
                        anchors.bottomMargin: 10
                    }
                },
                State {
                    name: "vEmpty"
                    when: root.orientation === Qt.Vertical && iconLoader.iconInEmpty
                    AnchorChanges {
                        target: iconLoader
                        anchors.left: undefined
                        anchors.right: undefined
                        anchors.top: parent.top
                        anchors.bottom: undefined
                        anchors.verticalCenter: undefined
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    PropertyChanges {
                        target: iconLoader
                        anchors.topMargin: 10
                    }
                }
            ]

            transitions: Transition {
                enabled: root.useAnim
                AnchorAnimation {
                    duration: Appearance.animations.durations.small
                    easing.type: Easing.InOutQuad
                }
            }

            sourceComponent: Icon {
                icon: root.icon
                color: iconLoader.iconInEmpty ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary
                font.pixelSize: root.iconSize || Appearance.fonts.size.large
            }
        }

        StyledRect {
            id: filledRect

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
            opacity: 1.0
        }

        StyledRect {
            id: emptyRect

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
            opacity: 1.0
        }

        Repeater {
            model: (root.snapEnabled && root.stepSize > 0) ? root.dotCount : 0

            delegate: Rectangle {
                id: snapDot

                required property int index

                readonly property real normalPos: root.dotCount > 1 ? index / (root.dotCount - 1) : 0.5
                readonly property bool isFilled: normalPos <= root.visualPosition

                width: root.snapDotSize
                height: root.snapDotSize
                radius: root.snapDotSize / 2
                color: isFilled ? root.snapDotFilledColor : root.snapDotEmptyColor

                x: root.orientation === Qt.Horizontal ? root.handleGap + (normalPos * root.availableTrackSize) - root.snapDotSize / 2 : (parent.width - root.snapDotSize) / 2
                y: root.orientation === Qt.Vertical ? root.handleGap + ((1 - normalPos) * root.availableTrackSize) - root.snapDotSize / 2 : (parent.height - root.snapDotSize) / 2
                z: 5

                Behavior on color {
                    CAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }
        }
    }

    handle: StyledRect {
        id: handle

        width: root.orientation === Qt.Horizontal ? root.handleSize : root.width
        height: root.orientation === Qt.Horizontal ? root.height : root.handleSize
        x: root.orientation === Qt.Horizontal ? root.handleGap + (root.visualPosition * root.availableTrackSize) - width / 2 : 0
        y: root.orientation === Qt.Vertical ? root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - height / 2 : 0
        anchors.verticalCenter: root.orientation === Qt.Horizontal ? parent.verticalCenter : undefined
        anchors.horizontalCenter: root.orientation === Qt.Vertical ? parent.horizontalCenter : undefined
        color: Colours.m3Colors.m3Primary
        opacity: 1.0

        Behavior on width {
            enabled: root.useAnim
            NAnim {}
        }
        Behavior on height {
            enabled: root.useAnim
            NAnim {}
        }

        Item {
            id: valuePopupRoot

            x: root.orientation === Qt.Horizontal ? (handle.width - valuePopupBubble.width) / 2 : -(valuePopupBubble.width + caret.caretSize + 2)
            y: root.orientation === Qt.Horizontal ? -(valuePopupBubble.height + caret.caretSize + 2) : (handle.height - valuePopupBubble.height) / 2

            width: valuePopupBubble.width + (root.orientation === Qt.Vertical ? caret.caretSize + 2 : 0)
            height: valuePopupBubble.height + (root.orientation === Qt.Horizontal ? caret.caretSize + 2 : 0)
            z: 20
            visible: root._popupVisible
            opacity: visible ? 1.0 : 0.0
            scale: visible ? 1.0 : 0.82

            transformOrigin: root.orientation === Qt.Horizontal ? Item.Bottom : Item.Right

            Behavior on opacity {
                enabled: root.useAnim
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
            Behavior on scale {
                enabled: root.useAnim
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            StyledRect {
                id: valuePopupBubble

                readonly property real hPad: 10
                readonly property real vPad: 6

                width: valueLabel.implicitWidth + hPad * 2
                height: valueLabel.implicitHeight + vPad * 2
                x: 0
                y: 0

                color: Colours.m3Colors.m3InverseSurface
                radius: Appearance.rounding.small

                StyledText {
                    id: valueLabel
                    anchors.centerIn: parent
                    text: root.popupValueFormat(root.value)
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.Medium
                    color: Colours.m3Colors.m3InverseOnSurface
                }
            }

            Shape {
                id: caret

                anchors {
                    horizontalCenter: root.orientation === Qt.Horizontal ? valuePopupBubble.horizontalCenter : undefined
                    top: root.orientation === Qt.Horizontal ? valuePopupBubble.bottom : undefined
                    left: root.orientation === Qt.Vertical ? valuePopupBubble.right : undefined
                    verticalCenter: root.orientation === Qt.Vertical ? valuePopupBubble.verticalCenter : undefined
                }

                readonly property int caretSize: 6

                width: root.orientation === Qt.Horizontal ? caretSize * 2 : caretSize
                height: root.orientation === Qt.Horizontal ? caretSize : caretSize * 2
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: Colours.m3Colors.m3InverseSurface
                    strokeColor: "transparent"
                    strokeWidth: 0

                    startX: 0
                    startY: 0

                    // Horizontal ▼: (0,0) → (12,0) → (6,6)
                    // Vertical   ▶: (0,0) → (0,12) → (6,6)
                    PathLine {
                        x: root.orientation === Qt.Horizontal ? caret.caretSize * 2 : 0
                        y: root.orientation === Qt.Horizontal ? 0 : caret.caretSize * 2
                    }
                    PathLine {
                        x: caret.caretSize
                        y: caret.caretSize
                    }
                    PathLine {
                        x: 0
                        y: 0
                    }
                }
            }
        }
    }
}

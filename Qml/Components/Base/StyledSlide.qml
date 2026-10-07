pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Vast.Utils

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Slider {
    id: root

    readonly property real availableTrackSize: isHorizontal ? availableWidth - handleGap * 2 : availableHeight - handleGap * 2
    readonly property int  dotCount: stepSize > 0 ? Math.floor((to - from) / stepSize) + 1 : 0
    readonly property real handleSize: pressed ? 2 : 4
    readonly property real invertedVisualPosition: 1 - visualPosition
    readonly property bool isHorizontal: orientation === Qt.Horizontal
    readonly property bool isVertical: root.orientation === Qt.Vertical
    readonly property bool popupVisible: showValuePopup && (pressed || (popupOnHoverToo && hovered))
    readonly property real trackSize: isHorizontal ? height - trackSizeDiff : width - trackSizeDiff

    property bool          animateChanges: true
    property alias         emptyRectColor: emptyRect.color
    property alias         emptyRectOpacity: emptyRect.opacity
    property alias         filledRectColor: filledRect.color
    property alias         filledRectOpacity: filledRect.opacity
    property alias         handleColor: handle.color
    property real          handleGap: 6
    property alias         handleOpacity: handle.opacity
    property string        icon: ""
    property int           iconSize: 0
    property int           popupDecimals: 0
    property bool          popupOnHoverToo: false
    property var           popupValueFormat: v => v.toFixed(root.popupDecimals)
    property bool          showValuePopup: true
    property color         snapDotEmptyColor: Colours.m3Colors.m3OnSurfaceVariant // qmllint:ignore
    property color         snapDotFilledColor: Colours.m3Colors.m3OnPrimary
    property real          snapDotSize: 4
    property bool          snapEnabled: false
    property real          trackSizeDiff: 15
    property int           valueHeight: isHorizontal ? StyledSlide.ContainerSize.M : 200
    property int           valueWidth: isHorizontal ? 200 : StyledSlide.ContainerSize.M

    enum ContainerSize {
        XS = 16,
        S  = 24,
        M  = 40,
        L  = 56,
        XL = 96
    }
    Layout.alignment: isHorizontal ? Qt.AlignHCenter : Qt.AlignVCenter
    hoverEnabled: true
    implicitHeight: valueHeight
    implicitWidth: valueWidth
    snapMode: (snapEnabled && stepSize > 0) ? Slider.SnapAlways : Slider.NoSnap
    background: Item {
        height: root.availableHeight
        implicitHeight: root.valueHeight
        implicitWidth: root.valueWidth
        width: root.availableWidth
        x: root.leftPadding
        y: root.topPadding

        Loader {
            id: iconLoader

            readonly property real effectiveIconSize: root.iconSize || Appearance.fonts.size.large
            readonly property real freeHeightVertical: root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            readonly property real freeWidthHorizontal: root.handleGap + ((1 - root.visualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            readonly property bool iconInEmpty: root.isHorizontal ? freeWidthHorizontal > iconSpaceNeeded : freeHeightVertical > iconSpaceNeeded
            readonly property real iconSpaceNeeded: effectiveIconSize + 20

            active: root.icon !== ""
            z: 10
            sourceComponent: Icon {
                color: iconLoader.iconInEmpty ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary
                font.pixelSize: root.iconSize || Appearance.fonts.size.large
                icon: root.icon
            }

            // qmllint disable
            states: [
                State {
                    name: "hFilled"
                    when: root.isHorizontal && !iconLoader.iconInEmpty

                    AnchorChanges {
                        target: iconLoader

                        anchors {
                            bottom: undefined
                            horizontalCenter: undefined
                            left: parent.left
                            right: undefined
                            top: undefined
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    PropertyChanges {
                        anchors.leftMargin: 10
                        target: iconLoader
                    }
                },
                State {
                    name: "hEmpty"
                    when: root.isHorizontal && iconLoader.iconInEmpty

                    AnchorChanges {
                        target: iconLoader

                        anchors {
                            bottom: undefined
                            horizontalCenter: undefined
                            left: undefined
                            right: parent.right
                            top: undefined
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    PropertyChanges {
                        anchors.rightMargin: 10
                        target: iconLoader
                    }
                },
                State {
                    name: "vFilled"
                    when: root.isVertical && !iconLoader.iconInEmpty

                    AnchorChanges {
                        target: iconLoader

                        anchors {
                            bottom: parent.bottom
                            horizontalCenter: parent.horizontalCenter
                            left: undefined
                            right: undefined
                            top: undefined
                            verticalCenter: undefined
                        }
                    }

                    PropertyChanges {
                        anchors.bottomMargin: 10
                        target: iconLoader
                    }
                },
                State {
                    name: "vEmpty"
                    when: root.isVertical && iconLoader.iconInEmpty

                    AnchorChanges {
                        target: iconLoader

                        anchors {
                            bottom: undefined
                            horizontalCenter: parent.horizontalCenter
                            left: undefined
                            right: undefined
                            top: parent.top
                            verticalCenter: undefined
                        }
                    }

                    PropertyChanges {
                        anchors.topMargin: 10
                        target: iconLoader
                    }
                }
            ]
            // qmllint enable

            transitions: Transition {
                enabled: root.animateChanges

                AnchorAnimation {
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.standard
                    easing.type: Easing.BezierSpline
                }
            }
        }

        StyledRect {
            id: filledRect

            color: Colours.m3Colors.m3Primary
            height: root.isHorizontal ? root.trackSize : root.handleGap + (root.invertedVisualPosition * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            opacity: 1.0
            radius: Appearance.rounding.small * 0.5
            width: root.isHorizontal ? root.handleGap + (root.visualPosition * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap) : root.trackSize

            anchors {
                bottom: root.isVertical ? parent.bottom : undefined
                horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
                left: root.isHorizontal ? parent.left : undefined
                verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
            }
        }

        StyledRect {
            id: emptyRect

            color: Colours.m3Colors.m3SurfaceContainerHighest
            height: root.isHorizontal ? root.trackSize : root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap)
            opacity: 1.0
            radius: Appearance.rounding.small * 0.5
            width: root.isHorizontal ? root.handleGap + ((1 - root.visualPosition) * root.availableTrackSize) - (root.handleSize / 2 + root.handleGap) : root.trackSize

            anchors {
                horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
                right: root.isHorizontal ? parent.right : undefined
                top: root.isVertical ? parent.top : undefined
                verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
            }
        }

        Repeater {
            model: (root.snapEnabled && root.stepSize > 0) ? root.dotCount : 0
            delegate: Rectangle {
                id: snapDot

                required property int  index

                readonly property bool isFilled: normalPos <= root.visualPosition
                readonly property real normalPos: root.dotCount > 1 ? index / (root.dotCount - 1) : 0.5

                property bool          colorBlending: false
                property real          colorBlendProgress: 1.0
                property color         colorFrom
                property color         colorTo

                color: isFilled ? root.snapDotFilledColor : root.snapDotEmptyColor
                height: root.snapDotSize
                radius: root.snapDotSize / 2
                width: root.snapDotSize
                x: root.isHorizontal ? root.handleGap + (normalPos * root.availableTrackSize) - root.snapDotSize / 2 : (parent.width - root.snapDotSize) / 2
                y: root.isVertical ? root.handleGap + ((1 - normalPos) * root.availableTrackSize) - root.snapDotSize / 2 : (parent.height - root.snapDotSize) / 2
                z: 5
                onColorBlendProgressChanged: {
                    if (!colorBlending)
                        return;
                    if (colorBlendProgress >= 1) {
                        color         = colorTo;
                        colorBlending = false;
                    } else if (colorBlendProgress > 0) {
                        color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                    }
                }
                onIsFilledChanged: {
                    colorBlendAnim.stop();
                    colorFrom          = color;
                    colorTo            = isFilled ? root.snapDotFilledColor : root.snapDotEmptyColor;
                    colorBlending      = true;
                    colorBlendProgress = 0.0;
                    colorBlendAnim.start();
                }

                NAnim {
                    id: colorBlendAnim

                    duration: Appearance.animations.durations.small
                    from: 0.0
                    property: "colorBlendProgress"
                    target: snapDot
                    to: 1.0
                }
            }
        }
    }
    handle: StyledRect {
        id: handle

        anchors.horizontalCenter: root.isVertical ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.isHorizontal ? parent.verticalCenter : undefined
        color: Colours.m3Colors.m3Primary
        height: root.isHorizontal ? root.height : root.handleSize
        opacity: 1.0
        width: root.isHorizontal ? root.handleSize : root.width
        x: root.isHorizontal ? root.handleGap + (root.visualPosition * root.availableTrackSize) - width / 2 : 0
        y: root.isVertical ? root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackSize) - height / 2 : 0
        Behavior on height {
            enabled: root.animateChanges

            NAnim {}
        }
        Behavior on width {
            enabled: root.animateChanges

            NAnim {}
        }

        Item {
            id: valuePopupRoot

            height: valuePopupBubble.height + (root.isHorizontal ? caret.caretSize + 2 : 0)
            opacity: visible ? 1.0 : 0.0
            scale: visible ? 1.0 : 0.82
            transformOrigin: root.isHorizontal ? Item.Bottom : Item.Right
            visible: root.popupVisible
            width: valuePopupBubble.width + (root.isVertical ? caret.caretSize + 2 : 0)
            x: root.isHorizontal ? (handle.width - valuePopupBubble.width) / 2 : -(valuePopupBubble.width + caret.caretSize + 2)
            y: root.isHorizontal ? -(valuePopupBubble.height + caret.caretSize + 2) : (handle.height - valuePopupBubble.height) / 2
            z: 20
            Behavior on opacity {
                enabled: root.animateChanges

                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
            Behavior on scale {
                enabled: root.animateChanges

                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }

            StyledRect {
                id: valuePopupBubble

                readonly property real horizontalPadding: 10
                readonly property real verticalPadding: 6

                color: Colours.m3Colors.m3InverseSurface
                height: valueLabel.implicitHeight + verticalPadding * 2
                radius: Appearance.rounding.small
                width: valueLabel.implicitWidth + horizontalPadding * 2
                x: 0
                y: 0

                StyledText {
                    id: valueLabel

                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3InverseOnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.Medium
                    text: root.popupValueFormat(root.value) // qmllint disable
                }
            }

            Shape {
                id: caret

                readonly property int caretSize: 6

                height: root.isHorizontal ? caretSize : caretSize * 2
                preferredRendererType: Shape.CurveRenderer
                width: root.isHorizontal ? caretSize * 2 : caretSize

                anchors {
                    horizontalCenter: root.isHorizontal ? valuePopupBubble.horizontalCenter : undefined
                    left: root.isVertical ? valuePopupBubble.right : undefined
                    top: root.isHorizontal ? valuePopupBubble.bottom : undefined
                    verticalCenter: root.isVertical ? valuePopupBubble.verticalCenter : undefined
                }

                ShapePath {
                    fillColor: Colours.m3Colors.m3InverseSurface
                    startX: 0
                    startY: 0
                    strokeColor: "transparent"
                    strokeWidth: 0

                    // Horizontal ▼: (0,0) → (12,0) → (6,6)
                    // Vertical   ▶: (0,0) → (0,12) → (6,6)

                    PathLine {
                        x: root.isHorizontal ? caret.caretSize * 2 : 0
                        y: root.isHorizontal ? 0 : caret.caretSize * 2
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

    MouseArea {
        anchors.fill: parent
        cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        onPressed: mouse => {
            if (root.isVertical) {
                var pos      = 1 - ((mouse.y - root.topPadding) / root.availableHeight);
                pos          = Math.max(0, Math.min(1, pos));
                var newValue = root.from + (pos * (root.to - root.from));
                if (root.stepSize > 0)
                    newValue = Math.round(newValue / root.stepSize) * root.stepSize;
                root.value = newValue;
            }
            mouse.accepted = false;
        }
    }
}

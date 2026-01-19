pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Services

Loader {
    id: loader

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

    property real value: 0.0
    property real from: 0.0
    property real to: 1.0
    property real stepSize: 0.0
    property int orientation: Qt.Horizontal
    property bool snapMode: false
    property bool live: true
    property bool pressed: item ? item.pressed : false
    property real visualPosition: item ? item.visualPosition : 0.0
    property real position: item ? item.position : 0.0

    property bool dotEnd: true
    property bool useAnim: true
    property string icon: ""
    property int iconSize: 0
    property int valueWidth: orientation === Qt.Horizontal ? 200 : StyledSlide.ContainerSize.M
    property int valueHeight: orientation === Qt.Horizontal ? StyledSlide.ContainerSize.M : 200

    signal moved

    onValueChanged: {
        if (item && item.value !== value) {
            item.value = value;
        }
    }

    Connections {
        target: item
        function onValueChanged() {
            if (loader.value !== item.value) {
                loader.value = item.value;
            }
        }
        function onMoved() {
            loader.moved();
        }
        function onPressedChanged() {
            loader.pressedChanged();
        }
    }

    sourceComponent: orientation === Qt.Vertical ? verticalSlider : horizontalSlider

    // I had no idea what i'm doing
    Component {
        id: verticalSlider

        Slider {
            id: root

            hoverEnabled: true
            orientation: Qt.Vertical
            from: loader.from
            to: loader.to
            stepSize: loader.stepSize
            snapMode: loader.snapMode
            live: loader.live
            value: loader.value
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: loader.valueWidth
            implicitHeight: loader.valueHeight

            readonly property real availableTrackHeight: availableHeight - handleGap * 2
            readonly property real trackWidth: width - trackWidthDiff
            readonly property real handleHeight: pressed ? 2 : 4
            readonly property int dotCount: stepSize > 0 ? Math.floor((to - from) / stepSize) + 1 : 0
            readonly property real invertedVisualPosition: 1 - visualPosition

            property bool dotEnd: loader.dotEnd
            property real trackWidthDiff: 15
            property real handleGap: 6
            property real trackDotSize: 4
            property bool useAnim: loader.useAnim
            property string icon: loader.icon
            property int iconSize: loader.iconSize

            MouseArea {
                anchors.fill: parent
                cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                onPressed: function (mouse) {
                    // Calculate relative position from bottom
                    var pos = 1 - (mouse.y / height);
                    // Clamp between 0 and 1
                    pos = Math.max(0, Math.min(1, pos));
                    // value conversion
                    var newValue = root.from + (pos * (root.to - root.from));

                    if (root.stepSize > 0)
                        newValue = Math.round(newValue / root.stepSize) * root.stepSize;

                    root.value = newValue;
                    // Keep send event too slider when drag
                    mouse.accepted = false;
                }
            }

            background: Item {
                implicitWidth: loader.valueWidth
                implicitHeight: loader.valueHeight
                width: root.availableWidth
                height: root.availableHeight
                x: root.leftPadding
                y: root.topPadding

                Loader {
                    active: root.icon !== ""
                    z: 10
                    anchors {
                        top: parent.top
                        topMargin: 10
                        horizontalCenter: parent.horizontalCenter
                    }
                    sourceComponent: Icon {
                        icon: root.icon
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: root.iconSize || Appearance.fonts.size.large
                    }
                }

                StyledRect {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    width: root.trackWidth
                    height: root.handleGap + (root.invertedVisualPosition * root.availableTrackHeight) - (root.handleHeight / 2 + root.handleGap)
                    color: Colours.m3Colors.m3Primary
                    radius: Appearance.rounding.small * 0.5

                    bottomLeftRadius: Appearance.rounding.small * 0.5
                    bottomRightRadius: Appearance.rounding.small * 0.5
                }

                StyledRect {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                    }
                    width: root.trackWidth
                    height: root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackHeight) - (root.handleHeight / 2 + root.handleGap)
                    color: Colours.m3Colors.m3SurfaceContainerHighest
                    radius: Appearance.rounding.small * 0.5

                    topLeftRadius: Appearance.rounding.small * 0.5
                    topRightRadius: Appearance.rounding.small * 0.5
                }
            }

            handle: StyledRect {
                width: root.width
                height: root.handleHeight
                y: root.handleGap + ((1 - root.invertedVisualPosition) * root.availableTrackHeight)
                anchors.horizontalCenter: parent.horizontalCenter
                color: Colours.m3Colors.m3Primary

                Behavior on height {
                    enabled: root.useAnim
                    NAnim {}
                }
            }
        }
    }

    Component {
        id: horizontalSlider

        Slider {
            id: root

            hoverEnabled: true
            from: loader.from
            to: loader.to
            stepSize: loader.stepSize
            snapMode: loader.snapMode
            live: loader.live
            value: loader.value
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: loader.valueWidth
            implicitHeight: loader.valueHeight

            readonly property real availableTrackWidth: availableWidth - handleGap * 2
            readonly property real trackHeight: height - trackHeightDiff
            readonly property real handleWidth: pressed ? 2 : 4
            readonly property int dotCount: stepSize > 0 ? Math.floor((to - from) / stepSize) + 1 : 0

            property bool dotEnd: loader.dotEnd
            property real trackHeightDiff: 15
            property real handleGap: 6
            property real trackDotSize: 4
            property bool useAnim: loader.useAnim
            property string icon: loader.icon
            property int iconSize: loader.iconSize

            MouseArea {
                anchors.fill: parent
                onPressed: mouse => mouse.accepted = false
                cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            }

            background: Item {
                implicitWidth: loader.valueWidth
                implicitHeight: loader.valueHeight
                width: root.availableWidth
                height: root.availableHeight
                x: root.leftPadding
                y: root.topPadding

                Loader {
                    active: root.icon !== ""
                    z: 10
                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    sourceComponent: Icon {
                        icon: root.icon
                        color: Colours.m3Colors.m3OnPrimary
                        font.pixelSize: root.iconSize || Appearance.fonts.size.large
                    }
                }

                StyledRect {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                    }
                    width: root.handleGap + (root.visualPosition * root.availableTrackWidth) - (root.handleWidth / 2 + root.handleGap)
                    height: root.trackHeight
                    color: Colours.m3Colors.m3Primary
                    radius: Appearance.rounding.small * 0.5

                    topLeftRadius: Appearance.rounding.small * 0.5
                    bottomLeftRadius: Appearance.rounding.small * 0.5
                }

                StyledRect {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                    }
                    width: root.handleGap + ((1 - root.visualPosition) * root.availableTrackWidth) - (root.handleWidth / 2 + root.handleGap)
                    height: root.trackHeight
                    color: Colours.m3Colors.m3SurfaceContainerHighest
                    radius: Appearance.rounding.small * 0.5

                    topRightRadius: Appearance.rounding.small * 0.5
                    bottomRightRadius: Appearance.rounding.small * 0.5
                }
            }

            handle: StyledRect {
                width: root.handleWidth
                height: root.height
                x: root.handleGap + (root.visualPosition * root.availableTrackWidth) - width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Colours.m3Colors.m3Primary

                Behavior on width {
                    enabled: root.useAnim
                    NAnim {}
                }
            }
        }
    }
}

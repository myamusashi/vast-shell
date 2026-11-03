pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

TextField {
    id: root

    readonly property color         accentColor: hasError ? errorColor : activeFocus ? primaryColor : contentVariantColor
    readonly property int           animationDuration: Appearance.animations.durations.small
    readonly property real          containerHeight: 56
    readonly property bool          counterVisible: showCharacterCounter && maximumLength < 32767
    readonly property bool          hasError: errorText.length > 0
    readonly property bool          hasLeadingIcon: leadingIcon.name !== ""
    readonly property bool          hasTrailingIcon: trailingIcon.name !== ""
    readonly property real          horizontalPadding: Appearance.padding.large
    readonly property real          iconInset: Appearance.margin.larger
    readonly property real          iconSize: Appearance.fonts.size.large * 1.5 // 24px
    readonly property real          iconTextOffset: iconInset + iconSize + horizontalPadding
    readonly property color         indicatorColor: {
        if (hasError)
            return errorColor;
        if (activeFocus)
            return primaryColor;
        if (hovered)
            return contentColor;
        return outlined ? outlineColor : contentVariantColor;
    }
    readonly property real          inputLineHeight: 24
    readonly property bool          labelFloating: activeFocus || length > 0 || preeditText.length > 0
    readonly property IconComponent leadingIcon: IconComponent {
        iconColor: root.contentVariantColor
    }
    readonly property real          supportingAreaHeight: supportingAreaVisible ? supportingTopMargin + supportingLineHeight : 0
    readonly property bool          supportingAreaVisible: hasError || supportingText.length > 0 || counterVisible
    readonly property real          supportingLineHeight: 16
    readonly property real          supportingTopMargin: Appearance.margin.small
    readonly property IconComponent trailingIcon: IconComponent {
        iconColor: root.hasError ? root.errorColor : root.contentVariantColor
        size: Appearance.fonts.size.large
    }

    property color                  contentColor: Colours.m3Colors.m3OnSurface
    property color                  contentVariantColor: Colours.m3Colors.m3OnSurfaceVariant
    property color                  errorColor: Colours.m3Colors.m3Error
    property string                 errorText: ""
    property bool                   keyboardFocusable: true
    property string                 label: ""
    property color                  outlineColor: Colours.m3Colors.m3Outline
    property bool                   outlined: false
    property color                  primaryColor: Colours.m3Colors.m3Primary
    property bool                   showCharacterCounter: false
    property string                 supportingText: ""
    property color                  surfaceColor: Colours.m3Colors.m3Surface
    property color                  surfaceContainerHighestColor: Colours.m3Colors.m3SurfaceContainerHighest

    signal                          trailingIconClicked

    implicitWidth: 210
    implicitHeight: containerHeight + supportingAreaHeight
    leftPadding: hasLeadingIcon ? iconTextOffset : horizontalPadding
    rightPadding: hasTrailingIcon ? iconTextOffset : horizontalPadding
    topPadding: outlined || label.length === 0 ? 16 : 24
    bottomPadding: containerHeight - topPadding - inputLineHeight + supportingAreaHeight
    verticalAlignment: TextInput.AlignVCenter
    opacity: enabled ? 1 : 0.38
    color: contentColor
    selectionColor: Qt.alpha(primaryColor, 0.4)
    selectedTextColor: contentColor
    placeholderTextColor: label.length === 0 || activeFocus ? contentVariantColor : "transparent"
    font.pixelSize: 16
    font.letterSpacing: 0.5
    cursorDelegate: Rectangle {
        width: 2
        color: root.hasError ? root.errorColor : root.primaryColor
    }
    background: Item {

        Rectangle {
            visible: !root.outlined
            width: parent.width
            height: root.containerHeight
            topLeftRadius: 4
            topRightRadius: 4
            color: root.surfaceContainerHighestColor

            Rectangle {
                anchors.fill: parent
                topLeftRadius: parent.topLeftRadius
                topRightRadius: parent.topRightRadius
                color: Qt.alpha(root.contentColor, root.hovered && !root.activeFocus ? 0.08 : 0)
                Behavior on color {
                    ColorAnimation {
                        duration: root.animationDuration
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: root.activeFocus ? 2 : 1
                color: root.indicatorColor
            }
        }

        Rectangle {
            visible: root.outlined
            width: parent.width
            height: root.containerHeight
            radius: 4
            color: "transparent"
            border.width: root.activeFocus ? 2 : 1
            border.color: root.indicatorColor
        }
    }

    Loader {
        active: root.hasLeadingIcon
        x: root.iconInset
        y: (root.containerHeight - root.iconSize) / 2
        width: root.iconSize
        height: root.iconSize
        sourceComponent: Icon {
            icon: root.leadingIcon.name
            color: root.leadingIcon.iconColor
            font.pixelSize: root.leadingIcon.size
        }
    }

    Loader {
        active: root.hasTrailingIcon
        x: root.width - root.iconInset - root.iconSize
        y: (root.containerHeight - root.iconSize) / 2
        width: root.iconSize
        height: root.iconSize
        sourceComponent: Icon {
            icon: root.trailingIcon.name
            color: root.trailingIcon.iconColor
            font.pixelSize: root.trailingIcon.size
        }

        TapHandler {
            onTapped: root.trailingIconClicked()
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }

    Rectangle {
        id: labelContainer

        readonly property real floatingHeight: 16
        readonly property real floatingX: (root.outlined ? root.horizontalPadding : restingX + notchPadding) - notchPadding
        readonly property real notchPadding: root.outlined ? 4 : 0
        readonly property real restingHeight: 24
        readonly property real restingX: (root.hasLeadingIcon ? root.iconTextOffset : root.horizontalPadding) - notchPadding

        visible: root.label.length > 0
        x: root.labelFloating ? floatingX : restingX
        y: {
            if (!root.labelFloating)
                return (root.containerHeight - height) / 2;
            return root.outlined ? -height / 2 : 8;
        }
        width: labelText.implicitWidth + notchPadding * 2
        height: root.labelFloating ? floatingHeight : restingHeight
        color: root.outlined && root.labelFloating ? root.surfaceColor : "transparent"
        Behavior on x {
            NAnim {
                duration: root.animationDuration
            }
        }
        Behavior on y {
            NAnim {
                duration: root.animationDuration
            }
        }

        StyledText {
            id: labelText

            x: labelContainer.notchPadding
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.accentColor
            font.pixelSize: root.labelFloating ? 12 : 16
            font.letterSpacing: root.labelFloating ? 0.4 : 0.5
            Behavior on font.pixelSize {
                NumberAnimation {
                    duration: root.animationDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    StyledText {
        visible: root.hasError || root.supportingText.length > 0
        x: root.horizontalPadding
        y: root.containerHeight + root.supportingTopMargin
        width: root.width - root.horizontalPadding * 2 - (root.counterVisible ? counterText.implicitWidth + root.horizontalPadding : 0)
        text: root.hasError ? root.errorText : root.supportingText
        color: root.hasError ? root.errorColor : root.contentVariantColor
        elide: Text.ElideRight
        font.pixelSize: 12
        font.letterSpacing: 0.4
    }

    StyledText {
        id: counterText

        visible: root.counterVisible
        x: root.width - root.horizontalPadding - implicitWidth
        y: root.containerHeight + root.supportingTopMargin
        text: root.length + "/" + root.maximumLength
        color: root.contentVariantColor
        font.pixelSize: 12
        font.letterSpacing: 0.4
    }

    component IconComponent: QtObject {
        property color  iconColor: Colours.m3Colors.m3OnPrimary
        property string name: ""
        property double size: Appearance.fonts.size.extraLarge
    }
}

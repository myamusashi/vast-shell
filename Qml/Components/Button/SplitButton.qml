pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property color containerColor: Colours.m3Colors.m3SecondaryContainer
    property color contentColor: Colours.m3Colors.m3OnSecondaryContainer
    property alias currentIndex: menu.currentIndex
    property var disabledLabel: modelData => ""
    readonly property real distributedSegmentWidth: segmentCount > 0 ? (width - (segmentCount - 1) * 2) / segmentCount : width
    property bool fillWidth: false
    readonly property bool hasMenu: ModelAdapter.countOf(model) > 0
    property IconComponent icon: IconComponent {
    }
    readonly property int innerRadius: 8
    property var isItemEnabled: modelData => true
    property bool leadingFillsWidth: false
    readonly property bool mainHovered: mainHoverHandler.hovered
    readonly property bool mainPressed: mainTapHandler.pressed
    readonly property bool menuHovered: menuHoverHandler.hovered
    property MenuIconComponent menuIcon: MenuIconComponent {
    }
    property bool menuOpen: false
    readonly property bool menuPressed: menuTapHandler.pressed
    property var model: []
    readonly property int pressedInnerRadius: 4
    readonly property int segmentCount: ModelAdapter.countOf(model)
    readonly property int segmentHeight: 40
    property string text: ""
    property string textRole: "text"
    property int textSize: Appearance.fonts.size.normal

    signal clicked
    signal menuItemActivated(int index)

    function openMenu() {
        if (enabled && hasMenu)
            menu.open();
    }
    function toggleMenu() {
        if (!enabled || !hasMenu)
            return;
        if (menu.visible)
            menu.close();
        else
            menu.open();
    }

    implicitHeight: segmentHeight
    implicitWidth: {
        let w = mainRow.implicitWidth + 32;
        if (hasMenu)
            w += 2 + menuRow.implicitWidth + 16;
        return w;
    }
    opacity: enabled ? 1 : 0.38

    Keys.onReturnPressed: event => {
        if (enabled) {
            clicked();
            event.accepted = true;
        }
    }
    Keys.onSpacePressed: event => {
        if (enabled) {
            clicked();
            event.accepted = true;
        }
    }

    DropdownMenu {
        id: menu

        anchorItem: mainSegment
        closePolicy: Popup.CloseOnPressOutsideParent | Popup.CloseOnEscape
        disabledLabel: root.disabledLabel
        isItemEnabled: root.isItemEnabled
        maxWidth: mainSegment.width
        model: root.model
        textRole: root.textRole

        onAboutToHide: root.menuOpen = false
        onAboutToShow: root.menuOpen = true
        onActivated: index => {
            root.menuItemActivated(index);
            close();
        }
    }
    StyledRect {
        id: mainSegment

        activeFocusOnTab: root.enabled
        bottomLeftRadius: Appearance.rounding.full
        bottomRightRadius: root.mainPressed ? root.pressedInnerRadius : root.innerRadius
        color: root.containerColor
        height: root.segmentHeight
        topLeftRadius: Appearance.rounding.full
        topRightRadius: root.mainPressed ? root.pressedInnerRadius : root.innerRadius
        width: {
            if (root.leadingFillsWidth)
                return root.width - (root.hasMenu ? 2 + menuSegment.width : 0);
            if (root.fillWidth)
                return root.distributedSegmentWidth;
            return root.hasMenu ? root.implicitWidth - 2 - menuSegment.width : root.implicitWidth;
        }
        x: 0

        Behavior on bottomRightRadius {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.type: Easing.OutBack
            }
        }
        Behavior on topRightRadius {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.type: Easing.OutBack
            }
        }

        Keys.onReturnPressed: event => {
            if (root.enabled) {
                root.clicked();
                event.accepted = true;
            }
        }
        Keys.onSpacePressed: event => {
            if (root.enabled) {
                root.clicked();
                event.accepted = true;
            }
        }

        StyledRect {
            id: mainOverlay

            anchors.fill: parent
            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
            color: root.contentColor
            opacity: root.mainHovered || root.mainPressed ? (root.mainPressed ? 0.12 : 0.08) : 0
            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
        }
        Rectangle {
            anchors.fill: parent
            border.color: Colours.m3Colors.m3Primary
            border.width: 2
            bottomLeftRadius: mainSegment.bottomLeftRadius
            bottomRightRadius: mainSegment.bottomRightRadius
            color: "transparent"
            opacity: mainSegment.activeFocus ? 1 : 0
            topLeftRadius: mainSegment.topLeftRadius
            topRightRadius: mainSegment.topRightRadius
        }
        RowLayout {
            id: mainRow

            anchors.centerIn: parent
            spacing: 8

            Icon {
                color: root.contentColor
                font.pixelSize: Appearance.fonts.size.large * 1.2
                icon: root.icon.name
                visible: root.icon.name !== ""
            }
            StyledText {
                color: root.contentColor
                font.pixelSize: root.textSize
                font.weight: Font.Medium
                text: root.text
                visible: root.text !== ""
            }
        }
        HoverHandler {
            id: mainHoverHandler

            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
        TapHandler {
            id: mainTapHandler

            enabled: root.enabled

            onTapped: root.clicked()
        }
    }
    StyledRect {
        id: menuSegment

        activeFocusOnTab: root.enabled
        bottomLeftRadius: root.innerRadius
        bottomRightRadius: Appearance.rounding.full
        color: root.containerColor
        height: root.segmentHeight
        topLeftRadius: root.innerRadius
        topRightRadius: Appearance.rounding.full
        visible: root.hasMenu
        width: menuRow.implicitWidth + 16
        x: mainSegment.width + 2

        // qmllint disable
        states: [
            State {
                name: "menu_open"
                when: root.menuOpen

                PropertyChanges {
                    bottomLeftRadius: root.segmentHeight * 0.5
                    target: menuSegment
                    topLeftRadius: root.segmentHeight * 0.5
                }
            },
            State {
                name: "menu_pressed"
                when: root.menuPressed

                PropertyChanges {
                    bottomLeftRadius: root.pressedInnerRadius
                    target: menuSegment
                    topLeftRadius: root.pressedInnerRadius
                }
            }
        ]
        // qmllint enable

        transitions: Transition {
            from: "*"
            to: "*"

            NAnim {
                duration: Appearance.animations.durations.normal
                easing.type: Easing.OutBack
                properties: "topLeftRadius,bottomLeftRadius"
            }
        }

        Keys.onReturnPressed: event => {
            if (root.enabled) {
                root.toggleMenu();
                event.accepted = true;
            }
        }
        Keys.onSpacePressed: event => {
            if (root.enabled) {
                root.toggleMenu();
                event.accepted = true;
            }
        }

        StyledRect {
            id: menuOverlay

            anchors.fill: parent
            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
            color: root.contentColor
            opacity: root.menuHovered || root.menuPressed || root.menuOpen ? (root.menuPressed ? 0.12 : 0.08) : 0
            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
        }
        Rectangle {
            anchors.fill: parent
            border.color: Colours.m3Colors.m3Primary
            border.width: 2
            bottomLeftRadius: menuSegment.bottomLeftRadius
            bottomRightRadius: menuSegment.bottomRightRadius
            color: "transparent"
            opacity: menuSegment.activeFocus ? 1 : 0
            topLeftRadius: menuSegment.topLeftRadius
            topRightRadius: menuSegment.topRightRadius
        }
        RowLayout {
            id: menuRow

            anchors.centerIn: parent
            spacing: 8

            Icon {
                color: root.menuIcon.color
                font.pixelSize: root.menuIcon.size
                icon: root.menuIcon.name
                rotation: root.menuOpen ? 180 : 0

                Behavior on rotation {
                    NAnim {
                    }
                }
            }
        }
        HoverHandler {
            id: menuHoverHandler

            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
        TapHandler {
            id: menuTapHandler

            property bool wasOpen: false

            enabled: root.enabled

            onPressedChanged: if (pressed)
                wasOpen = menu.visible
            onTapped: {
                if (wasOpen)
                    menu.close();
                else
                    menu.open();
            }
        }
    }

    component IconComponent: QtObject {
        property color color: Colours.m3Colors.m3OnSecondaryContainer
        property string name: ""
        property int size: Appearance.fonts.size.large * 1.2
    }
    component MenuIconComponent: QtObject {
        property color color: Colours.m3Colors.m3OnSecondaryContainer
        property string name: "keyboard_arrow_down"
        property int size: Appearance.fonts.size.large * 1.2
    }
}

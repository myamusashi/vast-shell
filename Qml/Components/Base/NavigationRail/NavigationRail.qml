pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property string actionButtonIcon: ""
    property string actionButtonLabel: ""
    property real animatedRailWidth: expanded ? expandedWidth : compactWidth
    property color backgroundColor: Colours.m3Colors.m3SurfaceContainerLow
    readonly property real compactWidth: 80
    property int currentIndex: 0
    property bool expanded: false
    readonly property real expandedWidth: 220
    property var model: []

    signal actionButtonTriggered
    signal activated(int index)

    function sectionBaseIndex(sectionIndex) {
        let sum = 0;
        for (let i = 0; i < sectionIndex; i++)
            sum += model[i]?.items?.length ?? 0;
        return sum;
    }

    implicitHeight: parent ? parent.height : 480
    implicitWidth: animatedRailWidth

    Behavior on animatedRailWidth {
        SpringAnimation {
            damping: 0.3
            mass: 1
            spring: 3
        }
    }

    StyledRect {
        anchors.fill: parent
        color: root.backgroundColor
        radius: 0
    }
    Column {
        id: railColumn

        anchors.bottomMargin: Appearance.margin.normal
        anchors.fill: parent
        anchors.topMargin: Appearance.margin.normal
        spacing: Appearance.spacing.small

        Item {
            height: Appearance.spacing.large - Appearance.spacing.small * 2
            visible: actionButtonItem.visible
            width: 1
        }
        WrapperItem {
            id: actionButtonItem

            anchors.left: parent.left
            anchors.leftMargin: Appearance.margin.normal
            implicitHeight: 56
            visible: root.actionButtonIcon !== ""

            states: [
                State {
                    name: "compact"
                    when: !root.expanded

                    // qmllint disable Quick.property-changes-parsed
                    PropertyChanges {
                        implicitWidth: 56
                        target: actionButtonItem
                    }
                },
                State {
                    name: "expanded"
                    when: root.expanded

                    PropertyChanges {
                        implicitWidth: railColumn.width - Appearance.margin.normal * 2
                        target: actionButtonItem
                    }
                }
                // qmllint enable Quick.property-changes-parsed


            ]
            transitions: Transition {
                ParallelAnimation {
                    NAnim {
                        properties: "implicitWidth"
                    }
                }
            }

            MArea {
                layerRadius: Appearance.rounding.large
                layerRect.opacity: 0.0

                onClicked: root.actionButtonTriggered()

                StyledRect {
                    anchors.fill: parent
                    color: Colours.m3Colors.m3PrimaryContainer
                    radius: Appearance.rounding.large

                    Icon {
                        id: actionButtonLeadingIcon

                        anchors.left: parent.left
                        anchors.leftMargin: Appearance.margin.normal
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colours.m3Colors.m3OnPrimaryContainer
                        font.pixelSize: Appearance.fonts.size.larger
                        icon: root.actionButtonIcon
                    }
                    StyledText {
                        anchors.left: actionButtonLeadingIcon.right
                        anchors.leftMargin: Appearance.spacing.normal
                        anchors.right: parent.right
                        anchors.rightMargin: Appearance.margin.normal
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colours.m3Colors.m3OnPrimaryContainer
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.Medium
                        opacity: root.expanded ? 1 : 0
                        text: root.actionButtonLabel

                        Behavior on opacity {
                            NAnim {
                            }
                        }
                    }
                }
            }
        }
        Item {
            height: Appearance.spacing.large + Appearance.spacing.normal - Appearance.spacing.small * 2
            width: 1
        }
        Flickable {
            id: destinationsFlick

            boundsBehavior: Flickable.StopAtBounds
            boundsMovement: Flickable.StopAtBounds
            clip: true
            contentHeight: destinationsColumn.height
            contentWidth: width
            flickableDirection: Flickable.VerticalFlick
            height: railColumn.height - y
            width: railColumn.width

            WheelHandler {
                target: destinationsFlick

                onWheel: event => {
                    const maxY = Math.max(0, destinationsFlick.contentHeight - destinationsFlick.height);
                    destinationsFlick.contentY = Math.max(0, Math.min(maxY, destinationsFlick.contentY - event.angleDelta.y));
                }
            }
            Column {
                id: destinationsColumn

                spacing: railColumn.spacing
                width: destinationsFlick.width

                Repeater {
                    model: root.model

                    delegate: Column {
                        id: sectionColumn

                        readonly property int baseIndex: root.sectionBaseIndex(index)
                        required property int index
                        required property var modelData
                        readonly property int topGap: index === 0 ? Appearance.spacing.small : Appearance.spacing.large

                        spacing: 0
                        width: destinationsColumn.width

                        Item {
                            id: sectionHeader

                            height: root.expanded ? sectionColumn.topGap + headerLabel.implicitHeight + Appearance.spacing.small : 0
                            width: parent.width

                            Behavior on height {
                                NAnim {
                                }
                            }

                            StyledText {
                                id: headerLabel

                                anchors.left: parent.left
                                anchors.leftMargin: Appearance.margin.normal
                                anchors.right: parent.right
                                anchors.rightMargin: Appearance.margin.normal
                                anchors.verticalCenter: parent.verticalCenter
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.fonts.size.large
                                font.weight: Font.Medium
                                opacity: root.expanded ? 1 : 0
                                text: sectionColumn.modelData.label ?? ""

                                Behavior on opacity {
                                    NAnim {
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: sectionColumn.modelData.items ?? []

                            delegate: NavigationRailItem {
                                required property int index
                                required property var modelData

                                badgeDot: modelData.badgeDot ?? false
                                badgeText: modelData.badgeText ?? ""
                                expanded: root.expanded
                                height: implicitHeight
                                icon: modelData.icon ?? ""
                                label: modelData.label ?? ""
                                selected: sectionColumn.baseIndex + index === root.currentIndex
                                width: destinationsColumn.width - (root.expanded ? Appearance.margin.normal : Appearance.margin.smaller) * 2
                                x: (destinationsColumn.width - width) / 2

                                onTriggered: {
                                    root.currentIndex = sectionColumn.baseIndex + index;
                                    root.activated(sectionColumn.baseIndex + index);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

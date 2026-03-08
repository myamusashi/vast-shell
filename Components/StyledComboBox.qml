pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

ComboBox {
    id: root

    readonly property string displayText_: {
        if (root.currentIndex < 0)
            return root.placeholderText;
        const m = root.model;
        if (!m)
            return root.placeholderText;
        const item = m.get ? m.get(root.currentIndex) : m[root.currentIndex];
        if (!item)
            return root.placeholderText;
        return item[root.textRole] ?? root.placeholderText;
    }
    property string placeholderText: qsTr("Select…")
    property real popupMaxHeight: 280
    property var isItemEnabled: modelData => true
    property var disabledLabel: modelData => qsTr("N/A")
    property var isItemActive: (modelData, itemIndex) => itemIndex === root.currentIndex

    textRole: "display"
    valueRole: ""
    onCurrentValueChanged: _syncIndex()
    onModelChanged: Qt.callLater(_syncIndex)

    function _syncIndex() {
        if (root.valueRole === "" || root.currentValue === null)
            return;
        const count = root.model?.count ?? root.model?.length ?? 0;
        for (let i = 0; i < count; i++) {
            const v = root.model.get ? root.model.get(i)[root.valueRole] : root.model[i]?.[root.valueRole];
            if (v === root.currentValue) {
                root.currentIndex = i;
                return;
            }
        }
    }

    contentItem: Item {
        implicitHeight: 48

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - root.indicator.width - 16
            text: root.displayText_
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            color: Colours.m3Colors.m3OnSecondaryContainer
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    background: StyledRect {
        implicitWidth: 280
        implicitHeight: 48
        color: "transparent"
    }

    indicator: Item {
        x: root.width - width - 16
        y: (root.height - height) / 2
        width: 24
        height: 24

        Icon {
            anchors.centerIn: parent
            icon: "keyboard_arrow_down"
            font.pixelSize: Appearance.fonts.size.extraLarge
            color: Colours.m3Colors.m3OnSecondaryContainer
            rotation: root.popup.visible ? 180 : 0

            Behavior on rotation {
                NAnim {
                    duration: Appearance.animations.durations.normal
                }
            }
        }
    }

    popup: Popup {
        y: root.height + 4
        implicitWidth: root.width
        implicitHeight: Math.min(itemListView.contentHeight + 16, root.popupMaxHeight)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            id: bgPopup

            color: Colours.m3Colors.m3SurfaceContainerLow
            radius: Appearance.rounding.large

            Elevation {
                anchors.fill: parent
                z: -1
                level: 2
                radius: bgPopup.radius
            }
        }

        contentItem: ListView {
            id: itemListView

            clip: true
            Layout.fillHeight: true
            cacheBuffer: 0
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.currentIndex

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: StyledRect {
                    implicitWidth: 4
                    radius: 2
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
                }
            }

            header: Item {
                height: 8
            }
            footer: Item {
                height: 8
            }

            delegate: ItemDelegate {
                id: menuDelegate

                required property var modelData
                required property int index

                readonly property bool itemEnabled: root.isItemEnabled(modelData)
                readonly property bool itemActive: root.isItemActive(modelData, index)

                width: itemListView.width
                height: 52
                leftPadding: 16
                rightPadding: 16
                topPadding: 0
                bottomPadding: 0
                highlighted: root.highlightedIndex === index
                enabled: itemEnabled

                background: StyledRect {
                    radius: Appearance.rounding.large
                    color: menuDelegate.itemActive ? Colours.m3Colors.m3TertiaryContainer : "transparent"

                    Behavior on color {
                        CAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }
                }

                contentItem: RowLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: menuDelegate.modelData[root.textRole] ?? ""
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: menuDelegate.highlighted ? Font.Medium : Font.Normal
                        color: !menuDelegate.itemEnabled ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38) : menuDelegate.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight

                        Behavior on color {
                            CAnim {
                                duration: Appearance.animations.durations.small
                            }
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignRight
                        Layout.rightMargin: Appearance.margin.large

                        StyledRect {
                            anchors.centerIn: parent
                            visible: !menuDelegate.itemEnabled
                            implicitWidth: badgeLabel.implicitWidth + 12
                            implicitHeight: 20
                            radius: Appearance.rounding.normal

                            StyledText {
                                id: badgeLabel

                                anchors.centerIn: parent
                                text: root.disabledLabel(menuDelegate.modelData)
                                font.pixelSize: Appearance.fonts.size.small
                                font.weight: Font.Medium
                                color: Colours.m3Colors.m3Error
                            }
                        }

                        Icon {
                            anchors.centerIn: parent
                            icon: "check"
                            font.pixelSize: Appearance.fonts.size.large * 1.3
                            color: Colours.m3Colors.m3Primary
                            visible: menuDelegate.itemActive
                            scale: visible ? 1.0 : 0.0

                            Behavior on scale {
                                NAnim {
                                    duration: Appearance.animations.durations.small
                                }
                            }
                        }
                    }
                }

                onClicked: {
                    if (!menuDelegate.itemEnabled)
                        return;
                    root.currentIndex = index;
                    root.activated(index);
                    root.popup.close();
                }
            }
        }

        enter: Transition {
            NAnim {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animations.durations.small
            }
            NAnim {
                property: "scale"
                from: 0.95
                to: 1
                duration: Appearance.animations.durations.small
            }
        }
        exit: Transition {
            NAnim {
                property: "opacity"
                from: 1
                to: 0
                duration: Appearance.animations.durations.small
            }
        }
    }
}

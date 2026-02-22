pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

ComboBox {
    id: profilesComboBox

    model: ScriptModel {
        values: [...Audio.models]
    }
    textRole: "readable"
    onActivated: index => {
        const profile = Audio.models[index];
        if (!profile || profile.available !== "yes")
            return;

        Quickshell.execDetached({
            command: ["pw-cli", "set-param", Audio.idPipewire, "Profile", `{ "index": ${profile.index} }`]
        });

        Audio.activeProfileIndex = profile.index;
    }

    contentItem: Item {
        implicitHeight: 48

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - profilesComboBox.indicator.width - 16
            text: {
                const active = Audio.models.find(m => m.index === Audio.activeProfileIndex);
                return active ? active.readable : qsTr("No profile");
            }
            font.weight: Font.Medium
            font.pixelSize: Appearance.fonts.size.normal
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
        x: profilesComboBox.width - width - 16
        y: (profilesComboBox.height - height) / 2
        width: 24
        height: 24

        Icon {
            anchors.centerIn: parent
            icon: "keyboard_arrow_down"
            font.pixelSize: Appearance.fonts.size.extraLarge
            color: Colours.m3Colors.m3OnSecondaryContainer
            rotation: profilesComboBox.popup.visible ? 180 : 0

            Behavior on rotation {
                NAnim {
                    duration: Appearance.animations.durations.normal
                }
            }
        }
    }

    popup: Popup {
        y: profilesComboBox.height + 4
        implicitWidth: profilesComboBox.width
        implicitHeight: Math.min(itemListView.contentHeight + 16, 280)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: StyledRect {
            color: Colours.m3Colors.m3SurfaceContainerLow
            radius: Appearance.rounding.large

            Elevation {
                anchors.fill: parent
                z: -1
                level: 2
                radius: parent.radius
            }
        }
        contentItem: ListView {
            id: itemListView

            clip: true
            implicitHeight: contentHeight
            model: profilesComboBox.popup.visible ? profilesComboBox.delegateModel : null
            currentIndex: profilesComboBox.currentIndex
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: StyledRect {
                    implicitWidth: 4
                    radius: 2
                    color: Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.38)
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

                width: itemListView.width
                height: 52
                leftPadding: 16
                rightPadding: 16
                topPadding: 0
                bottomPadding: 0
                highlighted: profilesComboBox.highlightedIndex === index
                enabled: modelData.available === "yes"
                background: StyledRect {
                    id: itemBg

                    radius: Appearance.rounding.large
                    height: parent.height
                    color: Audio.activeProfileIndex === menuDelegate.index ? Colours.m3Colors.m3TertiaryContainer : "transparent"

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
                        text: menuDelegate.modelData.readable
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: menuDelegate.highlighted ? Font.Medium : Font.Normal
                        color: !menuDelegate.enabled ? Colours.withAlpha(Colours.m3Colors.m3OnSurface, 0.38) : menuDelegate.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
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
                            visible: menuDelegate.modelData.available !== "yes"
                            implicitWidth: unavailableLabel.implicitWidth
                            implicitHeight: 20
                            radius: 10

                            StyledText {
                                id: unavailableLabel

                                anchors.centerIn: parent
                                text: qsTr("N/A")
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
                            visible: {
                                const active = Audio.models.find(m => m.index === Audio.activeProfileIndex);
                                return active && active.readable === menuDelegate.modelData.readable;
                            }
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
                    if (!modelData || modelData.available !== "yes")
                        return;
                    profilesComboBox.currentIndex = index;
                    profilesComboBox.activated(index);
                    profilesComboBox.popup.close();
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

import AnotherRipple
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

MenuItem {
    id: root

    property alias trailingIcon: trailingIconItem.icon

    implicitWidth: 200
    implicitHeight: 48

    background: Rectangle {
        id: bgRect
        property color c0From
        property color c0To
        property bool c0Active: false
        property real c0Blend: 1.0

        onC0BlendChanged: {
            if (!c0Active)
                return;
            if (c0Blend >= 1) {
                color = c0To;
                c0Active = false;
            } else if (c0Blend > 0) {
                color = Colours.blendColors(c0From, c0To, c0Blend);
            }
        }

        NAnim {
            id: c0Anim
            target: bgRect
            property: "c0Blend"
            from: 0.0
            to: 1.0
            duration: Appearance.animations.durations.small
        }

        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.small
        }
        radius: Appearance.rounding.normal
        property color bgTarget: root.highlighted ? Colours.m3Colors.m3SecondaryContainer : "transparent"

        onBgTargetChanged: {
            c0Anim.stop();
            c0From = bgRect.color;
            c0To = bgTarget;
            c0Active = true;
            c0Blend = 0.0;
            c0Anim.start();
        }

        Rectangle {
            id: innerRect
            property color c1From
            property color c1To
            property bool c1Active: false
            property real c1Blend: 1.0

            onC1BlendChanged: {
                if (!c1Active)
                    return;
                if (c1Blend >= 1) {
                    color = c1To;
                    c1Active = false;
                } else if (c1Blend > 0) {
                    color = Colours.blendColors(c1From, c1To, c1Blend);
                }
            }

            NAnim {
                id: c1Anim
                target: innerRect
                property: "c1Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            anchors.fill: parent
            radius: parent.radius

            property color innerTarget: trailingIconItem.icon === "" ? "transparent" : Colours.m3Colors.m3SurfaceContainerHighest

            onInnerTargetChanged: {
                c1Anim.stop();
                c1From = innerRect.color;
                c1To = innerTarget;
                c1Active = true;
                c1Blend = 0.0;
                c1Anim.start();
            }
        }
    }

    contentItem: RowLayout {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight

        StyledText {
            id: labelText
            property color c2From
            property color c2To
            property bool c2Active: false
            property real c2Blend: 1.0

            onC2BlendChanged: {
                if (!c2Active)
                    return;
                if (c2Blend >= 1) {
                    color = c2To;
                    c2Active = false;
                } else if (c2Blend > 0) {
                    color = Colours.blendColors(c2From, c2To, c2Blend);
                }
            }

            NAnim {
                id: c2Anim
                target: labelText
                property: "c2Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Appearance.margin.normal

            text: root.text
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            font.letterSpacing: 0.15
            elide: StyledText.ElideRight
            verticalAlignment: StyledText.AlignVCenter

            property color labelTarget: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface

            onLabelTargetChanged: {
                c2Anim.stop();
                c2From = labelText.color;
                c2To = labelTarget;
                c2Active = true;
                c2Blend = 0.0;
                c2Anim.start();
            }
        }

        Item {
            Layout.alignment: Qt.AlignCenter
            implicitWidth: 30
            implicitHeight: 30

            Icon {
                id: checkIcon
                property color c3From
                property color c3To
                property bool c3Active: false
                property real c3Blend: 1.0

                onC3BlendChanged: {
                    if (!c3Active)
                        return;
                    if (c3Blend >= 1) {
                        color = c3To;
                        c3Active = false;
                    } else if (c3Blend > 0) {
                        color = Colours.blendColors(c3From, c3To, c3Blend);
                    }
                }

                NAnim {
                    id: c3Anim
                    target: checkIcon
                    property: "c3Blend"
                    from: 0.0
                    to: 1.0
                    duration: Appearance.animations.durations.small
                }

                anchors.centerIn: parent
                icon: "check_box_outline_blank"
                font.pixelSize: Appearance.fonts.size.large

                property color checkTarget: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

                onCheckTargetChanged: {
                    c3Anim.stop();
                    c3From = checkIcon.color;
                    c3To = checkTarget;
                    c3Active = true;
                    c3Blend = 0.0;
                    c3Anim.start();
                }
            }

            Icon {
                id: trailingIconItem
                property color c4From
                property color c4To
                property bool c4Active: false
                property real c4Blend: 1.0

                onC4BlendChanged: {
                    if (!c4Active)
                        return;
                    if (c4Blend >= 1) {
                        color = c4To;
                        c4Active = false;
                    } else if (c4Blend > 0) {
                        color = Colours.blendColors(c4From, c4To, c4Blend);
                    }
                }

                NAnim {
                    id: c4Anim
                    target: trailingIconItem
                    property: "c4Blend"
                    from: 0.0
                    to: 1.0
                    duration: Appearance.animations.durations.small
                }

                anchors.centerIn: parent
                icon: ""
                font.pixelSize: Appearance.fonts.size.large

                property color trailTarget: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                visible: root.trailingIcon !== ""

                onTrailTargetChanged: {
                    c4Anim.stop();
                    c4From = trailingIconItem.color;
                    c4To = trailTarget;
                    c4Active = true;
                    c4Blend = 0.0;
                    c4Anim.start();
                }
            }
        }
    }

    SimpleRipple {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.small
        }
        color: Colours.m3Colors.m3OnSurface
        xClipRadius: Appearance.rounding.normal
        yClipRadius: Appearance.rounding.normal
    }
}

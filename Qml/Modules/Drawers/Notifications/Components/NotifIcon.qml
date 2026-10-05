pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    readonly property bool hasAppIcon: modelData.appIcon?.length > 0
    readonly property bool hasImage: modelData.image?.length > 0
    required property var modelData

    implicitHeight: 40
    implicitWidth: 40

    ClippingRectangle {
        anchors.centerIn: parent
        color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : root.modelData.urgency === NotificationUrgency.Low ? Colours.m3Colors.m3SecondaryContainer : Colours.m3Colors.m3PrimaryContainer
        implicitHeight: 40
        implicitWidth: 40
        radius: Appearance.rounding.full

        Loader {
            active: true
            anchors.fill: parent
            sourceComponent: {
                if (root.hasImage)
                    return imageComponent;
                return fallbackIconComponent;
            }
        }
    }
    Component {
        id: imageComponent

        IconImage {
            asynchronous: true
            backer.cache: true
            implicitSize: 36
            source: Qt.resolvedUrl(root.modelData.image)
        }
    }
    Component {
        id: iconComponent

        IconImage {
            asynchronous: true
            backer.cache: true
            implicitSize: 24
            source: Quickshell.iconPath(root.modelData.appIcon)
        }
    }
    Component {
        id: fallbackIconComponent

        IconImage {
            asynchronous: true
            backer.cache: true
            implicitSize: 30
            source: root.hasAppIcon ? Quickshell.iconPath(root.modelData.appIcon) : root.modelData.image
        }
    }
    Loader {
        id: appIcon

        active: root.hasImage && root.hasAppIcon
        height: 20
        width: 20
        z: 1

        sourceComponent: StyledRect {
            color: Colours.m3Colors.m3Surface
            implicitHeight: 20
            implicitWidth: 20
            radius: 10

            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1.5
            }
            ClippingWrapperRectangle {
                anchors.centerIn: parent
                implicitHeight: 16
                implicitWidth: 16
                radius: 8

                IconImage {
                    asynchronous: true
                    backer.cache: true
                    implicitSize: 16
                    source: Quickshell.iconPath(root.modelData.appIcon)
                }
            }
        }

        anchors {
            bottom: parent.bottom
            bottomMargin: -4
            right: parent.right
            rightMargin: -4
        }
    }
}

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

    required property var modelData
    readonly property bool hasImage: modelData.image?.length > 0
    readonly property bool hasAppIcon: modelData.appIcon?.length > 0
    implicitWidth: 40
    implicitHeight: 40

    ClippingRectangle {
        anchors.centerIn: parent
        implicitWidth: 40
        implicitHeight: 40
        radius: Appearance.rounding.full
        color: root.modelData.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : root.modelData.urgency === NotificationUrgency.Low ? Colours.m3Colors.m3SecondaryContainer : Colours.m3Colors.m3PrimaryContainer

        Loader {
            anchors.fill: parent
            active: true
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
            implicitSize: 36
            source: Qt.resolvedUrl(root.modelData.image)
            backer.cache: true
            asynchronous: true
        }
    }

    Component {
        id: iconComponent

        IconImage {
            implicitSize: 24
            source: Quickshell.iconPath(root.modelData.appIcon)
            backer.cache: true
            asynchronous: true
        }
    }

    Component {
        id: fallbackIconComponent

        IconImage {
            implicitSize: 30
            source: root.hasAppIcon ? Quickshell.iconPath(root.modelData.appIcon) : "root:/Assets/images/notif-icon-image-fallback.jpg"
            backer.cache: true
            asynchronous: true
        }
    }

    Loader {
        id: appIcon

        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: -4
            bottomMargin: -4
        }
        active: root.hasImage && root.hasAppIcon
        width: 20
        height: 20
        z: 1
        sourceComponent: StyledRect {
            implicitWidth: 20
            implicitHeight: 20
            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1.5
            }
            radius: 10
            color: Colours.m3Colors.m3Surface

            ClippingWrapperRectangle {
                anchors.centerIn: parent
                radius: 8
                implicitWidth: 16
                implicitHeight: 16

                IconImage {
                    implicitSize: 16
                    source: Quickshell.iconPath(root.modelData.appIcon)
                    backer.cache: true
                    asynchronous: true
                }
            }
        }
    }
}

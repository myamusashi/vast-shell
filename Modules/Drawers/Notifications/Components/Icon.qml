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
                if (root.hasAppIcon)
                    return iconComponent;
                return fallbackIconComponent;
            }
        }
    }

    Component {
        id: imageComponent

        Image {
            width: 36
            height: 36
            source: Qt.resolvedUrl(root.modelData.image)
            fillMode: Image.PreserveAspectFit
            cache: true
            asynchronous: true
            sourceSize: Qt.size(36, 36)
        }
    }

    Component {
        id: iconComponent

        Image {
            width: 24
            height: 24
            source: Quickshell.iconPath(root.modelData.appIcon)
            fillMode: Image.PreserveAspectFit
            cache: true
            asynchronous: true
            sourceSize: Qt.size(24, 24)
        }
    }

    Component {
        id: fallbackIconComponent

        Image {
            width: 30
            height: 30
            source: "root:/Assets/images/notif-icon-image-fallback.jpg"
            fillMode: Image.PreserveAspectFit
            cache: true
            asynchronous: true
            sourceSize: Qt.size(30, 30)
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
            radius: 10
            color: Colours.m3Colors.m3Surface
            border.color: Colours.m3Colors.m3OutlineVariant
            border.width: 1.5
            ClippingRectangle {
                anchors.centerIn: parent
                radius: 8
                implicitWidth: 16
                implicitHeight: 16
                Image {
                    anchors.fill: parent
                    source: Quickshell.iconPath(root.modelData.appIcon)
                    fillMode: Image.PreserveAspectFit
                    cache: true
                    asynchronous: true
                    sourceSize: Qt.size(16, 16)
                }
            }
        }
    }
}

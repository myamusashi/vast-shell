pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import M3Shapes

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

RowLayout {
    id: privacyRowLayout

    spacing: Appearance.spacing.small

    visible: PrivacyServices.activeAppNames.length > 0 || Configs.privacy.enablePrivacyIndicator

    MaterialShape {
        implicitWidth: 10
        implicitHeight: 10
        shape: MaterialShape.Circle
        animationDuration: 0
        color: Colours.m3Colors.m3Error
        visible: PrivacyServices.activeAppNames.length > 0
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        type: Icon.Material
        icon: "videocam"
        visible: PrivacyServices.screenshareAppNames.length > 0
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.larger
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        type: Icon.Material
        icon: "mic"
        visible: PrivacyServices.audioInAppNames.length > 0
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.larger
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        type: Icon.Material
        icon: "volume_up"
        visible: PrivacyServices.audioOutAppNames.length > 0
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.larger
    }

    Item {
        id: marquee

        readonly property real maxViewportWidth: 240
        readonly property real gap: 32

        readonly property bool overflowing: content.implicitWidth > maxViewportWidth

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: 20
        Layout.preferredWidth: Math.min(content.implicitWidth, maxViewportWidth)
        visible: PrivacyServices.activeAppNames.length > 0
        clip: true

        Row {
            id: scroller

            height: parent.height
            spacing: marquee.gap

            property real scrollOffset: 0
            x: scrollOffset

            Row {
                id: content

                spacing: Appearance.spacing.small
                height: parent.height

                Repeater {
                    model: PrivacyServices.activeAppNames

                    delegate: appDelegate
                }
            }

            Row {
                id: contentCopy

                visible: marquee.overflowing
                spacing: Appearance.spacing.small
                height: parent.height

                Repeater {
                    model: PrivacyServices.activeAppNames

                    delegate: appDelegate
                }
            }

            SequentialAnimation {
                id: scrollAnim

                running: marquee.overflowing && marquee.visible
                loops: Animation.Infinite

                PauseAnimation {
                    duration: 5000
                }

                NumberAnimation {
                    target: scroller
                    property: "scrollOffset"
                    from: 0
                    to: -(content.implicitWidth + marquee.gap)
                    duration: (content.implicitWidth + marquee.gap) / 40 * 1000
                    easing.type: Easing.Linear
                }
            }
        }

        Connections {
            target: PrivacyServices

            function onActiveAppNamesChanged() {
                scrollAnim.stop();
                scroller.scrollOffset = 0;
                if (marquee.overflowing && marquee.visible)
                    scrollAnim.start();
            }
        }
    }

    Component {
        id: appDelegate

        RowLayout {
            id: entry

            required property string modelData

            spacing: Appearance.spacing.small

            IconImage {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                visible: Configs.privacy.enablePrivacyIcon
                source: IconUtils.iconForId(entry.modelData)
                asynchronous: true
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: entry.modelData
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurface
            }
        }
    }
}

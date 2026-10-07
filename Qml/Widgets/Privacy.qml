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
        animationDuration: 0
        color: Colours.m3Colors.m3Error
        implicitHeight: 10
        implicitWidth: 10
        shape: MaterialShape.Circle
        visible: PrivacyServices.activeAppNames.length > 0
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.larger
        icon: "videocam"
        type: Icon.Material
        visible: PrivacyServices.screenshareAppNames.length > 0
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.larger
        icon: "mic"
        type: Icon.Material
        visible: PrivacyServices.audioInAppNames.length > 0
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.larger
        icon: "volume_up"
        type: Icon.Material
        visible: PrivacyServices.audioOutAppNames.length > 0
    }

    Item {
        id: marquee

        readonly property real gap: 32
        readonly property real maxViewportWidth: 240
        readonly property bool overflowing: content.implicitWidth > maxViewportWidth

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: 20
        Layout.preferredWidth: Math.min(content.implicitWidth, maxViewportWidth)
        clip: true
        visible: PrivacyServices.activeAppNames.length > 0

        Row {
            id: scroller

            property real scrollOffset: 0

            height: parent.height
            spacing: marquee.gap
            x: scrollOffset

            Row {
                id: content

                height: parent.height
                spacing: Appearance.spacing.small

                Repeater {
                    delegate: appDelegate
                    model: PrivacyServices.activeAppNames
                }
            }

            Row {
                id: contentCopy

                height: parent.height
                spacing: Appearance.spacing.small
                visible: marquee.overflowing

                Repeater {
                    delegate: appDelegate
                    model: PrivacyServices.activeAppNames
                }
            }

            SequentialAnimation {
                id: scrollAnim

                loops: Animation.Infinite
                running: marquee.overflowing && marquee.visible

                PauseAnimation {
                    duration: 5000
                }

                NumberAnimation {
                    duration: (content.implicitWidth + marquee.gap) / 40 * 1000
                    easing.type: Easing.Linear
                    from: 0
                    property: "scrollOffset"
                    target: scroller
                    to: -(content.implicitWidth + marquee.gap)
                }
            }
        }

        Connections {
            function onActiveAppNamesChanged() {
                scrollAnim.stop();
                scroller.scrollOffset = 0;
                if (marquee.overflowing && marquee.visible)
                    scrollAnim.start();
            }

            target: PrivacyServices
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
                Layout.preferredHeight: 20
                Layout.preferredWidth: 20
                asynchronous: true
                source: IconUtils.iconForId(entry.modelData)
                visible: Configs.privacy.enablePrivacyIcon
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: entry.modelData
            }
        }
    }
}

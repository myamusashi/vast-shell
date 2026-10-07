pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Effects

ColumnLayout {
    id: root

    required property PwNode node

    readonly property real   peak: peakMonitor.peak
    readonly property real   vol: node.audio.volume

    property bool            isCurrent: false
    property bool            selectable: false

    signal                   defaultRequested

    function                 dbText(v) {
        if (v <= 0.00001)
            return "-∞ dB";
        const db = 20 * Math.log10(v);
        return (db >= 0 ? "+" : "") + db.toFixed(1) + " dB";
    }

    PwObjectTracker {
        id: objectTracker

        objects: [root.node]
    }

    PwNodePeakMonitor {
        id: peakMonitor

        enabled: Configs.audio.showPeakLevels
        node: root.node
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        StyledRect {
            id: defaultIndicator

            property color target: root.isCurrent ? Colours.m3Colors.m3Primary : "transparent"

            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 18
            Layout.preferredWidth: 18
            border.color: Colours.m3Colors.m3Primary
            border.width: 2
            color: "transparent"
            radius: width / 2
            visible: root.selectable

            BlendColor {
                host: defaultIndicator
                target: defaultIndicator.target
            }

            TapHandler {
                onTapped: root.defaultRequested()
            }
        }

        StyledRect {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 36
            Layout.preferredWidth: 36
            radius: Appearance.rounding.full

            Icon {
                anchors.centerIn: parent
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                icon: Audio.getIcon(root.node)
            }

            MArea {
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        Audio.toggleMute(root.node);
                }
                onWheel: mouse => Audio.wheelAction(mouse, root.node)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.normal
                text: root.node.description || root.node.nickname || root.node.name
            }

            StyledText {
                id: percentText

                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: VolumeUtils.toPercent(root.vol) + "% · " + root.dbText(root.vol)
            }
        }
    }

    StyledSlide {
        id: volumeSlider

        Layout.fillWidth: true
        Layout.preferredHeight: 36
        from: 0
        popupValueFormat: v => VolumeUtils.toPercent(v) + "%"
        stepSize: 0.01
        to: 1.5
        value: root.vol
        onMoved: root.node.audio.volume = value
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 4
        color: Colours.m3Colors.m3SurfaceContainerHighest
        radius: height / 2
        visible: Configs.audio.showPeakLevels

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.top: parent.top
            color: root.peak > 0.98 ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Primary
            opacity: root.node.audio.muted ? 0.25 : 1.0
            radius: parent.radius
            width: parent.width * Math.min(root.peak, 1.0)
        }
    }
}

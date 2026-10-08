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
    id: root

    property real                  islandRadius: Appearance.rounding.full

    // "screenshare" | "audioIn" | "audioOut"
    required property string       kind

    readonly property list<string> kindAppNames: {
        if (kind === "audioIn")
            return PrivacyServices.audioInAppNames;
        if (kind === "audioOut")
            return PrivacyServices.audioOutAppNames;
        return PrivacyServices.screenshareAppNames;
    }
    readonly property string       kindIcon: kind === "audioIn" ? "mic" : kind === "audioOut" ? "volume_up" : "videocam"
    readonly property string       kindLabel: kind === "audioIn" ? qsTr("Mic is on") : kind === "audioOut" ? qsTr("Speaker is on") : qsTr("Screen share is on")

    implicitHeight: childrenRect.height + Appearance.spacing.normal
    implicitWidth: childrenRect.width + Appearance.spacing.large

    anchors {
        fill: parent
        leftMargin: Appearance.margin.normal
        rightMargin: Appearance.margin.normal
    }

    MaterialShape {
        Layout.alignment: Qt.AlignVCenter
        animationDuration: 0
        color: Colours.m3Colors.m3Error
        implicitHeight: 10
        implicitWidth: 10
        shape: MaterialShape.Circle
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.normal
        icon: root.kindIcon
        type: Icon.Material
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.normal
        text: root.kindLabel
    }

    Repeater {
        model: root.kindAppNames
        delegate: RowLayout {
            required property string modelData

            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.small

            IconImage {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 32
                Layout.preferredWidth: 32
                asynchronous: true
                source: IconUtils.iconForId(parent.modelData)
                visible: Configs.privacy.enablePrivacyIcon
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 160
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.normal
                text: parent.modelData
            }
        }
    }
}

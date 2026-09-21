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

    anchors {
        fill: parent
        leftMargin: Appearance.margin.normal
        rightMargin: Appearance.margin.normal
    }

    implicitWidth: childrenRect.width + Appearance.spacing.large
    implicitHeight: childrenRect.height + Appearance.spacing.normal

    property real islandRadius: Appearance.rounding.full

    // "screenshare" | "audioIn" | "audioOut"
    required property string kind

    readonly property list<string> kindAppNames: {
        if (kind === "audioIn")
            return PrivacyServices.audioInAppNames;
        if (kind === "audioOut")
            return PrivacyServices.audioOutAppNames;
        return PrivacyServices.screenshareAppNames;
    }

    readonly property string kindIcon: kind === "audioIn" ? "mic" : kind === "audioOut" ? "volume_up" : "videocam"
    readonly property string kindLabel: kind === "audioIn" ? qsTr("Mic is on") : kind === "audioOut" ? qsTr("Speaker is on") : qsTr("Screen share is on")

    MaterialShape {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 10
        implicitHeight: 10
        shape: MaterialShape.Circle
        animationDuration: 0
        color: Colours.m3Colors.m3Error
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        type: Icon.Material
        icon: root.kindIcon
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.normal
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: root.kindLabel
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.normal
    }

    Repeater {
        model: root.kindAppNames

        delegate: RowLayout {
            required property string modelData

            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.small

            IconImage {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                visible: Configs.privacy.enablePrivacyIcon
                source: IconUtils.iconForId(parent.modelData)
                asynchronous: true
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 160
                text: parent.modelData
                font.pixelSize: Appearance.fonts.size.normal
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
            }
        }
    }
}

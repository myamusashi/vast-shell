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

    MaterialShape {
        implicitWidth: 10
        implicitHeight: 10
        shape: MaterialShape.Circle
        animationDuration: 0
        color: Colours.m3Colors.m3Error
        visible: PrivacyServices.privacyActive
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        type: Icon.Material
        icon: "videocam"
        visible: PrivacyServices.screenshare.length > 0
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.larger
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        type: Icon.Material
        icon: "mic"
        visible: PrivacyServices.audioIn.length > 0
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.larger
    }

    Icon {
        Layout.alignment: Qt.AlignVCenter
        type: Icon.Material
        icon: "volume_up"
        visible: PrivacyServices.audioOut.length > 0
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.larger
    }

    Repeater {
        model: PrivacyServices.activeAppNames

        delegate: RowLayout {
            required property string modelData

            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.small

            IconImage {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
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

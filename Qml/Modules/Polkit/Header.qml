import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Services

RowLayout {
    implicitWidth: parent.width

    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 48
        Layout.preferredWidth: 48
        color: Qt.alpha(Colours.m3Colors.m3Primary, 0.12)
        radius: Appearance.rounding.full

        IconImage {
            anchors.centerIn: parent
            asynchronous: true
            height: 28
            source: PolAgent.agent?.flow?.iconName ? Quickshell.iconPath(PolAgent.agent.flow.iconName) : "" // qmllint disable
            width: 28
        }
    }

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.larger
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Authentication Is Required")
        }

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Normal
            horizontalAlignment: Text.AlignHCenter
            text: PolAgent.agent?.flow?.message || qsTr("<no message>") // qmllint disable
            wrapMode: Text.Wrap
        }
    }
}

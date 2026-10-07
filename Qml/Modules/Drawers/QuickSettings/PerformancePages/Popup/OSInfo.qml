import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    icon: "developer_board"
    text: qsTr("Operating system")
    content: ColumnLayout {

        Repeater {
            model: [
                {
                    text: qsTr("Distro version"),
                    value: SystemUsage.osPrettyName
                },
                {
                    text: qsTr("kernel name"),
                    value: SystemUsage.kernelName
                },
                {
                    text: qsTr("architecture design"),
                    value: SystemUsage.archDesign
                }
            ]
            delegate: RowLayout {
                required property var    modelData

                readonly property string text: modelData.text
                readonly property string value: modelData.value

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: parent.text + ": "
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: parent.value
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}

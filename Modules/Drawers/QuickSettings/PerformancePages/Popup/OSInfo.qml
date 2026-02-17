import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components

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
                },
                {
                    text: qsTr("CPU flags"),
                    value: SystemUsage.cpuFlags
                },
            ]
            delegate: RowLayout {
                required property var modelData
                readonly property string text: modelData.text
                readonly property string value: modelData.value

                StyledText {
                    text: parent.text + ": "
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                }

                StyledText {
                    Layout.fillWidth: true
                    text: parent.value
                    color: Colours.m3Colors.m3OnSurface
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}

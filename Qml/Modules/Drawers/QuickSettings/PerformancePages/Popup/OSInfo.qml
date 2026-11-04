pragma ComponentBehavior: Bound

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
            model: [qsTr("Distro version"), qsTr("kernel name"), qsTr("architecture design")]
            delegate: RowLayout {
                id: osRow

                required property int    index
                required property string modelData

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: osRow.modelData + ": "
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: osRow.index === 0 ? SystemUsage.osPrettyName : osRow.index === 1 ? SystemUsage.kernelName : SystemUsage.archDesign
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}

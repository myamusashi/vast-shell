pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property bool active

    implicitWidth: draggingRowLayout.implicitWidth + 32
    implicitHeight: 44

    RowLayout {
        id: draggingRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        Icon {
            icon: "upload_file"
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3Primary
        }

        StyledText {
            text: qsTr("Drop files to share")
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurface
        }
    }
}

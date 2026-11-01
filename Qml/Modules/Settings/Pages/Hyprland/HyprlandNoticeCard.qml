pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Rectangle {
    id: root

    default property alias content: textColumn.data
    property string        icon: "info"
    property bool          warning: false

    Layout.fillWidth: true
    color: warning ? Colours.m3Colors.m3ErrorContainer : Colours.m3Colors.m3SurfaceContainerHighest
    implicitHeight: noticeLayout.implicitHeight + (Appearance.margin.normal * 2)
    radius: Appearance.rounding.normal

    RowLayout {
        id: noticeLayout

        spacing: Appearance.spacing.normal

        anchors {
            left: parent.left
            margins: Appearance.margin.normal
            right: parent.right
            top: parent.top
        }

        Icon {
            Layout.alignment: Qt.AlignTop
            color: root.warning ? Colours.m3Colors.m3OnErrorContainer : Colours.m3Colors.m3OnSurfaceVariant
            icon: root.icon
        }

        ColumnLayout {
            id: textColumn

            Layout.fillWidth: true
            spacing: Appearance.spacing.small
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Feedback
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property bool   active
    required property var    island

    readonly property int    indicatorSize: 36
    readonly property string statusText: qsTr("%1 %2% of %3").arg(root.island.label).arg(root.island.percent).arg(root.island.sizeText)
    readonly property int    statusWidth: statusMetrics.width

    implicitHeight: 44
    implicitWidth: statusRowLayout.implicitWidth + 48

    TextMetrics {
        id: statusMetrics

        font.pixelSize: Appearance.fonts.size.normal
        text: qsTr("%1 %2% of %3").arg("Receiving files").arg(999).arg("999.9 MiB")
    }

    RowLayout {
        id: statusRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        CircleWaveProgress {
            Layout.alignment: Qt.AlignLeft
            activeColor: Colours.m3Colors.m3Primary
            implicitHeight: root.indicatorSize
            implicitWidth: root.indicatorSize
            inactiveColor: Colours.m3Colors.m3OnSurfaceVariant
            progress: root.island.percent / 100
        }

        StyledText {
            Layout.preferredWidth: root.statusWidth
            wrapMode: Text.Wrap
            maximumLineCount: 3
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.normal
            text: root.statusText
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property bool   active
    required property var    island

    readonly property real   contentHeight: 44
    readonly property string detailText: {
        if (outcome !== KDEConnectReceive.Outcome.Received)
            return "";
        if (island.fileName === "")
            return qsTr("%1% of %2").arg(island.maxPercent).arg(island.sizeText);
        if (island.deviceName === "")
            return "";
        return qsTr("from %1").arg(root.island.deviceName);
    }
    readonly property string headlineText: {
        if (outcome !== KDEConnectReceive.Outcome.Received)
            return qsTr("Transfer ended at %1%").arg(island.maxPercent);
        if (island.fileName === "")
            return qsTr("Received");
        return qsTr("Received %1").arg(island.fileName);
    }
    readonly property int    outcome: island.outcome
    readonly property color  outcomeColor: outcome === KDEConnectReceive.Outcome.Received ? Colours.m3Colors.m3Green : Colours.m3Colors.m3Tertiary
    readonly property string outcomeIcon: outcome === KDEConnectReceive.Outcome.Received ? "check_circle" : "warning"

    implicitHeight: contentHeight
    implicitWidth: doneRowLayout.implicitWidth

    RowLayout {
        id: doneRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        ExtendedFloatingButton {
            color: "transparent"
            icon.color: root.outcomeColor
            icon.name: root.outcomeIcon
            icon.size: Appearance.fonts.size.extraLarge
            text: root.headlineText
            textColor: Colours.m3Colors.m3OnSurface
            onClicked: {}
        }

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.small
            text: root.detailText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            visible: root.detailText !== ""
        }
    }
}

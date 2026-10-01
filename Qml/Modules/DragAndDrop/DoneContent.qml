pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property var island
    required property bool active

    readonly property real contentHeight: 44

    readonly property var islandService: root.island
    readonly property string deviceName: root.islandService.selectedDevice?.name ?? ""

    readonly property int outcome: root.islandService.outcome
    readonly property int failure: root.islandService.failure

    readonly property string headlineText: {
        switch (outcome) {
        case DragAndDropServices.Outcome.Sent:
            return qsTr("Handed to %1").arg(root.deviceName);
        case DragAndDropServices.Outcome.Partial:
            return qsTr("Handed %1 of %2 to %3").arg(root.islandService.sentCount).arg(root.islandService.totalCount).arg(root.deviceName);
        case DragAndDropServices.Outcome.Cancelled:
            return qsTr("Stopped");
        case DragAndDropServices.Outcome.Interrupted:
            return qsTr("Transfer ended at %1%").arg(root.islandService.maxPercent);
        default:
            return qsTr("Couldn't send to %1").arg(root.deviceName);
        }
    }

    readonly property string detailText: {
        switch (outcome) {
        case DragAndDropServices.Outcome.Sent:
            return "";
        case DragAndDropServices.Outcome.Partial:
            return qsTr("%1 not sent").arg(root.islandService.notSentCount);
        case DragAndDropServices.Outcome.Cancelled:
            return qsTr("nothing was sent");
        case DragAndDropServices.Outcome.Interrupted:
            return qsTr("the device stopped responding");
        default:
            switch (failure) {
            case DragAndDropServices.Failure.Unreachable:
                return qsTr("%1 is unreachable").arg(root.deviceName);
            case DragAndDropServices.Failure.Missing:
                return qsTr("some files are no longer available");
            case DragAndDropServices.Failure.Unreadable:
                return qsTr("some files could not be read");
            default:
                return qsTr("transfer failed");
            }
        }
    }

    readonly property string outcomeIcon: {
        switch (outcome) {
        case DragAndDropServices.Outcome.Sent:
            return "check_circle";
        case DragAndDropServices.Outcome.Partial:
            return "warning";
        case DragAndDropServices.Outcome.Cancelled:
            return "cancel";
        case DragAndDropServices.Outcome.Interrupted:
            return "warning";
        default:
            return "error";
        }
    }

    readonly property color outcomeColor: {
        switch (outcome) {
        case DragAndDropServices.Outcome.Sent:
            return Colours.m3Colors.m3Green;
        case DragAndDropServices.Outcome.Partial:
            return Colours.m3Colors.m3Tertiary;
        case DragAndDropServices.Outcome.Interrupted:
            return Colours.m3Colors.m3Tertiary;
        default:
            return Colours.m3Colors.m3Error;
        }
    }

    implicitWidth: doneRowLayout.implicitWidth
    implicitHeight: contentHeight

    RowLayout {
        id: doneRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        ExtendedFloatingButton {
            text: root.headlineText
            icon.name: root.outcomeIcon
            icon.color: root.outcomeColor
            icon.size: Appearance.fonts.size.extraLarge
            textColor: Colours.m3Colors.m3OnSurface
            color: "transparent"
            onClicked: {}
        }

        StyledText {
            visible: root.detailText !== ""
            text: root.detailText
            font.pixelSize: Appearance.fonts.size.small
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }
}

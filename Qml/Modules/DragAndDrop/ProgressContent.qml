pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Feedback
import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property bool   active
    required property var    island

    readonly property int    handedCount: root.island.sentCount + root.island.failedCount
    readonly property int    indicatorSize: 36
    readonly property string statusText: {
        if (root.island.watchingTransfer)
            return qsTr("%1% of %2").arg(root.island.maxPercent).arg(KDEConnectTransfer.sizeText);
        return handedCount < root.island.totalCount ? qsTr("Sending %1 of %2…").arg(handedCount).arg(root.island.totalCount) : qsTr("Transferring…");
    }
    readonly property int    statusWidth: Math.max(sendingMetrics.width, transferringMetrics.width)

    implicitHeight: 44
    implicitWidth: progressRowLayout.implicitWidth + 48

    TextMetrics {
        id: sendingMetrics

        font.pixelSize: Appearance.fonts.size.normal
        text: qsTr("Sending %1 of %2…").arg(999).arg(999)
    }

    TextMetrics {
        id: transferringMetrics

        font.pixelSize: Appearance.fonts.size.normal
        text: qsTr("%1% of %2").arg(999).arg("999.9 MiB")
    }

    RowLayout {
        id: progressRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        LoadingIndicator {
            Layout.alignment: Qt.AlignLeft
            contained: false
            implicitHeight: root.indicatorSize
            implicitWidth: root.indicatorSize
            status: root.active
            visible: !root.island.watchingTransfer
        }

        CircleWaveProgress {
            Layout.alignment: Qt.AlignLeft
            activeColor: Colours.m3Colors.m3Primary
            implicitHeight: root.indicatorSize
            implicitWidth: root.indicatorSize
            inactiveColor: Colours.m3Colors.m3OnSurfaceVariant
            progress: root.island.maxPercent / 100
            visible: root.island.watchingTransfer
        }

        StyledText {
            Layout.preferredWidth: root.statusWidth
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.normal
            text: root.statusText
        }

        Item {
            Layout.fillWidth: true
        }

        ExtendedFloatingButton {
            Layout.preferredWidth: implicitWidth
            color: Qt.alpha(Colours.m3Colors.m3Error, 0.12)
            enabled: !root.island.watchingTransfer
            implicitHeight: 28
            opacity: root.island.watchingTransfer ? 0 : 1
            text: qsTr("Stop sending")
            textColor: Colours.m3Colors.m3Error
            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
            onClicked: root.island.stopSending()
        }
    }
}

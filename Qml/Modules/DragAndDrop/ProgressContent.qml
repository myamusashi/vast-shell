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

    required property var island
    required property bool active

    readonly property int handedCount: root.island.sentCount + root.island.failedCount
    readonly property string statusText: {
        if (root.island.watchingTransfer)
            return qsTr("%1% of %2").arg(root.island.maxPercent).arg(KDEConnectTransfer.sizeText);
        return handedCount < root.island.totalCount ? qsTr("Sending %1 of %2…").arg(handedCount).arg(root.island.totalCount) : qsTr("Transferring…");
    }

    readonly property int indicatorSize: 36
    readonly property int statusWidth: Math.max(sendingMetrics.width, transferringMetrics.width)

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

    implicitWidth: progressRowLayout.implicitWidth + 48
    implicitHeight: 44

    RowLayout {
        id: progressRowLayout

        anchors.centerIn: parent
        spacing: Appearance.spacing.normal
        visible: root.active

        LoadingIndicator {
            Layout.alignment: Qt.AlignLeft
            visible: !root.island.watchingTransfer
            implicitWidth: root.indicatorSize
            implicitHeight: root.indicatorSize
            contained: false
            status: root.active
        }

        CircleWaveProgress {
            Layout.alignment: Qt.AlignLeft
            visible: root.island.watchingTransfer
            implicitWidth: root.indicatorSize
            implicitHeight: root.indicatorSize
            activeColor: Colours.m3Colors.m3Primary
            inactiveColor: Colours.m3Colors.m3OnSurfaceVariant
            progress: root.island.maxPercent / 100
        }

        StyledText {
            Layout.preferredWidth: root.statusWidth
            text: root.statusText
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
        }

        ExtendedFloatingButton {
            Layout.preferredWidth: implicitWidth
            enabled: !root.island.watchingTransfer
            opacity: root.island.watchingTransfer ? 0 : 1
            implicitHeight: 28
            text: qsTr("Stop sending")
            textColor: Colours.m3Colors.m3Error
            color: Qt.alpha(Colours.m3Colors.m3Error, 0.12)
            onClicked: root.island.stopSending()

            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }
}

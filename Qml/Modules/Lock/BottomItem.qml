pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base

Item {
    id: root

    required property bool isLockscreenOpen
    required property var  pam

    property alias         contentLayout: bar.contentLayout
    property alias         iconName: bar.lockIcon.icon
    property string        inputBuffer: ""
    property alias         lockIcon: bar.lockIcon
    property bool          showErrorMessage: false

    implicitHeight: 0
    Behavior on implicitHeight {
        NAnim {}
    }

    anchors {
        bottom: parent.bottom
        bottomMargin: Appearance.margin.normal
        left: parent.left
        right: parent.right
    }

    RowLayout {
        spacing: Appearance.spacing.normal

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        Item {
            Layout.fillWidth: true
        }

        Bar {
            id: bar

            mediaLayout: mediaPlayer.mediaLayout
            showErrorMessage: root.showErrorMessage
        }

        MediaPlayer {
            id: mediaPlayer
        }

        Item {
            Layout.fillWidth: true
        }
    }
}

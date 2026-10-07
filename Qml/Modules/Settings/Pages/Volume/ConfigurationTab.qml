pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Audio

import qs.Core.Configs
import qs.Services
import qs.Components.Base
import qs.Widgets

import "../../Components"

ColumnLayout {
    id: root

    readonly property var cards: AudioProfilesWatcher.cards
    readonly property int count: cards ? cards.count : 0

    spacing: Appearance.spacing.larger

    SettingsCard {
        title: qsTr("Level Meters")

        SettingRow {
            description: qsTr("Track live input and output levels. Turn this off if PipeWire reports missing channels for your devices.")
            label: qsTr("Show Audio Level Meters:")

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: Configs.audio.showPeakLevels
                onToggled: Configs.audio.showPeakLevels = checked
            }
        }
    }

    StyledText {
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
        text: qsTr("No audio cards detected.")
        visible: root.count === 0
    }

    Repeater {
        model: root.cards
        delegate: SettingsCard {
            id: cardDelegate

            required property var    card
            required property string description
            required property string name

            title: cardDelegate.description || cardDelegate.name

            AudioProfiles {
                Layout.fillWidth: true
                card: cardDelegate.card
            }
        }
    }
}

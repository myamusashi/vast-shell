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

    spacing: Appearance.spacing.larger

    readonly property var cards: AudioProfilesWatcher.cards
    readonly property int count: cards ? cards.count() : 0

    SettingsCard {
        title: qsTr("Level Meters")

        SettingRow {
            label: qsTr("Show Audio Level Meters:")
            description: qsTr("Track live input and output levels. Turn this off if PipeWire reports missing channels for your devices.")

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                checked: Configs.audio.showPeakLevels
                onToggled: Configs.audio.showPeakLevels = checked
            }
        }
    }

    StyledText {
        visible: root.count === 0
        text: qsTr("No audio cards detected.")
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.normal
    }

    Repeater {
        model: root.cards

        delegate: SettingsCard {
            id: cardDelegate

            required property var card
            required property string name
            required property string description

            title: cardDelegate.description || cardDelegate.name

            AudioProfiles {
                card: cardDelegate.card
                Layout.fillWidth: true
            }
        }
    }
}

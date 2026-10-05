import QtQuick
import Vast.Translation

import qs.Components.Button
import qs.Core.Configs

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("System Language")

    SettingsCard {
        title: qsTr("Locale Preference")

        SettingRow {
            description: qsTr("Locale code used for translations.")
            label: qsTr("Current Language:")

            SplitButton {
                readonly property int selectedIndex: Math.max(0, model.findIndex(entry => entry.display === Configs.language.language))

                currentIndex: selectedIndex
                icon.name: "language"
                model: TranslationManager.availableLanguages().map(language => ({
                            display: language
                        }))
                text: model[selectedIndex]?.display ?? Configs.language.language
                textRole: "display"

                onMenuItemActivated: index => Configs.language.language = model[index].display
            }
        }
    }
}

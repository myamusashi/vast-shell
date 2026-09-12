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
            label: qsTr("Current Language:")
            description: qsTr("Locale code used for translations.")

            SplitButton {
                readonly property int selectedIndex: Math.max(0, model.findIndex(entry => entry.display === Configs.language.language))

                model: TranslationManager.availableLanguages().map(language => ({
                            display: language
                        }))
                textRole: "display"
                icon.name: "language"
                currentIndex: selectedIndex
                text: model[selectedIndex]?.display ?? Configs.language.language
                onMenuItemActivated: index => Configs.language.language = model[index].display
            }
        }
    }
}

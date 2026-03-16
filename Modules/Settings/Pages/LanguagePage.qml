import QtQuick
import QtQuick.Layouts
import qs.Core.Configs
import qs.Components.Base
import qs.Services
import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.margin.large
        }
        spacing: Appearance.spacing.large

        StyledText {
            Layout.bottomMargin: Appearance.margin.normal
            text: qsTr("System Language")
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
        }

        SettingsCard {
            title: qsTr("Locale Preference")

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Current Language:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledTextInput {
                    text: Configs.language.language
                    onTextChanged: Configs.language.language = text
                    Layout.preferredWidth: 200
                    placeHolderText: "e.g., id-ID or en-US"
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}

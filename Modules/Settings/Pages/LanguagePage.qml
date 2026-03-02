import QtQuick
import QtQuick.Layouts
import qs.Configs
import qs.Components
import qs.Services
import "../Components"

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Configs.appearance.margin.large
        spacing: Configs.appearance.spacing.large

        StyledText {
            text: qsTr("System Language")
            font.pixelSize: Configs.appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Configs.appearance.margin.normal
        }

        SettingsCard {
            title: qsTr("Locale Preference")

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Current Language:")
                    Layout.fillWidth: true
                    font.pixelSize: Configs.appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledTextField {
                    text: Configs.language
                    onTextChanged: Configs.language = text
                    Layout.preferredWidth: 200
                    placeholderText: "e.g., id-ID or en-US"
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}

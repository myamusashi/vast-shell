pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Services
import qs.Services.Hyprland

import "../../Components"

SettingsPageBase {
    id: root

    readonly property bool categoryDirty: GeneralServices.isCategoryDirty(root.category)

    property string        category

    onCategoryChanged: root.revealer.target.contentY = 0
    pageTitle: qsTr("Hyprland ") + HyprlandGeneralSchema.pageLabel(category)

    HyprlandNoticeCard {
        icon: "warning"
        visible: !HyprlandSetupServices.onHyprland
        warning: true

        StyledText {
            color: Colours.m3Colors.m3OnErrorContainer
            text: qsTr("Hyprland with Lua configuration was not detected. Values are saved, but only Hyprland applies them.")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    HyprlandNoticeCard {
        icon: "warning"
        visible: root.category === "debug"
        warning: true

        StyledText {
            color: Colours.m3Colors.m3OnErrorContainer
            text: qsTr("Debug options are intended for development and testing only. Do not change them in a normal configuration.")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    Repeater {
        model: HyprlandGeneralSchema.cardsForCategory(root.category)
        delegate: SettingsCard {
            id: cardDelegate

            required property string modelData

            title: cardDelegate.modelData

            Repeater {
                model: HyprlandGeneralSchema.optionsForCard(root.category, cardDelegate.modelData)
                delegate: HyprlandOptionRow {
                    required property var modelData

                    Layout.fillWidth: true
                    category: root.category
                    descriptor: modelData
                }
            }
        }
    }

    footer: [
        Item {
            Layout.fillWidth: true
        },
        ExtendedFloatingButton {
            enabled: root.categoryDirty
            outlined: true
            text: qsTr("Revert")
            textColor: Colours.m3Colors.m3OnSurface
            onClicked: GeneralServices.revertCategory(root.category)
        },
        ExtendedFloatingButton {
            enabled: root.categoryDirty
            text: qsTr("Apply")
            onClicked: GeneralServices.applyCategory(root.category)
        }
    ]
}

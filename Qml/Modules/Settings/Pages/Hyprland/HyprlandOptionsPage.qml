pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

import "../../Components"

SettingsPageBase {
    id: root

    property string category

    function        cjsonText(): string {
        if (HyprlandSetupServices.cjsonState === "missing")
            return qsTr("lua-cjson was not found in Hyprland's embedded Lua (5.5). vast_shell.lua does nothing without it. Install lua-cjson built for Lua 5.5 and copy its cjson.so into ~/.config/hypr/ (or extend package.cpath in vast_shell.lua).");
        return "";
    }

    function        luaFileText(): string {
        if (HyprlandSetupServices.luaFileState === "exists" || HyprlandSetupServices.luaFileState === "created")
            return qsTr("vast_shell.lua is set up.");
        if (HyprlandSetupServices.luaFileState === "missing")
            return qsTr("vast_shell.lua will be created.");
        return "";
    }

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
        icon: "info"
        visible: HyprlandSetupServices.onHyprland

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            text: root.cjsonText()
            visible: HyprlandSetupServices.cjsonState === "missing"
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                text: qsTr("Add at the bottom of hyprland.lua: %1").arg(HyprlandSetupServices.requireLine)
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurfaceVariant
                text: root.luaFileText()
                visible: text !== ""
                wrapMode: Text.Wrap
                Layout.maximumWidth: 260
            }

            ExtendedFloatingButton {
                icon.name: "content_copy"
                onClicked: HyprlandSetupServices.copyRequireLine()
            }
        }

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            text: qsTr("vast-shell never edits hyprland.lua. It only creates %1 once, if missing.").arg(HyprlandSetupServices.vastShellLuaPath)
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

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        Item {
            Layout.fillWidth: true
        }

        ExtendedFloatingButton {
            enabled: GeneralServices.isCategoryDirty(root.category)
            outlined: true
            text: qsTr("Revert")
            textColor: Colours.m3Colors.m3OnSurface
            onClicked: GeneralServices.revertCategory(root.category)
        }

        ExtendedFloatingButton {
            enabled: GeneralServices.isCategoryDirty(root.category)
            text: qsTr("Apply")
            onClicked: GeneralServices.applyCategory(root.category)
        }
    }
}

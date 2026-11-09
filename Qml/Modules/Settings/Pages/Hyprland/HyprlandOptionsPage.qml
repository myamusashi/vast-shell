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

    readonly property bool categoryDirty: GeneralServices.isCategoryDirty(root.category)
    readonly property var  optionGridGroups: ({
            "binds:Binds": [["allow_pin_fullscreen", "client_requested_fs_uses_layout_handler", "allow_workspace_cycles", "disable_keybind_grabbing"], ["hide_special_on_workspace_change", "ignore_group_lock", "movefocus_cycles_fullscreen", "movefocus_cycles_groupfirst", "pass_mouse_when_bound"]],
            "cursor:Cursor": [["enable_hyprcursor", "hide_on_key_press", "hide_on_tablet", "hide_on_touch"]],
            "debug:Debug": [["disable_logs", "disable_scale_checks", "disable_time", "ds_handle_same_buffer", "ds_handle_same_buffer_fifo", "enable_stdout_logs"], ["log_damage", "overlay", "pass", "render_solitary_wo_damage", "suppress_errors", "vfr"]],
            "group:Group": [["focus_removed_window", "group_on_movetoworkspace", "insert_after_current", "merge_floated_into_tiled_on_groupbar", "merge_groups_on_groupbar"]],
            "input:Input": [["kb_file", "kb_layout", "kb_model", "kb_options", "kb_rules", "kb_variant"], ["left_handed", "mouse_refocus", "natural_scroll", "numlock_by_default"]],
            "input:Touchpad": [["touchpad.flip_x", "touchpad.flip_y", "touchpad.middle_button_emulation", "touchpad.natural_scroll"]],
            "misc:Misc": [["allow_session_lock_restore", "always_follow_on_dnd", "animate_manual_resizes", "animate_mouse_windowdragging"], ["close_special_on_empty", "disable_autoreload", "disable_hyprland_guiutils_check", "disable_hyprland_logo", "disable_scale_notification", "disable_splash_rendering", "disable_watchdog_warning", "disable_xdg_env_checks", "enable_anr_dialog", "enable_swallow"], ["middle_click_paste", "mouse_move_enables_dpms", "mouse_move_focuses_monitor", "name_vk_after_proc"], ["screencopy_force_8b", "session_lock_blur", "session_lock_xray", "size_limits_tiled"]]
        })

    property string        category

    function               gridGroupsFor(cardTitle: string): var {
        const key    = root.category + ":" + cardTitle;
        const groups = root.optionGridGroups[key];
        if (!groups)
            return [];
        const byKey = {};
        for (const option of HyprlandGeneralSchema.optionsForCard(root.category, cardTitle))
            byKey[option.path.substring(option.path.indexOf(".") + 1)] = option;
        const resolved = [];
        for (const group of groups) {
            const items = [];
            for (const gridKey of group) {
                if (byKey[gridKey] !== undefined)
                    items.push(byKey[gridKey]);
            }
            if (items.length > 0)
                resolved.push(items);
        }
        return resolved;
    }

    function               restOptionsFor(cardTitle: string): var {
        const key    = root.category + ":" + cardTitle;
        const groups = root.optionGridGroups[key];
        if (!groups)
            return HyprlandGeneralSchema.optionsForCard(root.category, cardTitle);
        const grouped = {};
        for (const group of groups)
            for (const gridKey of group)
                grouped[gridKey] = true;
        return HyprlandGeneralSchema.optionsForCard(root.category, cardTitle).filter(option => !grouped[option.path.substring(option.path.indexOf(".") + 1)]);
    }

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

    RowLayout {
        id: cardsRow

        readonly property var  leftCards: cardsRow.wide ? HyprlandGeneralSchema.cardsForCategory(root.category).slice(0, Math.ceil(HyprlandGeneralSchema.cardsForCategory(root.category).length / 2)) : HyprlandGeneralSchema.cardsForCategory(root.category)
        readonly property var  rightCards: cardsRow.wide ? HyprlandGeneralSchema.cardsForCategory(root.category).slice(Math.ceil(HyprlandGeneralSchema.cardsForCategory(root.category).length / 2)) : []
        readonly property bool wide: (cardsRow.width >= 850 && HyprlandGeneralSchema.cardsForCategory(root.category).length >= 2)

        Layout.fillWidth: true
        spacing: Appearance.spacing.large

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 0
            spacing: Appearance.spacing.large

            Repeater {
                model: cardsRow.leftCards
                delegate: SettingsCard {
                    id: leftCard
                    required property string modelData

                    Layout.fillWidth: true
                    title: modelData

                    Repeater {
                        model: root.gridGroupsFor(leftCard.modelData)
                        delegate: GridLayout {
                            id: leftGrid

                            required property var modelData

                            Layout.fillWidth: true
                            columnSpacing: Appearance.spacing.normal
                            columns: 2
                            rowSpacing: Appearance.spacing.normal

                            Repeater {
                                model: leftGrid.modelData
                                delegate: HyprlandOptionRow {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 0
                                    category: root.category
                                    descriptor: modelData
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.restOptionsFor(leftCard.modelData)
                        delegate: HyprlandOptionRow {
                            required property var modelData

                            Layout.fillWidth: true
                            category: root.category
                            descriptor: modelData
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 0
            spacing: Appearance.spacing.large
            visible: cardsRow.wide

            Repeater {
                model: cardsRow.rightCards
                delegate: SettingsCard {
                    id: rightCard
                    required property string modelData

                    Layout.fillWidth: true
                    title: modelData

                    Repeater {
                        model: root.gridGroupsFor(rightCard.modelData)
                        delegate: GridLayout {
                            id: rightGrid

                            required property var modelData

                            Layout.fillWidth: true
                            columnSpacing: Appearance.spacing.normal
                            columns: 2
                            rowSpacing: Appearance.spacing.normal

                            Repeater {
                                model: rightGrid.modelData
                                delegate: HyprlandOptionRow {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 0
                                    category: root.category
                                    descriptor: modelData
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.restOptionsFor(rightCard.modelData)
                        delegate: HyprlandOptionRow {
                            required property var modelData

                            Layout.fillWidth: true
                            category: root.category
                            descriptor: modelData
                        }
                    }
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

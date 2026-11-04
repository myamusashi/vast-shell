pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Match property and effects for hl.layer_rule(), typed after the 0.57.0
    // sources: LuaBindingsConfigRules.cpp LAYER_RULE_EFFECT_DESCS and
    // LayerRule.cpp (only the namespace prop is ever consulted).
    // "regex" values are RE2 full matches and may be inverted with a negative: prefix.
    readonly property var    effects: [
        {
            key: "above_lock",
            type: "int",
            default: 0,
            min: 0,
            max: 2,
            description: qsTr("Render the layer above the lock screen; 2 stays interactive on the lock screen.")
        },
        {
            key: "animation",
            type: "string",
            default: "",
            description: qsTr("Animation style for this layer.")
        },
        {
            key: "blur",
            type: "bool",
            default: false,
            description: qsTr("Enable blur for the layer.")
        },
        {
            key: "blur_popups",
            type: "bool",
            default: false,
            description: qsTr("Enable blur for the layer's popups.")
        },
        {
            key: "dim_around",
            type: "bool",
            default: false,
            description: qsTr("Dim everything behind the layer.")
        },
        {
            key: "ignore_alpha",
            type: "float",
            default: 0,
            min: 0,
            max: 1,
            description: qsTr("Blur ignores pixels at or below this opacity.")
        },
        {
            key: "no_anim",
            type: "bool",
            default: false,
            description: qsTr("Disable animations for the layer.")
        },
        {
            key: "no_screen_share",
            type: "bool",
            default: false,
            description: qsTr("Hide the layer from screen sharing.")
        },
        {
            key: "order",
            type: "int",
            default: 0,
            description: qsTr("Space-reservation priority relative to other layers; higher wins, may be negative.")
        },
        {
            key: "xray",
            type: "bool",
            default: false,
            description: qsTr("Blur xray mode for the layer.")
        }
    ]
    readonly property var    matchProps: [
        {
            key: "namespace",
            type: "regex",
            default: "",
            description: qsTr("Layer namespace, e.g. waybar or shell:drawers.")
        }
    ]

    // Kept for symmetry with the window schema; layer effects take no
    // move/size expressions.
    readonly property string expressionHint: ""

    function                 effectByKey(key: string): var { // qmllint disable
        return root.effects.find(effect => effect.key === key) ?? null;
    }

    function                 labelFromKey(key: string): string {
        const spaced = key.replace(/_/g, " ");
        return spaced.charAt(0).toUpperCase() + spaced.slice(1);
    }

    function                 matchPropByKey(key: string): var { // qmllint disable
        return root.matchProps.find(prop => prop.key === key) ?? null;
    }
}

pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // "regex" values are RE2 full matches and may be inverted with a negative: prefix.
    readonly property var    effects: [
        {
            key: "allows_input",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Force an Xwayland window to receive input even when it requests not to."
        },
        {
            key: "animation",
            type: "string",
            default: "",
            dynamic: true,
            description: "Force an animation style onto the window.",
            hint: "e.g. popin or popin 80%"
        },
        {
            key: "border_color",
            type: "string",
            default: "",
            dynamic: true,
            description: "Border color or gradient.",
            hint: "one color rgb(FF0000), or two colors rgb(FF0000) rgb(880808) as a gradient; combine with the focus match for active/inactive colors"
        },
        {
            key: "border_size",
            type: "int",
            default: 0,
            min: 0,
            dynamic: true,
            description: "Border size in pixels."
        },
        {
            key: "center",
            type: "bool",
            default: false,
            dynamic: false,
            description: "Center the window on the monitor when it floats."
        },
        {
            key: "confine_pointer",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Lock the mouse cursor to the window."
        },
        {
            key: "content",
            type: "enum",
            values: ["", "none", "photo", "video", "game"],
            default: "",
            dynamic: false,
            description: "Content type of the window."
        },
        {
            key: "decorate",
            type: "bool",
            default: true,
            dynamic: true,
            description: "Whether to draw window decorations."
        },
        {
            key: "dim_around",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Dim everything around the window."
        },
        {
            key: "float",
            type: "bool",
            default: false,
            dynamic: false,
            description: "Float the window."
        },
        {
            key: "focus_on_activate",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Focus the window when the app requests to be focused."
        },
        {
            key: "force_rgbx",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable the window's own transparency."
        },
        {
            key: "fullscreen",
            type: "bool",
            default: false,
            dynamic: false,
            description: "Fullscreen the window."
        },
        {
            key: "fullscreen_state",
            type: "string",
            default: "",
            dynamic: false,
            description: "Fullscreen mode, internal then client.",
            hint: "two numbers 0-3 separated by a space, e.g. 1 2; 0 none, 1 maximize, 2 fullscreen, 3 maximize and fullscreen"
        },
        {
            key: "group",
            type: "string",
            default: "",
            dynamic: false,
            description: "Window group behavior.",
            hint: "barred, deny, invade, lock [always], new, override, set [always], unset; bare group means set"
        },
        {
            key: "idle_inhibit",
            type: "enum",
            values: ["", "none", "always", "focus", "fullscreen"],
            default: "",
            dynamic: true,
            description: "Idle inhibit mode for the window."
        },
        {
            key: "immediate",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Allow tearing for this window."
        },
        {
            key: "keep_aspect_ratio",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Keep the aspect ratio when resizing with the mouse."
        },
        {
            key: "max_size",
            type: "exprVec2",
            default: ["", ""],
            dynamic: true,
            description: "Maximum size for floating windows."
        },
        {
            key: "maximize",
            type: "bool",
            default: false,
            dynamic: false,
            description: "Maximize the window."
        },
        {
            key: "min_size",
            type: "exprVec2",
            default: ["", ""],
            dynamic: true,
            description: "Minimum size for floating windows."
        },
        {
            key: "monitor",
            type: "string",
            default: "",
            dynamic: false,
            description: "Monitor the window opens on.",
            hint: "name, index or desc:…; append  silent to open without focusing"
        },
        {
            key: "move",
            type: "exprVec2",
            default: ["", ""],
            dynamic: false,
            description: "Monitor-local position for the floating window."
        },
        {
            key: "nearest_neighbor",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Force nearest-neighbor filtering."
        },
        {
            key: "no_anim",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable animations for the window."
        },
        {
            key: "no_auto_hdr",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable AutoHDR for the window."
        },
        {
            key: "no_blur",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable blur for the window."
        },
        {
            key: "no_close_for",
            type: "int",
            default: 0,
            min: 0,
            dynamic: false,
            description: "Uncloseable with killactive for this many milliseconds on open."
        },
        {
            key: "no_dim",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable window dimming for the window."
        },
        {
            key: "no_focus",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable focusing the window."
        },
        {
            key: "no_follow_mouse",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Do not focus the window when the mouse moves over it."
        },
        {
            key: "no_glow",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable glow for the window."
        },
        {
            key: "no_initial_focus",
            type: "bool",
            default: false,
            dynamic: false,
            description: "Do not focus the window when it opens."
        },
        {
            key: "no_max_size",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Remove max size limitations."
        },
        {
            key: "no_screen_share",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Hide the window and its popups from screen sharing."
        },
        {
            key: "no_shadow",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable shadows for the window."
        },
        {
            key: "no_shortcuts_inhibit",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disallow the app from inhibiting your shortcuts."
        },
        {
            key: "no_vrr",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable VRR for the window (misc.vrr must be 2 or 3)."
        },
        {
            key: "no_wobble",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable wobble for the window."
        },
        {
            key: "no_xdg_drags",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Disable XDG-driven drags for the window."
        },
        {
            key: "opacity",
            type: "string",
            default: "",
            dynamic: true,
            description: "Opacity multipliers for the window.",
            hint: "up to three values: active, inactive, fullscreen; append override after a value for absolute opacity, e.g. 0.8 override 0.8 override"
        },
        {
            key: "opaque",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Force the window opacities to 1."
        },
        {
            key: "persistent_size",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Restore the stored size when a floating window with the same class and title opens."
        },
        {
            key: "pin",
            type: "bool",
            default: false,
            dynamic: false,
            description: "Pin the window to all workspaces.",
            hint: "ignored for non-floating windows; usually combined with float"
        },
        {
            key: "pseudo",
            type: "bool",
            default: false,
            dynamic: false,
            description: "Pseudotile the window."
        },
        {
            key: "render_unfocused",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Keep rendering the window while it is not visible."
        },
        {
            key: "rounding",
            type: "int",
            default: 0,
            min: 0,
            max: 100,
            dynamic: true,
            description: "Rounding in pixels, ignoring the default."
        },
        {
            key: "rounding_power",
            type: "float",
            default: 2,
            min: 1,
            max: 10,
            dynamic: true,
            description: "Rounding power for the window."
        },
        {
            key: "scroll_mouse",
            type: "float",
            default: 1,
            min: 0.01,
            max: 10,
            dynamic: true,
            description: "Mouse scroll factor for the window."
        },
        {
            key: "scroll_touchpad",
            type: "float",
            default: 1,
            min: 0.01,
            max: 10,
            dynamic: true,
            description: "Touchpad scroll factor for the window."
        },
        {
            key: "scrolling_width",
            type: "float",
            default: 0,
            min: 0,
            dynamic: false,
            description: "Column width when the window opens on a workspace with the scrolling layout."
        },
        {
            key: "size",
            type: "exprVec2",
            default: ["", ""],
            dynamic: false,
            description: "Size for the floating window."
        },
        {
            key: "stay_focused",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Keep focus on the window as long as it is visible."
        },
        {
            key: "suppress_event",
            type: "string",
            default: "",
            dynamic: false,
            description: "Events the window ignores.",
            hint: "space-separated: fullscreen, maximize, activate, activatefocus, fullscreenoutput, x11configurerequest"
        },
        {
            key: "sync_fullscreen",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Always send the compositor fullscreen mode to the window."
        },
        {
            key: "tag",
            type: "string",
            default: "",
            dynamic: true,
            description: "Apply a dynamic tag to the window.",
            hint: "+name adds, -name unsets, bare name toggles; dynamic tags end with *"
        },
        {
            key: "tile",
            type: "bool",
            default: false,
            dynamic: false,
            description: "Tile the window."
        },
        {
            key: "tonemap",
            type: "enum",
            values: ["", "on", "off", "clamp", "limited"],
            default: "",
            dynamic: true,
            description: "Tonemapping behavior for the window."
        },
        {
            key: "workspace",
            type: "string",
            default: "",
            dynamic: false,
            description: "Workspace the window opens on.",
            hint: "workspace selector or unset; append  silent to open without focusing"
        },
        {
            key: "xray",
            type: "bool",
            default: false,
            dynamic: true,
            description: "Blur xray mode for the window."
        }
    ]
    readonly property var    matchProps: [
        {
            key: "class",
            type: "regex",
            pickerField: "class",
            description: "Window class."
        },
        {
            key: "content",
            type: "enum",
            values: ["", "none", "photo", "video", "game"],
            description: "Content type of the window."
        },
        {
            key: "float",
            type: "bool",
            description: "Whether the window is floating."
        },
        {
            key: "focus",
            type: "bool",
            description: "Whether the window currently has focus."
        },
        {
            key: "fullscreen",
            type: "bool",
            description: "Whether the window is fullscreen (covering or not)."
        },
        {
            key: "fullscreen_state_client",
            type: "enum",
            values: [0, 1, 2, 3],
            labels: ["none", "maximize", "fullscreen", "maximize and fullscreen"],
            description: "Fullscreen state the client requested."
        },
        {
            key: "fullscreen_state_internal",
            type: "enum",
            values: [0, 1, 2, 3],
            labels: ["none", "maximize", "fullscreen", "maximize and fullscreen"],
            description: "Fullscreen state the compositor uses."
        },
        {
            key: "group",
            type: "bool",
            description: "Whether the window is in a group."
        },
        {
            key: "initial_class",
            type: "regex",
            pickerField: "initialClass",
            description: "Class the window was created with."
        },
        {
            key: "initial_title",
            type: "regex",
            pickerField: "initialTitle",
            description: "Title the window was created with."
        },
        {
            key: "modal",
            type: "bool",
            description: "Whether the window is modal (e.g. confirmation popups)."
        },
        {
            key: "pin",
            type: "bool",
            description: "Whether the window is pinned to all workspaces."
        },
        {
            key: "tag",
            type: "string",
            description: "Tag name. Dynamic tags end with *."
        },
        {
            key: "title",
            type: "regex",
            pickerField: "title",
            description: "Window title. Static effects only ever see the initial title."
        },
        {
            key: "workspace",
            type: "string",
            description: "Workspace selector, e.g. 3, name:web or special:magic."
        },
        {
            key: "xdg_tag",
            type: "regex",
            pickerField: "xdgTag",
            description: "XDG tag of the window."
        },
        {
            key: "xwayland",
            type: "bool",
            description: "Whether the window is an Xwayland window."
        }
    ]

    // Expressions allowed inside move/size/min_size/max_size, shown as the
    // section hint by the cards.
    readonly property string expressionHint: "Numbers or expressions such as monitor_w * 0.5, using monitor_w, monitor_h, window_x, window_y, window_w, window_h, cursor_x, cursor_y."

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

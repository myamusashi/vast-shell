pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var options: [
        // general
        {
            path: "general.allow_tearing",
            category: "general",
            card: "Windows",
            type: "bool",
            default: false
        },
        {
            path: "general.border_size",
            category: "general",
            card: "Windows",
            type: "int",
            default: 1,
            min: 0,
            max: 20
        },
        {
            path: "general.extend_border_grab_area",
            category: "general",
            card: "Windows",
            type: "int",
            default: 15,
            min: 0,
            max: 100
        },
        {
            path: "general.float_gaps",
            category: "general",
            card: "Windows",
            type: "gaps",
            default: 0
        },
        {
            path: "general.gaps_in",
            category: "general",
            card: "Windows",
            type: "gaps",
            default: 5
        },
        {
            path: "general.gaps_out",
            category: "general",
            card: "Windows",
            type: "gaps",
            default: 20
        },
        {
            path: "general.gaps_workspaces",
            category: "general",
            card: "Windows",
            type: "int",
            default: 0,
            min: 0,
            max: 100
        },
        {
            path: "general.hover_icon_on_border",
            category: "general",
            card: "Windows",
            type: "bool",
            default: true
        },
        {
            path: "general.layout",
            category: "general",
            card: "Windows",
            type: "enum",
            default: "dwindle",
            values: ["dwindle", "master", "scrolling", "monocle"]
        },
        {
            path: "general.locale",
            category: "general",
            card: "Windows",
            type: "string",
            default: ""
        },
        {
            path: "general.modal_parent_blocking",
            category: "general",
            card: "Windows",
            type: "bool",
            default: true
        },
        {
            path: "general.no_focus_fallback",
            category: "general",
            card: "Windows",
            type: "bool",
            default: false
        },
        {
            path: "general.resize_corner",
            category: "general",
            card: "Windows",
            type: "int",
            default: 0,
            min: 0,
            max: 4
        },
        {
            path: "general.resize_on_border",
            category: "general",
            card: "Windows",
            type: "bool",
            default: false
        },
        {
            path: "general.snap.enabled",
            category: "general",
            card: "Snapping",
            type: "bool",
            default: false
        },
        {
            path: "general.snap.border_overlap",
            category: "general",
            card: "Snapping",
            type: "bool",
            default: false
        },
        {
            path: "general.snap.respect_gaps",
            category: "general",
            card: "Snapping",
            type: "bool",
            default: false
        },
        {
            path: "general.snap.monitor_gap",
            category: "general",
            card: "Snapping",
            type: "int",
            default: 10,
            min: 0,
            max: 100
        },
        {
            path: "general.snap.window_gap",
            category: "general",
            card: "Snapping",
            type: "int",
            default: 10,
            min: 0,
            max: 100
        },
        // decoration
        {
            path: "decoration.active_opacity",
            category: "decoration",
            card: "Decoration",
            type: "float",
            default: 1.0,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.border_part_of_window",
            category: "decoration",
            card: "Decoration",
            type: "bool",
            default: true
        },
        {
            path: "decoration.dim_around",
            category: "decoration",
            card: "Decoration",
            type: "float",
            default: 0.4,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.dim_inactive",
            category: "decoration",
            card: "Decoration",
            type: "bool",
            default: false
        },
        {
            path: "decoration.dim_modal",
            category: "decoration",
            card: "Decoration",
            type: "bool",
            default: true
        },
        {
            path: "decoration.dim_special",
            category: "decoration",
            card: "Decoration",
            type: "float",
            default: 0.2,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.dim_strength",
            category: "decoration",
            card: "Decoration",
            type: "float",
            default: 0.5,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.fullscreen_opacity",
            category: "decoration",
            card: "Decoration",
            type: "float",
            default: 1.0,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.inactive_opacity",
            category: "decoration",
            card: "Decoration",
            type: "float",
            default: 1.0,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.rounding",
            category: "decoration",
            card: "Decoration",
            type: "int",
            default: 0,
            min: 0,
            max: 100
        },
        {
            path: "decoration.rounding_power",
            category: "decoration",
            card: "Decoration",
            type: "float",
            default: 2.0,
            min: 1.0,
            max: 10.0
        },
        {
            path: "decoration.screen_shader",
            category: "decoration",
            card: "Decoration",
            type: "string",
            default: ""
        },
        {
            path: "decoration.blur.enabled",
            category: "decoration",
            card: "Blur",
            type: "bool",
            default: true
        },
        {
            path: "decoration.blur.brightness",
            category: "decoration",
            card: "Blur",
            type: "float",
            default: 1.0,
            min: 0.0,
            max: 2.0
        },
        {
            path: "decoration.blur.contrast",
            category: "decoration",
            card: "Blur",
            type: "float",
            default: 0.8916,
            min: 0.0,
            max: 2.0
        },
        {
            path: "decoration.blur.ignore_opacity",
            category: "decoration",
            card: "Blur",
            type: "bool",
            default: true
        },
        {
            path: "decoration.blur.input_methods",
            category: "decoration",
            card: "Blur",
            type: "bool",
            default: false
        },
        {
            path: "decoration.blur.input_methods_ignorealpha",
            category: "decoration",
            card: "Blur",
            type: "float",
            default: 0.2,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.new_optimizations",
            category: "decoration",
            card: "Blur",
            type: "bool",
            default: true
        },
        {
            path: "decoration.blur.noise",
            category: "decoration",
            card: "Blur",
            type: "float",
            default: 0.0117,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.passes",
            category: "decoration",
            card: "Blur",
            type: "int",
            default: 1,
            min: 0,
            max: 10,
            note: "Must be at least 1 for blur to apply."
        },
        {
            path: "decoration.blur.popups",
            category: "decoration",
            card: "Blur",
            type: "bool",
            default: false
        },
        {
            path: "decoration.blur.popups_ignorealpha",
            category: "decoration",
            card: "Blur",
            type: "float",
            default: 0.2,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.proportional",
            category: "decoration",
            card: "Blur",
            type: "bool",
            default: false,
            note: "Requires render.use_shader_blur_blend."
        },
        {
            path: "decoration.blur.size",
            category: "decoration",
            card: "Blur",
            type: "int",
            default: 8,
            note: "Must be at least 1 for blur to apply."
        },
        {
            path: "decoration.blur.special",
            category: "decoration",
            card: "Blur",
            type: "bool",
            default: false
        },
        {
            path: "decoration.blur.variant",
            category: "decoration",
            card: "Blur",
            type: "enum",
            default: "kawase",
            values: ["kawase", "acrylic", "aurora", "drops", "fluid_jar", "frost", "haze", "heat_shimmer", "prism", "ripple", "water"],
            note: "Selects which blur variant sub-options apply."
        },
        {
            path: "decoration.blur.vibrancy",
            category: "decoration",
            card: "Blur",
            type: "float",
            default: 0.1696,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.vibrancy_darkness",
            category: "decoration",
            card: "Blur",
            type: "float",
            default: 0.0,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.xray",
            category: "decoration",
            card: "Blur",
            type: "bool",
            default: false,
            note: "Disabled when blur.new_optimizations is false."
        },
        {
            path: "decoration.blur.acrylic.aberration",
            category: "decoration",
            card: "Blur Acrylic",
            type: "float",
            default: 0.025,
            min: 0.0,
            max: 0.25
        },
        {
            path: "decoration.blur.acrylic.bulb",
            category: "decoration",
            card: "Blur Acrylic",
            type: "float",
            default: 48.0,
            min: 4.0,
            max: 256.0
        },
        {
            path: "decoration.blur.acrylic.clarity",
            category: "decoration",
            card: "Blur Acrylic",
            type: "float",
            default: 0.82,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.acrylic.refraction",
            category: "decoration",
            card: "Blur Acrylic",
            type: "float",
            default: 24.0,
            min: 0.0,
            max: 48.0
        },
        {
            path: "decoration.blur.acrylic.tint",
            category: "decoration",
            card: "Blur Acrylic",
            type: "color",
            default: "0x14EEF5FF"
        },
        {
            path: "decoration.blur.aurora.color1",
            category: "decoration",
            card: "Blur Aurora",
            type: "color",
            default: "0x29F0A0FF"
        },
        {
            path: "decoration.blur.aurora.color2",
            category: "decoration",
            card: "Blur Aurora",
            type: "color",
            default: "0x7A4DFFFF"
        },
        {
            path: "decoration.blur.aurora.intensity",
            category: "decoration",
            card: "Blur Aurora",
            type: "float",
            default: 0.35,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.aurora.speed",
            category: "decoration",
            card: "Blur Aurora",
            type: "float",
            default: 1.0,
            min: 0.0,
            max: 10.0
        },
        {
            path: "decoration.blur.drops.speed",
            category: "decoration",
            card: "Blur Drops",
            type: "float",
            default: 3.0,
            min: 0.0,
            max: 10.0
        },
        {
            path: "decoration.blur.fluid_jar.color",
            category: "decoration",
            card: "Blur Fluid Jar",
            type: "color",
            default: "0xCC3399FF"
        },
        {
            path: "decoration.blur.fluid_jar.distortion",
            category: "decoration",
            card: "Blur Fluid Jar",
            type: "float",
            default: 8.0,
            min: 0.0,
            max: 10.0
        },
        {
            path: "decoration.blur.fluid_jar.fill_amount",
            category: "decoration",
            card: "Blur Fluid Jar",
            type: "float",
            default: 0.5,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.fluid_jar.mass",
            category: "decoration",
            card: "Blur Fluid Jar",
            type: "float",
            default: 1.4,
            min: 0.1,
            max: 10.0
        },
        {
            path: "decoration.blur.fluid_jar.precision",
            category: "decoration",
            card: "Blur Fluid Jar",
            type: "float",
            default: 2.0,
            min: 0.5,
            max: 8.0
        },
        {
            path: "decoration.blur.fluid_jar.speed",
            category: "decoration",
            card: "Blur Fluid Jar",
            type: "float",
            default: 3.7,
            min: 0.0,
            max: 10.0
        },
        {
            path: "decoration.blur.fluid_jar.turbulence",
            category: "decoration",
            card: "Blur Fluid Jar",
            type: "float",
            default: 1.2,
            min: 0.0,
            max: 5.0
        },
        {
            path: "decoration.blur.glass.refraction",
            category: "decoration",
            card: "Blur Glass",
            type: "float",
            default: 20.0,
            min: 0.0,
            max: 20.0
        },
        {
            path: "decoration.blur.glass.roughness",
            category: "decoration",
            card: "Blur Glass",
            type: "float",
            default: 1.0,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.glass.size",
            category: "decoration",
            card: "Blur Glass",
            type: "float",
            default: 40.0,
            min: 4.0,
            max: 512.0
        },
        {
            path: "decoration.blur.haze.intensity",
            category: "decoration",
            card: "Blur Haze",
            type: "float",
            default: 0.35,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.haze.iridescence",
            category: "decoration",
            card: "Blur Haze",
            type: "float",
            default: 0.7,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.heat_shimmer.speed",
            category: "decoration",
            card: "Blur Heat Shimmer",
            type: "float",
            default: 1.0,
            min: 0.0,
            max: 10.0
        },
        {
            path: "decoration.blur.ripple.duration",
            category: "decoration",
            card: "Blur Ripple",
            type: "float",
            default: 0.45,
            min: 0.05,
            max: 5.0
        },
        {
            path: "decoration.blur.ripple.radius",
            category: "decoration",
            card: "Blur Ripple",
            type: "float",
            default: 400.0,
            min: 1.0,
            max: 1000.0
        },
        {
            path: "decoration.blur.ripple.strength",
            category: "decoration",
            card: "Blur Ripple",
            type: "float",
            default: 30.0,
            min: 0.0,
            max: 32.0
        },
        {
            path: "decoration.blur.ripple.width",
            category: "decoration",
            card: "Blur Ripple",
            type: "float",
            default: 32.0,
            min: 1.0,
            max: 200.0
        },
        {
            path: "decoration.blur.water.damping",
            category: "decoration",
            card: "Blur Water",
            type: "float",
            default: 0.95,
            min: 0.0,
            max: 1.0
        },
        {
            path: "decoration.blur.water.duration",
            category: "decoration",
            card: "Blur Water",
            type: "float",
            default: 12.0,
            min: 0.5,
            max: 60.0
        },
        {
            path: "decoration.blur.water.radius",
            category: "decoration",
            card: "Blur Water",
            type: "float",
            default: 20.0,
            min: 1.0,
            max: 1000.0
        },
        {
            path: "decoration.blur.water.speed",
            category: "decoration",
            card: "Blur Water",
            type: "float",
            default: 0.76,
            min: 0.0,
            max: 10.0
        },
        {
            path: "decoration.blur.water.strength",
            category: "decoration",
            card: "Blur Water",
            type: "float",
            default: 32.0,
            min: 0.0,
            max: 32.0
        },
        {
            path: "decoration.shadow.enabled",
            category: "decoration",
            card: "Shadow",
            type: "bool",
            default: true
        },
        {
            path: "decoration.shadow.offset",
            category: "decoration",
            card: "Shadow",
            type: "vec2",
            default: [0, 0]
        },
        {
            path: "decoration.shadow.range",
            category: "decoration",
            card: "Shadow",
            type: "int",
            default: 4,
            min: 0,
            max: 100
        },
        {
            path: "decoration.shadow.render_power",
            category: "decoration",
            card: "Shadow",
            type: "int",
            default: 3,
            min: 1,
            max: 4
        },
        {
            path: "decoration.shadow.scale",
            category: "decoration",
            card: "Shadow",
            type: "float",
            default: 1.0,
            min: 0.05,
            max: 2.0
        },
        {
            path: "decoration.shadow.sharp",
            category: "decoration",
            card: "Shadow",
            type: "bool",
            default: false
        },
        {
            path: "decoration.glow.enabled",
            category: "decoration",
            card: "Glow",
            type: "bool",
            default: false
        },
        {
            path: "decoration.glow.color",
            category: "decoration",
            card: "Glow",
            type: "color",
            default: "0xee1a1a1a"
        },
        {
            path: "decoration.glow.color_inactive",
            category: "decoration",
            card: "Glow",
            type: "color",
            default: "",
            note: "Falls back to glow.color when empty."
        },
        {
            path: "decoration.glow.range",
            category: "decoration",
            card: "Glow",
            type: "int",
            default: 10,
            min: 0,
            max: 100
        },
        {
            path: "decoration.glow.render_power",
            category: "decoration",
            card: "Glow",
            type: "int",
            default: 3,
            min: 1,
            max: 4
        },
        {
            path: "decoration.motion_blur.enabled",
            category: "decoration",
            card: "Motion Blur",
            type: "bool",
            default: false
        },
        {
            path: "decoration.motion_blur.samples",
            category: "decoration",
            card: "Motion Blur",
            type: "int",
            default: 7,
            min: 1,
            max: 64
        },
        {
            path: "decoration.wobble.enabled",
            category: "decoration",
            card: "Wobble",
            type: "bool",
            default: false
        },
        {
            path: "decoration.wobble.mesh",
            category: "decoration",
            card: "Wobble",
            type: "int",
            default: 12,
            min: 2,
            max: 32
        },
        {
            path: "decoration.wobble.stiffness",
            category: "decoration",
            card: "Wobble",
            type: "float",
            default: 200,
            min: 0.0001,
            max: 1000
        },
        {
            path: "decoration.wobble.damping",
            category: "decoration",
            card: "Wobble",
            type: "float",
            default: 12,
            min: 0,
            max: 1000
        },
        {
            path: "decoration.wobble.mass",
            category: "decoration",
            card: "Wobble",
            type: "float",
            default: 1,
            min: 0.0001,
            max: 1000
        },
        {
            path: "decoration.wobble.intensity",
            category: "decoration",
            card: "Wobble",
            type: "float",
            default: 0.2,
            min: 0,
            max: 3
        },
        {
            path: "decoration.wobble.value_epsilon",
            category: "decoration",
            card: "Wobble",
            type: "float",
            default: 0.25,
            min: 0,
            max: 100
        },
        {
            path: "decoration.wobble.velocity_epsilon",
            category: "decoration",
            card: "Wobble",
            type: "float",
            default: 2,
            min: 0,
            max: 1000
        },
        // input
        {
            path: "input.accel_profile",
            category: "input",
            card: "Input",
            type: "enum",
            default: "",
            values: ["", "adaptive", "flat", "custom"]
        },
        {
            path: "input.emulate_discrete_scroll",
            category: "input",
            card: "Input",
            type: "int",
            default: 1,
            min: 0,
            max: 2
        },
        {
            path: "input.float_switch_override_focus",
            category: "input",
            card: "Input",
            type: "int",
            default: 1,
            min: 0,
            max: 2
        },
        {
            path: "input.focus_on_close",
            category: "input",
            card: "Input",
            type: "int",
            default: 0,
            min: 0,
            max: 2
        },
        {
            path: "input.follow_mouse",
            category: "input",
            card: "Input",
            type: "int",
            default: 1,
            min: 0,
            max: 3
        },
        {
            path: "input.follow_mouse_shrink",
            category: "input",
            card: "Input",
            type: "int",
            default: 0,
            min: 0,
            max: 300
        },
        {
            path: "input.follow_mouse_threshold",
            category: "input",
            card: "Input",
            type: "float",
            default: 0.0
        },
        {
            path: "input.force_no_accel",
            category: "input",
            card: "Input",
            type: "bool",
            default: false
        },
        {
            path: "input.kb_file",
            category: "input",
            card: "Input",
            type: "string",
            default: ""
        },
        {
            path: "input.kb_layout",
            category: "input",
            card: "Input",
            type: "string",
            default: "us"
        },
        {
            path: "input.kb_model",
            category: "input",
            card: "Input",
            type: "string",
            default: ""
        },
        {
            path: "input.kb_options",
            category: "input",
            card: "Input",
            type: "string",
            default: ""
        },
        {
            path: "input.kb_rules",
            category: "input",
            card: "Input",
            type: "string",
            default: ""
        },
        {
            path: "input.kb_variant",
            category: "input",
            card: "Input",
            type: "string",
            default: ""
        },
        {
            path: "input.left_handed",
            category: "input",
            card: "Input",
            type: "bool",
            default: false
        },
        {
            path: "input.mouse_refocus",
            category: "input",
            card: "Input",
            type: "bool",
            default: true
        },
        {
            path: "input.natural_scroll",
            category: "input",
            card: "Input",
            type: "bool",
            default: false
        },
        {
            path: "input.numlock_by_default",
            category: "input",
            card: "Input",
            type: "bool",
            default: false
        },
        {
            path: "input.off_window_axis_events",
            category: "input",
            card: "Input",
            type: "int",
            default: 1,
            min: 0,
            max: 3
        },
        {
            path: "input.repeat_delay",
            category: "input",
            card: "Input",
            type: "int",
            default: 600,
            min: 0,
            max: 2000
        },
        {
            path: "input.repeat_rate",
            category: "input",
            card: "Input",
            type: "int",
            default: 25,
            min: 0,
            max: 200
        },
        {
            path: "input.resolve_binds_by_sym",
            category: "input",
            card: "Input",
            type: "bool",
            default: false
        },
        {
            path: "input.rotation",
            category: "input",
            card: "Input",
            type: "int",
            default: 0,
            min: 0,
            max: 359
        },
        {
            path: "input.scroll_button",
            category: "input",
            card: "Input",
            type: "int",
            default: 0,
            min: 0,
            max: 300
        },
        {
            path: "input.scroll_button_lock",
            category: "input",
            card: "Input",
            type: "bool",
            default: false
        },
        {
            path: "input.scroll_factor",
            category: "input",
            card: "Input",
            type: "float",
            default: 1.0,
            min: 0,
            max: 100
        },
        {
            path: "input.scroll_method",
            category: "input",
            card: "Input",
            type: "enum",
            default: "",
            values: ["", "2fg", "edge", "on_button_down", "no_scroll"]
        },
        {
            path: "input.scroll_points",
            category: "input",
            card: "Input",
            type: "string",
            default: "",
            note: "Step and points list; requires accel_profile set to custom."
        },
        {
            path: "input.sensitivity",
            category: "input",
            card: "Input",
            type: "float",
            default: 0.0,
            min: -1.0,
            max: 1.0
        },
        {
            path: "input.special_fallthrough",
            category: "input",
            card: "Input",
            type: "bool",
            default: false
        },
        {
            path: "input.swallow_focus_click",
            category: "input",
            card: "Input",
            type: "bool",
            default: false
        },
        {
            path: "input.touchpad.clickfinger_behavior",
            category: "input",
            card: "Touchpad",
            type: "bool",
            default: false
        },
        {
            path: "input.touchpad.disable_while_typing",
            category: "input",
            card: "Touchpad",
            type: "bool",
            default: true
        },
        {
            path: "input.touchpad.drag_3fg",
            category: "input",
            card: "Touchpad",
            type: "int",
            default: 0,
            min: 0,
            max: 2
        },
        {
            path: "input.touchpad.drag_lock",
            category: "input",
            card: "Touchpad",
            type: "int",
            default: 0,
            min: 0,
            max: 2
        },
        {
            path: "input.touchpad.flip_x",
            category: "input",
            card: "Touchpad",
            type: "bool",
            default: false
        },
        {
            path: "input.touchpad.flip_y",
            category: "input",
            card: "Touchpad",
            type: "bool",
            default: false
        },
        {
            path: "input.touchpad.middle_button_emulation",
            category: "input",
            card: "Touchpad",
            type: "bool",
            default: false
        },
        {
            path: "input.touchpad.natural_scroll",
            category: "input",
            card: "Touchpad",
            type: "bool",
            default: false
        },
        {
            path: "input.touchpad.scroll_factor",
            category: "input",
            card: "Touchpad",
            type: "float",
            default: 1.0,
            min: 0.0,
            max: 100
        },
        {
            path: "input.touchpad.tap_and_drag",
            category: "input",
            card: "Touchpad",
            type: "bool",
            default: true
        },
        {
            path: "input.touchpad.tap_button_map",
            category: "input",
            card: "Touchpad",
            type: "enum",
            default: "",
            values: ["", "lrm", "lmr"]
        },
        {
            path: "input.touchpad.tap_to_click",
            category: "input",
            card: "Touchpad",
            type: "bool",
            default: true
        },
        {
            path: "input.touchdevice.enabled",
            category: "input",
            card: "Touch Devices",
            type: "bool",
            default: true
        },
        {
            path: "input.touchdevice.output",
            category: "input",
            card: "Touch Devices",
            type: "string",
            default: "",
            note: "Empty string stops auto-detection of the output."
        },
        {
            path: "input.touchdevice.transform",
            category: "input",
            card: "Touch Devices",
            type: "int",
            default: 0,
            min: 0,
            max: 6
        },
        {
            path: "input.virtualkeyboard.release_pressed_on_close",
            category: "input",
            card: "Virtual Keyboard",
            type: "bool",
            default: false
        },
        {
            path: "input.virtualkeyboard.share_states",
            category: "input",
            card: "Virtual Keyboard",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "input.tablet.enabled",
            category: "input",
            card: "Tablet",
            type: "bool",
            default: true
        },
        {
            path: "input.tablet.output",
            category: "input",
            card: "Tablet",
            type: "string",
            default: "",
            note: "Monitor name or current."
        },
        {
            path: "input.tablet.transform",
            category: "input",
            card: "Tablet",
            type: "int",
            default: 0,
            min: 0,
            max: 6
        },
        {
            path: "input.tablet.absolute_region_position",
            category: "input",
            card: "Tablet",
            type: "bool",
            default: false
        },
        {
            path: "input.tablet.active_area_position",
            category: "input",
            card: "Tablet",
            type: "vec2",
            default: [0, 0]
        },
        {
            path: "input.tablet.active_area_size",
            category: "input",
            card: "Tablet",
            type: "vec2",
            default: [0, 0]
        },
        {
            path: "input.tablet.left_handed",
            category: "input",
            card: "Tablet",
            type: "bool",
            default: false
        },
        {
            path: "input.tablet.region_position",
            category: "input",
            card: "Tablet",
            type: "vec2",
            default: [0, 0]
        },
        {
            path: "input.tablet.region_size",
            category: "input",
            card: "Tablet",
            type: "vec2",
            default: [0, 0]
        },
        {
            path: "input.tablet.relative_input",
            category: "input",
            card: "Tablet",
            type: "bool",
            default: false
        },
        {
            path: "input.tablettool.eraser_button_mode",
            category: "input",
            card: "Tablet Tools",
            type: "int",
            default: 0,
            min: 0,
            max: 6
        },
        {
            path: "input.tablettool.eraser_button_override",
            category: "input",
            card: "Tablet Tools",
            type: "int",
            default: 0,
            min: 0
        },
        {
            path: "input.tablettool.pressure_range_min",
            category: "input",
            card: "Tablet Tools",
            type: "float",
            default: -1.0,
            min: -1.0,
            max: 1.0,
            note: "Negative means device default."
        },
        {
            path: "input.tablettool.pressure_range_max",
            category: "input",
            card: "Tablet Tools",
            type: "float",
            default: -1.0,
            min: -1.0,
            max: 1.0,
            note: "Negative means device default."
        },
        // group
        {
            path: "group.auto_group",
            category: "group",
            card: "Group",
            type: "bool",
            default: true
        },
        {
            path: "group.drag_into_group",
            category: "group",
            card: "Group",
            type: "int",
            default: 1,
            min: 0,
            max: 2
        },
        {
            path: "group.focus_removed_window",
            category: "group",
            card: "Group",
            type: "bool",
            default: true
        },
        {
            path: "group.group_on_movetoworkspace",
            category: "group",
            card: "Group",
            type: "bool",
            default: false
        },
        {
            path: "group.insert_after_current",
            category: "group",
            card: "Group",
            type: "bool",
            default: true
        },
        {
            path: "group.merge_floated_into_tiled_on_groupbar",
            category: "group",
            card: "Group",
            type: "bool",
            default: false
        },
        {
            path: "group.merge_groups_on_drag",
            category: "group",
            card: "Group",
            type: "bool",
            default: true
        },
        {
            path: "group.merge_groups_on_groupbar",
            category: "group",
            card: "Group",
            type: "bool",
            default: false,
            note: "Requires drag_into_group set to 2 and merge_groups_on_drag enabled."
        },
        {
            path: "group.groupbar.enabled",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: true
        },
        {
            path: "group.groupbar.blur",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: false
        },
        {
            path: "group.groupbar.disable_when_only",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: false
        },
        {
            path: "group.groupbar.font_family",
            category: "group",
            card: "Group Bar",
            type: "string",
            default: "",
            note: "Falls back to misc.font_family when empty."
        },
        {
            path: "group.groupbar.font_size",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 8,
            min: 2,
            max: 64
        },
        {
            path: "group.groupbar.font_weight_active",
            category: "group",
            card: "Group Bar",
            type: "enum",
            default: "normal",
            values: ["thin", "ultralight", "light", "semilight", "book", "normal", "medium", "semibold", "bold", "ultrabold", "heavy", "ultraheavy"]
        },
        {
            path: "group.groupbar.font_weight_inactive",
            category: "group",
            card: "Group Bar",
            type: "enum",
            default: "normal",
            values: ["thin", "ultralight", "light", "semilight", "book", "normal", "medium", "semibold", "bold", "ultrabold", "heavy", "ultraheavy"]
        },
        {
            path: "group.groupbar.gaps_in",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 2,
            min: 0,
            max: 20
        },
        {
            path: "group.groupbar.gaps_out",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 2,
            min: 0,
            max: 20
        },
        {
            path: "group.groupbar.gradients",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: false
        },
        {
            path: "group.groupbar.gradient_round_only_edges",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: true
        },
        {
            path: "group.groupbar.gradient_rounding",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 2,
            min: 0,
            max: 100
        },
        {
            path: "group.groupbar.gradient_rounding_power",
            category: "group",
            card: "Group Bar",
            type: "float",
            default: 2.0,
            min: 1.0,
            max: 10.0
        },
        {
            path: "group.groupbar.height",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 14,
            min: 0,
            max: 64
        },
        {
            path: "group.groupbar.indicator_gap",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 0,
            min: 0,
            max: 64
        },
        {
            path: "group.groupbar.indicator_height",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 3,
            min: 0,
            max: 64
        },
        {
            path: "group.groupbar.keep_upper_gap",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: true
        },
        {
            path: "group.groupbar.middle_click_close",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: true
        },
        {
            path: "group.groupbar.priority",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 3,
            min: 0,
            max: 6
        },
        {
            path: "group.groupbar.render_titles",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: true
        },
        {
            path: "group.groupbar.round_only_edges",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: true
        },
        {
            path: "group.groupbar.rounding",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 1,
            min: 0,
            max: 40
        },
        {
            path: "group.groupbar.rounding_power",
            category: "group",
            card: "Group Bar",
            type: "float",
            default: 2.0,
            min: 1.0,
            max: 10.0
        },
        {
            path: "group.groupbar.scrolling",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: true
        },
        {
            path: "group.groupbar.stacked",
            category: "group",
            card: "Group Bar",
            type: "bool",
            default: false
        },
        {
            path: "group.groupbar.text_color",
            category: "group",
            card: "Group Bar",
            type: "color",
            default: "0xffffffff"
        },
        {
            path: "group.groupbar.text_color_inactive",
            category: "group",
            card: "Group Bar",
            type: "color",
            default: "",
            note: "Falls back to text_color when empty."
        },
        {
            path: "group.groupbar.text_color_locked_active",
            category: "group",
            card: "Group Bar",
            type: "color",
            default: "",
            note: "Falls back to text_color when empty."
        },
        {
            path: "group.groupbar.text_color_locked_inactive",
            category: "group",
            card: "Group Bar",
            type: "color",
            default: "",
            note: "Falls back to text_color_inactive when empty."
        },
        {
            path: "group.groupbar.text_offset",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 0,
            min: -20,
            max: 20
        },
        {
            path: "group.groupbar.text_padding",
            category: "group",
            card: "Group Bar",
            type: "int",
            default: 0,
            min: 0,
            max: 22
        },
        // misc
        {
            path: "misc.allow_session_lock_restore",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.always_follow_on_dnd",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: true
        },
        {
            path: "misc.animate_manual_resizes",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.animate_mouse_windowdragging",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.anr_missed_pings",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 5,
            min: 1,
            max: 20
        },
        {
            path: "misc.background_color",
            category: "misc",
            card: "Misc",
            type: "color",
            default: "0x111111",
            note: "Requires disable_hyprland_logo enabled."
        },
        {
            path: "misc.bell_sound",
            category: "misc",
            card: "Misc",
            type: "string",
            default: "default",
            note: "none or empty mutes, default uses the system sound, otherwise a path."
        },
        {
            path: "misc.close_special_on_empty",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: true
        },
        {
            path: "misc.disable_autoreload",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.disable_hyprland_guiutils_check",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.disable_hyprland_logo",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.disable_scale_notification",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.disable_splash_rendering",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false,
            note: "Monitor reload required."
        },
        {
            path: "misc.disable_watchdog_warning",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.disable_xdg_env_checks",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.enable_anr_dialog",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: true
        },
        {
            path: "misc.enable_swallow",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.exit_window_retains_fullscreen",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 0,
            min: 0,
            max: 3
        },
        {
            path: "misc.float_force_onscreen",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 0,
            min: 0,
            max: 2
        },
        {
            path: "misc.new_float_force_onscreen",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "misc.focus_on_activate",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.font_family",
            category: "misc",
            card: "Misc",
            type: "string",
            default: "Sans"
        },
        {
            path: "misc.force_default_wallpaper",
            category: "misc",
            card: "Misc",
            type: "int",
            default: -1,
            min: -1,
            max: 2,
            note: "-1 picks a random wallpaper."
        },
        {
            path: "misc.initial_workspace_token_timeout",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 10,
            min: 1,
            max: 3600
        },
        {
            path: "misc.initial_workspace_tracking",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 1,
            min: 0,
            max: 2
        },
        {
            path: "misc.key_press_enables_dpms",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.lockdead_screen_delay",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 1000,
            min: 0,
            max: 5000
        },
        {
            path: "misc.middle_click_paste",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: true
        },
        {
            path: "misc.mouse_move_enables_dpms",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.mouse_move_focuses_monitor",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: true
        },
        {
            path: "misc.name_vk_after_proc",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: true
        },
        {
            path: "misc.on_focus_under_fullscreen",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "misc.render_unfocused_fps",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 15,
            min: 1,
            max: 120
        },
        {
            path: "misc.screencopy_force_8b",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: true
        },
        {
            path: "misc.session_lock_blur",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false,
            note: "Requires session_lock_xray enabled."
        },
        {
            path: "misc.session_lock_xray",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.size_limits_tiled",
            category: "misc",
            card: "Misc",
            type: "bool",
            default: false
        },
        {
            path: "misc.splash_font_family",
            category: "misc",
            card: "Misc",
            type: "string",
            default: "",
            note: "Monitor reload required."
        },
        {
            path: "misc.swallow_exception_regex",
            category: "misc",
            card: "Misc",
            type: "string",
            default: ""
        },
        {
            path: "misc.swallow_regex",
            category: "misc",
            card: "Misc",
            type: "string",
            default: ""
        },
        {
            path: "misc.vrr",
            category: "misc",
            card: "Misc",
            type: "int",
            default: 0,
            min: 0,
            max: 3
        },
        {
            path: "misc.col.splash",
            category: "misc",
            card: "Splash",
            type: "color",
            default: "0x55ffffff",
            note: "Monitor reload required."
        },
        // binds
        {
            path: "binds.allow_pin_fullscreen",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: false
        },
        {
            path: "binds.client_requested_fs_uses_layout_handler",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: true
        },
        {
            path: "binds.allow_workspace_cycles",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: false
        },
        {
            path: "binds.disable_keybind_grabbing",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: false
        },
        {
            path: "binds.drag_threshold",
            category: "binds",
            card: "Binds",
            type: "int",
            default: 0,
            min: 0,
            note: "0 disables the threshold."
        },
        {
            path: "binds.focus_preferred_method",
            category: "binds",
            card: "Binds",
            type: "int",
            default: 0,
            min: 0,
            max: 1
        },
        {
            path: "binds.hide_special_on_workspace_change",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: false
        },
        {
            path: "binds.ignore_group_lock",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: false
        },
        {
            path: "binds.movefocus_cycles_fullscreen",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: false
        },
        {
            path: "binds.movefocus_cycles_groupfirst",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: false
        },
        {
            path: "binds.pass_mouse_when_bound",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: false
        },
        {
            path: "binds.scroll_event_delay",
            category: "binds",
            card: "Binds",
            type: "int",
            default: 300,
            min: 0,
            max: 2000
        },
        {
            path: "binds.window_direction_monitor_fallback",
            category: "binds",
            card: "Binds",
            type: "bool",
            default: true
        },
        {
            path: "binds.workspace_back_and_forth",
            category: "binds",
            card: "Binds",
            type: "int",
            default: 0,
            min: 0,
            max: 2
        },
        {
            path: "binds.workspace_center_on",
            category: "binds",
            card: "Binds",
            type: "int",
            default: 1,
            min: 0,
            max: 1
        },
        // render
        {
            path: "render.async_commit",
            category: "render",
            card: "Render",
            type: "bool",
            default: false
        },
        {
            path: "render.cm_auto_hdr",
            category: "render",
            card: "Render",
            type: "int",
            default: 1,
            min: 0,
            max: 2
        },
        {
            path: "render.cm_enabled",
            category: "render",
            card: "Render",
            type: "bool",
            default: true,
            note: "Hyprland restart required."
        },
        {
            path: "render.cm_sdr_eotf",
            category: "render",
            card: "Render",
            type: "enum",
            default: "default",
            values: ["default", "gamma22", "gamma22force", "srgb"]
        },
        {
            path: "render.ctm_animation",
            category: "render",
            card: "Render",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "render.commit_timing_enabled",
            category: "render",
            card: "Render",
            type: "bool",
            default: true,
            note: "Hyprland restart required."
        },
        {
            path: "render.direct_scanout",
            category: "render",
            card: "Render",
            type: "int",
            default: 0,
            min: 0,
            max: 2
        },
        {
            path: "render.expand_undersized_textures",
            category: "render",
            card: "Render",
            type: "bool",
            default: true
        },
        {
            path: "render.fp16_sdr_tf",
            category: "render",
            card: "Render",
            type: "int",
            default: 0,
            min: 0,
            max: 1
        },
        {
            path: "render.icc_vcgt_enabled",
            category: "render",
            card: "Render",
            type: "bool",
            default: true
        },
        {
            path: "render.keep_unmodified_copy",
            category: "render",
            card: "Render",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "render.new_render_scheduling",
            category: "render",
            card: "Render",
            type: "bool",
            default: false
        },
        {
            path: "render.not_shown_fifo_lock",
            category: "render",
            card: "Render",
            type: "int",
            default: 0,
            min: 0,
            max: 2
        },
        {
            path: "render.non_shader_cm",
            category: "render",
            card: "Render",
            type: "int",
            default: 2,
            min: 0,
            max: 3
        },
        {
            path: "render.non_shader_cm_interop",
            category: "render",
            card: "Render",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "render.send_content_type",
            category: "render",
            card: "Render",
            type: "bool",
            default: true
        },
        {
            path: "render.use_fp16",
            category: "render",
            card: "Render",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "render.use_shader_blur_blend",
            category: "render",
            card: "Render",
            type: "bool",
            default: false
        },
        {
            path: "render.xp_mode",
            category: "render",
            card: "Render",
            type: "bool",
            default: false
        },
        // cursor
        {
            path: "cursor.default_monitor",
            category: "cursor",
            card: "Cursor",
            type: "string",
            default: ""
        },
        {
            path: "cursor.enable_hyprcursor",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: true
        },
        {
            path: "cursor.hide_on_key_press",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: false
        },
        {
            path: "cursor.hide_on_tablet",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: false
        },
        {
            path: "cursor.hide_on_touch",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: true
        },
        {
            path: "cursor.hotspot_padding",
            category: "cursor",
            card: "Cursor",
            type: "int",
            default: 0,
            min: 0,
            max: 20
        },
        {
            path: "cursor.inactive_timeout",
            category: "cursor",
            card: "Cursor",
            type: "float",
            default: 0,
            min: 0,
            max: 20,
            note: "0 means never hide."
        },
        {
            path: "cursor.invisible",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: false
        },
        {
            path: "cursor.min_refresh_rate",
            category: "cursor",
            card: "Cursor",
            type: "int",
            default: 24,
            min: 10,
            max: 500
        },
        {
            path: "cursor.no_break_fs_vrr",
            category: "cursor",
            card: "Cursor",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "cursor.no_hardware_cursors",
            category: "cursor",
            card: "Cursor",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "cursor.no_warps",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: false
        },
        {
            path: "cursor.persistent_warps",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: false
        },
        {
            path: "cursor.sync_gsettings_theme",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: true
        },
        {
            path: "cursor.use_cpu_buffer",
            category: "cursor",
            card: "Cursor",
            type: "int",
            default: 2,
            min: 0,
            max: 2
        },
        {
            path: "cursor.warp_back_after_non_mouse_input",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: false
        },
        {
            path: "cursor.warp_on_change_workspace",
            category: "cursor",
            card: "Cursor",
            type: "int",
            default: 0,
            min: 0,
            max: 2
        },
        {
            path: "cursor.warp_on_monitor_change",
            category: "cursor",
            card: "Cursor",
            type: "int",
            default: -1,
            min: -1,
            max: 2,
            note: "-1 follows warp_on_change_workspace."
        },
        {
            path: "cursor.warp_on_toggle_special",
            category: "cursor",
            card: "Cursor",
            type: "int",
            default: 0,
            min: 0,
            max: 2
        },
        {
            path: "cursor.zoom_detached_camera",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: true
        },
        {
            path: "cursor.zoom_disable_aa",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: false
        },
        {
            path: "cursor.zoom_factor",
            category: "cursor",
            card: "Cursor",
            type: "float",
            default: 1.0,
            min: 1,
            max: 10,
            note: "1.0 means no zoom."
        },
        {
            path: "cursor.zoom_rigid",
            category: "cursor",
            card: "Cursor",
            type: "bool",
            default: false
        },
        // debug
        {
            path: "debug.colored_stdout_logs",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: true
        },
        {
            path: "debug.damage_blink",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false,
            note: "Epilepsy warning: flashes the screen on damage."
        },
        {
            path: "debug.damage_tracking",
            category: "debug",
            card: "Debug",
            type: "int",
            default: 2,
            min: 0,
            max: 2,
            note: "Do not change."
        },
        {
            path: "debug.disable_logs",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: true
        },
        {
            path: "debug.disable_scale_checks",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false
        },
        {
            path: "debug.disable_time",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: true
        },
        {
            path: "debug.ds_handle_same_buffer",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: true
        },
        {
            path: "debug.ds_handle_same_buffer_fifo",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: true
        },
        {
            path: "debug.enable_stdout_logs",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false
        },
        {
            path: "debug.error_limit",
            category: "debug",
            card: "Debug",
            type: "int",
            default: 5,
            min: 0,
            max: 20
        },
        {
            path: "debug.error_position",
            category: "debug",
            card: "Debug",
            type: "int",
            default: 0,
            min: 0,
            max: 1
        },
        {
            path: "debug.fifo_pending_workaround",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false
        },
        {
            path: "debug.full_cm_proto",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false,
            note: "Hyprland restart required."
        },
        {
            path: "debug.gl_debugging",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false,
            note: "Hyprland restart required."
        },
        {
            path: "debug.invalidate_buffers",
            category: "debug",
            card: "Debug",
            type: "int",
            default: 1,
            min: 0,
            max: 1
        },
        {
            path: "debug.log_damage",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false
        },
        {
            path: "debug.overlay",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false,
            note: "Disables VFR for accurate results."
        },
        {
            path: "debug.pass",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false
        },
        {
            path: "debug.render_solitary_wo_damage",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false
        },
        {
            path: "debug.suppress_errors",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: false
        },
        {
            path: "debug.vfr",
            category: "debug",
            card: "Debug",
            type: "bool",
            default: true
        },
        // advanced (small root categories merged)
        {
            path: "layers.allow_new_top_layers_over_existing_fullscreen",
            category: "advanced",
            card: "Layers",
            type: "bool",
            default: true
        },
        {
            path: "layers.layers_hog_keyboard_focus",
            category: "advanced",
            card: "Layers",
            type: "bool",
            default: true
        },
        {
            path: "layout.single_window_aspect_ratio",
            category: "advanced",
            card: "Layout",
            type: "string",
            default: "0 0",
            note: "Space-separated, e.g. 4 3. Zero disables."
        },
        {
            path: "layout.single_window_aspect_ratio_tolerance",
            category: "advanced",
            card: "Layout",
            type: "float",
            default: 0.1,
            min: 0.0,
            max: 1.0
        },
        {
            path: "xwayland.enabled",
            category: "advanced",
            card: "Xwayland",
            type: "bool",
            default: true
        },
        {
            path: "xwayland.create_abstract_socket",
            category: "advanced",
            card: "Xwayland",
            type: "bool",
            default: false,
            note: "Xwayland restart required, Linux only."
        },
        {
            path: "xwayland.force_zero_scaling",
            category: "advanced",
            card: "Xwayland",
            type: "bool",
            default: false
        },
        {
            path: "xwayland.use_nearest_neighbor",
            category: "advanced",
            card: "Xwayland",
            type: "bool",
            default: true
        },
        {
            path: "opengl.nvidia_anti_flicker",
            category: "advanced",
            card: "OpenGL",
            type: "bool",
            default: true,
            note: "Ignored on non-NVIDIA GPUs."
        },
        {
            path: "ecosystem.enforce_permissions",
            category: "advanced",
            card: "Ecosystem",
            type: "bool",
            default: false
        },
        {
            path: "ecosystem.no_donation_nag",
            category: "advanced",
            card: "Ecosystem",
            type: "bool",
            default: false
        },
        {
            path: "ecosystem.no_update_news",
            category: "advanced",
            card: "Ecosystem",
            type: "bool",
            default: false
        },
        {
            path: "quirks.prefer_hdr",
            category: "advanced",
            card: "Quirks",
            type: "int",
            default: 0,
            min: 0,
            max: 1
        },
        {
            path: "quirks.skip_non_kms_dmabuf_formats",
            category: "advanced",
            card: "Quirks",
            type: "bool",
            default: false
        },
        {
            path: "input-capture.capture_modifiers",
            category: "advanced",
            card: "Input Capture",
            type: "bool",
            default: false
        },
        {
            path: "input-capture.enforce_barriers",
            category: "advanced",
            card: "Input Capture",
            type: "bool",
            default: true
        },
        {
            path: "experimental.wp_cm_1_2",
            category: "advanced",
            card: "Experimental",
            type: "bool",
            default: false
        }
    ]
    readonly property var pages: [
        {
            key: "general",
            label: "General"
        },
        {
            key: "decoration",
            label: "Decoration"
        },
        {
            key: "input",
            label: "Input"
        },
        {
            key: "group",
            label: "Group"
        },
        {
            key: "misc",
            label: "Misc"
        },
        {
            key: "binds",
            label: "Binds"
        },
        {
            key: "render",
            label: "Render"
        },
        {
            key: "cursor",
            label: "Cursor"
        },
        {
            key: "debug",
            label: "Debug"
        },
        {
            key: "advanced",
            label: "Advanced"
        }
    ]

    function              cardsForCategory(category: string): var {
        const cards = [];
        for (const option of root.options) {
            if (option.category !== category)
                continue;
            if (!cards.includes(option.card))
                cards.push(option.card);
        }
        return cards;
    }

    function              choicesFor(path: string): var {
        return root.choicesByPath[path] ?? null;
    }

    function              descriptionFor(path: string): string {
        return root.descriptionsByPath[path] ?? "";
    }

    function              optionLabel(path: string): string {
        const name   = path.substring(path.lastIndexOf(".") + 1);
        const spaced = name.replace(/_/g, " ");
        return spaced.charAt(0).toUpperCase() + spaced.slice(1);
    }

    function              optionsForCard(category: string, card: string): var {
        return root.options.filter(option => option.category === category && option.card === card);
    }

    function              optionsForCategory(category: string): var {
        return root.options.filter(option => option.category === category);
    }

    function              pageLabel(key: string): string {
        const page = root.pages.find(candidate => candidate.key === key);
        return page ? page.label : key;
    }

    // Value meanings for small integer ranges, taken from the wiki's Limits and
    // Description columns (0.57.0). Options listed here get a SplitButton instead
    // of a number field.
    readonly property var choicesByPath: {
        "input.emulate_discrete_scroll": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("Non-Standard Events Only"),
                value: 1
            },
            {
                label: qsTr("Force All"),
                value: 2
            }
        ],
        "input.float_switch_override_focus": [
            {
                label: qsTr("Disabled"),
                value: 0
            },
            {
                label: qsTr("On Tiling-Float Switch"),
                value: 1
            },
            {
                label: qsTr("Also Float-To-Float"),
                value: 2
            }
        ],
        "input.focus_on_close": [
            {
                label: qsTr("Next Candidate"),
                value: 0
            },
            {
                label: qsTr("Window Under Cursor"),
                value: 1
            },
            {
                label: qsTr("Most Recently Used"),
                value: 2
            }
        ],
        "input.follow_mouse": [
            {
                label: qsTr("None"),
                value: 0
            },
            {
                label: qsTr("Always"),
                value: 1
            },
            {
                label: qsTr("Detached Click"),
                value: 2
            },
            {
                label: qsTr("Fully Separate"),
                value: 3
            }
        ],
        "input.off_window_axis_events": [
            {
                label: qsTr("Ignore"),
                value: 0
            },
            {
                label: qsTr("Out-Of-Bound Coords"),
                value: 1
            },
            {
                label: qsTr("Fake Closest Point"),
                value: 2
            },
            {
                label: qsTr("Warp Cursor"),
                value: 3
            }
        ],
        "input.touchpad.drag_3fg": [
            {
                label: qsTr("Disabled"),
                value: 0
            },
            {
                label: qsTr("Three Fingers"),
                value: 1
            },
            {
                label: qsTr("Four Fingers"),
                value: 2
            }
        ],
        "input.touchpad.drag_lock": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("With Timeout"),
                value: 1
            },
            {
                label: qsTr("Sticky"),
                value: 2
            }
        ],
        "input.virtualkeyboard.share_states": [
            {
                label: qsTr("No"),
                value: 0
            },
            {
                label: qsTr("Yes"),
                value: 1
            },
            {
                label: qsTr("Yes Unless IME Client"),
                value: 2
            }
        ],
        "group.drag_into_group": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("On"),
                value: 1
            },
            {
                label: qsTr("Only Into Groupbar"),
                value: 2
            }
        ],
        "misc.exit_window_retains_fullscreen": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("On"),
                value: 1
            },
            {
                label: qsTr("Only Grouped"),
                value: 2
            },
            {
                label: qsTr("Only Non-Grouped"),
                value: 3
            }
        ],
        "misc.float_force_onscreen": [
            {
                label: qsTr("None"),
                value: 0
            },
            {
                label: qsTr("Partially Onscreen"),
                value: 1
            },
            {
                label: qsTr("Fully Onscreen"),
                value: 2
            }
        ],
        "misc.new_float_force_onscreen": [
            {
                label: qsTr("None"),
                value: 0
            },
            {
                label: qsTr("Partially Onscreen"),
                value: 1
            },
            {
                label: qsTr("Fully Onscreen"),
                value: 2
            }
        ],
        "misc.on_focus_under_fullscreen": [
            {
                label: qsTr("Ignore"),
                value: 0
            },
            {
                label: qsTr("Take Over"),
                value: 1
            },
            {
                label: qsTr("Unfullscreen"),
                value: 2
            }
        ],
        "misc.initial_workspace_tracking": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("Single-Shot"),
                value: 1
            },
            {
                label: qsTr("Persistent"),
                value: 2
            }
        ],
        "misc.vrr": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("On"),
                value: 1
            },
            {
                label: qsTr("Fullscreen Only"),
                value: 2
            },
            {
                label: qsTr("Fullscreen Video/Game"),
                value: 3
            }
        ],
        "binds.focus_preferred_method": [
            {
                label: qsTr("Most Recent"),
                value: 0
            },
            {
                label: qsTr("Longer Shared Edges"),
                value: 1
            }
        ],
        "binds.workspace_back_and_forth": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("On"),
                value: 1
            },
            {
                label: qsTr("Per Monitor"),
                value: 2
            }
        ],
        "binds.workspace_center_on": [
            {
                label: qsTr("Cursor"),
                value: 0
            },
            {
                label: qsTr("Last Active Window"),
                value: 1
            }
        ],
        "render.cm_auto_hdr": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("HDR"),
                value: 1
            },
            {
                label: qsTr("HDR EDID"),
                value: 2
            }
        ],
        "render.ctm_animation": [
            {
                label: qsTr("Disabled"),
                value: 0
            },
            {
                label: qsTr("Enabled"),
                value: 1
            },
            {
                label: qsTr("Auto (No NVIDIA)"),
                value: 2
            }
        ],
        "render.direct_scanout": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("On"),
                value: 1
            },
            {
                label: qsTr("Auto (Game Content)"),
                value: 2
            }
        ],
        "render.fp16_sdr_tf": [
            {
                label: qsTr("Monitor"),
                value: 0
            },
            {
                label: qsTr("Linear"),
                value: 1
            }
        ],
        "render.keep_unmodified_copy": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("On"),
                value: 1
            },
            {
                label: qsTr("Auto"),
                value: 2
            }
        ],
        "render.not_shown_fifo_lock": [
            {
                label: qsTr("Always"),
                value: 0
            },
            {
                label: qsTr("Ignore Unfocused"),
                value: 1
            },
            {
                label: qsTr("Never"),
                value: 2
            }
        ],
        "render.non_shader_cm": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("Whenever Possible"),
                value: 1
            },
            {
                label: qsTr("DS + Passthrough"),
                value: 2
            },
            {
                label: qsTr("Off + Ignore Issues"),
                value: 3
            }
        ],
        "render.non_shader_cm_interop": [
            {
                label: qsTr("Disabled In Fullscreen"),
                value: 0
            },
            {
                label: qsTr("Enabled In Fullscreen"),
                value: 1
            },
            {
                label: qsTr("Off For Media Content"),
                value: 2
            }
        ],
        "render.use_fp16": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("On"),
                value: 1
            },
            {
                label: qsTr("HDR Mode"),
                value: 2
            }
        ],
        "cursor.no_break_fs_vrr": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("On"),
                value: 1
            },
            {
                label: qsTr("Auto (Game Content)"),
                value: 2
            }
        ],
        "cursor.no_hardware_cursors": [
            {
                label: qsTr("If Possible"),
                value: 0
            },
            {
                label: qsTr("Never"),
                value: 1
            },
            {
                label: qsTr("Auto When Tearing"),
                value: 2
            }
        ],
        "cursor.use_cpu_buffer": [
            {
                label: qsTr("Off"),
                value: 0
            },
            {
                label: qsTr("On"),
                value: 1
            },
            {
                label: qsTr("Auto (NVIDIA)"),
                value: 2
            }
        ],
        "cursor.warp_on_change_workspace": [
            {
                label: qsTr("Disabled"),
                value: 0
            },
            {
                label: qsTr("Enabled"),
                value: 1
            },
            {
                label: qsTr("Force (Ignores no_warps)"),
                value: 2
            }
        ],
        "cursor.warp_on_monitor_change": [
            {
                label: qsTr("Follow Workspace Warp"),
                value: -1
            },
            {
                label: qsTr("Disabled"),
                value: 0
            },
            {
                label: qsTr("Enabled"),
                value: 1
            },
            {
                label: qsTr("Force (Ignores no_warps)"),
                value: 2
            }
        ],
        "cursor.warp_on_toggle_special": [
            {
                label: qsTr("Disabled"),
                value: 0
            },
            {
                label: qsTr("Enabled"),
                value: 1
            },
            {
                label: qsTr("Force (Ignores no_warps)"),
                value: 2
            }
        ],
        "debug.damage_tracking": [
            {
                label: qsTr("None"),
                value: 0
            },
            {
                label: qsTr("Monitor"),
                value: 1
            },
            {
                label: qsTr("Full"),
                value: 2
            }
        ],
        "debug.error_position": [
            {
                label: qsTr("Top"),
                value: 0
            },
            {
                label: qsTr("Bottom"),
                value: 1
            }
        ],
        "debug.invalidate_buffers": [
            {
                label: qsTr("Not Allowed"),
                value: 0
            },
            {
                label: qsTr("Allowed"),
                value: 1
            }
        ]
    }
    readonly property var descriptionsByPath: {
        "binds.allow_pin_fullscreen": "Allow fullscreen on pinned windows, restoring pin state after",
        "binds.allow_workspace_cycles": "Workspaces remember their previous workspace, enabling cycle loops",
        "binds.client_requested_fs_uses_layout_handler": "Let the layout handler manage client-requested fullscreen",
        "binds.disable_keybind_grabbing": "Ignore apps that request to disable keybinds, e.g. VMs",
        "binds.drag_threshold": "Movement threshold in px for window drags and click/drag bind flags",
        "binds.focus_preferred_method": "How directional focus picks a window when several match",
        "binds.hide_special_on_workspace_change": "Hide the special workspace when changing workspaces",
        "binds.ignore_group_lock": "Group move dispatchers ignore per-group locks",
        "binds.movefocus_cycles_fullscreen": "Directional focus can seek windows out of fullscreen",
        "binds.movefocus_cycles_groupfirst": "Directional focus cycles through group windows first",
        "binds.pass_mouse_when_bound": "Pass mouse events through while a keybind fires",
        "binds.scroll_event_delay": "Delay in ms between scroll bind events",
        "binds.window_direction_monitor_fallback": "Moving focus or a window past a monitor edge reaches the next monitor",
        "binds.workspace_back_and_forth": "Switching to the current workspace goes back to the previous one",
        "binds.workspace_center_on": "What the cursor centers on when switching workspaces",
        "cursor.default_monitor": "Monitor the cursor starts on, by name",
        "cursor.enable_hyprcursor": "Enable hyprcursor cursor theme support",
        "cursor.hide_on_key_press": "Hide the cursor while typing until the mouse moves",
        "cursor.hide_on_tablet": "Hide the cursor after tablet input until the mouse moves",
        "cursor.hide_on_touch": "Hide the cursor after touch input until the mouse moves",
        "cursor.hotspot_padding": "Padding in logical px between the cursor and screen edges",
        "cursor.inactive_timeout": "Seconds of cursor inactivity before hiding it, 0 for never",
        "cursor.invisible": "Do not render the cursor at all",
        "cursor.min_refresh_rate": "Minimum refresh rate for cursor updates when VRR is active",
        "cursor.no_break_fs_vrr": "Avoid cursor-driven frame spikes on fullscreen VRR apps",
        "cursor.no_hardware_cursors": "When to avoid hardware cursors",
        "cursor.no_warps": "Never warp the cursor on focus changes or keybinds",
        "cursor.persistent_warps": "Cursor returns to its last position within a refocused window",
        "cursor.sync_gsettings_theme": "Sync the XCursor theme and size with GSettings",
        "cursor.use_cpu_buffer": "When hardware cursors use a CPU buffer; NVIDIA needs it",
        "cursor.warp_back_after_non_mouse_input": "Restore cursor position after it was moved by non-mouse input",
        "cursor.warp_on_change_workspace": "Warp to the last focused window after changing workspaces",
        "cursor.warp_on_monitor_change": "Warp to the last focused window when changing monitors",
        "cursor.warp_on_toggle_special": "Warp to the last focused window when toggling special workspaces",
        "cursor.zoom_detached_camera": "When zoomed, only follow the cursor at screen edges",
        "cursor.zoom_disable_aa": "Disable antialiasing while zoomed, making things pixelated",
        "cursor.zoom_factor": "Magnification factor around the cursor, 1 disables",
        "cursor.zoom_rigid": "Zoom view follows the cursor rigidly instead of loosely",
        "debug.colored_stdout_logs": "Colorize stdout logs",
        "debug.damage_blink": "Flash damaged areas on screen; epilepsy warning",
        "debug.damage_tracking": "Redraw only damaged parts of the display; leave at Full",
        "debug.disable_logs": "Disable logging to a file",
        "debug.disable_scale_checks": "Skip scale verification; causes rounding artifacts",
        "debug.disable_time": "Omit timestamps from logs",
        "debug.ds_handle_same_buffer": "Direct scanout special case for unmodified buffers",
        "debug.ds_handle_same_buffer_fifo": "Direct scanout FIFO variant of the same-buffer case",
        "debug.enable_stdout_logs": "Also log to stdout",
        "debug.error_limit": "How many config errors to display",
        "debug.error_position": "Which screen edge the config error bar sits on",
        "debug.fifo_pending_workaround": "Workaround for empty FIFO pending lists",
        "debug.full_cm_proto": "Claim support for all color-management protocol features",
        "debug.gl_debugging": "Enable OpenGL and EGL debugging",
        "debug.invalidate_buffers": "Whether buffer invalidation is allowed",
        "debug.log_damage": "Log damage events",
        "debug.overlay": "Show the debug performance overlay",
        "debug.pass": "Debug render passes",
        "debug.render_solitary_wo_damage": "Render solitary windows with empty damage",
        "debug.suppress_errors": "Hide config error popups",
        "debug.vfr": "Variable frame rate; leave enabled to save resources",
        "decoration.active_opacity": "Opacity of focused windows",
        "decoration.border_part_of_window": "Count the border as part of the window",
        "decoration.dim_around": "How much dim_around window rules dim",
        "decoration.dim_inactive": "Dim unfocused windows",
        "decoration.dim_modal": "Dim parents of modal windows",
        "decoration.dim_special": "Dim the screen behind special workspaces",
        "decoration.dim_strength": "How strongly inactive windows dim",
        "decoration.fullscreen_opacity": "Opacity of fullscreen windows",
        "decoration.inactive_opacity": "Opacity of unfocused windows",
        "decoration.rounding": "Corner radius in layout pixels",
        "decoration.rounding_power": "Corner curve shape: 2.0 is a circle, 4.0 a squircle",
        "decoration.screen_shader": "Path to a custom screen shader, empty to disable",
        "decoration.blur.enabled": "Enable window background blur",
        "decoration.blur.brightness": "Blur brightness modulation",
        "decoration.blur.contrast": "Blur contrast modulation",
        "decoration.blur.ignore_opacity": "Blur windows regardless of their opacity",
        "decoration.blur.input_methods": "Blur input method windows like fcitx5",
        "decoration.blur.input_methods_ignorealpha": "Skip blurring pixels below this opacity",
        "decoration.blur.new_optimizations": "Extra blur optimizations, recommended",
        "decoration.blur.noise": "Noise applied to the blur",
        "decoration.blur.passes": "Blur passes; needs at least 1 for blur to apply",
        "decoration.blur.popups": "Blur popups like right-click menus",
        "decoration.blur.popups_ignorealpha": "Skip blurring popup pixels below this opacity",
        "decoration.blur.proportional": "Scale blur strength with pixel opacity",
        "decoration.blur.size": "Blur size (distance)",
        "decoration.blur.special": "Blur behind the special workspace; expensive",
        "decoration.blur.variant": "Blur pattern; heavier ones cost GPU time",
        "decoration.blur.vibrancy": "Boost saturation of blurred colors",
        "decoration.blur.vibrancy_darkness": "How strongly vibrancy affects dark areas",
        "decoration.blur.xray": "Floating windows ignore tiled windows in their blur",
        "decoration.blur.acrylic.aberration": "Acrylic chromatic separation",
        "decoration.blur.acrylic.bulb": "Curved acrylic edge width in px",
        "decoration.blur.acrylic.clarity": "Sharp backdrop passing through the acrylic",
        "decoration.blur.acrylic.refraction": "Maximum acrylic lens displacement in px",
        "decoration.blur.acrylic.tint": "Acrylic tint color; alpha sets absorption",
        "decoration.blur.aurora.color1": "First aurora color; alpha sets its contribution",
        "decoration.blur.aurora.color2": "Second aurora color; alpha sets its contribution",
        "decoration.blur.aurora.intensity": "Aurora color strength",
        "decoration.blur.aurora.speed": "Aurora animation speed, 0 freezes",
        "decoration.blur.drops.speed": "Drops animation speed, 0 disables",
        "decoration.blur.fluid_jar.color": "Fluid color",
        "decoration.blur.fluid_jar.distortion": "Fluid refraction distortion multiplier",
        "decoration.blur.fluid_jar.fill_amount": "How full the fluid container is",
        "decoration.blur.fluid_jar.mass": "Fluid inertial mass",
        "decoration.blur.fluid_jar.precision": "Fluid simulation precision multiplier",
        "decoration.blur.fluid_jar.speed": "Fluid animation speed",
        "decoration.blur.fluid_jar.turbulence": "Interior fluid turbulence multiplier",
        "decoration.blur.glass.refraction": "Maximum glass refraction displacement in px",
        "decoration.blur.glass.roughness": "Glass relief shading strength",
        "decoration.blur.glass.size": "Glass pattern size in px",
        "decoration.blur.haze.intensity": "Haze sheen strength",
        "decoration.blur.haze.iridescence": "Haze color-shift strength",
        "decoration.blur.heat_shimmer.speed": "Shimmer animation speed, 0 disables",
        "decoration.blur.ripple.duration": "Ripple duration in seconds",
        "decoration.blur.ripple.radius": "Ripple maximum radius in px",
        "decoration.blur.ripple.strength": "Ripple maximum refraction in px",
        "decoration.blur.ripple.width": "Ripple wave width in px",
        "decoration.blur.water.damping": "Water wave damping",
        "decoration.blur.water.duration": "Water maximum duration in seconds",
        "decoration.blur.water.radius": "Water pointer radius in px",
        "decoration.blur.water.speed": "Water propagation speed",
        "decoration.blur.water.strength": "Water refraction and injection strength in px",
        "decoration.glow.color": "Active window glow color; alpha sets opacity",
        "decoration.glow.color_inactive": "Inactive glow color; empty falls back to color",
        "decoration.glow.enabled": "Enable inner window glow",
        "decoration.glow.range": "Glow size in px",
        "decoration.glow.render_power": "Glow falloff power; higher is a faster falloff",
        "decoration.motion_blur.enabled": "Blur windows while they move or resize",
        "decoration.motion_blur.samples": "Motion blur samples; more is smoother but costlier",
        "decoration.shadow.enabled": "Enable window drop shadows",
        "decoration.shadow.offset": "Shadow rendering offset",
        "decoration.shadow.range": "Shadow size in px",
        "decoration.shadow.render_power": "Shadow falloff power; higher is a faster falloff",
        "decoration.shadow.scale": "Shadow scale",
        "decoration.shadow.sharp": "Render shadows sharp, as with infinite falloff power",
        "decoration.wobble.damping": "Wobble spring damping",
        "decoration.wobble.enabled": "Wobble windows while they move or resize",
        "decoration.wobble.intensity": "Wobble impulse multiplier",
        "decoration.wobble.mass": "Wobble spring mass",
        "decoration.wobble.mesh": "Wobble mesh vertices per edge",
        "decoration.wobble.stiffness": "Wobble spring stiffness",
        "decoration.wobble.value_epsilon": "Position delta treated as settled",
        "decoration.wobble.velocity_epsilon": "Velocity delta treated as settled",
        "ecosystem.enforce_permissions": "Enable the permission control system",
        "ecosystem.no_donation_nag": "Hide the periodic donation popup",
        "ecosystem.no_update_news": "Hide the new-version news popup",
        "experimental.wp_cm_1_2": "Allow color-management protocol version 2",
        "general.allow_tearing": "Master switch for tearing",
        "general.border_size": "Window border width",
        "general.extend_border_grab_area": "Extend the draggable border area; needs resize_on_border",
        "general.float_gaps": "Gaps between floating windows and monitor edges, -1 for default",
        "general.gaps_in": "Gaps between windows",
        "general.gaps_out": "Gaps between windows and monitor edges",
        "general.gaps_workspaces": "Gaps between workspaces, stacks with gaps_out",
        "general.hover_icon_on_border": "Show a resize cursor icon on borders; needs resize_on_border",
        "general.layout": "Which tiling layout to use",
        "general.locale": "Override the system locale, e.g. en_US",
        "general.modal_parent_blocking": "Keep parents of modal windows interactive",
        "general.no_focus_fallback": "No fallback window when directional focus finds none",
        "general.resize_corner": "Force a resize corner for floating windows, 0 to disable",
        "general.resize_on_border": "Resize windows by dragging borders and gaps",
        "general.snap.border_overlap": "Snap floating windows to one border width apart",
        "general.snap.enabled": "Enable floating window snapping",
        "general.snap.monitor_gap": "Snapping distance to monitor edges in px",
        "general.snap.respect_gaps": "Snapping respects gaps_in",
        "general.snap.window_gap": "Snapping distance between windows in px",
        "group.auto_group": "New windows join the focused unlocked group",
        "group.drag_into_group": "Whether dragging a window into a group merges them",
        "group.focus_removed_window": "Focus the window just moved out of a group",
        "group.groupbar.blur": "Blur the groupbar",
        "group.groupbar.disable_when_only": "Hide the groupbar for single-window groups",
        "group.groupbar.enabled": "Enable groupbars",
        "group.groupbar.font_family": "Groupbar font; empty uses misc.font_family",
        "group.groupbar.font_size": "Groupbar title font size",
        "group.groupbar.font_weight_active": "Active title font weight",
        "group.groupbar.font_weight_inactive": "Inactive title font weight",
        "group.groupbar.gaps_in": "Gap between groupbar gradients",
        "group.groupbar.gaps_out": "Gap between gradients and the window",
        "group.groupbar.gradient_rounding": "Gradient corner rounding",
        "group.groupbar.gradient_rounding_power": "Gradient corner curve shape",
        "group.groupbar.gradient_round_only_edges": "Round only the groupbar gradient edges",
        "group.groupbar.gradients": "Enable groupbar gradients",
        "group.groupbar.height": "Groupbar height",
        "group.groupbar.indicator_gap": "Gap between indicator and titles",
        "group.groupbar.indicator_height": "Groupbar indicator height",
        "group.groupbar.keep_upper_gap": "Keep the gap above the groupbar",
        "group.groupbar.middle_click_close": "Middle click on the groupbar closes the window",
        "group.groupbar.priority": "Groupbar decoration priority",
        "group.groupbar.render_titles": "Render titles in the groupbar",
        "group.groupbar.rounding": "Indicator corner rounding",
        "group.groupbar.rounding_power": "Indicator corner curve shape",
        "group.groupbar.round_only_edges": "Round only the indicator edges",
        "group.groupbar.scrolling": "Scrolling the groupbar switches windows",
        "group.groupbar.stacked": "Render the groupbar vertically",
        "group.groupbar.text_color": "Active title color",
        "group.groupbar.text_color_inactive": "Inactive title color; empty falls back to text_color",
        "group.groupbar.text_color_locked_active": "Locked-group active title color; falls back to text_color",
        "group.groupbar.text_color_locked_inactive": "Locked-group inactive title color; falls back to text_color_inactive",
        "group.groupbar.text_offset": "Vertical title offset",
        "group.groupbar.text_padding": "Horizontal title padding",
        "group.group_on_movetoworkspace": "Moving a window to a workspace merges it into its group",
        "group.insert_after_current": "New group windows spawn after the current one",
        "group.merge_floated_into_tiled_on_groupbar": "Dragging a floating window into a groupbar merges it",
        "group.merge_groups_on_drag": "Groups can be dragged into other groups",
        "group.merge_groups_on_groupbar": "Dragging a group onto another groupbar merges them",
        "input.accel_profile": "Pointer acceleration profile; empty uses libinput default",
        "input.emulate_discrete_scroll": "Turn high-resolution scrolling into discrete scroll events",
        "input.float_switch_override_focus": "Focus the cursor window on tiling-float switches",
        "input.focus_on_close": "What gets focus when a window closes",
        "input.follow_mouse": "How cursor movement affects window focus",
        "input.follow_mouse_shrink": "Shrink inactive hitboxes to create focus dead zones in gaps",
        "input.follow_mouse_threshold": "Minimum cursor travel before refocusing, in px",
        "input.force_no_accel": "Use raw pointer input without acceleration",
        "input.kb_file": "Path to a custom XKB keymap file",
        "input.kb_layout": "XKB keyboard layout",
        "input.kb_model": "XKB keyboard model",
        "input.kb_options": "XKB options",
        "input.kb_rules": "XKB rules",
        "input.kb_variant": "XKB layout variant",
        "input.left_handed": "Swap left and right mouse buttons",
        "input.mouse_refocus": "Refocus on window boundary crossings; needs follow_mouse 1",
        "input.natural_scroll": "Invert scrolling direction",
        "input.numlock_by_default": "Turn numlock on at startup",
        "input.off_window_axis_events": "How scroll events around a window edges behave",
        "input.repeat_delay": "Delay before key repeat kicks in, in ms",
        "input.repeat_rate": "Key repeats per second while held",
        "input.resolve_binds_by_sym": "Match keybinds by symbol across keyboard layouts",
        "input.rotation": "Device rotation in degrees clockwise",
        "input.scroll_button": "Button used for on-button scrolling, 0 default",
        "input.scroll_button_lock": "Toggle scroll-button lock instead of holding it",
        "input.scroll_factor": "Scroll movement multiplier for mice",
        "input.scroll_method": "How scrolling is performed",
        "input.scroll_points": "Custom scroll acceleration curve for accel_profile custom",
        "input.sensitivity": "Mouse sensitivity in the libinput range",
        "input.special_fallthrough": "Floating-only special workspaces do not block regular focus",
        "input.swallow_focus_click": "First click on an unfocused window only focuses it",
        "input.tablet.absolute_region_position": "Treat region_position as absolute in the monitor layout",
        "input.tablet.active_area_position": "Tablet active area position in mm",
        "input.tablet.active_area_size": "Tablet active area size in mm",
        "input.tablet.enabled": "Enable tablet input",
        "input.tablet.left_handed": "Rotate the tablet 180 degrees",
        "input.tablet.output": "Monitor the tablet maps to; empty maps across all",
        "input.tablet.region_position": "Mapped region position relative to the bound monitor",
        "input.tablet.region_size": "Map tablet input to this region size",
        "input.tablet.relative_input": "Use relative tablet input",
        "input.tablet.transform": "Transform applied to tablet input",
        "input.tablettool.eraser_button_mode": "Eraser button sends a button event instead of erasing",
        "input.tablettool.eraser_button_override": "Which button the eraser button emulates",
        "input.tablettool.pressure_range_max": "Tool pressure maximum; negative uses device default",
        "input.tablettool.pressure_range_min": "Tool pressure minimum; negative uses device default",
        "input.touchdevice.enabled": "Enable touch device input",
        "input.touchdevice.output": "Monitor touch devices map to; empty string stops auto-detection",
        "input.touchdevice.transform": "Transform applied to touch input",
        "input.touchpad.clickfinger_behavior": "Multi-finger clicks send fixed buttons instead of by position",
        "input.touchpad.disable_while_typing": "Disable the touchpad while typing",
        "input.touchpad.drag_3fg": "Enable multi-finger drag",
        "input.touchpad.drag_lock": "Keep dragging after lifting the finger",
        "input.touchpad.flip_x": "Invert horizontal touchpad movement",
        "input.touchpad.flip_y": "Invert vertical touchpad movement",
        "input.touchpad.middle_button_emulation": "LMB and RMB together act as middle click",
        "input.touchpad.natural_scroll": "Invert touchpad scrolling direction",
        "input.touchpad.scroll_factor": "Touchpad scroll movement multiplier",
        "input.touchpad.tap_and_drag": "Tap then hold to drag",
        "input.touchpad.tap_button_map": "Finger-count to button mapping for taps",
        "input.touchpad.tap_to_click": "Taps send mouse clicks",
        "input.virtualkeyboard.release_pressed_on_close": "Release held keys when the virtual keyboard closes",
        "input.virtualkeyboard.share_states": "Share key and modifier states with other keyboards",
        "input-capture.capture_modifiers": "Also capture and forward modifier keys",
        "input-capture.enforce_barriers": "Error out on invalid pointer barriers",
        "layers.allow_new_top_layers_over_existing_fullscreen": "Let newly mapped layers render over a covering fullscreen window",
        "layers.layers_hog_keyboard_focus": "Keyboard-interactive layers like launchers keep keyboard focus",
        "layout.single_window_aspect_ratio": "Pad the screen so a lone window matches the ratio, e.g. 4 3",
        "layout.single_window_aspect_ratio_tolerance": "Skip the aspect ratio when padding would be smaller than this",
        "misc.allow_session_lock_restore": "Allow restarting a crashed lock screen",
        "misc.always_follow_on_dnd": "Focus follows the mouse during drag and drop",
        "misc.animate_manual_resizes": "Animate manual window resizes",
        "misc.animate_mouse_windowdragging": "Animate windows dragged by the mouse",
        "misc.anr_missed_pings": "Missed pings before the app-not-responding dialog shows",
        "misc.background_color": "Background color; needs disable_hyprland_logo",
        "misc.bell_sound": "System bell sound: none, default, or a wav/ogg path",
        "misc.close_special_on_empty": "Close special workspaces when their last window closes",
        "misc.disable_autoreload": "Do not auto-reload the config on file changes",
        "misc.disable_hyprland_guiutils_check": "Hide the missing hyprland-guiutils warning",
        "misc.disable_hyprland_logo": "Hide the Hyprland logo and anime background",
        "misc.disable_scale_notification": "Hide the scale-failure notification popup",
        "misc.disable_splash_rendering": "Hide the splash text on the background",
        "misc.disable_watchdog_warning": "Hide the start-hyprland watchdog warning",
        "misc.disable_xdg_env_checks": "Hide the externally-managed XDG environment warning",
        "misc.enable_anr_dialog": "Show the app-not-responding dialog",
        "misc.enable_swallow": "Enable window swallowing",
        "misc.exit_window_retains_fullscreen": "Whether closing a fullscreen window fullscreenes the next one",
        "misc.float_force_onscreen": "Keep existing floating windows on screen",
        "misc.focus_on_activate": "Focus apps that request activation",
        "misc.font_family": "Global default font",
        "misc.force_default_wallpaper": "Which default wallpaper to enforce, -1 random",
        "misc.initial_workspace_token_timeout": "Seconds before workspace-tracking tokens expire",
        "misc.initial_workspace_tracking": "Open windows on the workspace they were invoked from",
        "misc.key_press_enables_dpms": "A key press wakes screensaver-off monitors",
        "misc.lockdead_screen_delay": "Delay before the lockdead screen shows, in ms",
        "misc.middle_click_paste": "Enable middle-click primary-selection paste",
        "misc.mouse_move_enables_dpms": "Mouse movement wakes screensaver-off monitors",
        "misc.mouse_move_focuses_monitor": "Hovering a monitor focuses it",
        "misc.name_vk_after_proc": "Name virtual keyboards after their creating process",
        "misc.new_float_force_onscreen": "Keep newly spawned floating windows on screen",
        "misc.on_focus_under_fullscreen": "What happens when a tiled window is focused under fullscreen",
        "misc.render_unfocused_fps": "FPS cap for windows rendered while unfocused",
        "misc.screencopy_force_8b": "Force 8-bit screen capture",
        "misc.session_lock_blur": "Blur the lock screen; needs session_lock_xray",
        "misc.session_lock_xray": "Keep rendering workspaces under the lock screen",
        "misc.size_limits_tiled": "Apply min and max size rules to tiled windows",
        "misc.splash_font_family": "Splash text font",
        "misc.swallow_exception_regex": "Title regex for windows exempt from swallowing",
        "misc.swallow_regex": "Class regex of windows that swallow others, e.g. terminals",
        "misc.vrr": "Monitor adaptive-sync (VRR) mode",
        "misc.col.splash": "Splash text color",
        "opengl.nvidia_anti_flicker": "Reduce NVIDIA flickering; may cost frames on weaker GPUs",
        "quirks.prefer_hdr": "Report HDR as the preferred mode",
        "quirks.skip_non_kms_dmabuf_formats": "Do not report dmabuf formats KMS cannot import",
        "render.async_commit": "Async DRM commits to cut cursor latency",
        "render.cm_auto_hdr": "Auto-switch to HDR in fullscreen when content wants it",
        "render.cm_enabled": "Enable the color management pipeline",
        "render.cm_sdr_eotf": "Transfer function used for SDR content",
        "render.ctm_animation": "Fade animation for color temperature changes",
        "render.commit_timing_enabled": "Enable the commit timing protocol",
        "render.direct_scanout": "Direct scanout for fullscreen apps to reduce lag",
        "render.expand_undersized_textures": "Expand undersized textures instead of stretching them",
        "render.fp16_sdr_tf": "Transfer function of the fp16 SDR workbuffer",
        "render.icc_vcgt_enabled": "Send VCGT ramps from ICC profiles to the display",
        "render.keep_unmodified_copy": "Keep an SDR frame copy for screen sharing",
        "render.new_render_scheduling": "Automatic triple buffering; helps weaker GPUs",
        "render.not_shown_fifo_lock": "FIFO locking for surfaces that are not shown",
        "render.non_shader_cm": "When to use color management without shaders",
        "render.non_shader_cm_interop": "How external color temperature interacts with fullscreen",
        "render.send_content_type": "Report window content types for profile autoswitch",
        "render.use_fp16": "Use FP16 render buffers",
        "render.use_shader_blur_blend": "Experimental blurred background blending",
        "render.xp_mode": "Disable back buffer and bottom layer rendering",
        "xwayland.create_abstract_socket": "Create the abstract Unix socket for Xwayland; needs restart",
        "xwayland.enabled": "Allow running X11 applications",
        "xwayland.force_zero_scaling": "Force scale 1 on Xwayland windows under scaled displays",
        "xwayland.use_nearest_neighbor": "Nearest-neighbor filtering for Xwayland; pixelated not blurry"
    }
}

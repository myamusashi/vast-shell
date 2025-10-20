pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	readonly property var dark: JSON.parse(colorsFile.text()).colors

	FileView {
		id: colorsFile

		path: Quickshell.env("HOME") + "/.config/shell/colors.json"
		watchChanges: true
		blockLoading: true
		onFileChanged: reload()
		onAdapterUpdated: writeAdapter()
	}

	function parseHSLA(hslaString) {
		const match = hslaString.match(/hsla\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/);
		if (!match)
			return Qt.rgba(0, 0, 0, 1);

		const h = parseFloat(match[1]) / 360;  // Hue: 0-360 -> 0-1
		const s = parseFloat(match[2]) / 100;  // Saturation: 0-100% -> 0-1
		const l = parseFloat(match[3]) / 100;  // Lightness: 0-100% -> 0-1
		let a = parseFloat(match[4]);

		if (a === 0.0)
			a = 1.0;

		return Qt.hsla(h, s, l, a);
	}

	function withAlpha(color, alpha) {
		return Qt.rgba(color.r, color.g, color.b, alpha);
	}

	component ColorsComponent: QtObject {
		readonly property color background: root.parseHSLA(root.dark.background)
		readonly property color error: root.parseHSLA(root.dark.error)
		readonly property color error_container: root.parseHSLA(root.dark.error_container)
		readonly property color inverse_on_surface: root.parseHSLA(root.dark.inverse_on_surface)
		readonly property color inverse_primary: root.parseHSLA(root.dark.inverse_primary)
		readonly property color inverse_surface: root.parseHSLA(root.dark.inverse_surface)
		readonly property color on_background: root.parseHSLA(root.dark.on_background)
		readonly property color on_error: root.parseHSLA(root.dark.on_error)
		readonly property color on_error_container: root.parseHSLA(root.dark.on_error_container)
		readonly property color on_primary: root.parseHSLA(root.dark.on_primary)
		readonly property color on_primary_container: root.parseHSLA(root.dark.on_primary_container)
		readonly property color on_primary_fixed: root.parseHSLA(root.dark.on_primary_fixed)
		readonly property color on_primary_fixed_variant: root.parseHSLA(root.dark.on_primary_fixed_variant)
		readonly property color on_secondary: root.parseHSLA(root.dark.on_secondary)
		readonly property color on_secondary_container: root.parseHSLA(root.dark.on_secondary_container)
		readonly property color on_secondary_fixed: root.parseHSLA(root.dark.on_secondary_fixed)
		readonly property color on_secondary_fixed_variant: root.parseHSLA(root.dark.on_secondary_fixed_variant)
		readonly property color on_surface: root.parseHSLA(root.dark.on_surface)
		readonly property color on_surface_variant: root.parseHSLA(root.dark.on_surface_variant)
		readonly property color on_tertiary: root.parseHSLA(root.dark.on_tertiary)
		readonly property color on_tertiary_container: root.parseHSLA(root.dark.on_tertiary_container)
		readonly property color on_tertiary_fixed: root.parseHSLA(root.dark.on_tertiary_fixed)
		readonly property color on_tertiary_fixed_variant: root.parseHSLA(root.dark.on_tertiary_fixed_variant)
		readonly property color outline: root.parseHSLA(root.dark.outline)
		readonly property color outline_variant: root.parseHSLA(root.dark.outline_variant)
		readonly property color primary: root.parseHSLA(root.dark.primary)
		readonly property color primary_container: root.parseHSLA(root.dark.primary_container)
		readonly property color primary_fixed: root.parseHSLA(root.dark.primary_fixed)
		readonly property color primary_fixed_dim: root.parseHSLA(root.dark.primary_fixed_dim)
		readonly property color scrim: root.parseHSLA(root.dark.scrim)
		readonly property color secondary: root.parseHSLA(root.dark.secondary)
		readonly property color secondary_container: root.parseHSLA(root.dark.secondary_container)
		readonly property color secondary_fixed: root.parseHSLA(root.dark.secondary_fixed)
		readonly property color secondary_fixed_dim: root.parseHSLA(root.dark.secondary_fixed_dim)
		readonly property color shadow: root.parseHSLA(root.dark.shadow)
		readonly property color surface: root.parseHSLA(root.dark.surface)
		readonly property color surface_bright: root.parseHSLA(root.dark.surface_bright)
		readonly property color surface_container: root.parseHSLA(root.dark.surface_container)
		readonly property color surface_container_high: root.parseHSLA(root.dark.surface_container_high)
		readonly property color surface_container_highest: root.parseHSLA(root.dark.surface_container_highest)
		readonly property color surface_container_low: root.parseHSLA(root.dark.surface_container_low)
		readonly property color surface_container_lowest: root.parseHSLA(root.dark.surface_container_lowest)
		readonly property color surface_dim: root.parseHSLA(root.dark.surface_dim)
		readonly property color surface_tint: root.parseHSLA(root.dark.surface_tint)
		readonly property color surface_variant: root.parseHSLA(root.dark.surface_variant)
		readonly property color tertiary: root.parseHSLA(root.dark.tertiary)
		readonly property color tertiary_container: root.parseHSLA(root.dark.tertiary_container)
		readonly property color tertiary_fixed: root.parseHSLA(root.dark.tertiary_fixed)
		readonly property color tertiary_fixed_dim: root.parseHSLA(root.dark.tertiary_fixed_dim)
	}

	readonly property ColorsComponent colors: ColorsComponent {}
}

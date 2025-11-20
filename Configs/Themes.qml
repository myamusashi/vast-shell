pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import qs.Helpers

Singleton {
    id: root

    readonly property var colorsTemplates: JSON.parse(colorsFile.text()).colors.dark

    FileView {
        id: colorsFile

        path: Paths.home + "/.config/shell/colors.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
        onAdapterChanged: writeAdapter()
    }

    function parseRGBA(color) {
        const values = color.slice(color.indexOf("(") + 1, color.indexOf(")")).split(",");

        if (values.length === 4) {
            const r = parseInt(values[0].trim(), 10);
            const g = parseInt(values[1].trim(), 10);
            const b = parseInt(values[2].trim(), 10);
            const a = parseFloat(values[3].trim(), 10);

            return `${r},${g},${b},${a}`;
        }

        return null;
    }

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    component M3ColorsComponent: QtObject {
        readonly property color background: root.colorsTemplates.background
        readonly property color error: root.colorsTemplates.error
        readonly property color errorContainer: root.colorsTemplates.error_container
        readonly property color inverseOnSurface: root.colorsTemplates.inverse_on_surface
        readonly property color inversePrimary: root.colorsTemplates.inverse_primary
        readonly property color inverseSurface: root.colorsTemplates.inverse_surface
        readonly property color onBackground: root.colorsTemplates.on_background
        readonly property color onError: root.colorsTemplates.on_error
        readonly property color onErrorContainer: root.colorsTemplates.on_error_container
        readonly property color onPrimary: root.colorsTemplates.on_primary
        readonly property color onPrimaryContainer: root.colorsTemplates.on_primary_container
        readonly property color onPrimaryFixed: root.colorsTemplates.on_primary_fixed
        readonly property color onPrimaryFixedVariant: root.colorsTemplates.on_primary_fixed_variant
        readonly property color onSecondary: root.colorsTemplates.on_secondary
        readonly property color onSecondaryContainer: root.colorsTemplates.on_secondary_container
        readonly property color onSecondaryFixed: root.colorsTemplates.on_secondary_fixed
        readonly property color onSecondaryFixedVariant: root.colorsTemplates.on_secondary_fixed_variant
        readonly property color onSurface: root.colorsTemplates.on_surface
        readonly property color onSurfaceVariant: root.colorsTemplates.on_surface_variant
        readonly property color onTertiary: root.colorsTemplates.on_tertiary
        readonly property color onTertiaryContainer: root.colorsTemplates.on_tertiary_container
        readonly property color onTertiaryFixed: root.colorsTemplates.on_tertiary_fixed
        readonly property color onTertiaryFixedVariant: root.colorsTemplates.on_tertiary_fixed_variant
        readonly property color outline: root.colorsTemplates.outline
        readonly property color outlineVariant: root.colorsTemplates.outline_variant
        readonly property color primary: root.colorsTemplates.primary
        readonly property color primaryContainer: root.colorsTemplates.primary_container
        readonly property color primaryFixed: root.colorsTemplates.primary_fixed
        readonly property color primaryFixedDim: root.colorsTemplates.primary_fixed_dim
        readonly property color scrim: root.colorsTemplates.scrim
        readonly property color secondary: root.colorsTemplates.secondary
        readonly property color secondaryContainer: root.colorsTemplates.secondary_container
        readonly property color secondaryFixed: root.colorsTemplates.secondary_fixed
        readonly property color secondaryFixedDim: root.colorsTemplates.secondary_fixed_dim
        readonly property color shadow: root.colorsTemplates.shadow
        readonly property color surface: root.colorsTemplates.surface
        readonly property color surfaceBright: root.colorsTemplates.surface_bright
        readonly property color surfaceContainer: root.colorsTemplates.surface_container
        readonly property color surfaceContainerHigh: root.colorsTemplates.surface_container_high
        readonly property color surfaceContainerHighest: root.colorsTemplates.surface_container_highest
        readonly property color surfaceContainerLow: root.colorsTemplates.surface_container_low
        readonly property color surfaceContainerLowest: root.colorsTemplates.surface_container_lowest
        readonly property color surfaceDim: root.colorsTemplates.surface_dim
        readonly property color surfaceTint: root.colorsTemplates.surface_tint
        readonly property color surfaceVariant: root.colorsTemplates.surface_variant
        readonly property color tertiary: root.colorsTemplates.tertiary
        readonly property color tertiaryContainer: root.colorsTemplates.tertiary_container
        readonly property color tertiaryFixed: root.colorsTemplates.tertiary_fixed
        readonly property color tertiaryFixedDim: root.colorsTemplates.tertiary_fixed_dim

        readonly property color red: error
        readonly property color green: "#63A002"
        readonly property color blue: "#769CDF"
        readonly property color yellow: "#FFDE3F"
    }

    readonly property M3ColorsComponent m3Colors: M3ColorsComponent {}
}

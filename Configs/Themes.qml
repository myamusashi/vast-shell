pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import qs.Helpers

Singleton {
    id: root

    readonly property var dark: JSON.parse(colorsFile.text()).colors

    FileView {
        id: colorsFile

        path: Paths.home + "/.config/shell/colors.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
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
        readonly property color background: root.dark.background
        readonly property color error: root.dark.error
        readonly property color errorContainer: root.dark.errorContainer
        readonly property color inverseOnSurface: root.dark.inverseOnSurface
        readonly property color inversePrimary: root.dark.inversePrimary
        readonly property color inverseSurface: root.dark.inverseSurface
        readonly property color onBackground: root.dark.onBackground
        readonly property color onError: root.dark.onError
        readonly property color onErrorContainer: root.dark.onErrorContainer
        readonly property color onPrimary: root.dark.onPrimary
        readonly property color onPrimaryContainer: root.dark.onPrimaryContainer
        readonly property color onPrimaryFixed: root.dark.onPrimaryFixed
        readonly property color onPrimaryFixedVariant: root.dark.onPrimaryFixedVariant
        readonly property color onSecondary: root.dark.onSecondary
        readonly property color onSecondaryContainer: root.dark.onSecondaryContainer
        readonly property color onSecondaryFixed: root.dark.onSecondaryFixed
        readonly property color onSecondaryFixedVariant: root.dark.onSecondaryFixedVariant
        readonly property color onSurface: root.dark.onSurface
        readonly property color onSurfaceVariant: root.dark.onSurfaceVariant
        readonly property color onTertiary: root.dark.onTertiary
        readonly property color onTertiaryContainer: root.dark.onTertiaryContainer
        readonly property color onTertiaryFixed: root.dark.onTertiaryFixed
        readonly property color onTertiaryFixedVariant: root.dark.onTertiaryFixedVariant
        readonly property color outline: root.dark.outline
        readonly property color outlineVariant: root.dark.outlineVariant
        readonly property color primary: root.dark.primary
        readonly property color primaryContainer: root.dark.primaryContainer
        readonly property color primaryFixed: root.dark.primaryFixed
        readonly property color primaryFixedDim: root.dark.primaryFixedDim
        readonly property color scrim: root.dark.scrim
        readonly property color secondary: root.dark.secondary
        readonly property color secondaryContainer: root.dark.secondaryContainer
        readonly property color secondaryFixed: root.dark.secondaryFixed
        readonly property color secondaryFixedDim: root.dark.secondaryFixedDim
        readonly property color shadow: root.dark.shadow
        readonly property color surface: root.dark.surface
        readonly property color surfaceBright: root.dark.surfaceBright
        readonly property color surfaceContainer: root.dark.surfaceContainer
        readonly property color surfaceContainerHigh: root.dark.surfaceContainerHigh
        readonly property color surfaceContainerHighest: root.dark.surfaceContainerHighest
        readonly property color surfaceContainerLow: root.dark.surfaceContainerLow
        readonly property color surfaceContainerLowest: root.dark.surfaceContainerLowest
        readonly property color surfaceDim: root.dark.surfaceDim
        readonly property color surfaceTint: root.dark.surfaceTint
        readonly property color surfaceVariant: root.dark.surfaceVariant
        readonly property color tertiary: root.dark.tertiary
        readonly property color tertiaryContainer: root.dark.tertiaryContainer
        readonly property color tertiaryFixed: root.dark.tertiaryFixed
        readonly property color tertiaryFixedDim: root.dark.tertiaryFixedDim

        readonly property color red: root.dark.error
        readonly property color green: "#63A002"
        readonly property color blue: "#769CDF"
        readonly property color yellow: "#FFDE3F"
    }

    readonly property M3ColorsComponent m3Colors: M3ColorsComponent {}
}

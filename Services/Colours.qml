pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Configs
import qs.Helpers

Singleton {
    id: root

    readonly property M3GeneratedColors m3Generated: M3GeneratedColors {}
    readonly property MatugenColors matugen: MatugenColors {}
    readonly property StaticColors staticColors: StaticColors {}
    readonly property var matugenPalette: JSON.parse(matugenDarkFile.text()).colors
    readonly property var staticPalette: JSON.parse(staticColorFile.text())
    readonly property M3TemplateColors activePalette: Configs.colors.useMatugenColor ? matugen : Configs.colors.useStaticColors ? staticColors : m3Generated

    FileView {
        id: matugenDarkFile
        path: Configs.colors.matugenConfigPathForDarkColor
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: matugenLightFile
        path: Configs.colors.matugenConfigPathForLightColor
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: staticColorFile
        path: Configs.colors.staticColorsPath
        watchChanges: true
        onFileChanged: reload()
    }

    ColorQuantizer {
        id: colorQuantizer
        source: Qt.resolvedUrl(Paths.currentWallpaper) || "root:/Assets/wallpaper.png"
        depth: 2
        rescaleSize: 32
    }

    function getSourceColor() {
        if (!colorQuantizer.colors.length)
            return "#6750A4";

        let maxChroma = 0;
        let sourceColor = colorQuantizer.colors[0];

        for (let i = 0; i < Math.min(colorQuantizer.colors.length, 16); i++) {
            const color = colorQuantizer.colors[i];
            const chroma = calculateChroma(color);
            if (chroma > maxChroma) {
                maxChroma = chroma;
                sourceColor = color;
            }
        }
        return sourceColor;
    }

    function calculateChroma(color) {
        const max = Math.max(color.r, color.g, color.b);
        const min = Math.min(color.r, color.g, color.b);
        return max - min;
    }

    function rgbToHct(color) {
        // Gamma correction
        const r = color.r > 0.04045 ? Math.pow((color.r + 0.055) / 1.055, 2.4) : color.r / 12.92;
        const g = color.g > 0.04045 ? Math.pow((color.g + 0.055) / 1.055, 2.4) : color.g / 12.92;
        const b = color.b > 0.04045 ? Math.pow((color.b + 0.055) / 1.055, 2.4) : color.b / 12.92;

        // RGB to XYZ
        let x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375;
        let y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750;
        let z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041;

        x = x / 0.95047;
        z = z / 1.08883;

        // XYZ to Lab
        const fx = x > 0.008856 ? Math.pow(x, 1 / 3) : (7.787 * x) + (16 / 116);
        const fy = y > 0.008856 ? Math.pow(y, 1 / 3) : (7.787 * y) + (16 / 116);
        const fz = z > 0.008856 ? Math.pow(z, 1 / 3) : (7.787 * z) + (16 / 116);

        const l = (116 * fy) - 16;
        const a = 500 * (fx - fy);
        const bLab = 200 * (fy - fz);

        // Lab to HCT
        const chroma = Math.sqrt(a * a + bLab * bLab);
        let hue = Math.atan2(bLab, a) * 180 / Math.PI;
        if (hue < 0)
            hue += 360;

        return {
            h: hue,
            c: chroma,
            t: l
        };
    }

    function hctToRgb(h, c, t) {
        // HCT to Lab
        const hueRad = h * Math.PI / 180;
        const a = c * Math.cos(hueRad);
        const bLab = c * Math.sin(hueRad);
        const l = t;

        // Lab to XYZ
        const fy = (l + 16) / 116;
        const fx = a / 500 + fy;
        const fz = fy - bLab / 200;

        let x = fx > 0.206897 ? Math.pow(fx, 3) : (fx - 16 / 116) / 7.787;
        let y = fy > 0.206897 ? Math.pow(fy, 3) : (fy - 16 / 116) / 7.787;
        let z = fz > 0.206897 ? Math.pow(fz, 3) : (fz - 16 / 116) / 7.787;

        x *= 0.95047;
        z *= 1.08883;

        // XYZ to RGB
        let r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314;
        let g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560;
        let b = x * 0.0556434 + y * -0.2040259 + z * 1.0572252;

        r = r > 0.0031308 ? 1.055 * Math.pow(r, 1 / 2.4) - 0.055 : 12.92 * r;
        g = g > 0.0031308 ? 1.055 * Math.pow(g, 1 / 2.4) - 0.055 : 12.92 * g;
        b = b > 0.0031308 ? 1.055 * Math.pow(b, 1 / 2.4) - 0.055 : 12.92 * b;

        return Qt.rgba(Math.max(0, Math.min(1, r)), Math.max(0, Math.min(1, g)), Math.max(0, Math.min(1, b)), 1.0);
    }

    function hctToRgbWithGamutMapping(h, c, t) {
        const maxAttempts = 20;
        const chromaStep = c / maxAttempts;
        let currentChroma = c;

        for (let i = 0; i < maxAttempts; i++) {
            const color = hctToRgb(h, currentChroma, t);
            if (color.r >= -0.001 && color.r <= 1.001 && color.g >= -0.001 && color.g <= 1.001 && color.b >= -0.001 && color.b <= 1.001) {
                return color;
            }
            currentChroma -= chromaStep;
            if (currentChroma < 0) {
                currentChroma = 0;
                break;
            }
        }
        return hctToRgb(h, currentChroma, t);
    }

    function createTonalColor(baseColor, tone) {
        const hct = rgbToHct(baseColor);
        let adjustedChroma = hct.c;

        // Chroma adjustment based on tone
        if (tone < 10)
            adjustedChroma *= 0.4;
        else if (tone > 95)
            adjustedChroma *= 0.3;
        else if (tone < 20)
            adjustedChroma *= 0.7;
        else if (tone > 90)
            adjustedChroma *= 0.8;

        adjustedChroma = Math.min(adjustedChroma, 115);
        return hctToRgbWithGamutMapping(hct.h, adjustedChroma, tone);
    }

    function createAnalogousColor(baseColor, hueShift) {
        const hct = rgbToHct(baseColor);
        let newHue = (hct.h + hueShift) % 360;
        if (newHue < 0)
            newHue += 360;
        return hctToRgb(newHue, hct.c, hct.t);
    }

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    component M3TemplateColors: QtObject {
        readonly property color m3Background: "transparent"
        readonly property color m3Surface: "transparent"
        readonly property color m3SurfaceDim: "transparent"
        readonly property color m3SurfaceBright: "transparent"
        readonly property color m3SurfaceContainerLowest: "transparent"
        readonly property color m3SurfaceContainerLow: "transparent"
        readonly property color m3SurfaceContainer: "transparent"
        readonly property color m3SurfaceContainerHigh: "transparent"
        readonly property color m3SurfaceContainerHighest: "transparent"
        readonly property color m3SurfaceVariant: "transparent"
        readonly property color m3SurfaceTint: "transparent"

        readonly property color m3OnSurface: "transparent"
        readonly property color m3OnSurfaceVariant: "transparent"
        readonly property color m3OnBackground: "transparent"
        readonly property color m3InverseSurface: "transparent"
        readonly property color m3InverseOnSurface: "transparent"

        readonly property color m3Primary: "transparent"
        readonly property color m3OnPrimary: "transparent"
        readonly property color m3PrimaryContainer: "transparent"
        readonly property color m3OnPrimaryContainer: "transparent"
        readonly property color m3PrimaryFixed: "transparent"
        readonly property color m3PrimaryFixedDim: "transparent"
        readonly property color m3OnPrimaryFixed: "transparent"
        readonly property color m3OnPrimaryFixedVariant: "transparent"
        readonly property color m3InversePrimary: "transparent"

        readonly property color m3Secondary: "transparent"
        readonly property color m3OnSecondary: "transparent"
        readonly property color m3SecondaryContainer: "transparent"
        readonly property color m3OnSecondaryContainer: "transparent"
        readonly property color m3SecondaryFixed: "transparent"
        readonly property color m3SecondaryFixedDim: "transparent"
        readonly property color m3OnSecondaryFixed: "transparent"
        readonly property color m3OnSecondaryFixedVariant: "transparent"

        readonly property color m3Tertiary: "transparent"
        readonly property color m3OnTertiary: "transparent"
        readonly property color m3TertiaryContainer: "transparent"
        readonly property color m3OnTertiaryContainer: "transparent"
        readonly property color m3TertiaryFixed: "transparent"
        readonly property color m3TertiaryFixedDim: "transparent"
        readonly property color m3OnTertiaryFixed: "transparent"
        readonly property color m3OnTertiaryFixedVariant: "transparent"

        readonly property color m3Error: "transparent"
        readonly property color m3ErrorContainer: "transparent"
        readonly property color m3OnError: "transparent"
        readonly property color m3OnErrorContainer: "transparent"

        readonly property color m3Outline: "transparent"
        readonly property color m3OutlineVariant: "transparent"
        readonly property color m3Scrim: "transparent"
        readonly property color m3Shadow: "transparent"

        readonly property color m3Red: "transparent"
        readonly property color m3Green: "transparent"
        readonly property color m3Blue: "transparent"
        readonly property color m3Yellow: "transparent"
    }

    component StaticColors: M3TemplateColors {
        readonly property color m3Background: root.staticPalette.background
        readonly property color m3Surface: root.staticPalette.surface
        readonly property color m3SurfaceDim: root.staticPalette.surfaceDim
        readonly property color m3SurfaceBright: root.staticPalette.surfaceBright
        readonly property color m3SurfaceContainerLowest: root.staticPalette.surfaceContainerLowest
        readonly property color m3SurfaceContainerLow: root.staticPalette.surfaceContainerLow
        readonly property color m3SurfaceContainer: root.staticPalette.surfaceContainer
        readonly property color m3SurfaceContainerHigh: root.staticPalette.surfaceContainerHigh
        readonly property color m3SurfaceContainerHighest: root.staticPalette.surfaceContainerHighest
        readonly property color m3SurfaceVariant: root.staticPalette.surfaceVariant
        readonly property color m3SurfaceTint: root.staticPalette.surfaceTint

        readonly property color m3OnSurface: root.staticPalette.onSurface
        readonly property color m3OnSurfaceVariant: root.staticPalette.onSurfaceVariant
        readonly property color m3OnBackground: root.staticPalette.onBackground
        readonly property color m3InverseSurface: root.staticPalette.inverseSurface
        readonly property color m3InverseOnSurface: root.staticPalette.inverseOnSurface
        readonly property color m3InversePrimary: root.staticPalette.inversePrimary

        readonly property color m3Primary: root.staticPalette.primary
        readonly property color m3OnPrimary: root.staticPalette.onPrimary
        readonly property color m3PrimaryContainer: root.staticPalette.primaryContainer
        readonly property color m3OnPrimaryContainer: root.staticPalette.onPrimaryContainer
        readonly property color m3PrimaryFixed: root.staticPalette.primaryFixed
        readonly property color m3PrimaryFixedDim: root.staticPalette.primaryFixedDim
        readonly property color m3OnPrimaryFixed: root.staticPalette.onPrimaryFixed
        readonly property color m3OnPrimaryFixedVariant: root.staticPalette.onPrimaryFixedVariant

        readonly property color m3Secondary: root.staticPalette.secondary
        readonly property color m3OnSecondary: root.staticPalette.onSecondary
        readonly property color m3SecondaryContainer: root.staticPalette.secondaryContainer
        readonly property color m3OnSecondaryContainer: root.staticPalette.onSecondaryContainer
        readonly property color m3SecondaryFixed: root.staticPalette.secondaryFixed
        readonly property color m3SecondaryFixedDim: root.staticPalette.secondaryFixedDim
        readonly property color m3OnSecondaryFixed: root.staticPalette.onSecondaryFixed
        readonly property color m3OnSecondaryFixedVariant: root.staticPalette.onSecondaryFixedVariant

        readonly property color m3Tertiary: root.staticPalette.tertiary
        readonly property color m3OnTertiary: root.staticPalette.onTertiary
        readonly property color m3TertiaryContainer: root.staticPalette.tertiaryContainer
        readonly property color m3OnTertiaryContainer: root.staticPalette.onTertiaryContainer
        readonly property color m3TertiaryFixed: root.staticPalette.tertiaryFixed
        readonly property color m3TertiaryFixedDim: root.staticPalette.tertiaryFixedDim
        readonly property color m3OnTertiaryFixed: root.staticPalette.onTertiaryFixed
        readonly property color m3OnTertiaryFixedVariant: root.staticPalette.onTertiaryFixedVariant

        readonly property color m3Error: root.staticPalette.error
        readonly property color m3ErrorContainer: root.staticPalette.errorContainer
        readonly property color m3OnError: root.staticPalette.onError
        readonly property color m3OnErrorContainer: root.staticPalette.onErrorContainer

        readonly property color m3Outline: root.staticPalette.outline
        readonly property color m3OutlineVariant: root.staticPalette.outlineVariant
        readonly property color m3Scrim: root.staticPalette.scrim
        readonly property color m3Shadow: root.staticPalette.shadow

        readonly property color m3Red: m3Error
        readonly property color m3Green: root.hctToRgb(145, 50, 70)
        readonly property color m3Blue: root.hctToRgb(220, 50, 70)
        readonly property color m3Yellow: root.hctToRgb(90, 60, 70)
    }

    component MatugenColors: M3TemplateColors {
        readonly property color m3Background: root.matugenPalette.background
        readonly property color m3Surface: root.matugenPalette.surface
        readonly property color m3SurfaceDim: root.matugenPalette.surfaceDim
        readonly property color m3SurfaceBright: root.matugenPalette.surfaceBright
        readonly property color m3SurfaceContainerLowest: root.matugenPalette.surfaceContainerLowest
        readonly property color m3SurfaceContainerLow: root.matugenPalette.surfaceContainerLow
        readonly property color m3SurfaceContainer: root.matugenPalette.surfaceContainer
        readonly property color m3SurfaceContainerHigh: root.matugenPalette.surfaceContainerHigh
        readonly property color m3SurfaceContainerHighest: root.matugenPalette.surfaceContainerHighest
        readonly property color m3SurfaceVariant: root.matugenPalette.surfaceVariant
        readonly property color m3SurfaceTint: root.matugenPalette.surfaceTint

        readonly property color m3OnSurface: root.matugenPalette.onSurface
        readonly property color m3OnSurfaceVariant: root.matugenPalette.onSurfaceVariant
        readonly property color m3OnBackground: root.matugenPalette.onBackground
        readonly property color m3InverseSurface: root.matugenPalette.inverseSurface
        readonly property color m3InverseOnSurface: root.matugenPalette.inverseOnSurface
        readonly property color m3InversePrimary: root.matugenPalette.inversePrimary

        readonly property color m3Primary: root.matugenPalette.primary
        readonly property color m3OnPrimary: root.matugenPalette.onPrimary
        readonly property color m3PrimaryContainer: root.matugenPalette.primaryContainer
        readonly property color m3OnPrimaryContainer: root.matugenPalette.onPrimaryContainer
        readonly property color m3PrimaryFixed: root.matugenPalette.primaryFixed
        readonly property color m3PrimaryFixedDim: root.matugenPalette.primaryFixedDim
        readonly property color m3OnPrimaryFixed: root.matugenPalette.onPrimaryFixed
        readonly property color m3OnPrimaryFixedVariant: root.matugenPalette.onPrimaryFixedVariant

        readonly property color m3Secondary: root.matugenPalette.secondary
        readonly property color m3OnSecondary: root.matugenPalette.onSecondary
        readonly property color m3SecondaryContainer: root.matugenPalette.secondaryContainer
        readonly property color m3OnSecondaryContainer: root.matugenPalette.onSecondaryContainer
        readonly property color m3SecondaryFixed: root.matugenPalette.secondaryFixed
        readonly property color m3SecondaryFixedDim: root.matugenPalette.secondaryFixedDim
        readonly property color m3OnSecondaryFixed: root.matugenPalette.onSecondaryFixed
        readonly property color m3OnSecondaryFixedVariant: root.matugenPalette.onSecondaryFixedVariant

        readonly property color m3Tertiary: root.matugenPalette.tertiary
        readonly property color m3OnTertiary: root.matugenPalette.onTertiary
        readonly property color m3TertiaryContainer: root.matugenPalette.tertiaryContainer
        readonly property color m3OnTertiaryContainer: root.matugenPalette.onTertiaryContainer
        readonly property color m3TertiaryFixed: root.matugenPalette.tertiaryFixed
        readonly property color m3TertiaryFixedDim: root.matugenPalette.tertiaryFixedDim
        readonly property color m3OnTertiaryFixed: root.matugenPalette.onTertiaryFixed
        readonly property color m3OnTertiaryFixedVariant: root.matugenPalette.onTertiaryFixedVariant

        readonly property color m3Error: root.matugenPalette.error
        readonly property color m3ErrorContainer: root.matugenPalette.errorContainer
        readonly property color m3OnError: root.matugenPalette.onError
        readonly property color m3OnErrorContainer: root.matugenPalette.onErrorContainer

        readonly property color m3Outline: root.matugenPalette.outline
        readonly property color m3OutlineVariant: root.matugenPalette.outlineVariant
        readonly property color m3Scrim: root.matugenPalette.scrim
        readonly property color m3Shadow: root.matugenPalette.shadow

        readonly property color m3Red: m3Error
        readonly property color m3Green: root.hctToRgb(145, 50, 70)
        readonly property color m3Blue: root.hctToRgb(220, 50, 70)
        readonly property color m3Yellow: root.hctToRgb(90, 60, 70)
    }

    component M3GeneratedColors: M3TemplateColors {
        readonly property color m3SourceColor: root.getSourceColor()
        readonly property color m3SecondarySource: root.createAnalogousColor(m3SourceColor, 60)
        readonly property color m3TertiarySource: root.createAnalogousColor(m3SourceColor, 120)
        readonly property color m3NeutralSource: {
            const hct = root.rgbToHct(m3SourceColor);
            return root.hctToRgb(hct.h, 4, hct.t);
        }
        readonly property color m3NeutralVariantSource: {
            const hct = root.rgbToHct(m3SourceColor);
            return root.hctToRgb(hct.h, 8, hct.t);
        }
        readonly property color m3ErrorSource: root.hctToRgb(25, 84, 40)

        readonly property bool isDark: Configs.colors.isDarkMode

        readonly property color m3Background: createTonal(m3NeutralSource, isDark ? 6 : 98)
        readonly property color m3Surface: createTonal(m3NeutralSource, isDark ? 6 : 98)
        readonly property color m3SurfaceDim: createTonal(m3NeutralSource, isDark ? 6 : 87)
        readonly property color m3SurfaceBright: createTonal(m3NeutralSource, isDark ? 24 : 98)
        readonly property color m3SurfaceContainerLowest: createTonal(m3NeutralSource, isDark ? 4 : 100)
        readonly property color m3SurfaceContainerLow: createTonal(m3NeutralSource, isDark ? 10 : 96)
        readonly property color m3SurfaceContainer: createTonal(m3NeutralSource, isDark ? 12 : 94)
        readonly property color m3SurfaceContainerHigh: createTonal(m3NeutralSource, isDark ? 17 : 92)
        readonly property color m3SurfaceContainerHighest: createTonal(m3NeutralSource, isDark ? 22 : 90)
        readonly property color m3SurfaceVariant: createTonal(m3NeutralVariantSource, isDark ? 30 : 90)

        readonly property color m3OnSurface: createTonal(m3NeutralSource, isDark ? 90 : 10)
        readonly property color m3OnSurfaceVariant: createTonal(m3NeutralVariantSource, isDark ? 80 : 30)
        readonly property color m3OnBackground: createTonal(m3NeutralSource, isDark ? 90 : 10)
        readonly property color m3InverseSurface: createTonal(m3NeutralSource, isDark ? 90 : 20)
        readonly property color m3InverseOnSurface: createTonal(m3NeutralSource, isDark ? 20 : 95)

        readonly property color m3Primary: createTonal(m3SourceColor, isDark ? 80 : 40)
        readonly property color m3OnPrimary: createTonal(m3SourceColor, isDark ? 20 : 100)
        readonly property color m3PrimaryContainer: createTonal(m3SourceColor, isDark ? 30 : 90)
        readonly property color m3OnPrimaryContainer: createTonal(m3SourceColor, isDark ? 90 : 10)
        readonly property color m3PrimaryFixed: createTonal(m3SourceColor, 90)
        readonly property color m3PrimaryFixedDim: createTonal(m3SourceColor, 80)
        readonly property color m3OnPrimaryFixed: createTonal(m3SourceColor, 10)
        readonly property color m3OnPrimaryFixedVariant: createTonal(m3SourceColor, 30)
        readonly property color m3InversePrimary: createTonal(m3SourceColor, isDark ? 40 : 80)

        readonly property color m3Secondary: createTonal(m3SecondarySource, isDark ? 80 : 40)
        readonly property color m3OnSecondary: createTonal(m3SecondarySource, isDark ? 20 : 100)
        readonly property color m3SecondaryContainer: createTonal(m3SecondarySource, isDark ? 30 : 90)
        readonly property color m3OnSecondaryContainer: createTonal(m3SecondarySource, isDark ? 90 : 10)
        readonly property color m3SecondaryFixed: createTonal(m3SecondarySource, 90)
        readonly property color m3SecondaryFixedDim: createTonal(m3SecondarySource, 80)
        readonly property color m3OnSecondaryFixed: createTonal(m3SecondarySource, 10)
        readonly property color m3OnSecondaryFixedVariant: createTonal(m3SecondarySource, 30)

        readonly property color m3Tertiary: createTonal(m3TertiarySource, isDark ? 80 : 40)
        readonly property color m3OnTertiary: createTonal(m3TertiarySource, isDark ? 20 : 100)
        readonly property color m3TertiaryContainer: createTonal(m3TertiarySource, isDark ? 30 : 90)
        readonly property color m3OnTertiaryContainer: createTonal(m3TertiarySource, isDark ? 90 : 10)
        readonly property color m3TertiaryFixed: createTonal(m3TertiarySource, 90)
        readonly property color m3TertiaryFixedDim: createTonal(m3TertiarySource, 80)
        readonly property color m3OnTertiaryFixed: createTonal(m3TertiarySource, 10)
        readonly property color m3OnTertiaryFixedVariant: createTonal(m3TertiarySource, 30)

        readonly property color m3Error: createTonal(m3ErrorSource, isDark ? 80 : 40)
        readonly property color m3ErrorContainer: createTonal(m3ErrorSource, isDark ? 30 : 90)
        readonly property color m3OnError: createTonal(m3ErrorSource, isDark ? 20 : 100)
        readonly property color m3OnErrorContainer: createTonal(m3ErrorSource, isDark ? 90 : 10)

        readonly property color m3Outline: createTonal(m3NeutralVariantSource, isDark ? 60 : 50)
        readonly property color m3OutlineVariant: createTonal(m3NeutralVariantSource, isDark ? 30 : 80)
        readonly property color m3Scrim: "#000000"
        readonly property color m3Shadow: "#000000"
        readonly property color m3SurfaceTint: m3Primary

        readonly property color m3Red: m3Error
        readonly property color m3Green: root.hctToRgb(145, 50, isDark ? 70 : 40)
        readonly property color m3Blue: root.hctToRgb(220, 50, isDark ? 70 : 40)
        readonly property color m3Yellow: root.hctToRgb(90, 60, isDark ? 70 : 40)

        function createTonal(source, tone) {
            return root.createTonalColor(source, tone);
        }
    }
}

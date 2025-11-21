pragma ComponentBehavior: Bound
pragma Singleton

import Quickshell
import QtQuick

import qs.Helpers

Singleton {
    id: root

	readonly property M3TemplateComponent m3Colors: M3TemplateComponent {}

    ColorQuantizer {
        id: colorQuantizer

        source: Qt.resolvedUrl(Paths.currentWallpaper)
        depth: 1
		rescaleSize: 64
    }

    function getSourceColor() {
        if (colorQuantizer.colors.length === 0)
            return "#6750A4";
        let maxChroma = 0;
        let sourceColor = colorQuantizer.colors[0];
        for (let i = 0; i < Math.min(colorQuantizer.colors.length, 16); i++) {
            let color = colorQuantizer.colors[i];
            let chroma = calculateChroma(color);
            if (chroma > maxChroma) {
                maxChroma = chroma;
                sourceColor = color;
            }
        }
        return sourceColor;
    }

    function calculateChroma(color) {
        let r = color.r;
        let g = color.g;
        let b = color.b;
        let max = Math.max(r, g, b);
        let min = Math.min(r, g, b);
        return max - min;
    }

    function rgbToHct(color) {
        let r = color.r;
        let g = color.g;
        let b = color.b;

        r = r > 0.04045 ? Math.pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
        g = g > 0.04045 ? Math.pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
        b = b > 0.04045 ? Math.pow((b + 0.055) / 1.055, 2.4) : b / 12.92;

        let x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375;
        let y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750;
        let z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041;

        x = x / 0.95047;
        z = z / 1.08883;

        x = x > 0.008856 ? Math.pow(x, 1 / 3) : (7.787 * x) + (16 / 116);
        y = y > 0.008856 ? Math.pow(y, 1 / 3) : (7.787 * y) + (16 / 116);
        z = z > 0.008856 ? Math.pow(z, 1 / 3) : (7.787 * z) + (16 / 116);

        let l = (116 * y) - 16;
        let a = 500 * (x - y);
        let bLab = 200 * (y - z);

        let chroma = Math.sqrt(a * a + bLab * bLab);
        let hue = Math.atan2(bLab, a) * 180 / Math.PI;
        if (hue < 0)
            hue += 360;

        let tone = l;

        return {
            h: hue,
            c: chroma,
            t: tone
        };
    }

    function hctToRgb(h, c, t) {
        let hueRad = h * Math.PI / 180;
        let a = c * Math.cos(hueRad);
        let bLab = c * Math.sin(hueRad);
        let l = t;

        let y = (l + 16) / 116;
        let x = a / 500 + y;
        let z = y - bLab / 200;

        x = x > 0.206897 ? Math.pow(x, 3) : (x - 16 / 116) / 7.787;
        y = y > 0.206897 ? Math.pow(y, 3) : (y - 16 / 116) / 7.787;
        z = z > 0.206897 ? Math.pow(z, 3) : (z - 16 / 116) / 7.787;

        x = x * 0.95047;
        z = z * 1.08883;

        let r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314;
        let g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560;
        let b = x * 0.0556434 + y * -0.2040259 + z * 1.0572252;

        r = r > 0.0031308 ? 1.055 * Math.pow(r, 1 / 2.4) - 0.055 : 12.92 * r;
        g = g > 0.0031308 ? 1.055 * Math.pow(g, 1 / 2.4) - 0.055 : 12.92 * g;
        b = b > 0.0031308 ? 1.055 * Math.pow(b, 1 / 2.4) - 0.055 : 12.92 * b;

        r = Math.max(0, Math.min(1, r));
        g = Math.max(0, Math.min(1, g));
        b = Math.max(0, Math.min(1, b));

        return Qt.rgba(r, g, b, 1.0);
    }

    function createTonalColor(baseColor, tone) {
        let hct = rgbToHct(baseColor);

        let adjustedChroma = hct.c;
        if (tone < 20 || tone > 90)
            adjustedChroma = hct.c * 0.5;
        else if (tone >= 50 && tone <= 70)
            adjustedChroma = Math.min(hct.c * 1.1, 120);

        return hctToRgb(hct.h, adjustedChroma, tone);
    }

    function createAnalogousColor(baseColor, hueShift) {
        let hct = rgbToHct(baseColor);
        let newHue = (hct.h + hueShift) % 360;
        if (newHue < 0)
            newHue += 360;
        return hctToRgb(newHue, hct.c, hct.t);
    }

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    component M3TemplateComponent: QtObject {
        readonly property color m3SourceColor: root.getSourceColor()
        readonly property color m3SecondarySource: root.createAnalogousColor(m3SourceColor, 30)
        readonly property color m3TertiarySource: root.createAnalogousColor(m3SourceColor, 60)

        readonly property color m3NeutralSource: {
            let hct = root.rgbToHct(m3SourceColor);
            return root.hctToRgb(hct.h, Math.min(hct.c * 0.04, 6), hct.t);
        }

        readonly property color m3NeutralVariantSource: {
            let hct = root.rgbToHct(m3SourceColor);
            return root.hctToRgb(hct.h, Math.min(hct.c * 0.08, 12), hct.t);
        }

        readonly property color m3Background: root.createTonalColor(m3NeutralSource, 6)
        readonly property color m3Surface: root.createTonalColor(m3NeutralSource, 6)
        readonly property color m3SurfaceDim: root.createTonalColor(m3NeutralSource, 6)
        readonly property color m3SurfaceBright: root.createTonalColor(m3NeutralSource, 24)
        readonly property color m3SurfaceContainerLowest: root.createTonalColor(m3NeutralSource, 4)
        readonly property color m3SurfaceContainerLow: root.createTonalColor(m3NeutralSource, 10)
        readonly property color m3SurfaceContainer: root.createTonalColor(m3NeutralSource, 12)
        readonly property color m3SurfaceContainerHigh: root.createTonalColor(m3NeutralSource, 17)
        readonly property color m3SurfaceContainerHighest: root.createTonalColor(m3NeutralSource, 22)

        readonly property color m3OnSurface: root.createTonalColor(m3NeutralSource, 90)
        readonly property color m3OnSurfaceVariant: root.createTonalColor(m3NeutralVariantSource, 80)
        readonly property color m3OnBackground: root.createTonalColor(m3NeutralSource, 90)

        readonly property color m3Primary: root.createTonalColor(m3SourceColor, 80)
        readonly property color m3OnPrimary: root.createTonalColor(m3SourceColor, 20)
        readonly property color m3PrimaryContainer: root.createTonalColor(m3SourceColor, 30)
        readonly property color m3OnPrimaryContainer: root.createTonalColor(m3SourceColor, 90)
        readonly property color m3PrimaryFixed: root.createTonalColor(m3SourceColor, 90)
        readonly property color m3PrimaryFixedDim: root.createTonalColor(m3SourceColor, 80)
        readonly property color m3OnPrimaryFixed: root.createTonalColor(m3SourceColor, 10)
        readonly property color m3OnPrimaryFixedVariant: root.createTonalColor(m3SourceColor, 30)

        readonly property color m3Secondary: root.createTonalColor(m3SecondarySource, 80)
        readonly property color m3OnSecondary: root.createTonalColor(m3SecondarySource, 20)
        readonly property color m3SecondaryContainer: root.createTonalColor(m3SecondarySource, 30)
        readonly property color m3OnSecondaryContainer: root.createTonalColor(m3SecondarySource, 90)
        readonly property color m3SecondaryFixed: root.createTonalColor(m3SecondarySource, 90)
        readonly property color m3SecondaryFixedDim: root.createTonalColor(m3SecondarySource, 80)
        readonly property color m3OnSecondaryFixed: root.createTonalColor(m3SecondarySource, 10)
        readonly property color m3OnSecondaryFixedVariant: root.createTonalColor(m3SecondarySource, 30)

        readonly property color m3Tertiary: root.createTonalColor(m3TertiarySource, 80)
        readonly property color m3OnTertiary: root.createTonalColor(m3TertiarySource, 20)
        readonly property color m3TertiaryContainer: root.createTonalColor(m3TertiarySource, 30)
        readonly property color m3OnTertiaryContainer: root.createTonalColor(m3TertiarySource, 90)
        readonly property color m3TertiaryFixed: root.createTonalColor(m3TertiarySource, 90)
        readonly property color m3TertiaryFixedDim: root.createTonalColor(m3TertiarySource, 80)
        readonly property color m3OnTertiaryFixed: root.createTonalColor(m3TertiarySource, 10)
        readonly property color m3OnTertiaryFixedVariant: root.createTonalColor(m3TertiarySource, 30)

        readonly property color m3Error: "#F2B8B5"
        readonly property color m3ErrorContainer: "#8C1D18"
        readonly property color m3OnError: "#690005"
        readonly property color m3OnErrorContainer: "#ffdad6"

        readonly property color m3InverseSurface: root.createTonalColor(m3NeutralSource, 90)
        readonly property color m3InverseOnSurface: root.createTonalColor(m3NeutralSource, 20)
        readonly property color m3InversePrimary: root.createTonalColor(m3SourceColor, 40)
        readonly property color m3Outline: root.createTonalColor(m3NeutralVariantSource, 60)
        readonly property color m3OutlineVariant: root.createTonalColor(m3NeutralVariantSource, 30)
        readonly property color m3Scrim: "#000000"
        readonly property color m3Shadow: "#000000"
        readonly property color m3SurfaceTint: m3Primary
        readonly property color m3SurfaceVariant: root.createTonalColor(m3NeutralVariantSource, 30)

        readonly property color m3Red: m3Error
        readonly property color m3Green: "#4CAF50"
        readonly property color m3Blue: "#2196F3"
        readonly property color m3Yellow: "#FFC107"
    }
}

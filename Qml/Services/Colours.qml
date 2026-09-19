pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vast.Utils
import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services // qmllint disable

Singleton {
    id: root

    readonly property M3GeneratedTemplateComponent m3GeneratedColors: M3GeneratedTemplateComponent {}
    readonly property M3TemplateColors materialColors: M3TemplateColors {
        source: root.animatedMaterialColors
    }
    readonly property M3TemplateColors staticColors: M3TemplateColors {
        source: root.staticTemplateColors
    }
    readonly property var materialTemplateColors: animatedMaterialColors
    readonly property var staticTemplateColors: JSON.parse(staticColorFile.text())
    readonly property var m3Colors: Configs.colors.useStaticColors ? staticColors : materialColors

    readonly property string wallpaperSource: {
        const wp = GlobalStates.previewWallpaper !== "" ? GlobalStates.previewWallpaper : Paths.currentWallpaper;
        if (!wp)
            return "";
        if (!MediaKind.isVideo(wp))
            return wp;
        return `${MediaKind.thumbnailPathFor(wp)}?v=${Wallpaper.thumbnailVersion}`;
    }

    readonly property var materialPaletteSource: materialColor.ready ? materialColor.colors : lastValidPalette
    property var lastValidPalette: ({})

    readonly property alias animatedMaterialColors: paletteAnimator.currentPalette

    function schemeEnum(name) {
        switch (name) {
        case "vibrant":
            return ColorMaterial.Vibrant;
        case "expressive":
            return ColorMaterial.Expressive;
        case "monochrome":
            return ColorMaterial.Monochrome;
        case "rainbow":
            return ColorMaterial.Rainbow;
        case "fruit-salad":
            return ColorMaterial.FruitSalad;
        case "neutral":
            return ColorMaterial.Neutral;
        case "fidelity":
            return ColorMaterial.Fidelity;
        case "content":
            return ColorMaterial.Content;
        default:
            return ColorMaterial.TonalSpot;
        }
    }

    onMaterialPaletteSourceChanged: {
        if (!materialPaletteSource || Object.keys(materialPaletteSource).length === 0)
            return;
        lastValidPalette = materialPaletteSource;
        paletteAnimator.transitionTo(materialPaletteSource);
    }

    Component.onCompleted: {
        if (materialPaletteSource && Object.keys(materialPaletteSource).length > 0)
            paletteAnimator.transitionTo(materialPaletteSource);
    }

    function clamp01(x) {
        return Math.min(1, Math.max(0, x));
    }

    function overlayColor(baseColor, targetColor, overlayOpacity) {
        if (overlayOpacity <= 0)
            // Impossible to influence the base
            return Qt.rgba(0, 0, 0, 0);

        let invA = 1.0 - overlayOpacity;

        let r = (targetColor.r - baseColor.r * invA) / overlayOpacity;
        let g = (targetColor.g - baseColor.g * invA) / overlayOpacity;
        let b = (targetColor.b - baseColor.b * invA) / overlayOpacity;

        return Qt.rgba(clamp01(r), clamp01(g), clamp01(b), 1.0);
    }

    FileView {
        id: staticColorFile

        path: Configs.colors.staticColorsPath
        watchChanges: true
        onFileChanged: reload()
    }

    ColorMaterial {
        id: materialColor

        source: root.wallpaperSource !== "" ? `file://${root.wallpaperSource}` : ""
        darkMode: Configs.colors.isDarkMode
        scheme: root.schemeEnum(Configs.colors.scheme)
    }

    PaletteAnimator {
        id: paletteAnimator
        duration: Appearance.animations.durations.expressiveDefaultSpatial
    }

    component M3GeneratedTemplateComponent: QtObject {
        readonly property color m3SourceColor: {
            const sourceColor = root.materialTemplateColors.sourceColor;
            return sourceColor ? sourceColor : "#6750A4";
        }
        readonly property color m3SecondarySource: ColorUtils.createAnalogousColor(m3SourceColor, 60)
        readonly property color m3TertiarySource: ColorUtils.createAnalogousColor(m3SourceColor, 120)
        readonly property color m3NeutralSource: {
            let hct = ColorUtils.rgbToHct(m3SourceColor);
            return ColorUtils.hctToRgb(hct.h, 4, hct.t);
        }
        readonly property color m3NeutralVariantSource: {
            let hct = ColorUtils.rgbToHct(m3SourceColor);
            return ColorUtils.hctToRgb(hct.h, 8, hct.t);
        }

        readonly property color m3Background: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 6 : 98)
        readonly property color m3Surface: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 6 : 98)
        readonly property color m3SurfaceDim: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 6 : 87)
        readonly property color m3SurfaceBright: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 24 : 98)
        readonly property color m3SurfaceContainerLowest: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 4 : 100)
        readonly property color m3SurfaceContainerLow: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 10 : 96)
        readonly property color m3SurfaceContainer: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 12 : 94)
        readonly property color m3SurfaceContainerHigh: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 17 : 92)
        readonly property color m3SurfaceContainerHighest: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 22 : 90)

        readonly property color m3OnSurface: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 90 : 10)
        readonly property color m3OnSurfaceVariant: ColorUtils.createTonalColor(m3NeutralVariantSource, Configs.colors.isDarkMode ? 80 : 30)
        readonly property color m3OnBackground: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 90 : 10)

        readonly property color m3Primary: ColorUtils.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 80 : 40)
        readonly property color m3OnPrimary: ColorUtils.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 20 : 100)
        readonly property color m3PrimaryContainer: ColorUtils.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 30 : 90)
        readonly property color m3OnPrimaryContainer: ColorUtils.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 90 : 10)
        readonly property color m3PrimaryFixed: ColorUtils.createTonalColor(m3SourceColor, 90)
        readonly property color m3PrimaryFixedDim: ColorUtils.createTonalColor(m3SourceColor, 80)
        readonly property color m3OnPrimaryFixed: ColorUtils.createTonalColor(m3SourceColor, 10)
        readonly property color m3OnPrimaryFixedVariant: ColorUtils.createTonalColor(m3SourceColor, 30)

        readonly property color m3Secondary: ColorUtils.createTonalColor(m3SecondarySource, Configs.colors.isDarkMode ? 80 : 40)
        readonly property color m3OnSecondary: ColorUtils.createTonalColor(m3SecondarySource, Configs.colors.isDarkMode ? 20 : 100)
        readonly property color m3SecondaryContainer: ColorUtils.createTonalColor(m3SecondarySource, Configs.colors.isDarkMode ? 30 : 90)
        readonly property color m3OnSecondaryContainer: ColorUtils.createTonalColor(m3SecondarySource, Configs.colors.isDarkMode ? 90 : 10)
        readonly property color m3SecondaryFixed: ColorUtils.createTonalColor(m3SecondarySource, 90)
        readonly property color m3SecondaryFixedDim: ColorUtils.createTonalColor(m3SecondarySource, 80)
        readonly property color m3OnSecondaryFixed: ColorUtils.createTonalColor(m3SecondarySource, 10)
        readonly property color m3OnSecondaryFixedVariant: ColorUtils.createTonalColor(m3SecondarySource, 30)

        readonly property color m3Tertiary: ColorUtils.createTonalColor(m3TertiarySource, Configs.colors.isDarkMode ? 80 : 40)
        readonly property color m3OnTertiary: ColorUtils.createTonalColor(m3TertiarySource, Configs.colors.isDarkMode ? 20 : 100)
        readonly property color m3TertiaryContainer: ColorUtils.createTonalColor(m3TertiarySource, Configs.colors.isDarkMode ? 30 : 90)
        readonly property color m3OnTertiaryContainer: ColorUtils.createTonalColor(m3TertiarySource, Configs.colors.isDarkMode ? 90 : 10)
        readonly property color m3TertiaryFixed: ColorUtils.createTonalColor(m3TertiarySource, 90)
        readonly property color m3TertiaryFixedDim: ColorUtils.createTonalColor(m3TertiarySource, 80)
        readonly property color m3OnTertiaryFixed: ColorUtils.createTonalColor(m3TertiarySource, 10)
        readonly property color m3OnTertiaryFixedVariant: ColorUtils.createTonalColor(m3TertiarySource, 30)

        readonly property color m3ErrorSource: ColorUtils.hctToRgb(25, 84, 40)
        readonly property color m3Error: ColorUtils.createTonalColor(m3ErrorSource, Configs.colors.isDarkMode ? 80 : 40)
        readonly property color m3ErrorContainer: ColorUtils.createTonalColor(m3ErrorSource, Configs.colors.isDarkMode ? 30 : 90)
        readonly property color m3OnError: ColorUtils.createTonalColor(m3ErrorSource, Configs.colors.isDarkMode ? 20 : 100)
        readonly property color m3OnErrorContainer: ColorUtils.createTonalColor(m3ErrorSource, Configs.colors.isDarkMode ? 90 : 10)

        readonly property color m3InverseSurface: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 90 : 20)
        readonly property color m3InverseOnSurface: ColorUtils.createTonalColor(m3NeutralSource, Configs.colors.isDarkMode ? 20 : 95)
        readonly property color m3InversePrimary: ColorUtils.createTonalColor(m3SourceColor, Configs.colors.isDarkMode ? 40 : 80)

        readonly property color m3Outline: ColorUtils.createTonalColor(m3NeutralVariantSource, Configs.colors.isDarkMode ? 60 : 50)
        readonly property color m3OutlineVariant: ColorUtils.createTonalColor(m3NeutralVariantSource, Configs.colors.isDarkMode ? 30 : 80)

        readonly property color m3Scrim: "#000000"
        readonly property color m3Shadow: "#000000"
        readonly property color m3SurfaceTint: m3Primary
        readonly property color m3SurfaceVariant: ColorUtils.createTonalColor(m3NeutralVariantSource, Configs.colors.isDarkMode ? 30 : 90)

        readonly property color m3Red: m3Error
        readonly property color m3Green: "#4CAF50"
        readonly property color m3Blue: "#2196F3"
        readonly property color m3Yellow: "#FFEB3B"
        readonly property color m3Orange: "#FF9800"
        readonly property color m3Maroon: "#B71C1C"
    }
}

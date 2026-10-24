pragma Singleton
import QtQuick 
QtObject {
    id: theme

    //
    // Primary Palette
    //
    readonly property QtObject primary: QtObject {
        readonly property color base: "{{colors.primary.default.hex}}"
        readonly property color on: "{{colors.on_primary.default.hex}}"
    }
    readonly property QtObject primaryContainer: QtObject {
        readonly property color base: "{{colors.primary_container.default.hex}}"
        readonly property color on: "{{colors.on_primary_container.default.hex}}"
    }
    readonly property QtObject primaryFixed: QtObject {
        readonly property color base: "{{colors.primary_fixed.default.hex}}"
        readonly property color on: "{{colors.on_primary_fixed.default.hex}}"
    }
    readonly property QtObject primaryFixedDim: QtObject {
        readonly property color base: "{{colors.primary_fixed_dim.default.hex}}"
        // no explicit onPrimaryFixedDim in your list
    }
    readonly property QtObject primaryFixedVariant: QtObject {
        // no base token exposed in your list
        readonly property color on: "{{colors.on_primary_fixed_variant.default.hex}}"
    }

    //
    // Secondary Palette
    //
    readonly property QtObject secondary: QtObject {
        readonly property color base: "{{colors.secondary.default.hex}}"
        readonly property color on: "{{colors.on_secondary.default.hex}}"
    }
    readonly property QtObject secondaryContainer: QtObject {
        readonly property color base: "{{colors.secondary_container.default.hex}}"
        readonly property color on: "{{colors.on_secondary_container.default.hex}}"
    }
    readonly property QtObject secondaryFixed: QtObject {
        readonly property color base: "{{colors.secondary_fixed.default.hex}}"
        readonly property color on: "{{colors.on_secondary_fixed.default.hex}}"
    }
    readonly property QtObject secondaryFixedDim: QtObject {
        readonly property color base: "{{colors.secondary_fixed_dim.default.hex}}"
    }
    readonly property QtObject secondaryFixedVariant: QtObject {
        readonly property color on: "{{colors.on_secondary_fixed_variant.default.hex}}"
    }

    //
    // Tertiary Palette
    //
    readonly property QtObject tertiary: QtObject {
        readonly property color base: "{{colors.tertiary.default.hex}}"
        readonly property color on: "{{colors.on_tertiary.default.hex}}"
    }
    readonly property QtObject tertiaryContainer: QtObject {
        readonly property color base: "{{colors.tertiary_container.default.hex}}"
        readonly property color on: "{{colors.on_tertiary_container.default.hex}}"
    }
    readonly property QtObject tertiaryFixed: QtObject {
        readonly property color base: "{{colors.tertiary_fixed.default.hex}}"
        readonly property color on: "{{colors.on_tertiary_fixed.default.hex}}"
    }
    readonly property QtObject tertiaryFixedDim: QtObject {
        readonly property color base: "{{colors.tertiary_fixed_dim.default.hex}}"
    }
    readonly property QtObject tertiaryFixedVariant: QtObject {
        readonly property color on: "{{colors.on_tertiary_fixed_variant.default.hex}}"
    }

    //
    // Surface & Background
    //
    readonly property QtObject background: QtObject {
        readonly property color base: "{{colors.background.default.hex}}"
        readonly property color on: "{{colors.on_background.default.hex}}"
    }
    readonly property QtObject surface: QtObject {
        readonly property color base: "{{colors.surface.default.hex}}"
        readonly property color on: "{{colors.on_surface.default.hex}}"
        readonly property color tint: "{{colors.surface_tint.default.hex}}"
        readonly property color dim: "{{colors.surface_dim.default.hex}}"
        readonly property color bright: "{{colors.surface_bright.default.hex}}"
        readonly property QtObject container: QtObject {
            readonly property color base: "{{colors.surface_container.default.hex}}"
            readonly property color low: "{{colors.surface_container_low.default.hex}}"
            readonly property color lowest: "{{colors.surface_container_lowest.default.hex}}"
            readonly property color high: "{{colors.surface_container_high.default.hex}}"
            readonly property color highest: "{{colors.surface_container_highest.default.hex}}"
        }
        readonly property QtObject variant: QtObject {
            readonly property color base: "{{colors.surface_variant.default.hex}}"
            readonly property color on: "{{colors.on_surface_variant.default.hex}}"
        }
        readonly property QtObject inverse: QtObject {
            readonly property color base: "{{colors.inverse_surface.default.hex}}"
            readonly property color on: "{{colors.inverse_on_surface.default.hex}}"
        }
    }

    //
    // Error Palette
    //
    readonly property QtObject error: QtObject {
        readonly property color base: "{{colors.error.default.hex}}"
        readonly property color on: "{{colors.on_error.default.hex}}"
        readonly property QtObject container: QtObject {
            readonly property color base: "{{colors.error_container.default.hex}}"
            readonly property color on: "{{colors.on_error_container.default.hex}}"
        }
    }

    //
    // Misc
    //
    readonly property color outline: "{{colors.outline.default.hex}}"
    readonly property color outlineVariant: "{{colors.outline_variant.default.hex}}"
    readonly property color scrim: "{{colors.scrim.default.hex}}"
    readonly property color shadow: "{{colors.shadow.default.hex}}"
    readonly property color inversePrimary: "{{colors.inverse_primary.default.hex}}"
    readonly property color sourceColor: "{{colors.source_color.default.hex}}"

    // Typography
    readonly property string fontFamily: "sans-serif"
    readonly property string fontFamilyMono: "monospace"
    readonly property string fontFamilyIcons: "JetBrainsMono Nerd Font Propo"

    // Font Sizes (Material Design Type Scale)
    readonly property int displayLarge: 57
    readonly property int displayMedium: 45
    readonly property int displaySmall: 36
    readonly property int headlineLarge: 32
    readonly property int headlineMedium: 28
    readonly property int headlineSmall: 24
    readonly property int titleLarge: 22
    readonly property int titleMedium: 16
    readonly property int titleSmall: 14
    readonly property int bodyLarge: 16
    readonly property int bodyMedium: 14
    readonly property int bodySmall: 12
    readonly property int labelLarge: 14
    readonly property int labelMedium: 12
    readonly property int labelSmall: 11

    // Font Weights
    readonly property int weightRegular: 400
    readonly property int weightMedium: 500
    readonly property int weightBold: 700

    // Spacing (Material Design 8dp grid)
    readonly property int spacing1: 4
    readonly property int spacing2: 8
    readonly property int spacing3: 12
    readonly property int spacing4: 16
    readonly property int spacing5: 20
    readonly property int spacing6: 24
    readonly property int spacing8: 32
    readonly property int spacing10: 40
    readonly property int spacing12: 48
    readonly property int spacing16: 64

    // Corner Radius (Material Design 3)
    readonly property int radiusNone: 0
    readonly property int radiusXs: 4
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusXl: 28
    readonly property int radiusFull: 9999

    // Elevation (shadows)
    readonly property int elevation0: 0
    readonly property int elevation1: 1
    readonly property int elevation2: 3
    readonly property int elevation3: 6
    readonly property int elevation4: 8
    readonly property int elevation5: 12

    // Animation Durations
    readonly property int durationFast: 150
    readonly property int durationDefault: 200
    readonly property int durationSlow: 300
    readonly property int durationSpatialFast: 350
    readonly property int durationSpatialDefault: 500
    readonly property int durationSpatialSlow: 650

    // Easing Curves
    readonly property var easingStandard: Easing.OutCubic
    readonly property var easingDecelerate: Easing.OutQuart
    readonly property var easingAccelerate: Easing.InQuart
    readonly property var easingEmphasized: Easing.OutBack
    readonly property var curveEmphasizedAccelerate: [0.3, 0, 0.8, 0.15, 1, 1]

    // Animation Curves
    readonly property QtObject animation: QtObject {
        // Expressive Curves
        readonly property QtObject expressive: QtObject {
            readonly property QtObject spatial: QtObject {
                // Use standard Easing curves instead of cubic bezier
                readonly property var fastCurve: Easing.BezierSpline
                readonly property int fastDuration: 350
                readonly property var defaultCurve: Easing.BezierSpline
                readonly property int defaultDuration: 500
                readonly property var slowCurve: Easing.BezierSpline
                readonly property int slowDuration: 650
                // Store bezier parameters for reference
                readonly property var fastParams: [0.42, 1.67, 0.21, 0.9]
                readonly property var defaultParams: [0.38, 1.21, 0.22, 1]
                readonly property var slowParams: [0.39, 1.29, 0.35, 0.98]
            }
            readonly property QtObject effects: QtObject {
                readonly property var fastCurve: Easing.OutCubic
                readonly property int fastDuration: 150
                readonly property var defaultCurve: Easing.OutCubic
                readonly property int defaultDuration: 200
                readonly property var slowCurve: Easing.OutCubic
                readonly property int slowDuration: 300
                // Store bezier parameters for reference
                readonly property var fastParams: [0.31, 0.94, 0.34, 1]
                readonly property var defaultParams: [0.34, 0.8, 0.34, 1]
                readonly property var slowParams: [0.34, 0.88, 0.34, 1]
            }
        }

        // Standard Curves
        readonly property QtObject standard: QtObject {
            readonly property QtObject spatial: QtObject {
                readonly property var fastCurve: Easing.OutCubic
                readonly property int fastDuration: 350
                readonly property var defaultCurve: Easing.OutCubic
                readonly property int defaultDuration: 500
                readonly property var slowCurve: Easing.OutCubic
                readonly property int slowDuration: 750
                // Store bezier parameters for reference
                readonly property var fastParams: [0.27, 1.06, 0.18, 1]
                readonly property var defaultParams: [0.27, 1.06, 0.18, 1]
                readonly property var slowParams: [0.27, 1.06, 0.18, 1]
            }
            readonly property QtObject effects: QtObject {
                readonly property var fastCurve: Easing.OutCubic
                readonly property int fastDuration: 150
                readonly property var defaultCurve: Easing.OutCubic
                readonly property int defaultDuration: 200
                readonly property var slowCurve: Easing.OutCubic
                readonly property int slowDuration: 300
                // Store bezier parameters for reference
                readonly property var fastParams: [0.31, 0.94, 0.34, 1]
                readonly property var defaultParams: [0.34, 0.8, 0.34, 1]
                readonly property var slowParams: [0.34, 0.88, 0.34, 1]
            }
        }
    }

    // Dark mode toggle
    property bool isDarkMode: false

    // Helpers
    function withOpacity(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }

    function getStateLayerColor(baseColor, state) {
        switch (state) {
        case "hover":
            return withOpacity(baseColor, 0.08);
        case "focus":
            return withOpacity(baseColor, 0.12);
        case "pressed":
            return withOpacity(baseColor, 0.12);
        case "dragged":
            return withOpacity(baseColor, 0.16);
        default:
            return "transparent";
        }
    }

    function getElevationColor(level) {
        var opacity = 0;
        switch (level) {
        case 1:
            opacity = 0.05;
            break;
        case 2:
            opacity = 0.08;
            break;
        case 3:
            opacity = 0.11;
            break;
        case 4:
            opacity = 0.12;
            break;
        case 5:
            opacity = 0.14;
            break;
        default:
            opacity = 0;
            break;
        }
        return withOpacity(theme.primary.base, opacity);
    }
}

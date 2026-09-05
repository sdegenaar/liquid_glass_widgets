// Copyright 2025, Tim Lehmann for whynotmake.it
// Copyright 2026, Sebastian Degenaar for pixel-innovations.com (liquid_glass_widgets)
//
// SPDX-License-Identifier: MIT
//
// Vendored from liquid_glass_renderer at version 0.2.0-dev.4 (2026-03-28).
// Source: https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer
//
// Modifications (2026):
//   - Removed internal package dependencies; adapted for direct vendoring.
//   - Extended public API surface with additional shape types and blend options.
//   - Added Windows/SkSL shader compatibility layer.
import 'package:flutter/foundation.dart' show kDebugMode;

export 'glass_glow.dart' show GlassGlow, GlassGlowLayer;
export 'liquid_glass.dart' show LiquidGlass;
export 'liquid_glass_blend_group.dart' show LiquidGlassBlendGroup;
export 'liquid_glass_settings.dart'
    show GlassBodyMode, LiquidGlassSettings, PlatformViewGlassMode;
export 'liquid_shape.dart';
export 'internal/liquid_glass_self_scale_scope.dart'
    show LiquidGlassSelfScaleScope;
export 'rendering/liquid_glass_layer.dart' show LiquidGlassLayer;
export 'stretch.dart'
    show
        AnchorStretchSettings,
        LiquidStretch,
        OffsetResistanceExtension,
        RawLiquidStretch;

/// Whether to paint the liquid glass geometry texture for debugging purposes.
///
/// When enabled, geometry textures will be drawn directly instead of the
/// liquid glass effect.
///
/// Will be set to `false` in release builds.
@pragma('vm:platform-const-if', !kDebugMode)
bool debugPaintLiquidGlassGeometry = false;

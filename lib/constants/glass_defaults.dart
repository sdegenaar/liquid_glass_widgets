/// Common constants used throughout the liquid_glass_widgets package.
///
/// These constants define default values for glass effects, dimensions,
/// and other commonly used values to ensure consistency across widgets.
library;

import 'package:flutter/widgets.dart';

/// Default values for glass visual properties.
class GlassDefaults {
  // Prevent instantiation
  GlassDefaults._();

  // ============================================================================
  // Glass Effect Properties
  // ============================================================================

  /// Default glass thickness for most widgets (30.0)
  static const double thickness = 30.0;

  /// Default blur amount for glass effects (3.0)
  static const double blur = 3.0;

  /// Default light intensity for specular highlights (2.0)
  static const double lightIntensity = 2.0;

  /// Default chromatic aberration amount (0.5)
  static const double chromaticAberration = 0.5;

  /// Default refractive index for glass (1.15)
  static const double refractiveIndex = 1.15;

  /// Default light angle in radians (135° = 0.75 * π — Apple iOS 26 standard, upper-left light)
  static const double lightAngle = 0.75 * 3.14159265358979; // 0.75 * pi

  // ============================================================================
  // Border Radius
  // ============================================================================

  /// Standard border radius for most glass widgets (16.0)
  static const double borderRadius = 16.0;

  /// Small border radius for compact elements (8.0)
  static const double borderRadiusSmall = 8.0;

  /// Large border radius for prominent elements (20.0)
  static const double borderRadiusLarge = 20.0;

  /// Sentinel radius that produces a perfect capsule (stadium) shape at any
  /// widget height.
  ///
  /// Internally, interactive widgets such as [GlassSegmentedControl]
  /// and [GlassTabBar] detect this value via a
  /// `>= capsuleRadius` guard and pass it straight through to the glass shader
  /// without subtracting the indicator padding inset. This guarantees a
  /// true circular pill even during jelly-bloom expansion, where the physics
  /// canvas grows well beyond the widget’s at-rest height.
  ///
  /// Use this constant instead of a raw `9999` literal:
  /// ```dart
  /// GlassTabBar.bottom(
  ///   barBorderRadius: GlassDefaults.capsuleRadius, // true capsule
  /// )
  /// ```
  ///
  /// Why 9999 and not [double.infinity]? The shader SDF receives the radius
  /// as a uniform float and guards against infinity, so a large-but-finite
  /// sentinel is the safe cross-platform choice.
  static const double capsuleRadius = 9999.0;

  // ============================================================================
  // Padding
  // ============================================================================

  /// Standard padding for card-like widgets
  static const EdgeInsets paddingCard = EdgeInsets.all(16.0);

  /// Standard padding for panel-like widgets
  static const EdgeInsets paddingPanel = EdgeInsets.all(24.0);

  /// Standard padding for input fields
  static const EdgeInsets paddingInput =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  /// Compact padding for small elements
  static const EdgeInsets paddingCompact = EdgeInsets.all(8.0);

  /// Minimal padding for tight layouts
  static const EdgeInsets paddingMinimal = EdgeInsets.all(4.0);

  // ============================================================================
  // Dimensions
  // ============================================================================

  /// Standard height for interactive controls (32.0)
  static const double heightControl = 32.0;

  /// Standard height for buttons (48.0)
  static const double heightButton = 48.0;

  /// Standard height for input fields (48.0)
  static const double heightInput = 48.0;

  // ============================================================================
  // Animation Durations
  // ============================================================================

  /// Standard animation duration for glass effects (200ms)
  static const Duration animationDuration = Duration(milliseconds: 200);

  /// Fast animation duration for quick transitions (100ms)
  static const Duration animationDurationFast = Duration(milliseconds: 100);

  /// Slow animation duration for deliberate effects (300ms)
  static const Duration animationDurationSlow = Duration(milliseconds: 300);

  // ============================================================================
  // Overlay / Compositor
  // ============================================================================

  /// Barrier colour for modal overlays (sheets, action sheets).
  /// iOS 26 uses 54% black to dim content behind modals.
  static const Color barrierColor = Color(0x8A000000); // ~54% black

  /// Specular tint applied to drag handles and pill surfaces (light mode).
  static const double specularLightAlpha = 0.15;

  /// Specular tint applied to drag handles and pill surfaces (dark mode).
  static const double specularDarkAlpha = 0.10;
}

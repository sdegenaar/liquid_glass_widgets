import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Recommended glass settings optimized for the calibrated lightweight shader.
///
/// These settings provide the best iOS 26 liquid glass appearance across
/// both Skia (standard) and Impeller (premium) renderers.
///
/// ## refractiveIndex Parameter Guide:
///
/// **Standard Quality (Lightweight Shader - Skia):**
/// - Controls rim prominence/thickness
/// - Range: 0.7-2.0
///   - `0.7-1.0`: Thin delicate rim (iOS 26 default aesthetic)
///   - `1.0-1.5`: Moderate rim visibility
///   - `1.5-2.0`: Bold prominent rim
///
/// **Premium Quality (Full Shader - Impeller):**
/// - Controls actual light refraction through glass
/// - Range: 1.0-2.0
///   - `1.0-1.2`: Subtle refraction
///   - `1.2-1.5`: Noticeable refraction
///   - `1.5-2.0`: Strong refraction
class RecommendedGlassSettings {
  const RecommendedGlassSettings._();

  /// Standard settings for scrollable content.
  ///
  /// Optimized for performance with excellent visual quality.
  /// Use with `GlassQuality.standard` (default).
  ///
  /// - refractiveIndex: 0.7 = thin delicate rim (standard) / subtle refraction (premium)
  static const standard = LiquidGlassSettings(
    blur: 10,
    thickness: 0,
    glassColor: Color.fromRGBO(255, 255, 255, 0.12),
    lightAngle: 135, // 135° - upper right
    lightIntensity: 0.7,
    ambientStrength: 0.4,
    saturation: 1.2,
    refractiveIndex: 0.7, // Thin rim (standard) / subtle refraction (premium)
    chromaticAberration: 0.0,
  );

  /// Settings for buttons and interactive elements.
  ///
  /// Optimized for interactive feedback with adaptive glow effects.
  ///
  /// - refractiveIndex: 0.7 = thin delicate rim (iOS 26 aesthetic)
  /// - saturation: 0.0 at rest, automatically animated to 1.0 on press
  ///   - On Impeller: GlassGlow handles advanced compositing
  ///   - On Skia: Shader glow provides frosted press feedback
  static const interactive = LiquidGlassSettings(
    blur: 10,
    thickness: 10,
    glassColor: Color.fromRGBO(255, 255, 255, 0.2),
    lightAngle: 135,
    lightIntensity: 0.7,
    ambientStrength: 0.3,
    saturation: 0.0, // Glow intensity (0.0=off, animated on press)
    refractiveIndex: 0.7, // Thin rim (standard) / subtle refraction (premium)
    chromaticAberration: 0.0,
  );

  /// Settings for static surfaces (app bars, toolbars).
  ///
  /// Can use premium quality for best visual impact.
  ///
  /// - refractiveIndex: 1.15 = moderate rim (standard) / subtle refraction (premium)
  static const surface = LiquidGlassSettings(
    blur: 10,
    thickness: 10,
    glassColor: Color.fromRGBO(255, 255, 255, 0.2),
    lightAngle: 135,
    lightIntensity: 0.7,
    ambientStrength: 0.3,
    saturation: 1.2,
    refractiveIndex:
        1.15, // Moderate rim (standard) / subtle refraction (premium)
    chromaticAberration: 0.0,
  );

  /// Settings for bottom navigation bars.
  ///
  /// Optimized for premium quality in static position.
  ///
  /// - refractiveIndex: 1.2 = moderate rim (standard) / noticeable refraction (premium)
  static const bottomBar = LiquidGlassSettings(
    blur: 12,
    thickness: 20,
    glassColor: Color.fromRGBO(255, 255, 255, 0.08),
    lightAngle: 0.75 * math.pi,
    lightIntensity: 0.7,
    ambientStrength: 0.5,
    saturation: 1.4,
    refractiveIndex:
        1.2, // Moderate rim (standard) / noticeable refraction (premium)
    chromaticAberration: 0.0,
  );

  /// Settings for overlays and sheets.
  ///
  /// Balanced for modal dialogs and bottom sheets.
  ///
  /// - refractiveIndex: 0.7 = thin delicate rim (iOS 26 aesthetic)
  static const overlay = LiquidGlassSettings(
    blur: 10,
    thickness: 10,
    glassColor: Color.fromRGBO(255, 255, 255, 0.12),
    lightAngle: 135,
    lightIntensity: 0.7,
    ambientStrength: 0.4,
    saturation: 1.2,
    refractiveIndex: 0.7, // Thin rim (standard) / subtle refraction (premium)
    chromaticAberration: 0.0,
  );

  /// Settings for input fields.
  ///
  /// Subtle appearance that doesn't distract from content.
  ///
  /// - refractiveIndex: 0.7 = thin delicate rim (iOS 26 aesthetic)
  static const input = LiquidGlassSettings(
    blur: 20,
    thickness: 10,
    glassColor: Color.fromRGBO(255, 255, 255, 0.12),
    lightAngle: 135,
    lightIntensity: 0.7,
    ambientStrength: 0.4,
    saturation: 1.2,
    refractiveIndex: 0.7, // Thin rim (standard) / subtle refraction (premium)
    chromaticAberration: 0.0,
  );
}

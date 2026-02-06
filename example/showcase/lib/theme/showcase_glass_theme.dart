import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Glass theme settings for the Wanderlust Showcase App
///
/// This file centralizes all glass morphism settings to ensure visual
/// consistency across the entire showcase application while making it
/// easy to adjust the overall aesthetic.
///
/// All settings have been carefully calibrated to match the current
/// production-ready look of the app.
class ShowcaseGlassTheme {
  ShowcaseGlassTheme._();

  // ===========================================================================
  // SHARED CONSTANTS
  // ===========================================================================

  /// Standard light angle used across most UI elements (45 degrees)
  static const double standardLightAngle = 0.25 * math.pi;

  /// Light angle for bottom sheets and modals (130 degrees)
  static const double modalLightAngle = 130.0;

  // ===========================================================================
  // HEADER & NAVIGATION
  // ===========================================================================

  /// Settings for top navigation buttons (back, settings, profile, etc.)
  static LiquidGlassSettings get headerButtons => LiquidGlassSettings(
        blur: 8,
        thickness: 25,
        ambientStrength: 0.4,
        lightAngle: standardLightAngle,
        glassColor: Colors.white.withValues(alpha: 0.1),
      );

  /// Settings for the profile button in home page (lighter variant)
  static LiquidGlassSettings get profileButton => LiquidGlassSettings(
        blur: 8,
        thickness: 24,
        ambientStrength: 0.5,
        lightIntensity: 0.7,
        lightAngle: standardLightAngle,
        glassColor: Colors.white12,
      );

  /// Settings for top navigation buttons on detail page (darker variant)
  static LiquidGlassSettings get detailHeaderButtons => LiquidGlassSettings(
        blur: 12,
        thickness: 25,
        ambientStrength: 0.4,
        lightAngle: standardLightAngle,
        glassColor: Colors.black.withValues(alpha: 0.3),
      );

  // ===========================================================================
  // SEARCH & INPUT
  // ===========================================================================

  /// Settings for search bar and text input areas
  static LiquidGlassSettings get searchBar => LiquidGlassSettings(
        blur: 4,
        ambientStrength: 2,
        lightAngle: standardLightAngle,
        glassColor: Colors.black12,
        thickness: 30,
      );

  /// Settings for chat/concierge input area
  static LiquidGlassSettings get chatInput => LiquidGlassSettings(
        thickness: 5,
        ambientStrength: 0.4,
        lightAngle: modalLightAngle,
        glassColor: Colors.white.withValues(alpha: 0.08),
      );

  // ===========================================================================
  // CARDS & CONTAINERS
  // ===========================================================================

  /// Settings for booking card on detail page
  static LiquidGlassSettings get bookingCard => LiquidGlassSettings(
        thickness: 5,
        ambientStrength: 0.5,
        lightIntensity: 0.5,
        lightAngle: 120,
        glassColor: Colors.black.withValues(alpha: 0.4),
      );

  /// Settings for segmented control
  static LiquidGlassSettings get segmentedControl => LiquidGlassSettings(
        blur: 8,
        thickness: 25,
        ambientStrength: 0.4,
        lightAngle: modalLightAngle,
        glassColor: Colors.white.withValues(alpha: 0.08),
      );

  /// Settings for prompt suggestion chips
  static LiquidGlassSettings get promptChips => LiquidGlassSettings(
        thickness: 5,
        ambientStrength: 0.3,
        lightAngle: modalLightAngle,
        glassColor: Colors.white.withValues(alpha: 0.12),
      );

  // ===========================================================================
  // INTERACTIVE BUTTONS
  // ===========================================================================

  /// Settings for primary action buttons (Book Now, Contact, etc.)
  static LiquidGlassSettings get actionButton => LiquidGlassSettings(
        thickness: 5,
        ambientStrength: 0.5,
        lightIntensity: 0.8,
        lightAngle: 120,
        glassColor: Colors.blue.withValues(alpha: 0.1),
      );

  /// Settings for filter/modal action buttons (Clear, Apply)
  static LiquidGlassSettings get modalActionButtons => LiquidGlassSettings(
        thickness: 5,
        ambientStrength: 0.5,
        lightIntensity: 0.8,
        lightAngle: 120,
        glassColor: Colors.blue.withValues(alpha: 0.1),
      );

  /// Settings for the "Done" button in concierge settings
  static LiquidGlassSettings get doneButton => LiquidGlassSettings(
        thickness: 5,
        ambientStrength: 0.5,
        lightIntensity: 0.8,
        lightAngle: 120,
        glassColor: Colors.blue.withValues(alpha: 0.1),
      );

  // ===========================================================================
  // SHEETS & MODALS
  // ===========================================================================

  /// Settings for bottom sheets (filters, settings)
  static LiquidGlassSettings get bottomSheet => LiquidGlassSettings(
        blur: 12,
        thickness: 5,
        ambientStrength: 0.5,
        lightIntensity: 0.6,
        lightAngle: modalLightAngle,
        glassColor: Colors.white.withValues(alpha: 0.12),
      );

  /// Settings for switches inside bottom sheets
  static LiquidGlassSettings get sheetSwitches => LiquidGlassSettings(
        blur: 8,
        thickness: 25,
        ambientStrength: 0.4,
        lightAngle: standardLightAngle,
        glassColor: Colors.white.withValues(alpha: 0.08),
      );

  /// Settings for dialogs
  static LiquidGlassSettings get dialog => LiquidGlassSettings(
        blur: 12,
        thickness: 5,
        ambientStrength: 0.5,
        lightIntensity: 0.6,
        lightAngle: modalLightAngle,
        glassColor: Colors.white.withValues(alpha: 0.08),
      );

  // ===========================================================================
  // QUALITY PRESETS
  // ===========================================================================

  /// Standard quality for most UI elements (uses lightweight shader)
  static const GlassQuality standardQuality = GlassQuality.standard;

  /// Premium quality for key interactive elements (uses Impeller on iOS/macOS)
  static const GlassQuality premiumQuality = GlassQuality.premium;
}

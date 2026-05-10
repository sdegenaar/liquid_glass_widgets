import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart'; // Required for SpringSimulation
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../constants/glass_defaults.dart';
import '../../types/glass_quality.dart';
import '../containers/glass_container.dart';
import '../shared/inherited_liquid_glass.dart';
import 'glass_menu_item.dart';
import '../../theme/glass_theme_helpers.dart';

part 'shared/glass_menu_internal.dart';

/// A liquid glass context menu that morphs from its trigger button.
///
/// [GlassMenu] implements the iOS 26 "liquid glass" morphing pattern where
/// a button seamlessly transforms into a menu. The same glass container
/// transitions between button and menu states using spring physics.
///
/// ## Features
/// - **True morphing**: Button transforms into menu (not overlay)
/// - **Smooth spring physics**: Gentle settle with no harsh bounces (stiffness: 300, damping: 24)
/// - **Liquid swoop**: Subtle 5px parabolic arc for seamless down-and-up motion
/// - **Seamless crossfade**: Button only appears at final 5% to preserve morph illusion
/// - **Dimension interpolation**: Width, height, and border radius morph smoothly
/// - **Position aware**: Menu expands from button position
/// - **Settings inheritance**: Inherits parent layer settings like GlassCard (thin rim by default)
/// - **No button animation**: Trigger button remains static, only shape morphs
class GlassMenu extends StatefulWidget {
  /// The widget that triggers the menu.
  ///
  /// If provided, this widget will be wrapped in a [GestureDetector] to handle
  /// taps. Use this for simple, non-interactive triggers like Icons or Text.
  ///
  /// If your trigger is interactive (like a [GlassButton]), use [triggerBuilder]
  /// instead to manually handle the tap event.
  final Widget? trigger;

  /// A builder for the trigger widget that provides access to the menu toggle callback.
  ///
  /// Use this when your trigger widget handles its own interactions (e.g., a [GlassButton]
  /// or [IconButton]).
  ///
  /// Example:
  /// ```dart
  /// GlassMenu(
  ///   triggerBuilder: (context, toggle) => GlassButton(
  ///     onTap: toggle,
  ///     child: Text('Open'),
  ///   ),
  ///   ...
  /// )
  /// ```
  final Widget Function(BuildContext context, VoidCallback toggleMenu)?
      triggerBuilder;

  /// The list of items to display in the menu.
  ///
  /// Typically contains [GlassMenuItem] and [GlassMenuDivider].
  final List<Widget> items;

  /// The alignment of the menu relative to the trigger.
  final GlassMenuAlignment? menuAlignment;

  /// Whether to automatically adjust the menu position to keep it on screen.
  final bool autoAdjustToScreen;

  /// Width of the expanded menu.
  final double menuWidth;

  /// Border radius of the expanded menu.
  ///
  /// Defaults to 32.0 for a modern rounded look.
  final double menuBorderRadius;

  /// Border radius of the selection highlight and menu items.
  ///
  /// Defaults to 24.0.
  final double itemBorderRadius;

  /// Custom glass settings for the menu container.
  final LiquidGlassSettings? glassSettings;

  /// Rendering quality for the glass effect.
  final GlassQuality? quality;

  /// Liquid stretch factor. Default: 0.5.
  final double stretch;

  /// Scale factor applied on touch. Default: 1.02.
  final double interactionScale;

  /// The resistance factor to apply to the drag offset.
  /// Higher values make the drag feel "stickier". Default: 0.08.
  final double stretchResistance;

  /// The axis to constrain the stretch to. If null, stretches in both axes.
  final Axis? stretchAxis;

  /// Whether to allow stretch in the positive X direction (Right).
  /// If null, automatically determined by menu position.
  final bool? allowPositiveX;

  /// Whether to allow stretch in the negative X direction (Left).
  /// If null, automatically determined by menu position.
  final bool? allowNegativeX;

  /// Whether to allow stretch in the positive Y direction (Down).
  /// If null, automatically determined by menu position.
  final bool? allowPositiveY;

  /// Whether to allow stretch in the negative Y direction (Up).
  /// If null, automatically determined by menu position.
  final bool? allowNegativeY;

  /// Whether to show glow/glare on touch for tactile feedback. Default: true.
  final bool enableInteractionGlow;

  /// Whether the glow should act as a momentary tap indicator.
  ///
  /// If true, the glow will appear on tap but will automatically fade out
  /// if the user starts dragging. It will not reappear until a new tap starts.
  /// Default: true.
  final bool glowOnTapOnly;

  /// Custom color for the touch interaction glow.
  final Color? glowColor;

  /// Radius of the touch interaction glow. Default: 0.6.
  final double glowRadius;

  /// The intensity of the interactive glow.
  ///
  /// Defaults to 0.0.
  final double glowIntensity;

  /// Custom color for the menu selection background.
  final Color selectionColor;

  /// Optional fixed height for the menu.
  ///
  /// If null, the menu will size itself to fit its items.
  /// If provided, the menu will have a fixed height and internal scrolling.
  final double? menuHeight;

  /// The minimum distance between the menu and the screen edges.
  ///
  /// Only applies when [autoAdjustToScreen] is true.
  /// Defaults to 0.0 (touches the edge). Set to a value like 12.0 for a safe margin.
  final EdgeInsets menuPadding;

  /// Creates a liquid glass menu.
  const GlassMenu({
    super.key,
    this.trigger,
    this.triggerBuilder,
    required this.items,
    this.menuAlignment,
    this.autoAdjustToScreen = false,
    this.menuWidth = 200,
    this.menuBorderRadius = 32.0,
    this.itemBorderRadius = 24.0,
    this.glassSettings,
    this.quality,
    this.stretch = 0.5,
    this.interactionScale = 1.02,
    this.stretchResistance = 0.08,
    this.stretchAxis,
    this.allowPositiveX,
    this.allowNegativeX,
    this.allowPositiveY,
    this.allowNegativeY,
    this.menuHeight,
    this.menuPadding = EdgeInsets.zero,
    this.selectionColor = const Color(0x3DFFFFFF),
    this.enableInteractionGlow = true,
    this.glowOnTapOnly = true,
    this.glowColor,
    this.glowRadius = 0.6,
    this.glowIntensity = 0.0,
  }) : assert(trigger != null || triggerBuilder != null,
            'Either trigger or triggerBuilder must be provided');

  @override
  State<GlassMenu> createState() => _GlassMenuState();
}

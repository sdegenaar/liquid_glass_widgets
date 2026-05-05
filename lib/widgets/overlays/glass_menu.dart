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

  /// Width of the expanded menu.
  final double menuWidth;

  /// Border radius of the expanded menu.
  ///
  /// Defaults to 28.0 for a modern rounded look.
  final double menuBorderRadius;

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
  final bool? allowPositiveXStretch;

  /// Whether to allow stretch in the negative X direction (Left).
  /// If null, automatically determined by menu position.
  final bool? allowNegativeXStretch;

  /// Whether to allow stretch in the positive Y direction (Down).
  /// If null, automatically determined by menu position.
  final bool? allowPositiveYStretch;

  /// Whether to allow stretch in the negative Y direction (Up).
  /// If null, automatically determined by menu position.
  final bool? allowNegativeYStretch;

  /// Whether to show glow/glare on touch for tactile feedback. Default: true.
  final bool enableInteractionGlow;

  /// Whether the glow should act as a momentary tap indicator.
  ///
  /// If true, the glow will appear on tap but will automatically fade out
  /// if the user starts dragging. It will not reappear until a new tap starts.
  /// Default: false.
  final bool glowOnTapOnly;

  /// Custom color for the touch interaction glow.
  final Color? glowColor;

  /// Radius of the touch interaction glow. Default: 0.6.
  final double glowRadius;

  /// Custom color for the menu selection background.
  final Color selectionColor;

  /// Optional fixed height for the menu.
  ///
  /// If null, the menu will size itself to fit its items.
  /// If provided, the menu will have a fixed height and internal scrolling.
  final double? menuHeight;

  /// Creates a liquid glass menu.
  const GlassMenu({
    super.key,
    this.trigger,
    this.triggerBuilder,
    required this.items,
    this.menuWidth = 200,
    this.menuBorderRadius = 32.0,
    this.glassSettings,
    this.quality,
    this.stretch = 0.5,
    this.interactionScale = 1.02,
    this.stretchResistance = 0.08,
    this.stretchAxis,
    this.allowPositiveXStretch,
    this.allowNegativeXStretch,
    this.allowPositiveYStretch,
    this.allowNegativeYStretch,
    this.menuHeight,
    this.selectionColor = const Color(0x3DFFFFFF),
    this.enableInteractionGlow = true,
    this.glowOnTapOnly = false,
    this.glowColor,
    this.glowRadius = 0.6,
  }) : assert(trigger != null || triggerBuilder != null,
            'Either trigger or triggerBuilder must be provided');

  @override
  State<GlassMenu> createState() => _GlassMenuState();
}

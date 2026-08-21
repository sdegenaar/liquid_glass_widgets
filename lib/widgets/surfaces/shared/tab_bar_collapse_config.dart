import 'package:flutter/widgets.dart';

import '../../interactive/glass_button.dart';

// =============================================================================
// Masking Quality
// =============================================================================

/// Rendering quality for the liquid glass masking effect in [GlassTabBar].
///
/// Controls the complexity of the masking effect that creates the "magic lens"
/// appearance where selected tab content appears to glow through the glass indicator.
enum MaskingQuality {
  /// No masking effect, simple icon color change (fastest).
  ///
  /// Uses the traditional approach where tabs simply change color when selected.
  /// No dual-layer rendering or clipping. Best performance, but less visual polish.
  ///
  /// **Recommended for:**
  /// - Apps targeting older devices (iPhone X or older)
  /// - Maximum performance requirements
  /// - 7+ tabs
  off,

  /// Full jelly physics clip path with dual-layer rendering (best quality, default).
  ///
  /// Creates a "magic lens" effect where selected tabs appear to glow through
  /// the glass indicator as it moves. Content is magnified and the clip path
  /// follows the jelly physics for perfect synchronization.
  ///
  /// **Recommended for:**
  /// - Modern devices (iPhone 12+, Pixel 5+)
  /// - 3-5 tabs (typical use case)
  /// - Premium/polished apps
  /// - When visual quality is a priority
  ///
  /// **Performance:** Renders tabs twice with ClipPath operations. Maintains
  /// 60fps on modern devices with typical 3-5 tab configurations.
  high,
}

// =============================================================================
// Extra Button Configuration
// =============================================================================

/// Where a [GlassTabBarExtraButton] appears relative to the search pill
/// in a searchable tab bar.
///
/// Has no effect in non-searchable bottom tabs, where
/// [GlassExtraButtonPlacement] controls left/right placement instead.
enum GlassExtraButtonPosition {
  /// Place the button **before** the search pill — between the tab pill and
  /// the search pill. This is the default and matches the classic iOS
  /// "compose" button position seen in Mail and Messages.
  beforeSearch,

  /// Place the button **after** the search pill — pinned to the trailing
  /// (right) edge of the bar. Use this when you want a persistent action
  /// button that stays visible at the far right even while search is expanded.
  /// The search pill's spring calculations automatically reserve the required
  /// space so no RenderFlex overflow occurs during transitions.
  afterSearch,
}

/// Where a [GlassTabBarExtraButton] appears in a non-searchable
/// [GlassTabBar.bottom].
///
/// Defaults to [GlassExtraButtonPlacement.right], matching the original
/// bottom-bar layout.
enum GlassExtraButtonPlacement {
  /// Place the button on the physical left side of the bar, before the tabs.
  left,

  /// Place the button on the physical right side of the bar, after the tabs.
  right,
}

/// Configuration for the extra button in [GlassTabBar].
///
/// The extra button is rendered as a [GlassButton] and typically used for
/// primary actions like creating new content.
class GlassTabBarExtraButton {
  /// Creates an extra button configuration.
  const GlassTabBarExtraButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.iconColor,
    this.size = 64,
    this.placement = GlassExtraButtonPlacement.right,
    this.position = GlassExtraButtonPosition.beforeSearch,
    this.collapseOnSearchFocus = true,
  });

  /// Icon widget displayed in the button.
  final Widget icon;

  /// Callback when the button is tapped.
  final VoidCallback onTap;

  /// Accessibility label for the button.
  final String label;

  /// Color used for the button's icon.
  final Color? iconColor;

  /// Width and height of the button.
  ///
  /// Defaults to 64 to match the default bar height.
  final double size;

  /// Where this button is placed in [GlassTabBar.bottom].
  ///
  /// Defaults to [GlassExtraButtonPlacement.right], which preserves the
  /// original bottom-bar behavior. Set to [GlassExtraButtonPlacement.left] to
  /// place the action before the tab pill.
  ///
  /// Has no effect in searchable tab bars, where [position] controls
  /// placement relative to the search pill.
  final GlassExtraButtonPlacement placement;

  /// Where this button is placed relative to the search pill in a
  /// searchable tab bar.
  ///
  /// - [GlassExtraButtonPosition.beforeSearch] (default) — between the tab pill
  ///   and the search pill. Classic iOS pattern (Mail compose button).
  /// - [GlassExtraButtonPosition.afterSearch] — pinned to the right edge, after
  ///   the search pill. The search pill's spring calculations automatically
  ///   reserve space so no RenderFlex overflow occurs during transitions.
  final GlassExtraButtonPosition position;

  /// Whether this button collapses (hides + frees layout space) when the
  /// search field is focused (i.e. the keyboard is visible).
  ///
  /// When `true` (default), the button fades out and its horizontal layout
  /// space spring-animates to zero on keyboard appearance, giving the search
  /// input the full available width — matching native iOS system apps
  /// (Weather, App Store, Apple News).
  ///
  /// When `false`, the button remains fully visible and tappable alongside
  /// the search input. Use this for buttons with contextual relevance during
  /// active search (e.g. a "Filter" action that applies to search results).
  final bool collapseOnSearchFocus;
}

// =============================================================================
// Collapse Configuration
// =============================================================================

/// Which way the tab pill retracts when the tab bar collapses.
enum GlassTabBarCollapseDirection {
  /// Retract toward the configured [GlassTabBarExtraButton].
  towardsExtraButton,

  /// Retract away from the configured [GlassTabBarExtraButton].
  awayFromExtraButton,
}

/// Enables the tab bar's collapse-to-extra-button interaction.
///
/// When provided to [GlassTabBar.bottom], an upward swipe collapses the tab
/// pill toward a single point while keeping the extra button visible. A downward
/// swipe expands it again, and tapping the collapsed bar can optionally expand
/// it before the extra action fires.
class GlassTabBarCollapseConfig {
  /// Creates a collapse behavior configuration.
  const GlassTabBarCollapseConfig({
    this.direction = GlassTabBarCollapseDirection.towardsExtraButton,
    this.expandOnTap = true,
    this.animationDuration = const Duration(milliseconds: 280),
    this.collapsedExtraButtonScale = 0.9,
  }) : assert(
          collapsedExtraButtonScale > 0,
          'collapsedExtraButtonScale must be greater than 0.',
        );

  /// Which physical edge the tab pill collapses toward.
  final GlassTabBarCollapseDirection direction;

  /// Whether tapping the collapsed bar expands it.
  ///
  /// Defaults to `true`.
  final bool expandOnTap;

  /// Duration of the collapse/expand animation.
  ///
  /// Defaults to 280 milliseconds — long enough for the collapse trajectory
  /// to read clearly while still feeling responsive. Apple's equivalent
  /// Dynamic Island and Live Activity transitions run at 300–400 ms.
  final Duration animationDuration;

  /// Scale applied to the extra button while collapsed.
  ///
  /// Defaults to `0.9`.
  final double collapsedExtraButtonScale;
}

// =============================================================================
// Search Morph Alignment
// =============================================================================

/// Controls how the tab pill is anchored **horizontally** during the morph
/// animation in a searchable tab bar.
///
/// This only affects the tab pill's position. The search pill position is
/// always computed from the trailing edge.
enum GlassTabPillAnchor {
  /// The tab pill is pinned to the **leading (left) edge** — the right edge
  /// retracts as the pill collapses. This is the default and matches the
  /// classic iOS News / Safari behaviour.
  start,

  /// The tab pill scales **from its centre** — both edges collapse inward
  /// symmetrically as the pill morphs into the collapsed search state, and
  /// expand outward symmetrically when search closes.
  ///
  /// Use this when you want a more balanced, symmetrical animation. Note that
  /// while searching, the search pill will be slightly narrower than in
  /// [start] mode because it starts after the centred collapsed tab pill.
  center,
}

// =============================================================================
// Jelly Clipper
// =============================================================================

/// Clipper that matches the shape and physics of the jelly indicator.
class JellyClipper extends CustomClipper<Path> {
  /// Creates a new [JellyClipper].
  JellyClipper({
    required this.itemCount,
    required this.alignment,
    required this.thickness,
    required this.expansion,
    required this.transform,
    required this.borderRadius,
    this.inverse = false,
  });

  /// The number of items.
  final int itemCount;

  /// The alignment of the clipper.
  final Alignment alignment;

  /// The thickness of the jelly effect.
  final double thickness;

  /// The expansion insets.
  final EdgeInsets expansion;

  /// The transform matrix.
  final Matrix4 transform;

  /// The border radius.
  final double borderRadius;

  /// Whether the clipper is inverted.
  final bool inverse;

  /// Threshold for clip recalculation optimization.
  ///
  /// When changes in alignment or thickness are below this threshold,
  /// the cached clip path is reused instead of recalculating.
  /// This is below human perception threshold (sub-pixel).
  static const double _recalcThreshold = 0.001;

  @override
  Path getClip(Size size) {
    final tabWidth = size.width / itemCount;
    final availableWidth = size.width - tabWidth;

    // Map alignment (-1 to 1) to horizontal offset
    final left = (alignment.x + 1) / 2 * availableWidth;

    final baseRect = Rect.fromLTWH(left, 0, tabWidth, size.height);
    final paddedRect = Rect.fromLTRB(
      baseRect.left + 4.0,
      baseRect.top + 4.0,
      baseRect.right - 4.0,
      baseRect.bottom - 4.0,
    );

    // Apply expansion based on thickness (drag state)
    final inflatedRect = Rect.fromLTRB(
      paddedRect.left - (expansion.left * thickness),
      paddedRect.top - (expansion.top * thickness),
      paddedRect.right + (expansion.right * thickness),
      paddedRect.bottom + (expansion.bottom * thickness),
    );

    // Clamp radius to avoid invalid RRect paths on Impeller.
    final maxRadius = (inflatedRect.shortestSide / 2) - 0.1;
    final safeRadius = borderRadius > maxRadius ? maxRadius : borderRadius;

    // Create rounded rect path
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        inflatedRect,
        Radius.circular(safeRadius > 0 ? safeRadius : 0),
      ));

    // Apply jelly physics transform around the center
    final center = inflatedRect.center;
    final centeredTransform = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0.0, 1.0)
      ..multiply(transform)
      ..translateByDouble(-center.dx, -center.dy, 0.0, 1.0);

    final indicatorPath = path.transform(centeredTransform.storage);

    if (inverse) {
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addPath(indicatorPath, Offset.zero);
    }

    return indicatorPath;
  }

  @override
  bool shouldReclip(JellyClipper oldClipper) {
    if (itemCount == oldClipper.itemCount &&
        inverse == oldClipper.inverse &&
        borderRadius == oldClipper.borderRadius &&
        expansion == oldClipper.expansion &&
        transform == oldClipper.transform &&
        (alignment.x - oldClipper.alignment.x).abs() < _recalcThreshold &&
        (thickness - oldClipper.thickness).abs() < _recalcThreshold) {
      return false;
    }

    return itemCount != oldClipper.itemCount ||
        alignment != oldClipper.alignment ||
        thickness != oldClipper.thickness ||
        expansion != oldClipper.expansion ||
        transform != oldClipper.transform ||
        borderRadius != oldClipper.borderRadius ||
        inverse != oldClipper.inverse;
  }
}

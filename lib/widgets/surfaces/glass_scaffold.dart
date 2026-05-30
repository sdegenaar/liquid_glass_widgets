import 'package:flutter/material.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../theme/glass_theme_data.dart';
import '../shared/glass_isolation_scope.dart';
import '../shared/glass_page.dart';
import '../shared/glass_scroll_edge_effect.dart';

/// A one-stop-shop scaffold that replaces the manual assembly of [GlassPage],
/// [Scaffold], [GlassScrollEdgeEffect], and a [Stack] for proper z-ordering.
///
/// ## Why GlassScaffold?
///
/// When using glass surfaces (navigation bars, bottom bars, cards), the correct
/// layout requires 4-5 nested widgets with manual padding calculations and
/// scroll controller wiring. `GlassScaffold` handles all of this internally:
///
/// - **Z-ordering**: App bar and bottom bar always render above body content,
///   preventing glass cards in the body from overlapping navigation buttons.
/// - **Edge fading**: Content fades smoothly as it approaches the bar areas,
///   matching iOS 26's `.scrollEdgeEffectStyle(.soft)`.
/// - **Auto padding**: Calculates safe-area-aware top/bottom padding so content
///   starts below the app bar and above the bottom bar automatically.
/// - **Background & glass layer**: Wraps everything in [GlassPage] for the
///   glass rendering context, background, and status bar styling.
///
/// ## Before (manual assembly)
///
/// ```dart
/// GlassPage(
///   background: Image.asset('assets/bg.jpg', fit: BoxFit.cover),
///   settings: RecommendedGlassSettings.standard,
///   statusBarStyle: GlassStatusBarStyle.light,
///   child: Scaffold(
///     extendBodyBehindAppBar: true,
///     extendBody: true,
///     appBar: GlassAppBar(
///       title: Text('Messages'),
///       scrollController: _ctrl,
///       settings: RecommendedGlassSettings.surface,
///     ),
///     body: GlassScrollEdgeEffect(
///       topFadeHeight: MediaQuery.paddingOf(context).top + 44 + 40,
///       bottomFadeHeight: 60 + MediaQuery.paddingOf(context).bottom,
///       child: CustomScrollView(
///         controller: _ctrl,
///         slivers: [
///           SliverToBoxAdapter(
///             child: SizedBox(
///               height: MediaQuery.paddingOf(context).top + 44 + 16,
///             ),
///           ),
///           // ... content
///         ],
///       ),
///     ),
///   ),
/// )
/// ```
///
/// ## After (one widget)
///
/// ```dart
/// GlassScaffold(
///   background: Image.asset('assets/bg.jpg', fit: BoxFit.cover),
///   settings: RecommendedGlassSettings.standard,
///   statusBarStyle: GlassStatusBarStyle.light,
///   appBar: GlassAppBar(
///     title: Text('Messages'),
///     scrollController: _ctrl,
///     settings: RecommendedGlassSettings.surface,
///   ),
///   body: CustomScrollView(
///     controller: _ctrl,
///     slivers: [
///       // No manual spacer needed — GlassScaffold handles it
///       // ... content
///     ],
///   ),
/// )
/// ```
///
/// ## How it works internally
///
/// `GlassScaffold` builds:
///
/// ```
/// GlassPage(
///   background: ...,
///   child: Scaffold(
///     body: Stack(
///       children: [
///         // 1. Body with edge fading (bottom of stack)
///         // 2. App bar (top of stack — always above body)
///         // 3. Bottom bar (top of stack — always above body)
///       ],
///     ),
///   ),
/// )
/// ```
///
/// The app bar and bottom bar are placed AFTER the body in the [Stack]'s
/// children list, guaranteeing they always paint on top regardless of
/// `BackdropFilter` compositing from glass widgets in the body.
class GlassScaffold extends StatelessWidget {
  /// Creates a glass scaffold with automatic z-ordering, edge fading,
  /// and glass layer setup.
  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomBar,
    this.background,
    this.settings,
    this.statusBarStyle = GlassStatusBarStyle.none,
    this.edgeToEdge = false,
    this.themeOverride,
    this.enableBackgroundSampling,
    this.edgeFade = true,
    this.topEdgeFade,
    this.bottomEdgeFade,
    this.topEdgeFadeExtent = 40.0,
    this.bottomEdgeFadeExtent = 40.0,
    this.edgeStyle = GlassScrollEdgeStyle.soft,
    this.extendBody = true,
    this.appBarHeight = 44.0,
    this.bottomBarHeight,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
  });

  // ===========================================================================
  // Body
  // ===========================================================================

  /// The main content of the scaffold.
  ///
  /// When [extendBody] is `true` (the default), the body extends behind the
  /// app bar and bottom bar. A top spacer is automatically added to push
  /// initial content below the app bar. When `false`, the body occupies only
  /// the area between the app bar and bottom bar.
  final Widget body;

  // ===========================================================================
  // Bars
  // ===========================================================================

  /// An optional app bar placed at the top, always above the body.
  ///
  /// Typically a [GlassAppBar], but any widget works. Z-ordering is
  /// guaranteed — glass cards in the body will never overlap the app bar.
  ///
  /// If the widget implements [PreferredSizeWidget], its preferred height
  /// is used for edge fade calculations. Otherwise, [appBarHeight] is used.
  final Widget? appBar;

  /// An optional bottom bar placed at the bottom, always above the body.
  ///
  /// Typically a [GlassBottomBar], [GlassSearchableBottomBar], or any widget.
  /// When provided, bottom edge fading is auto-calculated to cover the bar
  /// area plus safe zone.
  final Widget? bottomBar;

  // ===========================================================================
  // GlassPage passthrough
  // ===========================================================================

  /// Background widget rendered behind everything. See [GlassPage.background].
  final Widget? background;

  /// Glass settings for the page's rendering layer. See [GlassPage.settings].
  final LiquidGlassSettings? settings;

  /// Status bar icon style. See [GlassPage.statusBarStyle].
  final GlassStatusBarStyle statusBarStyle;

  /// Whether to enable edge-to-edge rendering. See [GlassPage.edgeToEdge].
  final bool edgeToEdge;

  /// Optional per-page glass theme override. See [GlassPage.themeOverride].
  final GlassThemeData? themeOverride;

  /// Whether to capture the background as a GPU texture for glass colour
  /// absorption. See [GlassPage.enableBackgroundSampling].
  final bool? enableBackgroundSampling;

  // ===========================================================================
  // Edge fading
  // ===========================================================================

  /// Master toggle for edge fading. Defaults to `true`.
  ///
  /// When `true`, content fades at the top (below app bar) and bottom
  /// (above bottom bar) edges. Override individual edges with [topEdgeFade]
  /// and [bottomEdgeFade].
  final bool edgeFade;

  /// Whether to fade content at the top edge. When `null`, follows [edgeFade].
  final bool? topEdgeFade;

  /// Whether to fade content at the bottom edge. When `null`, follows
  /// [edgeFade]. Automatically set to `true` when [bottomBar] is provided.
  final bool? bottomEdgeFade;

  /// Extra fade height beyond the auto-calculated app bar area.
  ///
  /// The total top fade height = safe area top + [appBarHeight] +
  /// [topEdgeFadeExtent]. Defaults to 40.0.
  final double topEdgeFadeExtent;

  /// Extra fade height beyond the auto-calculated bottom bar area.
  ///
  /// The total bottom fade height = [bottomBarHeight] + safe area bottom +
  /// [bottomEdgeFadeExtent]. Defaults to 40.0.
  final double bottomEdgeFadeExtent;

  /// The edge fade style. See [GlassScrollEdgeStyle].
  final GlassScrollEdgeStyle edgeStyle;

  // ===========================================================================
  // Layout
  // ===========================================================================

  /// Whether the body extends behind the app bar and bottom bar.
  ///
  /// Defaults to `true`, matching iOS 26's design where content scrolls
  /// behind the transparent navigation bar. When `false`, the body occupies
  /// only the area between the bars (no overlap, no edge fading).
  final bool extendBody;

  /// The preferred height of the app bar, used for padding calculations.
  ///
  /// When [appBar] is a [PreferredSizeWidget], this value is overridden by
  /// [PreferredSizeWidget.preferredSize.height]. Defaults to 44.0.
  final double appBarHeight;

  /// The height of the bottom bar, used for padding calculations.
  ///
  /// When null, defaults to 60.0 if [bottomBar] is provided. Set this
  /// explicitly for custom-height bottom bars.
  final double? bottomBarHeight;

  /// An optional floating action button.
  final Widget? floatingActionButton;

  /// Whether the body should resize when the keyboard appears.
  ///
  /// When null, uses Scaffold's default (true).
  final bool? resizeToAvoidBottomInset;

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPad = mediaQuery.padding.top;
    final botPad = mediaQuery.padding.bottom;

    // Resolve effective bar heights.
    // If appBar implements PreferredSizeWidget, use its preferred height;
    // otherwise fall back to the explicit appBarHeight parameter.
    final effectiveAppBarHeight = appBar is PreferredSizeWidget
        ? (appBar! as PreferredSizeWidget).preferredSize.height
        : appBarHeight;
    final effectiveBottomBarHeight =
        bottomBar != null ? (bottomBarHeight ?? 60.0) : 0.0;

    // Resolve edge fade toggles.
    final doFadeTop = topEdgeFade ?? (edgeFade && appBar != null);
    final doFadeBottom = bottomEdgeFade ?? (edgeFade && bottomBar != null);

    // Calculate fade heights.
    final topFadeHeight = topPad + effectiveAppBarHeight + topEdgeFadeExtent;
    final bottomFadeHeight =
        effectiveBottomBarHeight + botPad + bottomEdgeFadeExtent;

    // Build the body content.
    Widget bodyContent = body;

    // Wrap with edge fading if enabled.
    if (extendBody && (doFadeTop || doFadeBottom)) {
      bodyContent = GlassScrollEdgeEffect(
        topFadeHeight: topFadeHeight,
        bottomFadeHeight: bottomFadeHeight,
        fadeTop: doFadeTop,
        fadeBottom: doFadeBottom,
        style: edgeStyle,
        child: bodyContent,
      );
    }

    // Build the Stack with guaranteed z-ordering.
    final stackChildren = <Widget>[
      // 1. Body (bottom of stack — always below bars).
      if (extendBody)
        Positioned.fill(child: bodyContent)
      else
        Positioned(
          top: appBar != null ? topPad + effectiveAppBarHeight : 0,
          left: 0,
          right: 0,
          bottom: bottomBar != null ? effectiveBottomBarHeight + botPad : 0,
          child: bodyContent,
        ),

      // 2. App bar (above body — painted after body in Stack).
      // Uses _GlassIsolationScope to tell descendant glass widgets
      // (GlassButton, AdaptiveGlass) to render with their own independent
      // glass layer instead of sharing the page-level layer. This prevents
      // body glass cards from compositing over the app bar's glass buttons.
      // Zero shader overhead — no extra glass layer is created. Each button
      // simply renders its own small glass surface independently.
      if (appBar != null)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlassIsolationScope(child: appBar!),
        ),

      // 3. Bottom bar (above body — painted after body in Stack).
      if (bottomBar != null)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GlassIsolationScope(child: bottomBar!),
        ),
    ];

    return GlassPage(
      background: background,
      settings: settings,
      statusBarStyle: statusBarStyle,
      edgeToEdge: edgeToEdge,
      themeOverride: themeOverride,
      enableBackgroundSampling: enableBackgroundSampling,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        body: Stack(children: stackChildren),
      ),
    );
  }
}


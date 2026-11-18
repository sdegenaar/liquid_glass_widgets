import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';

import '../../theme/glass_theme.dart';

import '../../src/renderer/liquid_glass_renderer.dart';
import '../../src/widgets/surfaces/dynamic_preferred_size.dart';
import '../../src/widgets/surfaces/status_bar_row.dart';
import '../../src/widgets/surfaces/vertical_bar_background.dart';
import '../../src/widgets/surfaces/vertical_bar_title_row.dart';
import '../../types/glass_quality.dart';
import '../../theme/glass_theme_data.dart';
import '../shared/glass_accessibility_scope.dart';
import '../shared/glass_content_aware_scope.dart';
import '../shared/glass_isolation_scope.dart';
import '../shared/glass_page.dart';
import '../shared/glass_scroll_edge_effect.dart';
import 'glass_app_bar.dart';
import 'glass_navigation_stack.dart' show GlassNavigationTitleScope;
import 'glass_tab_bar.dart';
import 'glass_toolbar.dart';
import 'glass_vertical_bar.dart';

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
/// );
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
///       SliverSafeArea(
///         sliver: SliverMainAxisGroup(
///           slivers: [
///             // ... content
///           ],
///         ),
///       ),
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
///   child: CupertinoPageScaffold(
///     child: Stack(
///       children: [
///         // 1. Body with edge fading (bottom of stack)
///         // 2. Body overlays (between body and bars)
///         // 3. App bar (top of stack — always above body)
///         // 4. Bottom bar (top of stack — always above body)
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
    this.backgroundColor,
    this.settings,
    this.statusBarStyle = GlassStatusBarStyle.none,
    this.edgeToEdge = false,
    this.themeOverride,
    this.enableBackgroundSampling,
    this.transitionCornerRadius,
    this.edgeFade = true,
    this.topEdgeFade,
    this.bottomEdgeFade,
    this.edgeFadeAbsorbsPointers = false,
    this.topEdgeFadeExtent = 20.0,
    this.bottomEdgeFadeExtent = 20.0,
    this.edgeStyle = GlassScrollEdgeStyle.soft,
    this.maxSigma = 18.0,
    this.extendBody = true,
    this.appBarHeight = 44.0,
    this.bottomBarHeight,
    this.resizeToAvoidBottomInset,
    this.bodyOverlays,
    this.header,
    this.headerScrollController,
    this.headerFadeDistance = 60.0,
    this.contentAwareBrightness = false,
  });

  // ===========================================================================
  // Body
  // ===========================================================================

  /// The main content of the scaffold.
  ///
  /// When [extendBody] is `true` (the default), the body extends behind the
  /// app bar and bottom bar. The scaffold publishes the combined system and
  /// bar safe-area insets through the body's [MediaQueryData.padding].
  /// That override applies only inside the [body] subtree; reading
  /// [MediaQueryData.padding] in the caller's outer `build` context still sees
  /// the platform insets alone.
  /// A [GlassAppBar] includes its default vertical padding in `preferredSize`;
  /// the platform top safe inset is added once by the scaffold.
  /// [ListView] consumes those vertical insets automatically. A
  /// [CustomScrollView] does not, so wrap its content in [SliverSafeArea] (or
  /// another sliver that consumes [MediaQueryData.padding]). If the first
  /// sliver is [GlassLargeTitle], that widget owns the top inset internally;
  /// leave it outside the wrapper and use `SliverSafeArea(top: false, ...)` for
  /// the remaining slivers. [SafeArea] can likewise handle non-scrollable
  /// content.
  /// The viewport itself still starts at the screen edge, allowing content to
  /// scroll behind the glass chrome.
  ///
  /// When `false`, the body is laid out between the app bar and bottom bar, so
  /// those bars are removed from the body's [MediaQueryData.padding] to avoid
  /// applying the same inset twice. A body that opts out of safe-area handling
  /// (for example a full-screen canvas) still receives the complete scaffold
  /// bounds.
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
  /// Typically a [GlassTabBar.bottom], [GlassTabBar.searchable], or any widget.
  /// When provided, bottom edge fading is auto-calculated to cover the bar
  /// area plus safe zone.
  final Widget? bottomBar;

  // ===========================================================================
  // GlassPage passthrough
  // ===========================================================================

  /// Background widget rendered behind everything. See [GlassPage.background].
  final Widget? background;

  /// A solid background colour rendered behind everything when no [background]
  /// widget is provided.
  ///
  /// This is a convenience shorthand for:
  /// ```dart
  /// background: Container(color: myColor)
  /// ```
  /// When both [background] and [backgroundColor] are provided, [background]
  /// takes precedence and [backgroundColor] has no effect as a solid fill.
  ///
  /// **Scroll edge fade colour:** [backgroundColor] is also used as the target
  /// colour for the `GlassScrollEdgeEffect` overlay (the fade at the top/bottom
  /// of the body). When `background` is set, this is its *only* visible role.
  /// If left null the fade defaults to `CupertinoTheme.scaffoldBackgroundColor`
  /// (near-black in dark mode), which can produce an unexpected dark wash.
  /// Set this explicitly whenever you use a `background` widget and the edge
  /// fade colour matters.
  ///
  /// When neither [background] nor [backgroundColor] is set, the scaffold
  /// background colour is resolved from the glass brightness cascade (see
  /// [GlassTheme.brightnessOf]) so that it correctly follows Material
  /// [ThemeMode] — including [ThemeMode.dark] — rather than relying on
  /// [CupertinoTheme], which does not read Material's [Theme] in a
  /// [MaterialApp] (issue #289).
  final Color? backgroundColor;

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

  /// Continuous superellipse corner radius applied to clip the page surface
  /// during route push/pop transitions and interactive swipe-back gestures.
  /// See [GlassPage.transitionCornerRadius].
  final double? transitionCornerRadius;

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

  /// Whether the edge fades absorb pointer events. Defaults to `false`.
  ///
  /// When enabled, taps and gestures are blocked across each visible fade
  /// zone, including content that is still visible beneath the fade.
  final bool edgeFadeAbsorbsPointers;

  /// Extra fade height beyond the auto-calculated app bar area.
  ///
  /// The total top fade height = safe area top + [appBarHeight] +
  /// [topEdgeFadeExtent]. Defaults to 20.0.
  ///
  /// Negative values (e.g. `-20.0`) are valid and retract the fade boundary
  /// inside the app bar area — especially useful with [GlassScrollEdgeStyle.blur]
  /// to keep content sharp until it passes directly beneath the bar.
  final double topEdgeFadeExtent;

  /// Extra fade height beyond the auto-calculated bottom bar area.
  ///
  /// The total bottom fade height = [bottomBarHeight] + safe area bottom +
  /// [bottomEdgeFadeExtent]. Defaults to 20.0.
  ///
  /// Negative values (e.g. `-20.0` or `-30.0`) are valid and retract the fade
  /// boundary inside the bottom bar area — ideal for floating tab bars and
  /// [GlassScrollEdgeStyle.blur] so content stays 100% sharp until it is
  /// physically beneath the glass capsule.
  final double bottomEdgeFadeExtent;

  /// The edge fade style applied at the top and bottom of the scroll body.
  /// See [GlassScrollEdgeStyle].
  ///
  /// Defaults to [GlassScrollEdgeStyle.soft], which matches iOS 26's
  /// `.scrollEdgeEffectStyle(.soft)` — a diffused gradient fade.
  ///
  /// Set to [GlassScrollEdgeStyle.blur] for a stronger hardware-accelerated
  /// progressive Gaussian frost. This is a design enhancement beyond the
  /// iOS 26 system default — opt in explicitly when you want a more aggressive
  /// frosted-glass edge look. Note it adds a [BackdropFilterLayer] per edge.
  ///
  /// Set to [GlassScrollEdgeStyle.hard] for a crisp cutoff, matching iOS 26's
  /// `.scrollEdgeEffectStyle(.hard)`.
  final GlassScrollEdgeStyle edgeStyle;

  /// Maximum blur sigma for [GlassScrollEdgeStyle.blur].
  ///
  /// Defaults to 18.0.
  final double maxSigma;

  // ===========================================================================
  // Layout
  // ===========================================================================

  /// Whether the body extends behind the app bar and bottom bar.
  ///
  /// Defaults to `true`, matching iOS 26's design where content scrolls
  /// behind the transparent navigation bar. When `false`, the body occupies
  /// only the area between the bars (no overlap, no edge fading).
  ///
  /// Set to `false` when the body widget manages its own internal layout
  /// and does not know to add a manual top spacer for the app bar — for
  /// example, a third-party chat widget, a full-screen form, or any widget
  /// that renders to the full height of the space it is given. With
  /// `extendBody: false` the scaffold positions the body precisely between
  /// the bottom of the app bar and the top of the bottom bar, so the widget
  /// fills exactly the visible content area without being obscured.
  final bool extendBody;

  /// Fallback height of the app bar used for body and edge-fade inset
  /// calculations before layout measurement.
  ///
  /// When [appBar] is a [PreferredSizeWidget], this value is overridden by
  /// its `preferredSize.height`. Defaults to 44.0.
  final double appBarHeight;

  /// Fallback height of a non-[PreferredSizeWidget] bottom bar.
  ///
  /// When null, defaults to 60.0 if [bottomBar] is provided. The scaffold
  /// measures the rendered bar after layout and keeps updating the body inset
  /// as its height changes, so this value is only needed for the first frame.
  final double? bottomBarHeight;

  /// Whether the body should resize when the keyboard appears.
  ///
  /// When null, defaults to `true` (the CupertinoPageScaffold default).
  final bool? resizeToAvoidBottomInset;

  /// Optional overlay widgets placed between the body and the bars in the
  /// z-order Stack.
  ///
  /// Use this for floating elements that should render above the body content
  /// but below the app bar and bottom bar. Each widget is typically wrapped
  /// in an [AnimatedPositioned] or [Positioned]. Like [appBar] and [bottomBar],
  /// each overlay is wrapped in a [GlassIsolationScope] with
  /// `defaultQuality: GlassQuality.premium` so floating pills and action
  /// buttons render with their own premium glass layer out of the box.
  ///
  /// Example: Apple Music's floating play bar pill:
  /// ```dart
  /// GlassScaffold(
  ///   bodyOverlays: [
  ///     AnimatedPositioned(
  ///       bottom: isMiniMode ? miniBottom : aboveBarBottom,
  ///       left: 20, right: 20,
  ///       child: PlayBarPill(),
  ///     ),
  ///   ],
  ///   bottomBar: GlassTabBar.searchable(...),
  ///   body: scrollContent,
  /// )
  /// ```
  final List<Widget>? bodyOverlays;

  /// A fixed header widget positioned below the status bar that fades out
  /// as the user scrolls.
  ///
  /// Use this for iOS-style large title headers (e.g. Apple Music's
  /// "Listen Now") that are not part of the scroll view but fade to
  /// transparent as content scrolls up.
  ///
  /// Requires [headerScrollController] to drive the fade animation.
  /// The fade is computed as `1.0 - (scrollOffset / headerFadeDistance)`.
  ///
  /// ```dart
  /// GlassScaffold(
  ///   header: Text('Listen Now', style: largeTitle),
  ///   headerScrollController: _scrollController,
  ///   headerFadeDistance: 60.0,
  ///   body: CustomScrollView(
  ///     controller: _scrollController,
  ///     slivers: [...],
  ///   ),
  /// )
  /// ```
  final Widget? header;

  /// The scroll controller that drives the [header] fade animation.
  ///
  /// Required when [header] is provided.
  final ScrollController? headerScrollController;

  /// The scroll distance (in pixels) over which the [header] fades from
  /// fully opaque to fully transparent. Defaults to 60.0.
  final double headerFadeDistance;

  /// Whether to install a [GlassContentAwareScope] around the scaffold's
  /// body and bars.
  ///
  /// When `true`, the scaffold wraps the body in [GlassContentAwareContent]
  /// and the entire Stack in [GlassContentAwareScope]. This enables bars
  /// with `adaptiveBrightness: true` to sample the body content and
  /// automatically flip between light and dark appearance.
  ///
  /// The standalone [GlassContentAwareScope] and [GlassContentAwareContent]
  /// widgets remain available for custom layouts that don't use
  /// `GlassScaffold`.
  ///
  /// ```dart
  /// GlassScaffold(
  ///   contentAwareBrightness: true,
  ///   bottomBar: GlassTabBar.bottom(
  ///     adaptiveBrightness: true,
  ///     ...
  ///   ),
  ///   body: CustomScrollView(...),
  /// )
  /// ```
  final bool contentAwareBrightness;

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return _GlassScaffoldMeasurementHost(scaffold: this);
  }

  Widget _buildContent(
    BuildContext context, {
    required GlobalKey appBarMeasureKey,
    required GlobalKey bottomBarMeasureKey,
    required double? measuredAppBarHeight,
    required double? measuredBottomBarHeight,
    required VoidCallback onChromeLayoutChanged,
  }) {
    // Some bars change height from their own internal state — a tab bar
    // minimizing on scroll — without the widget instance being replaced.
    // Their preferredSize is read below, so the scaffold has to know when it
    // has changed; nothing else would mark this build dirty.
    //
    // Only build() re-runs. `body` is the same Widget instance every time, so
    // the element for the app's content is re-parented rather than rebuilt.
    final resizeListenables = <Listenable>[
      if (appBar case final GlassDynamicPreferredSize bar)
        if (bar.preferredSizeListenable case final Listenable listenable)
          listenable,
      if (bottomBar case final GlassDynamicPreferredSize bar)
        if (bar.preferredSizeListenable case final Listenable listenable)
          listenable,
    ];
    if (resizeListenables.isNotEmpty) {
      return ListenableBuilder(
        listenable: Listenable.merge(resizeListenables),
        builder: (context, child) => _buildScaffoldContent(
          context,
          appBarMeasureKey: appBarMeasureKey,
          bottomBarMeasureKey: bottomBarMeasureKey,
          measuredAppBarHeight: measuredAppBarHeight,
          measuredBottomBarHeight: measuredBottomBarHeight,
          onChromeLayoutChanged: onChromeLayoutChanged,
        ),
      );
    }
    return _buildScaffoldContent(
      context,
      measuredAppBarHeight: measuredAppBarHeight,
      measuredBottomBarHeight: measuredBottomBarHeight,
      appBarMeasureKey: appBarMeasureKey,
      bottomBarMeasureKey: bottomBarMeasureKey,
      onChromeLayoutChanged: onChromeLayoutChanged,
    );
  }

  Widget _buildScaffoldContent(
    BuildContext context, {
    required GlobalKey appBarMeasureKey,
    required GlobalKey bottomBarMeasureKey,
    required double? measuredAppBarHeight,
    required double? measuredBottomBarHeight,
    required VoidCallback onChromeLayoutChanged,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final verticalBar = GlassVerticalBar.maybeOf(context);
    final topPad = mediaQuery.padding.top;
    final botPad = mediaQuery.padding.bottom;

    // In iPhone Duo's vertical bar strip a pinned app bar keeps only its
    // title row, and the package's bottom bars leave the bottom edge for the
    // strip — so neither covers what its preferred size says it does.
    final bar = appBar;
    final appBarInStrip =
        verticalBar != null && bar is GlassAppBar && bar.pinnedActions != null;
    // On iPhone Duo's inner display held upright it shares the status bar's
    // row, and the content starts under the status bar, as natively.
    final statusRow = bar is GlassAppBar && bar.pinnedActions != null
        ? StatusBarRow.of(context)
        : null;
    final bottom = bottomBar;
    final bottomBarInStrip = verticalBar != null &&
        (bottom is GlassToolbar ||
            (bottom is GlassTabBar && bottom.followsVerticalBar));

    // Resolve effective bar heights.
    // If appBar implements PreferredSizeWidget, use its preferred height;
    // otherwise fall back to the explicit appBarHeight parameter.
    final preferredAppBarHeight = appBarInStrip
        ? verticalBar.rowTop + GlassVerticalBarMetrics.rowHeight
        : statusRow != null
            ? math.max(0.0, statusRow.bottom - topPad)
            : appBar is PreferredSizeWidget
                ? (appBar! as PreferredSizeWidget).preferredSize.height
                : appBarHeight;
    final preferredBottomBarHeight = bottomBarInStrip
        ? 0.0
        : bottomBar is PreferredSizeWidget
            ? (bottomBar as PreferredSizeWidget).preferredSize.height
            : (bottomBar != null ? (bottomBarHeight ?? 60.0) : 0.0);
    // A PreferredSizeWidget declares chrome height synchronously and excludes
    // the system top inset, so the scaffold adds topPad once. GlassAppBar uses
    // this path: its preferred height contains its own vertical content
    // padding, and adding topPad publishes the complete app-bar safe area in
    // the same rebuild. Arbitrary app bars only reveal their complete extent
    // after measurement.
    final topOcclusion = appBar == null
        ? topPad
        : appBar is PreferredSizeWidget || appBarInStrip || statusRow != null
            ? topPad + preferredAppBarHeight
            : measuredAppBarHeight ?? topPad + appBarHeight;
    final bottomOcclusion = bottomBar == null || bottomBarInStrip
        ? botPad
        : bottomBar is PreferredSizeWidget
            ? preferredBottomBarHeight +
                (defaultTargetPlatform == TargetPlatform.android ? botPad : 0.0)
            : measuredBottomBarHeight ??
                (bottomBarHeight ?? preferredBottomBarHeight) +
                    (defaultTargetPlatform == TargetPlatform.android
                        ? botPad
                        : 0.0);

    // Resolve edge fade toggles.
    final doFadeTop = topEdgeFade ?? (edgeFade && appBar != null);
    final doFadeBottom =
        bottomEdgeFade ?? (edgeFade && bottomBar != null && !bottomBarInStrip);

    // Calculate fade heights.
    // Only include appBarHeight when an appBar is present — without one, the
    // fade covers just the status bar area + extent.
    final topFadeHeight = topOcclusion + topEdgeFadeExtent;
    final bottomFadeHeight = bottomOcclusion + bottomEdgeFadeExtent;

    // Cupertino lays navigation bars out edge to edge and publishes the space
    // they occupy through MediaQuery. Scrollables consume that padding at
    // their extremities (and SafeArea consumes it for arbitrary content),
    // while the viewport can still scroll behind the glass chrome. This is the
    // single source of truth for body insets, so a bar that resizes only needs
    // to rebuild this scope rather than callers recalculating padding.
    final bodyPadding = mediaQuery.padding.copyWith(
      top: extendBody ? topOcclusion : (appBar == null ? topPad : 0.0),
      bottom: extendBody ? bottomOcclusion : (bottomBar == null ? botPad : 0.0),
    );

    // Build the body content.
    Widget bodyContent = MediaQuery(
      data: mediaQuery.copyWith(padding: bodyPadding),
      child: body,
    );

    // Wrap with edge fading if enabled.
    if (extendBody && (doFadeTop || doFadeBottom)) {
      Widget edgeEffect(double topFadeHeight, Widget child) =>
          GlassScrollEdgeEffect(
            topFadeHeight: topFadeHeight,
            bottomFadeHeight: bottomFadeHeight,
            fadeTop: doFadeTop,
            fadeBottom: doFadeBottom,
            absorbPointer: edgeFadeAbsorbsPointers,
            style: edgeStyle,
            maxSigma: maxSigma,
            // Pass the explicit background colour so the async-capture
            // fallback gradient uses the correct colour in dark mode instead
            // of defaulting to CupertinoTheme.scaffoldBackgroundColor (which
            // is near-black).
            fadeColor: backgroundColor,
            child: child,
          );

      // In the strip a large title's row scrolls away, and hides while its
      // search is open, so the fade under it goes with it. Built the same way
      // either side of a posture change, so the body is never remounted.
      final largeTitle = appBarInStrip ? bar.largeTitleController : null;
      bodyContent = ListenableBuilder(
        listenable: Listenable.merge([largeTitle]),
        builder: (context, child) => edgeEffect(
          largeTitle == null
              ? topFadeHeight
              : topFadeHeight -
                  VerticalBarTitleRow.collapseExtent *
                      (largeTitle.isSearchPresented
                          ? 1.0
                          : largeTitle.collapseProgress),
          child!,
        ),
        child: bodyContent,
      );
    }

    // Wrap in GlassContentAwareContent when content-aware brightness is on.
    // This installs the RepaintBoundary that the scope captures.
    if (contentAwareBrightness) {
      bodyContent = GlassContentAwareContent(child: bodyContent);
    }

    // Build the Stack with guaranteed z-ordering.
    // All conditional children have explicit Keys so that Flutter can track
    // them by identity rather than position. Without keys, toggling header
    // (null → widget → null) shifts the index of appBar and bottomBar,
    // causing Flutter to unmount/remount them — losing animation state.
    final stackChildren = <Widget>[
      // 1. Body (bottom of stack — always below bars).
      if (extendBody)
        Positioned.fill(child: bodyContent)
      else
        Positioned(
          top: appBar != null ? topOcclusion : 0,
          left: 0,
          right: 0,
          bottom: bottomBar != null ? bottomOcclusion : 0,
          child: bodyContent,
        ),

      // 2. Body overlays (between body and bars — e.g. floating play pill).
      if (bodyOverlays != null)
        for (final overlay in bodyOverlays!)
          GlassIsolationScope(
            // Carry the overlay's key onto the wrapper so the Stack still
            // matches an overlay by key when the list reorders or changes.
            key: overlay.key == null ? null : ValueKey<Key>(overlay.key!),
            isolated: true,
            defaultQuality: GlassQuality.premium,
            child: overlay,
          ),

      // 2a. Under Reduce Transparency, the strip and the title row turn
      // opaque behind the bars in iPhone Duo's vertical bar strip.
      if ((appBarInStrip || bottomBarInStrip) &&
          GlassAccessibilityData.of(context).reduceTransparency)
        Positioned.fill(
          key: const ValueKey('glass_scaffold_vertical_bar_background'),
          child: VerticalBarBackground(
            bar: verticalBar,
            titleRow: appBarInStrip,
            controller: appBarInStrip ? bar.largeTitleController : null,
          ),
        ),

      // 2b. Fixed header — fades on scroll (e.g. "Listen Now" in Apple Music).
      // IgnorePointer is only active when opacity == 0 (fully faded) so that
      // tappable elements inside the header work at full visibility.
      if (header != null)
        Positioned(
          key: const ValueKey('glass_scaffold_header'),
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: headerScrollController != null
                ? AnimatedBuilder(
                    animation: headerScrollController!,
                    builder: (context, child) {
                      // Guard: during AnimatedSwitcher cross-fades, both old
                      // and new scroll views briefly share the same controller.
                      // Reading .offset (or .positions.last) throws if there
                      // are multiple positions. Falling back to 0.0 for that
                      // brief ~300 ms window is correct UX — the header just
                      // stays fully visible during the transition.
                      final offset = headerScrollController!.hasClients &&
                              headerScrollController!.positions.length == 1
                          ? headerScrollController!.offset
                          : 0.0;
                      // Guard against divide-by-zero if headerFadeDistance == 0.
                      final opacity = headerFadeDistance > 0
                          ? (1.0 - offset / headerFadeDistance).clamp(0.0, 1.0)
                          : (offset > 0 ? 0.0 : 1.0);
                      return IgnorePointer(
                        // Disable hit-testing only when fully invisible.
                        ignoring: opacity == 0.0,
                        child: Opacity(opacity: opacity, child: child),
                      );
                    },
                    child: header!,
                  )
                : header!,
          ),
        ),

      // 2. App bar (above body — painted after body in Stack).
      // Uses _GlassIsolationScope to tell descendant glass widgets
      // (GlassButton, AdaptiveGlass) to render with their own independent
      // glass layer instead of sharing the page-level layer. This prevents
      // body glass cards from compositing over the app bar's glass buttons,
      // and ensures the glass background paints in the correct Z-order.
      // If isolated were false, the button's background would paint in the
      // page's blend group (which is behind the body text), while the button's
      // foreground would paint here, causing visual tearing.
      if (appBar != null)
        Positioned(
          key: const ValueKey('glass_scaffold_app_bar'),
          top: 0,
          left: 0,
          right: 0,
          child: GlassIsolationScope(
            isolated: true,
            defaultQuality: GlassQuality.premium,
            child: appBar is PreferredSizeWidget
                ? appBar!
                : _MeasuredChrome(
                    measureKey: appBarMeasureKey,
                    onSizeChanged: onChromeLayoutChanged,
                    child: appBar!,
                  ),
          ),
        ),

      // 3. Bottom bar (above body — painted after body in Stack).
      // SafeArea ensures the bar is never obscured by the Android system
      // navigation bar or the iOS home indicator on any device.
      //
      // A bar in iPhone Duo's vertical bar strip gets the full height: it
      // aligns itself to the bottom of the strip, and a searchable tab bar
      // opens its field at the top of the content.
      if (bottomBar != null)
        Positioned(
          key: const ValueKey('glass_scaffold_bottom_bar'),
          top: bottomBarInStrip ? 0 : null,
          left: 0,
          right: 0,
          bottom: 0,
          child: bottomBar is PreferredSizeWidget
              ? SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  // iOS 26 floats pills natively over the home indicator visually
                  // (the 20px gap straddles the indicator).
                  // Android uses a physical nav bar or gesture bar that requires
                  // being pushed up explicitly.
                  bottom: defaultTargetPlatform == TargetPlatform.android,
                  child: GlassIsolationScope(
                    isolated: true,
                    defaultQuality: GlassQuality.premium,
                    child: bottomBar!,
                  ),
                )
              : _MeasuredChrome(
                  measureKey: bottomBarMeasureKey,
                  onSizeChanged: onChromeLayoutChanged,
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    bottom: defaultTargetPlatform == TargetPlatform.android,
                    child: GlassIsolationScope(
                      isolated: true,
                      defaultQuality: GlassQuality.premium,
                      child: bottomBar!,
                    ),
                  ),
                ),
        ),
    ];

    // Resolve brightness from the glass brightness cascade (issue #289):
    // themeOverride.brightness → GlassThemeData.brightness → Cupertino pin →
    // Material ThemeMode (via glassExternalBrightnessResolver) → system OS.
    final Brightness resolvedBrightness =
        themeOverride?.brightness ?? GlassTheme.brightnessOf(context);

    // Resolve the system UI overlay style for the AnnotatedRegion.
    // This ensures the status bar icons are correctly styled even on routes
    // pushed via CupertinoPageRoute (which manages its own AnnotatedRegion).
    // Without this, pages without a GlassAppBar lose the status bar icons
    // because CupertinoPageRoute's default region overrides the imperative
    // SystemChrome call from GlassPage.
    final bool useLightIcons = switch (statusBarStyle) {
      GlassStatusBarStyle.light => true,
      GlassStatusBarStyle.dark => false,
      // Use the glass brightness cascade (issue #289): honours Material
      // ThemeMode via the external resolver, not just the OS platform setting.
      GlassStatusBarStyle.auto => resolvedBrightness == Brightness.dark,
      GlassStatusBarStyle.none => true, // doesn't matter — no region
    };

    Widget stackWidget = GlassNavigationTitleScope(
      child: Stack(clipBehavior: Clip.none, children: stackChildren),
    );

    // Wrap in GlassContentAwareScope when content-aware brightness is on.
    // The scope must be an ancestor of both the sampled body
    // (GlassContentAwareContent) and the adaptive controls (bars with
    // adaptiveBrightness: true).
    if (contentAwareBrightness) {
      stackWidget = GlassContentAwareScope(child: stackWidget);
    }

    // Resolve effective background: explicit widget > backgroundColor colour >
    // null.
    final Widget? effectiveBackground = background ??
        (backgroundColor != null
            ? SizedBox.expand(
                child: ColoredBox(color: backgroundColor!),
              )
            : null);

    // Wrap in CupertinoTheme with resolved brightness so CupertinoPageScaffold
    // and all child Cupertino widgets (GlassAppBar title, etc.) resolve their
    // dynamic colours (like CupertinoColors.systemBackground) to the correct
    // brightness in MaterialApp (issue #289).
    // When no explicit background is provided, passing null for backgroundColor
    // allows CupertinoPageScaffold to inherit CupertinoTheme.scaffoldBackgroundColor
    // as an opaque background, preserving route transition opacity (issue #177)
    // while adapting correctly to dark/light mode.
    final CupertinoThemeData currentCupertinoTheme = CupertinoTheme.of(context);

    Widget scaffold = CupertinoTheme(
      data: currentCupertinoTheme.copyWith(
        brightness: resolvedBrightness,
      ),
      child: CupertinoPageScaffold(
        backgroundColor:
            effectiveBackground != null ? const Color(0x00000000) : null,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
        child: stackWidget,
      ),
    );

    // Wrap in AnnotatedRegion so the status bar style sticks even on
    // CupertinoPageRoute transitions that manage their own region.
    if (statusBarStyle != GlassStatusBarStyle.none) {
      scaffold = AnnotatedRegion<SystemUiOverlayStyle>(
        value: useLightIcons
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: scaffold,
      );
    }

    return GlassPage(
      background: effectiveBackground,
      settings: settings,
      // GlassScaffold handles AnnotatedRegion itself, so tell GlassPage to
      // skip its own wrap + imperative SystemChrome call.
      statusBarStyle: GlassStatusBarStyle.none,
      edgeToEdge: edgeToEdge,
      themeOverride: themeOverride,
      enableBackgroundSampling: enableBackgroundSampling,
      transitionCornerRadius: transitionCornerRadius,
      child: scaffold,
    );
  }
}

/// Reports a bar's first layout and every later size change.
///
/// The notification is produced by layout, not by a widget rebuild, which is
/// what lets an arbitrary bar animate its own height without the scaffold
/// having to know its implementation.
class _MeasuredChrome extends StatelessWidget {
  const _MeasuredChrome({
    required this.measureKey,
    required this.onSizeChanged,
    required this.child,
  });

  final GlobalKey measureKey;
  final VoidCallback onSizeChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        onSizeChanged();
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: SizedBox(key: measureKey, child: child),
      ),
    );
  }
}

/// Measures the rendered chrome once the first frame is laid out.
///
/// A [PreferredSizeWidget] gives the scaffold a synchronous fallback, but
/// arbitrary bottom bars — including padded or animated wrappers — only expose
/// their real height through layout. Rebuilding only when that height changes
/// keeps the body's [MediaQuery] in sync without a per-frame setState loop.
class _GlassScaffoldMeasurementHost extends StatefulWidget {
  const _GlassScaffoldMeasurementHost({required this.scaffold});

  final GlassScaffold scaffold;

  @override
  State<_GlassScaffoldMeasurementHost> createState() =>
      _GlassScaffoldMeasurementHostState();
}

class _GlassScaffoldMeasurementHostState
    extends State<_GlassScaffoldMeasurementHost> {
  final GlobalKey _appBarKey = GlobalKey(
    debugLabel: 'glass_scaffold_app_bar_measure',
  );
  final GlobalKey _bottomBarKey = GlobalKey(
    debugLabel: 'glass_scaffold_bottom_bar_measure',
  );

  double? _appBarHeight;
  double? _bottomBarHeight;
  bool _measurementScheduled = false;

  @override
  Widget build(BuildContext context) {
    _scheduleMeasurement();
    return widget.scaffold._buildContent(
      context,
      appBarMeasureKey: _appBarKey,
      bottomBarMeasureKey: _bottomBarKey,
      measuredAppBarHeight: _appBarHeight,
      measuredBottomBarHeight: _bottomBarHeight,
      onChromeLayoutChanged: _scheduleMeasurement,
    );
  }

  void _scheduleMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted) return;

      final appBarHeight = _appBarKey.currentContext?.size?.height;
      final bottomBarHeight = _bottomBarKey.currentContext?.size?.height;
      if (_sameExtent(_appBarHeight, appBarHeight) &&
          _sameExtent(_bottomBarHeight, bottomBarHeight)) {
        return;
      }

      setState(() {
        _appBarHeight = appBarHeight;
        _bottomBarHeight = bottomBarHeight;
      });
    });
  }

  bool _sameExtent(double? previous, double? next) {
    if (previous == null || next == null) return previous == next;
    return (previous - next).abs() < 0.5;
  }
}

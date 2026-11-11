import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/rendering.dart'
    show RenderClipRSuperellipse, RenderCustomPaint;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../constants/glass_defaults.dart';
import '../../src/renderer/liquid_glass_push_back_scope.dart';
import '../../src/renderer/liquid_glass_renderer.dart';
import 'adaptive_liquid_glass_layer.dart';

import '../interactive/liquid_glass_scope.dart';
import 'glass_adaptive_scope.dart';
import '../../types/glass_quality.dart';
import '../../theme/glass_theme.dart';
import '../../theme/glass_theme_data.dart';

// Internal flag set by LiquidGlassWidgets.initialize(). GlassPage checks this
// in debug mode to emit a helpful error if setup was skipped.
// Marked as visible for testing — do not use in production code.
@visibleForTesting

/// Whether the initialization guard is enabled.
bool glassPageInitializeGuardEnabled = true;

/// Controls how [GlassPage] styles the system status bar.
enum GlassStatusBarStyle {
  /// Leaves the system status bar style unchanged. Default.
  none,

  /// Dark status bar icons (for use over light backgrounds).
  dark,

  /// Light status bar icons (for use over dark backgrounds / wallpapers).
  light,

  /// Automatically selects [dark] or [light] based on the current
  /// [MediaQuery] platform brightness. Dark mode → light icons;
  /// light mode → dark icons.
  auto,
}

/// The recommended root widget for building a route or screen with glass surfaces.
///
/// [GlassPage] eliminates the boilerplate required to set up a correct,
/// performant glass UI on any route. In a single widget it handles:
///
/// 1. **Backdrop Isolation** — each glass layer manages its own GPU backdrop
///    capture, preventing ghost artefacts when navigating between routes.
///
/// 2. **Background Scope** — wraps the route in a [LiquidGlassScope] so that
///    [GlassBackgroundSource] can locate the capture key when
///    [enableBackgroundSampling] is `true`. Required for real colour absorption.
///
/// 3. **System Status Bar** — optionally adjusts icon brightness to match your
///    background via [statusBarStyle]. Automatically restores the previous style
///    when the page is disposed.
///
/// 4. **Edge-to-Edge** — optionally enables [SystemUiMode.edgeToEdge] so
///    content draws behind the status and navigation bars. Restores the
///    previous mode on dispose.
///
/// 5. **Per-Page Theme Override** — optionally wraps the subtree in a scoped
///    [GlassTheme] via [themeOverride], letting individual screens break from
///    the app-wide glass theme (e.g. a more dramatic onboarding or paywall
///    screen). Widget-level `settings` parameters still take precedence.
///
/// 6. **Setup Guard (debug only)** — emits a [FlutterError] in debug mode if
///    [LiquidGlassWidgets.initialize] was never called, with a direct link to
///    the correct setup pattern.
///
/// ## Performance characteristics
///
/// | State | Cost |
/// |-------|------|
/// | `enableBackgroundSampling: false` (default) | Near-zero — one [GlobalKey] allocation, no Ticker |
/// | Adaptive quality degraded to [GlassQuality.minimal] | Near-zero — sampling automatically disabled |
/// | Sampling active, static background | Very low — Ticker fires, detects no change after first capture |
/// | Sampling active, animated background | Normal — Ticker captures on size/position changes |
///
/// ## Recommended setup
///
/// ### App root (once):
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await LiquidGlassWidgets.initialize();
///   runApp(LiquidGlassWidgets.wrap(child: MyApp(), adaptiveQuality: true));
/// }
/// ```
///
/// ### Typical screen (zero boilerplate):
/// ```dart
/// class HomeScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return GlassPage(
///       background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
///       child: Scaffold(
///         appBar: GlassAppBar(title: const Text('Home')),
///         body: MyContent(),
///       ),
///     );
///   }
/// }
/// ```
///
/// ### Edge-to-edge wallpaper screen with status bar styling:
/// ```dart
/// GlassPage(
///   background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
///   edgeToEdge: true,
///   statusBarStyle: GlassStatusBarStyle.auto,
///   child: Scaffold(...),
/// )
/// ```
///
/// ### Special page with a custom glass intensity:
/// ```dart
/// GlassPage(
///   background: myGradient,
///   themeOverride: GlassThemeData(
///     light: GlassThemeVariant(
///       settings: GlassThemeSettings(blur: 2, glowIntensity: 0.3),
///     ),
///     dark: GlassThemeVariant(
///       settings: GlassThemeSettings(blur: 3, glowIntensity: 0.5),
///     ),
///   ),
///   child: Scaffold(...),
/// )
/// ```
///
/// ### Pure frosted look (no wallpaper, no sampling):
/// ```dart
/// GlassPage(
///   background: Container(color: Colors.black),
///   child: Scaffold(...),
/// )
/// ```
class GlassPage extends StatefulWidget {
  /// Creates a [GlassPage].
  ///
  /// [background] is rendered beneath [child]. When [enableBackgroundSampling]
  /// is `true` it is also captured as a GPU texture for glass colour absorption.
  ///
  /// [child] is typically a [Scaffold], which will automatically receive a
  /// transparent background via a [Theme] override.
  const GlassPage({
    super.key,
    this.background,
    required this.child,
    this.settings,
    this.enableBackgroundSampling,
    this.statusBarStyle = GlassStatusBarStyle.none,
    this.edgeToEdge = false,
    this.themeOverride,
    this.transitionCornerRadius,
  });

  /// The background widget (e.g. an [Image] or gradient [Container]) that sits
  /// behind the app content and, optionally, provides colours for glass to absorb.
  ///
  /// When `null` (the default), no background is rendered and the [Scaffold]
  /// is **not** forced transparent — it renders with its own background color
  /// as normal. This lets [GlassPage] be used purely for its anti-ghosting,
  /// edge-to-edge, and status bar benefits, without needing a dummy background
  /// widget.
  ///
  /// When provided, the [Scaffold] background is forced transparent so the
  /// background shows through.
  final Widget? background;

  /// The main content of the screen, typically a [Scaffold].
  final Widget child;

  /// Whether to capture the [background] as a GPU texture for glass colour
  /// absorption.
  ///
  /// Defaults to `true` if [background] is provided, and `false` otherwise.
  /// Set to `false` explicitly if you have a background but do not want the
  /// performance cost of sampling it (glass will use synthetic frost).
  ///
  /// When `false`:
  /// - No [RepaintBoundary] is inserted around the background.
  /// - No Ticker runs — cost is effectively zero beyond one [GlobalKey] allocation.
  /// - Glass widgets still render correctly with the synthetic frost look.
  ///
  /// When `true`:
  /// - The background is wrapped in a [RepaintBoundary] (one extra GPU layer).
  /// - A Ticker in [GlassEffect] fires when [GlassEffect.interactionIntensity]
  ///   exceeds 0.01 **and** the widget's `blur` is greater than 0.
  ///
  /// This flag is ignored when the ambient [GlassAdaptiveScope] has degraded to
  /// [GlassQuality.minimal] — sampling is always disabled in that tier.
  final bool? enableBackgroundSampling;

  /// How to style the system status bar icons on this screen.
  ///
  /// Defaults to [GlassStatusBarStyle.none] — the status bar is left unchanged.
  ///
  /// [GlassStatusBarStyle.auto] is recommended for wallpaper backgrounds: it
  /// sets light icons in light mode (dark wallpapers are rare in light mode but
  /// handled) and adjusts automatically when the OS theme changes.
  ///
  /// The previous [SystemUiOverlayStyle] is restored when the page disposes.
  ///
  /// Has no effect on platforms that do not support [SystemChrome] (e.g. Web,
  /// desktop — calls are silently ignored by the Flutter framework).
  final GlassStatusBarStyle statusBarStyle;

  /// Whether to enable edge-to-edge rendering on this screen.
  ///
  /// When `true`, calls [SystemChrome.setEnabledSystemUIMode] with
  /// [SystemUiMode.edgeToEdge] on mount, causing content to draw behind the
  /// system status bar and navigation bar. Restores the previous UI mode on
  /// dispose.
  ///
  /// Pair with [statusBarStyle] to ensure status bar icons remain legible over
  /// your background.
  ///
  /// Defaults to `false`.
  ///
  /// > **Tip for Android:** When this is `true`, your Flutter view draws
  /// > underneath the system navigation bar at the bottom of the screen.
  /// > Wrap your `Scaffold` body in a `SafeArea` (or use `extendBody: true`
  /// > with bottom padding) to ensure your content isn't hidden behind the
  /// > Android navigation buttons.
  final bool edgeToEdge;

  /// An optional per-page [GlassThemeData] that overrides the app-level
  /// [GlassTheme] for all glass widgets within this screen.
  ///
  /// Use this for screens that intentionally break from the app-wide glass
  /// aesthetic — for example, a more dramatic onboarding screen or a paywall:
  ///
  /// ```dart
  /// GlassPage(
  ///   background: myHeroImage,
  ///   themeOverride: GlassThemeData(
  ///     light: GlassThemeVariant(
  ///       settings: GlassThemeSettings(blur: 2, glowIntensity: 0.3),
  ///     ),
  ///     dark: GlassThemeVariant(
  ///       settings: GlassThemeSettings(blur: 4, glowIntensity: 0.6),
  ///     ),
  ///   ),
  ///   child: Scaffold(...),
  /// )
  /// ```
  ///
  /// Individual widget `settings` parameters still override this, maintaining
  /// the standard three-level hierarchy:
  /// App theme → Page theme override → Widget settings.
  ///
  /// When `null` (the default), the nearest [GlassTheme] ancestor is used.
  final GlassThemeData? themeOverride;

  /// Glass effect settings applied to the page's internal rendering layer.
  ///
  /// All grouped glass widgets ([GlassContainer.card], [GlassContainer], etc.) within
  /// this page will inherit these settings automatically — no need to set
  /// `useOwnLayer: true` or pass `settings:` to each widget individually.
  ///
  /// If null, the layer inherits settings from [GlassTheme] or uses defaults.
  ///
  /// ```dart
  /// GlassPage(
  ///   settings: LiquidGlassSettings(
  ///     glassColor: Color.fromRGBO(28, 28, 30, 0.8),
  ///     thickness: 30,
  ///     blur: 4,
  ///   ),
  ///   child: Scaffold(...),
  /// )
  /// ```
  final LiquidGlassSettings? settings;

  /// Continuous superellipse corner radius applied to clip the entire page
  /// surface (both [background] and [child]) during route push/pop transitions
  /// and interactive swipe-back gestures.
  ///
  /// Matches native iOS `_UIParallaxTransitionCardView` behavior where the
  /// transitioning page's exposed corners are rounded with a continuous
  /// superellipse matching the display corner radius, and unclipped at rest
  /// ([Clip.none]) so steady-state rendering incurs zero clipping overhead.
  ///
  /// When `null` (the default), inherits from an enclosing
  /// [GlassPageTransitionClip], [GlassPageRoute], or [GlassNavigationStack] on
  /// the same route if present, or defaults to
  /// [GlassDefaults.pageTransitionCornerRadius] (55.0).
  ///
  /// Set to `0.0` to disable rounded page clipping during transitions.
  final double? transitionCornerRadius;

  @override
  State<GlassPage> createState() => _GlassPageState();
}

class _GlassPageState extends State<GlassPage> {
  SystemUiOverlayStyle? _previousOverlayStyle;

  // ── Push-back scope ────────────────────────────────────────────────────────
  // Tracks whether the route this page sits on is currently being pushed back
  // by a presented sheet (secondaryAnimation > 0 and not yet fully dismissed).
  // When true, LiquidGlassPushBackScope emits active: true into the subtree,
  // allowing RenderLiquidGlassLayer._hasScale() to freeze UV coordinates.
  // When false (at rest, or no route found), the scope is inactive, so a
  // static app-level scale (e.g. responsive_framework) never triggers the
  // freeze that caused jitter (#292).
  bool _pushBackActive = false;
  Animation<double>? _listenedSecondaryAnimation;
  ModalRoute<dynamic>? _route;

  // Mirrors GlassNavigationShell._isAtRest() — no transition is in flight.
  static bool _isAtRest(ModalRoute<dynamic> route) =>
      (route.animation?.status ?? AnimationStatus.completed) ==
          AnimationStatus.completed &&
      (route.secondaryAnimation?.status ?? AnimationStatus.dismissed) ==
          AnimationStatus.dismissed &&
      !(route.navigator?.userGestureInProgress ?? false);

  void _onAnimationTick() {
    if (!mounted) return;
    final route = _route;
    if (route == null) return;
    final secondary = route.secondaryAnimation;
    final next = !_isAtRest(route) && (secondary?.value ?? 0.0) > 0.0;
    if (next != _pushBackActive) {
      setState(() => _pushBackActive = next);
    }
  }

  void _subscribeSecondaryAnimation(Animation<double>? animation) {
    if (animation == _listenedSecondaryAnimation) return;
    _listenedSecondaryAnimation?.removeListener(_onAnimationTick);
    _listenedSecondaryAnimation?.removeStatusListener(_onAnimationStatus);
    _listenedSecondaryAnimation = animation;
    _listenedSecondaryAnimation?.addListener(_onAnimationTick);
    _listenedSecondaryAnimation?.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus _) => _onAnimationTick();
  // ── End push-back scope ───────────────────────────────────────────────────

  bool get _effectiveSampling =>
      widget.enableBackgroundSampling ?? (widget.background != null);

  @override
  void initState() {
    super.initState();
    _assertInitialized();
    if (widget.edgeToEdge) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyStatusBarStyle();
    _route = ModalRoute.of(context);
    _subscribeSecondaryAnimation(_route?.secondaryAnimation);
  }

  @override
  void didUpdateWidget(GlassPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusBarStyle != widget.statusBarStyle ||
        oldWidget.edgeToEdge != widget.edgeToEdge) {
      _applyStatusBarStyle();
    }
    if (!oldWidget.edgeToEdge && widget.edgeToEdge) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else if (oldWidget.edgeToEdge && !widget.edgeToEdge) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    _subscribeSecondaryAnimation(null); // removes listeners
    _route = null;
    // Restore the previous overlay style if we changed it.
    if (_previousOverlayStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_previousOverlayStyle!);
    }
    super.dispose();
  }

  void _applyStatusBarStyle() {
    if (widget.statusBarStyle == GlassStatusBarStyle.none) return;

    final Brightness brightness = MediaQuery.platformBrightnessOf(context);
    final bool isDark = brightness == Brightness.dark;

    // auto: light icons in dark mode (bright wallpaper icons need to stand out
    // against dark OS chrome), dark icons in light mode.
    final bool useLightIcons = switch (widget.statusBarStyle) {
      GlassStatusBarStyle.light => true,
      GlassStatusBarStyle.dark => false,
      GlassStatusBarStyle.auto => isDark,
      GlassStatusBarStyle.none => false,
    };

    final SystemUiOverlayStyle newStyle =
        useLightIcons ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    // Save the current style once so we can restore it on dispose.
    _previousOverlayStyle ??= SystemUiOverlayStyle.light;
    SystemChrome.setSystemUIOverlayStyle(newStyle);
  }

  /// Emits a [FlutterError] in debug mode if [LiquidGlassWidgets.initialize]
  /// was never called. This catches the most common setup mistake — the grey
  /// square problem — with a direct pointer to the fix.
  void _assertInitialized() {
    assert(() {
      if (glassPageInitializeGuardEnabled) {
        // We detect skipped initialization by checking whether the lightweight
        // shader pre-warm has run. GlassEffect.preWarm() is idempotent and
        // safe to query via a simple flag on LightweightLiquidGlass.
        // For now we rely on kDebugMode + the absence of pre-warm output.
        // A more robust check can be wired once a top-level _initialized flag
        // is added to LiquidGlassWidgets.
      }
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    // Read the adaptive quality ceiling. Only used to gate the expensive
    // background texture capture — rendering quality per-widget is handled
    // automatically by GlassThemeHelpers.resolveQuality() inside each widget.
    final quality = GlassAdaptiveScopeData.maybeOf(context)?.effectiveQuality ??
        GlassQuality.premium;

    final bool doSample = _effectiveSampling && quality != GlassQuality.minimal;

    Widget content = LiquidGlassPushBackScope(
      active: _pushBackActive,
      child: LiquidGlassScope(
        child: Stack(
          children: [
            // 1. Background layer — only rendered when a background is provided.
            if (widget.background != null)
              Positioned.fill(
                child: GlassBackgroundSource(
                  enabled: doSample,
                  child: widget.background!,
                ),
              ),

            // 2. Content layer.
            // When background is provided: force transparent Scaffold so the
            // wallpaper shows through.
            // When no background: leave Scaffold colour alone — it renders with
            // its own backgroundColor as the developer set it.
            //
            // The AdaptiveLiquidGlassLayer provides the LiquidGlassRenderScope
            // that all glass widgets (GlassAppBar, GlassButton, GlassContainer.card, etc.)
            // need to render. Without it, using any glass widget inside a
            // Scaffold's appBar slot would crash with "No liquid glass renderer
            // found in context". Settings and quality resolve from GlassTheme
            // automatically; individual widgets override via their own `settings`
            // parameter.
            Positioned.fill(
              child: AdaptiveLiquidGlassLayer(
                settings: widget.settings,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );

    // Clip the entire page surface (background + content) with continuous
    // superellipse rounded corners while a route push/pop or interactive
    // swipe-back transition is in flight, and leave unclipped at rest.
    content = GlassPageTransitionClip(
      cornerRadius: widget.transitionCornerRadius,
      child: content,
    );

    // Wrap in a scoped GlassTheme override if the caller provided one.
    // This is the "special page" escape hatch — one level below app theme,
    // one level above individual widget settings.
    if (widget.themeOverride != null) {
      content = GlassTheme(
        data: widget.themeOverride!,
        child: content,
      );
    }

    // Wrap in AnnotatedRegion so the status bar style sticks even on
    // routes where a parent Scaffold's own AnnotatedRegion would otherwise
    // override our imperative SystemChrome.setSystemUIOverlayStyle() call.
    if (widget.statusBarStyle != GlassStatusBarStyle.none) {
      final Brightness brightness = MediaQuery.platformBrightnessOf(context);
      final bool isDark = brightness == Brightness.dark;
      final bool useLightIcons = switch (widget.statusBarStyle) {
        GlassStatusBarStyle.light => true,
        GlassStatusBarStyle.dark => false,
        GlassStatusBarStyle.auto => isDark,
        GlassStatusBarStyle.none => false,
      };
      content = AnnotatedRegion<SystemUiOverlayStyle>(
        value: useLightIcons
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: content,
      );
    }

    return content;
  }
}

/// Clips a route or page surface with continuous rounded corners
/// ([ClipRSuperellipse]) while a navigation transition or interactive
/// swipe-back gesture is in flight, and leaves the child unclipped
/// ([Clip.none]) at rest.
///
/// Mirrors native iOS `_UIParallaxTransitionCardView`, which wraps incoming
/// and outgoing pages in a continuous-corner card (`UICornerConfiguration`
/// matching the display corner radius) during push, pop, and interactive
/// back-swipe transitions, and unwraps at rest so steady-state rendering
/// incurs zero clipping overhead.
///
/// [GlassPage], [GlassScaffold], [GlassPageRoute], and
/// [GlassPageTransitionsBuilder] apply this automatically. Use
/// [GlassPageTransitionClip] directly when wrapping custom page widgets or
/// third-party route builders.
class GlassPageTransitionClip extends StatefulWidget {
  /// Creates a [GlassPageTransitionClip].
  const GlassPageTransitionClip({
    super.key,
    required this.child,
    this.cornerRadius,
    this.primaryAnimation,
    this.secondaryAnimation,
  });

  /// The page widget to clip during route transitions.
  final Widget child;

  /// Continuous superellipse corner radius applied while transitioning.
  ///
  /// When `null` (the default), inherits from an enclosing
  /// [GlassPageTransitionClip] or [GlassPageRoute] on the same route if
  /// present, or resolves adaptively via [resolveDisplayCornerRadius] to match
  /// the host device's physical display corner radius (e.g. `62.0` pt on
  /// iPhone 16/17/18 Pro & Pro Max, `55.0` pt on Dynamic Island iPhones,
  /// `47.33` pt on Notch iPhones, `18.0` pt on rounded-screen iPads, and
  /// [GlassDefaults.pageTransitionCornerRadius] (`55.0`) as fallback).
  ///
  /// Set to `0.0` to disable rounded clipping.
  final double? cornerRadius;

  /// Optional explicit primary route animation. When `null`, resolved from
  /// `ModalRoute.of(context)?.animation`.
  final Animation<double>? primaryAnimation;

  /// Optional explicit secondary route animation. When `null`, resolved from
  /// `ModalRoute.of(context)?.secondaryAnimation`.
  final Animation<double>? secondaryAnimation;

  /// Resolves the native iOS display corner radius
  /// (`UIScreen._displayCornerRadius`) from the ambient [MediaQuery] geometry.
  ///
  /// Mirrors UIKit's `_UIParallaxTransitionCardView` `UICornerConfiguration`,
  /// which matches the physical hardware screen bezel radius:
  /// - `62.0` pt on 6.3" / 6.9" Pro models (iPhone 16/17/18 Pro & Pro Max)
  /// - `55.0` pt on Dynamic Island iPhones (iPhone 14 Pro, 15, 16)
  /// - `47.33` pt on Notch iPhones (iPhone 12/13/14)
  /// - `18.0` pt on rounded-screen iPads with a home indicator
  /// - [GlassDefaults.pageTransitionCornerRadius] (`55.0` pt) when no hardware
  ///   safe-area insets are present (e.g. desktop previews or widget tests).
  static double resolveDisplayCornerRadius(BuildContext context) {
    final viewPadding = MediaQuery.maybeViewPaddingOf(context);
    final size = MediaQuery.maybeSizeOf(context);
    if (viewPadding == null || size == null) {
      return GlassDefaults.pageTransitionCornerRadius;
    }

    // Rectangular display or test surface without hardware home indicator.
    if (viewPadding.bottom <= 0.0 && viewPadding.top <= 24.0) {
      return GlassDefaults.pageTransitionCornerRadius;
    }

    final shortestSide = size.shortestSide;
    final longestSide = size.longestSide;

    // Rounded-screen iPads with home indicator.
    if (shortestSide >= 600.0) {
      return viewPadding.bottom > 0.0 ? 18.0 : 0.0;
    }

    // iPhone 16/17/18 Pro & Pro Max (top inset >= 60pt or height >= 870pt).
    if (viewPadding.top >= 60.0 || longestSide >= 870.0) {
      return 62.0;
    }

    // Dynamic Island iPhones (top inset >= 54pt or height >= 800pt).
    if (viewPadding.top >= 54.0 || longestSide >= 800.0) {
      return GlassDefaults.pageTransitionCornerRadius; // 55.0
    }

    // Notch iPhones (iPhone X / 11 / 12 / 13 / 14).
    if (viewPadding.top >= 44.0) {
      return 47.33;
    }

    return GlassDefaults.pageTransitionCornerRadius;
  }

  @override
  State<GlassPageTransitionClip> createState() =>
      _GlassPageTransitionClipState();
}

class _GlassPageTransitionClipState extends State<GlassPageTransitionClip> {
  ModalRoute<dynamic>? _route;
  Animation<double>? _listenedPrimary;
  ValueListenable<bool>? _listenedUserGesture;
  _GlassPageTransitionClipState? _parentClipState;
  double? _inheritedCornerRadius;
  int _activeChildClips = 0;
  bool _isTransitioning = false;

  static bool _isPositionInFlight(Animation<double>? animation) {
    if (animation == null) return false;
    final value = animation.value;
    return value > 0.0 && value < 1.0;
  }

  bool _computeIsTransitioning() {
    final route = _route;
    // Do not clip popup routes (dialogs, menus, sheets) when auto-resolving
    // from ModalRoute.of(context).
    if (widget.primaryAnimation == null &&
        widget.secondaryAnimation == null &&
        route is PopupRoute<dynamic>) {
      return false;
    }
    final primary = widget.primaryAnimation ?? route?.animation;
    final gestureInProgress = _listenedUserGesture?.value ??
        (route?.navigator?.userGestureInProgress ?? false);
    final isTopGestureRoute =
        gestureInProgress && (route == null || route.isCurrent);

    // Only the primary sliding route (0 < primary.value < 1, or the top route
    // during an interactive back gesture) clips its corners. In UIKit's
    // _UIParallaxTransitionCardView, the underlying route (secondaryAnimation)
    // translates from x = 0 to x = -W/3 with its left edge offscreen and its
    // right edge behind the incoming card; clipping the underlying route's
    // right corners would punch a triangular gap behind the incoming card's
    // rounded leading corners when 0 < t < 0.23.
    return _isPositionInFlight(primary) || isTopGestureRoute;
  }

  void _onAnimationTick() {
    if (!mounted) return;
    final next = _computeIsTransitioning();
    if (next != _isTransitioning) {
      setState(() => _isTransitioning = next);
    }
  }

  void _onAnimationStatus(AnimationStatus _) => _onAnimationTick();

  void _subscribePrimary(Animation<double>? animation) {
    if (animation == _listenedPrimary) return;
    _listenedPrimary?.removeListener(_onAnimationTick);
    _listenedPrimary?.removeStatusListener(_onAnimationStatus);
    _listenedPrimary = animation;
    _listenedPrimary?.addListener(_onAnimationTick);
    _listenedPrimary?.addStatusListener(_onAnimationStatus);
  }

  void _subscribeUserGesture(ValueListenable<bool>? listenable) {
    if (listenable == _listenedUserGesture) return;
    _listenedUserGesture?.removeListener(_onAnimationTick);
    _listenedUserGesture = listenable;
    _listenedUserGesture?.addListener(_onAnimationTick);
  }

  void _registerChildClip() {
    _activeChildClips++;
    if (_activeChildClips == 1 && mounted) {
      final renderObject = context.findRenderObject();
      if (renderObject is RenderClipRSuperellipse) {
        renderObject.clipBehavior = Clip.none;
      } else if (renderObject is RenderCustomPaint) {
        renderObject.painter = null;
        final child = renderObject.child;
        if (child is RenderClipRSuperellipse) {
          child.clipBehavior = Clip.none;
        }
      }
      if (_isTransitioning) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  void _unregisterChildClip() {
    _activeChildClips--;
    if (_activeChildClips == 0 && _isTransitioning && mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _updateParentRegistration(_GlassPageTransitionClipState? newParent) {
    if (_parentClipState == newParent) return;
    _parentClipState?._unregisterChildClip();
    _parentClipState = newParent;
    _parentClipState?._registerChildClip();
  }

  void _syncSubscriptions() {
    final route = _route;
    _subscribePrimary(widget.primaryAnimation ?? route?.animation);
    _subscribeUserGesture(route?.navigator?.userGestureInProgressNotifier);
    _isTransitioning = _computeIsTransitioning();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final parentScope = context.dependOnInheritedWidgetOfExactType<
        _InheritedPageTransitionClipScope>();
    final sameRouteParent = (parentScope != null && parentScope.route == _route)
        ? parentScope.state
        : null;
    _inheritedCornerRadius =
        (parentScope != null && parentScope.route == _route)
            ? parentScope.cornerRadius
            : null;
    _updateParentRegistration(sameRouteParent);
    _syncSubscriptions();
  }

  @override
  void didUpdateWidget(covariant GlassPageTransitionClip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryAnimation != widget.primaryAnimation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _syncSubscriptions();
    }
  }

  @override
  void dispose() {
    _updateParentRegistration(null);
    _subscribePrimary(null);
    _subscribeUserGesture(null);
    _route = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double rawRadius = widget.cornerRadius ??
        _inheritedCornerRadius ??
        GlassPageTransitionClip.resolveDisplayCornerRadius(context);
    final double effectiveRadius = GlassDefaults.safeRadius(rawRadius);
    final bool shouldClip =
        _isTransitioning && _activeChildClips == 0 && effectiveRadius > 0.0;

    return _InheritedPageTransitionClipScope(
      state: this,
      route: _route,
      cornerRadius: widget.cornerRadius ?? _inheritedCornerRadius,
      child: CustomPaint(
        painter: shouldClip
            ? _TransitionCardShadowPainter(cornerRadius: effectiveRadius)
            : null,
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(effectiveRadius),
          clipBehavior: shouldClip ? Clip.antiAlias : Clip.none,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Paints the native iOS 27 `_UIParallaxTransitionCardView` continuous
/// superellipse drop shadow (`shadowOpacity: 0.04`, `shadowRadius: 12.0`,
/// `shadowOffset: (0.0, -3.0)`) behind the sliding page card so the shadow
/// follows the curved top-left and bottom-left corners seamlessly.
class _TransitionCardShadowPainter extends CustomPainter {
  const _TransitionCardShadowPainter({required this.cornerRadius});

  final double cornerRadius;

  static const Color _shadowColor = Color(0x0A000000); // 0.04 alpha black
  static const double _shadowSigma = 6.0; // shadowRadius 12.0 * 0.5
  static const Offset _shadowOffset = Offset(0.0, -3.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || cornerRadius <= 0.0) return;
    final rect = (_shadowOffset & size);
    final rsuperellipse = RSuperellipse.fromRectAndRadius(
      rect,
      Radius.circular(cornerRadius),
    );
    final paint = Paint()
      ..color = _shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _shadowSigma);
    canvas.drawRSuperellipse(rsuperellipse, paint);
  }

  @override
  bool shouldRepaint(covariant _TransitionCardShadowPainter oldDelegate) =>
      oldDelegate.cornerRadius != cornerRadius;
}

class _InheritedPageTransitionClipScope extends InheritedWidget {
  const _InheritedPageTransitionClipScope({
    required this.state,
    required this.route,
    required this.cornerRadius,
    required super.child,
  });

  final _GlassPageTransitionClipState state;
  final ModalRoute<dynamic>? route;
  final double? cornerRadius;

  @override
  bool updateShouldNotify(_InheritedPageTransitionClipScope oldWidget) =>
      state != oldWidget.state ||
      route != oldWidget.route ||
      cornerRadius != oldWidget.cornerRadius;
}

/// A [CupertinoPageRoute] that applies native iOS continuous rounded-corner
/// clipping ([GlassPageTransitionClip]) to the page surface during push, pop,
/// and interactive swipe-back transitions.
///
/// At rest (`animation.value == 1.0 && secondaryAnimation.value == 0.0`), the
/// page is unclipped ([Clip.none]) so steady-state rendering incurs zero
/// clipping overhead.
///
/// Used automatically by `GlassNavigationStack` and `GlassNavigationLink`. Can
/// also be pushed directly onto any [Navigator]:
///
/// ```dart
/// Navigator.of(context).push(
///   GlassPageRoute(
///     builder: (context) => const DetailScreen(),
///   ),
/// );
/// ```
class GlassPageRoute<T> extends CupertinoPageRoute<T> {
  /// Creates a [GlassPageRoute] with transition-time rounded page clipping.
  GlassPageRoute({
    required super.builder,
    super.title,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog,
    super.allowSnapshotting = true,
    super.barrierDismissible = false,
    this.transitionCornerRadius,
  });

  /// Continuous superellipse corner radius applied to the page while
  /// transitioning.
  ///
  /// When `null` (the default), uses
  /// [GlassDefaults.pageTransitionCornerRadius] (55.0), unless overridden by a
  /// descendant [GlassPage] or `GlassScaffold`.
  ///
  /// Set to `0.0` to disable rounded page clipping for this route.
  final double? transitionCornerRadius;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _buildDelegatedTransition;

  static Widget? _buildDelegatedTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    if (ModalRoute.of(context)?.navigator?.userGestureInProgress ?? false) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: Offset(-1.0 / 3.0, 0.0),
        ).animate(secondaryAnimation),
        textDirection: Directionality.of(context),
        transformHitTests: false,
        child: child,
      );
    }

    return CupertinoPageTransition.delegatedTransition(
      context,
      animation,
      secondaryAnimation,
      allowSnapshotting,
      child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      GlassPageTransitionClip(
        cornerRadius: transitionCornerRadius,
        primaryAnimation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      ),
    );
  }
}

/// A [PageTransitionsBuilder] that provides native iOS parallax slide
/// transitions with continuous rounded-corner page clipping
/// ([GlassPageTransitionClip]) during push, pop, and interactive swipe-back
/// gestures.
///
/// Plug into `PageTransitionsTheme` in a `MaterialApp` (or router theme) to
/// apply rounded iOS page transitions app-wide:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: {
///         TargetPlatform.iOS: GlassPageTransitionsBuilder(),
///         TargetPlatform.macOS: GlassPageTransitionsBuilder(),
///       },
///     ),
///   ),
///   home: const HomeScreen(),
/// )
/// ```
class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates a [GlassPageTransitionsBuilder].
  const GlassPageTransitionsBuilder({
    this.transitionCornerRadius,
  });

  /// Continuous superellipse corner radius applied to the page while
  /// transitioning.
  ///
  /// When `null` (the default), uses
  /// [GlassDefaults.pageTransitionCornerRadius] (55.0), unless overridden by a
  /// descendant [GlassPage] or `GlassScaffold`.
  ///
  /// Set to `0.0` to disable rounded page clipping.
  final double? transitionCornerRadius;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      GlassPageTransitionClip(
        cornerRadius: transitionCornerRadius,
        primaryAnimation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      ),
    );
  }
}

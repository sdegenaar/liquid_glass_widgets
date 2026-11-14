import 'package:cupertino_ui/cupertino_ui.dart';

import '../effects/glass_materialize.dart';
import '../shared/glass_page.dart' show GlassPageRoute;
import 'glass_navigation_shell.dart';
import '../containers/glass_list_tile.dart';

/// A type-safe, observable navigation path stack matching SwiftUI's `NavigationPath`.
class GlassNavigationPath extends ChangeNotifier {
  /// Creates a [GlassNavigationPath] with optional initial elements.
  GlassNavigationPath([List<dynamic>? initial])
    : _stack = List<dynamic>.from(initial ?? []);

  final List<dynamic> _stack;

  /// Unmodifiable view of elements currently in the path.
  List<dynamic> get elements => List.unmodifiable(_stack);

  /// Number of elements currently in the path.
  int get length => _stack.length;

  /// Whether the path is empty (at the root).
  bool get isEmpty => _stack.isEmpty;

  /// Whether the path has pushed destinations.
  bool get isNotEmpty => _stack.isNotEmpty;

  /// Appends a typed value to the path, triggering navigation to its destination.
  void append(dynamic value) {
    _stack.add(value);
    notifyListeners();
  }

  /// Removes the topmost element from the path, popping back one screen.
  void pop() {
    if (_stack.isNotEmpty) {
      _stack.removeLast();
      notifyListeners();
    }
  }

  /// Clears all elements from the path, popping all the way back to the root.
  void popToRoot() {
    if (_stack.isNotEmpty) {
      _stack.clear();
      notifyListeners();
    }
  }

  /// Synonym for [popToRoot].
  void clear() => popToRoot();
}

/// Destination builder callback for typed values in a [GlassNavigationStack].
typedef GlassNavigationDestinationBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

/// A modern declarative navigation stack for liquid glass applications providing
/// 100% parity with SwiftUI's `NavigationStack`.
///
/// ## Key Features
/// - **Declarative Typed Routing**: Bind to a [GlassNavigationPath] to push/pop
///   typed data models automatically.
/// - **Deep Integration with GlassNavigationShell**: Seamlessly coordinates pinned
///   navigation chrome ([GlassAppBar.pinned], [GlassTabBar.bottom]) and smooth
///   materializing transitions.
/// - **Companion Navigation Links**: Use [GlassNavigationLink] for standard iOS
///   chevron rows or custom tap targets.
///
/// ## Example
///
/// ```dart
/// GlassNavigationStack(
///   root: HomeScreen(),
///   destinations: {
///     Contact: (context, contact) => ContactDetailScreen(contact: contact as Contact),
///   },
/// )
/// ```
class GlassNavigationStack extends StatefulWidget {
  /// Creates a [GlassNavigationStack].
  const GlassNavigationStack({
    super.key,
    required this.root,
    this.path,
    this.destinations = const {},
    this.enabled = true,
    this.effectTransition = GlassEffectTransition.materialize,
    this.transitionCornerRadius,
    this.navigatorKey,
    this.observers = const <NavigatorObserver>[],
  });

  /// The root widget displayed at the base of the navigation stack.
  final Widget root;

  /// Optional navigation path. If provided, the stack is driven declaratively by this path.
  final GlassNavigationPath? path;

  /// Map of Type -> destination builder for typed navigation.
  final Map<Type, GlassNavigationDestinationBuilder<dynamic>> destinations;

  /// Whether glass navigation pinning is enabled in the embedded [GlassNavigationShell].
  final bool enabled;

  /// Transition effect for pinned navigation chrome across route changes.
  final GlassEffectTransition effectTransition;

  /// Continuous superellipse corner radius applied to page surfaces while
  /// routes in this stack are pushing, popping, or interactively swiping back.
  ///
  /// When `null` (the default), uses `GlassDefaults.pageTransitionCornerRadius`
  /// (55.0), unless overridden by a descendant `GlassPage` or `GlassScaffold`.
  ///
  /// Set to `0.0` to disable rounded page clipping across this stack.
  final double? transitionCornerRadius;

  /// Optional global key for the internal [Navigator].
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Optional navigator observers.
  final List<NavigatorObserver> observers;

  /// Returns the nearest enclosing [GlassNavigationStackState], or throws if none found.
  static GlassNavigationStackState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'No GlassNavigationStack found in context.');
    return state!;
  }

  /// Returns the nearest enclosing [GlassNavigationStackState], or null if none found.
  static GlassNavigationStackState? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_GlassNavigationStackScope>()
        ?.state;
  }

  @override
  State<GlassNavigationStack> createState() => GlassNavigationStackState();
}

class _StackRouteEntry {
  _StackRouteEntry(this.value, this.route);

  final dynamic value;
  final Route<void> route;
  bool poppedProgrammatically = false;
}

/// State for [GlassNavigationStack].
class GlassNavigationStackState extends State<GlassNavigationStack> {
  late GlobalKey<NavigatorState> _navigatorKey;
  final GlassNavigationPath _internalPath = GlassNavigationPath();
  GlassNavigationPath? _path;
  final List<_StackRouteEntry> _entries = <_StackRouteEntry>[];
  bool _isSyncingFromNavigator = false;

  /// The navigator key used by this stack.
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// The active navigation path driving this stack.
  GlassNavigationPath get effectivePath => _path ?? _internalPath;

  /// The active navigation path, if any.
  GlassNavigationPath? get path => _path ?? _internalPath;

  @override
  void initState() {
    super.initState();
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
    _path = widget.path;
    effectivePath.addListener(_handlePathChanged);
    if (effectivePath.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handlePathChanged();
      });
    }
  }

  @override
  void didUpdateWidget(covariant GlassNavigationStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    var navigatorReplaced = false;
    if (oldWidget.navigatorKey != widget.navigatorKey) {
      for (final entry in _entries) {
        entry.poppedProgrammatically = true;
      }
      _entries.clear();
      _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
      navigatorReplaced = true;
    }
    final pathReplaced = oldWidget.path != widget.path;
    if (pathReplaced) {
      effectivePath.removeListener(_handlePathChanged);
      _path = widget.path;
      effectivePath.addListener(_handlePathChanged);
    }
    if (navigatorReplaced || pathReplaced) {
      // Bring the navigator in line with the new path once it has built:
      // keep the routes both paths share, pop the rest, push what is new.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reconcile();
        }
      });
    }
  }

  @override
  void dispose() {
    effectivePath.removeListener(_handlePathChanged);
    _internalPath.dispose();
    super.dispose();
  }

  void _handlePathChanged() {
    if (!mounted || _isSyncingFromNavigator) return;
    _reconcile();
  }

  /// Brings the navigator in line with [effectivePath].
  void _reconcile() {
    final nav = _navigatorKey.currentState;
    if (nav == null) return;

    final elems = effectivePath.elements;
    final targetLength = elems.length;

    var keep = 0;
    while (keep < _entries.length &&
        keep < targetLength &&
        _entries[keep].value == elems[keep]) {
      keep++;
    }

    // Pop routes the path no longer has.
    while (_entries.length > keep) {
      final entry = _entries.removeLast();
      entry.poppedProgrammatically = true;
      if (entry.route.isActive) {
        if (entry.route.isCurrent && nav.canPop()) {
          nav.pop();
        } else {
          nav.removeRoute(entry.route);
        }
      }
    }

    // Push any newly appended elements in order.
    while (_entries.length < targetLength) {
      if (!_pushValueRoute(nav, elems[_entries.length])) {
        break;
      }
    }
  }

  bool _pushValueRoute(NavigatorState nav, dynamic value) {
    GlassNavigationDestinationBuilder<dynamic>? builder =
        widget.destinations[value.runtimeType];
    builder ??= widget.destinations[dynamic] ?? widget.destinations[Object];
    if (builder == null) return false;

    final resolvedBuilder = builder;
    final route = GlassPageRoute<void>(
      transitionCornerRadius: widget.transitionCornerRadius,
      builder: (context) =>
          GlassNavigationTitleScope(child: resolvedBuilder(context, value)),
    );
    final entry = _StackRouteEntry(value, route);
    _entries.add(entry);

    nav.push<void>(route).then((_) {
      if (!mounted || entry.poppedProgrammatically) return;
      _entries.remove(entry);
      final activePath = effectivePath;
      if (activePath.length > _entries.length) {
        _isSyncingFromNavigator = true;
        try {
          activePath.pop();
        } finally {
          _isSyncingFromNavigator = false;
        }
      }
    });
    return true;
  }

  /// Pushes a destination widget directly onto the stack.
  Future<T?> push<T>(Widget destination, {double? transitionCornerRadius}) {
    final nav = _navigatorKey.currentState;
    if (nav == null) return Future.value(null);
    return nav.push<T>(
      GlassPageRoute<T>(
        transitionCornerRadius:
            transitionCornerRadius ?? widget.transitionCornerRadius,
        builder: (context) => GlassNavigationTitleScope(child: destination),
      ),
    );
  }

  /// Pops the topmost screen from the stack.
  void pop<T extends Object?>([T? result]) {
    final nav = _navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop<T>(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassNavigationStackScope(
      state: this,
      root: widget.root,
      child: GlassNavigationShell(
        enabled: widget.enabled,
        effectTransition: widget.effectTransition,
        child: Navigator(
          key: _navigatorKey,
          observers: widget.observers,
          onGenerateRoute: (settings) {
            return GlassPageRoute<void>(
              settings: settings,
              transitionCornerRadius: widget.transitionCornerRadius,
              builder: (context) {
                context
                    .dependOnInheritedWidgetOfExactType<
                      _GlassNavigationStackScope
                    >();
                return GlassNavigationTitleScope(child: widget.root);
              },
            );
          },
        ),
      ),
    );
  }
}

class _GlassNavigationStackScope extends InheritedWidget {
  const _GlassNavigationStackScope({
    required this.state,
    required this.root,
    required super.child,
  });

  final GlassNavigationStackState state;
  final Widget root;

  @override
  bool updateShouldNotify(_GlassNavigationStackScope oldWidget) =>
      state != oldWidget.state || root != oldWidget.root;
}

/// A navigational tap target providing 100% parity with SwiftUI's `NavigationLink`.
///
/// Features:
/// - Supports both declarative typed values (`value: myObject`) and explicit
///   destination builders (`destination: (context) => DetailView()`).
/// - When used without a custom [child], automatically formats as an authentic
///   iOS liquid glass row ([GlassListTile]) with title, subtitle, leading icon,
///   and trailing disclosure chevron (`CupertinoIcons.chevron_right`).
/// - Custom tap target support: wrap any arbitrary widget in a [GlassNavigationLink].
class GlassNavigationLink<T> extends StatelessWidget {
  /// Creates a [GlassNavigationLink].
  const GlassNavigationLink({
    super.key,
    this.destination,
    this.value,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.contentPadding,
    this.titleStyle,
    this.child,
    this.onTap,
    this.enabled = true,
    this.transitionCornerRadius,
  }) : assert(
         destination != null || value != null,
         'Either destination or value must be provided.',
       );

  /// Builder for the destination widget pushed when this link is tapped.
  final WidgetBuilder? destination;

  /// The typed value appended to the enclosing [GlassNavigationStack]'s path.
  final T? value;

  /// Primary title displayed if rendering standard list tile.
  final Widget? title;

  /// Secondary subtitle displayed if rendering standard list tile.
  final Widget? subtitle;

  /// Leading accessory widget (e.g. icon).
  final Widget? leading;

  /// Trailing accessory widget. Defaults to a subtle disclosure chevron.
  final Widget? trailing;

  /// Optional padding inside the tile around the content row.
  final EdgeInsetsGeometry? contentPadding;

  /// Optional text style for [title].
  final TextStyle? titleStyle;

  /// Custom widget content. If null, renders a standard [GlassListTile].
  final Widget? child;

  /// Optional additional callback executed upon tap.
  final VoidCallback? onTap;

  /// Whether this link is interactable.
  final bool enabled;

  /// Continuous superellipse corner radius applied to the pushed route's page
  /// surface while transitioning.
  ///
  /// See [GlassPageRoute.transitionCornerRadius].
  final double? transitionCornerRadius;

  void _handleTap(BuildContext context) {
    if (!enabled) return;

    onTap?.call();

    // 1. Try appending value to ambient GlassNavigationStack path
    if (value != null) {
      final stack = GlassNavigationStack.maybeOf(context);
      if (stack != null) {
        stack.effectivePath.append(value);
        return;
      }
    }

    // 2. Otherwise navigate to explicit destination or stack push
    if (destination != null) {
      final stack = GlassNavigationStack.maybeOf(context);
      if (stack != null) {
        stack.push(
          destination!(context),
          transitionCornerRadius: transitionCornerRadius,
        );
      } else {
        Navigator.of(context).push(
          GlassPageRoute<void>(
            transitionCornerRadius: transitionCornerRadius,
            builder: destination!,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(context),
        child: child!,
      );
    }

    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return GlassListTile(
      leading: leading,
      title: title ?? const SizedBox.shrink(),
      subtitle: subtitle,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      titleStyle: titleStyle,
      trailing:
          trailing ??
          Icon(
            isRtl ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
            size: 15,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
      onTap: () => _handleTap(context),
    );
  }
}

/// Convenient extension providing SwiftUI-like `.navigationTitle(...)` ergonomics.
extension GlassNavigationTitleExtension on Widget {
  /// Annotates this widget with a navigation title that drives enclosing or
  /// descendant [GlassAppBar] / [GlassAppBar.pinned] bars (when their explicit
  /// `title` is null) as well as header accessibility semantics.
  Widget navigationTitle(String title) {
    return _GlassNavigationTitle(title: title, child: this);
  }
}

/// Scope that coordinates `.navigationTitle(...)` declarations inside a page
/// or route with an enclosing [GlassScaffold] or [GlassAppBar].
class GlassNavigationTitleScope extends StatefulWidget {
  /// Creates a [GlassNavigationTitleScope].
  const GlassNavigationTitleScope({super.key, required this.child});

  /// The widget subtree within this title scope.
  final Widget child;

  /// Returns the title [ValueNotifier] from the nearest enclosing scope, if any.
  static ValueNotifier<String?>? maybeNotifierOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_InheritedNavigationTitleScope>()
        ?.notifier;
  }

  /// Resolves the active navigation title from an ancestor `.navigationTitle`
  /// wrapper, if any.
  static String? maybeTitleOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedNavigationTitle>()
        ?.title;
  }

  @override
  State<GlassNavigationTitleScope> createState() =>
      _GlassNavigationTitleScopeState();
}

class _NavigationTitleNotifier extends ValueNotifier<String?> {
  _NavigationTitleNotifier() : super(null);

  void publish(String title, {required bool Function() isActive}) {
    if (value == title) return;
    if (!hasListeners) {
      value = title;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isActive()) {
          value = title;
        }
      });
    }
  }
}

class _GlassNavigationTitleScopeState extends State<GlassNavigationTitleScope> {
  final _NavigationTitleNotifier _notifier = _NavigationTitleNotifier();

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedNavigationTitleScope(
      notifier: _notifier,
      child: widget.child,
    );
  }
}

class _InheritedNavigationTitleScope extends InheritedWidget {
  const _InheritedNavigationTitleScope({
    required this.notifier,
    required super.child,
  });

  final _NavigationTitleNotifier notifier;

  @override
  bool updateShouldNotify(_InheritedNavigationTitleScope oldWidget) =>
      notifier != oldWidget.notifier;
}

class _InheritedNavigationTitle extends InheritedWidget {
  const _InheritedNavigationTitle({required this.title, required super.child});

  final String title;

  @override
  bool updateShouldNotify(_InheritedNavigationTitle oldWidget) =>
      title != oldWidget.title;
}

class _GlassNavigationTitle extends StatefulWidget {
  const _GlassNavigationTitle({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<_GlassNavigationTitle> createState() => _GlassNavigationTitleState();
}

class _GlassNavigationTitleState extends State<_GlassNavigationTitle> {
  _NavigationTitleNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifier = context
        .getInheritedWidgetOfExactType<_InheritedNavigationTitleScope>()
        ?.notifier;
    _publishTitle(widget.title);
  }

  @override
  void didUpdateWidget(covariant _GlassNavigationTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _publishTitle(widget.title);
    }
  }

  void _publishTitle(String title) {
    final notifier = _notifier;
    if (notifier == null) return;
    notifier.publish(title, isActive: () => mounted && _notifier == notifier);
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedNavigationTitle(
      title: widget.title,
      child: Semantics(header: true, label: widget.title, child: widget.child),
    );
  }
}

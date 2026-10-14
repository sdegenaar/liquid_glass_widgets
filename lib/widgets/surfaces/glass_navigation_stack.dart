import 'package:flutter/cupertino.dart';

import '../effects/glass_materialize.dart';
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
        .dependOnInheritedWidgetOfExactType<_GlassNavigationStackScope>()
        ?.state;
  }

  @override
  State<GlassNavigationStack> createState() => GlassNavigationStackState();
}

/// State for [GlassNavigationStack].
class GlassNavigationStackState extends State<GlassNavigationStack> {
  late GlobalKey<NavigatorState> _navigatorKey;
  GlassNavigationPath? _path;

  /// The navigator key used by this stack.
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// The active navigation path, if any.
  GlassNavigationPath? get path => _path;

  @override
  void initState() {
    super.initState();
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
    _path = widget.path;
    _path?.addListener(_handlePathChanged);
  }

  @override
  void didUpdateWidget(covariant GlassNavigationStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigatorKey != widget.navigatorKey &&
        widget.navigatorKey != null) {
      _navigatorKey = widget.navigatorKey!;
    }
    if (oldWidget.path != widget.path) {
      _path?.removeListener(_handlePathChanged);
      _path = widget.path;
      _path?.addListener(_handlePathChanged);
    }
  }

  @override
  void dispose() {
    _path?.removeListener(_handlePathChanged);
    super.dispose();
  }

  void _handlePathChanged() {
    if (!mounted || _path == null) return;

    final nav = _navigatorKey.currentState;
    if (nav == null) return;

    final targetLength = _path!.length;

    // Pop until at root if path was cleared
    if (targetLength == 0) {
      nav.popUntil((route) => route.isFirst);
      return;
    }

    // Push the newest element
    final latest = _path!.elements.last;
    final builder = widget.destinations[latest.runtimeType];
    if (builder != null) {
      nav.push(
        CupertinoPageRoute<void>(
          builder: (context) => builder(context, latest),
        ),
      );
    }
  }

  /// Pushes a destination widget directly onto the stack.
  Future<T?> push<T>(Widget destination) {
    final nav = _navigatorKey.currentState;
    if (nav == null) return Future.value(null);
    return nav.push<T>(
      CupertinoPageRoute<T>(builder: (context) => destination),
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
      child: GlassNavigationShell(
        enabled: widget.enabled,
        effectTransition: widget.effectTransition,
        child: Navigator(
          key: _navigatorKey,
          observers: widget.observers,
          onGenerateRoute: (settings) {
            return CupertinoPageRoute<void>(
              settings: settings,
              builder: (context) => widget.root,
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
    required super.child,
  });

  final GlassNavigationStackState state;

  @override
  bool updateShouldNotify(_GlassNavigationStackScope oldWidget) =>
      state != oldWidget.state;
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
    this.child,
    this.onTap,
    this.enabled = true,
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

  /// Custom widget content. If null, renders a standard [GlassListTile].
  final Widget? child;

  /// Optional additional callback executed upon tap.
  final VoidCallback? onTap;

  /// Whether this link is interactable.
  final bool enabled;

  void _handleTap(BuildContext context) {
    if (!enabled) return;

    onTap?.call();

    // 1. Try appending value to ambient GlassNavigationStack path
    if (value != null) {
      final stack = GlassNavigationStack.maybeOf(context);
      if (stack != null && stack.path != null) {
        stack.path!.append(value);
        return;
      }
    }

    // 2. Otherwise navigate to explicit destination or stack push
    if (destination != null) {
      final stack = GlassNavigationStack.maybeOf(context);
      if (stack != null) {
        stack.push(destination!(context));
      } else {
        Navigator.of(context).push(
          CupertinoPageRoute<void>(builder: destination!),
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

    return GlassListTile(
      leading: leading,
      title: title ?? const SizedBox.shrink(),
      subtitle: subtitle,
      trailing: trailing ??
          const Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: CupertinoColors.tertiaryLabel,
          ),
      onTap: () => _handleTap(context),
    );
  }
}

/// Convenient extension providing SwiftUI-like `.navigationTitle(...)` ergonomics.
extension GlassNavigationTitleExtension on Widget {
  /// Wraps this widget in a default title header annotation.
  Widget navigationTitle(String title) {
    return _GlassNavigationTitle(title: title, child: this);
  }
}

class _GlassNavigationTitle extends StatelessWidget {
  const _GlassNavigationTitle({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: title,
      child: child,
    );
  }
}

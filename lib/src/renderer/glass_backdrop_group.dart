import 'package:flutter/widgets.dart';

/// Premium glass surfaces that read the backdrop together, in one pass.
///
/// On Impeller every [BackdropFilter] ends the render pass and copies the
/// whole screen before it runs, however small the glass. Premium glass has
/// two of these per surface (the blur, or the iOS 27 frost with its weight,
/// and the refraction shader), so six surfaces cost a dozen full-screen
/// copies a frame. Inside a [GlassBackdropGroup] the surfaces share one
/// backdrop read for the blur and the frost, and where their filters match
/// (the same settings) the engine runs that filter once for all of them.
/// Only the refraction pass stays per surface. This is the same idea as
/// SwiftUI's `GlassEffectContainer`, which renders its glass "together,
/// improving rendering performance".
///
/// It suits glass that sits side by side over content, like the controls of
/// a navigation bar, a toolbar or a tab bar:
///
/// ```dart
/// GlassBackdropGroup(
///   child: GlassAppBar(actions: [...]),
/// )
/// ```
///
/// Two things change for the glass inside, which is why it's opt-in:
///
/// - **Glass doesn't see glass.** The shared read happens when the first
///   surface of the group paints. A surface that lies over another surface
///   of the same group shows the content behind both instead of the glass
///   below it, and so does anything painted between the two. Keep
///   overlapping or nested glass, like buttons on a glass sheet or card, out
///   of the group.
/// - **The frost doesn't see what the glass paints inside itself.** The
///   frost's cloud is blurred from the shared read, so content a glass
///   surface draws into its own glass layer isn't part of it. The sharp
///   content itself is unaffected.
///
/// Without Impeller (web, Skia) the group has no effect.
class GlassBackdropGroup extends StatefulWidget {
  /// Lets the premium glass in [child] read the backdrop together.
  const GlassBackdropGroup({required this.child, super.key});

  /// The subtree whose premium glass shares the backdrop read.
  final Widget child;

  /// The key the premium glass under [context] shares its backdrop read
  /// through, or null outside a [GlassBackdropGroup].
  static BackdropKey? keyOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_GlassBackdropGroupScope>()
      ?.backdropKey;

  @override
  State<GlassBackdropGroup> createState() => _GlassBackdropGroupState();
}

class _GlassBackdropGroupState extends State<GlassBackdropGroup> {
  final BackdropKey _key = BackdropKey();

  @override
  Widget build(BuildContext context) =>
      _GlassBackdropGroupScope(backdropKey: _key, child: widget.child);
}

class _GlassBackdropGroupScope extends InheritedWidget {
  const _GlassBackdropGroupScope({
    required this.backdropKey,
    required super.child,
  });

  final BackdropKey backdropKey;

  @override
  bool updateShouldNotify(_GlassBackdropGroupScope oldWidget) =>
      backdropKey != oldWidget.backdropKey;
}

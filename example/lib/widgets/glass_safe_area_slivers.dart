import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Occupies the top system/chrome inset at the start of a [CustomScrollView].
///
/// A [CustomScrollView] does not consume [MediaQuery] padding automatically the
/// way [ListView] does, so examples add this sliver explicitly unless their
/// first sliver is a [GlassLargeTitle], which owns the top inset internally.
///
/// The inset is read in the sliver's own context. This matters because a
/// [GlassScaffold] publishes its bar-aware padding only inside its body
/// subtree; reading from the page's outer build context sees the platform
/// inset alone.
Widget glassTopSafeAreaSliver() {
  return SliverToBoxAdapter(
    child: Builder(
      builder: (context) => SizedBox(
        height: MediaQuery.paddingOf(context).top,
      ),
    ),
  );
}

/// Occupies the bottom system/chrome inset at the end of a [CustomScrollView].
///
/// The inset is read in the sliver's own context for the same reason as
/// [glassTopSafeAreaSliver].
Widget glassBottomSafeAreaSliver() {
  return SliverToBoxAdapter(
    child: Builder(
      builder: (context) => SizedBox(
        height: MediaQuery.paddingOf(context).bottom,
      ),
    ),
  );
}

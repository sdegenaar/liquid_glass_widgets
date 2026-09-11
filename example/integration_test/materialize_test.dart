// On-device verification for the materialize entrance/exit transition.
//
// The effect dissolves glass through the shader's own visibility uniforms, so
// it only means anything where those uniforms are actually uploaded — a
// headless `flutter test` run reports no shader filter support and renders the
// fallback. This drives the real transition on a simulator/device and proves
// the glass ramps rather than switching, and that it settles inert.
//
//   cd example && flutter test integration_test/materialize_test.dart -d <device>

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/renderer/glass_materialize_scope.dart';
import 'package:liquid_glass_widgets/widgets/effects/shared/glass_materialize_effect.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/glass_nav_pinned_host.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    expect(
      ui.ImageFilter.isShaderFilterSupported,
      isTrue,
      reason: 'This device reports no shader filter support, so glass would '
          'render through the frosted fallback. Run it on Impeller.',
    );
  });

  /// The scope a glass surface below the pinned capsule resolves against.
  GlassMaterializeScope? capsuleScope(WidgetTester tester) {
    final effects = find.descendant(
      of: find.byType(GlassNavPinnedHost),
      matching: find.byType(GlassMaterializeEffect),
    );
    for (final element in effects.evaluate()) {
      if ((element.widget as GlassMaterializeEffect).alignment ==
          Alignment.centerRight) {
        return tester.widget<GlassMaterializeScope>(
          find.descendant(
            of: find.byWidget(element.widget),
            matching: find.byType(GlassMaterializeScope),
          ),
        );
      }
    }
    return null;
  }

  testWidgets('a capsule with nowhere to go dissolves through the shader',
      (tester) async {
    runApp(LiquidGlassWidgets.wrap(
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => GlassNavigationShell(child: child!),
        home: const _Root(),
      ),
    ));
    await tester.pumpAndSettle();

    // At rest the effect is mounted but inert, so the capsule's glass shell is
    // never remounted when a transition starts.
    final resting = capsuleScope(tester);
    expect(resting, isNotNull);
    expect(resting!.glassProgress, 1.0);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(CupertinoPageRoute<void>(builder: (_) => const _Detail()));
    await tester.pump();

    // Walk the push and collect the glass channel each frame.
    final samples = <double>[];
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      final scope = capsuleScope(tester);
      if (scope == null) break;
      samples.add(scope.glassProgress);
    }

    expect(
      samples.where((v) => v > 0.0 && v < 1.0),
      isNotEmpty,
      reason: 'the capsule must dissolve through intermediate values, not '
          'switch off at the midpoint',
    );
    expect(
      samples,
      orderedEquals(samples.toList()..sort((a, b) => b.compareTo(a))),
      reason: 'the dissolve must be monotone across the push',
    );

    await tester.pumpAndSettle();
    expect(capsuleScope(tester), isNull, reason: 'gone once the push settles');
  });

  testWidgets('the settled glass carries no leftover blur or fade',
      (tester) async {
    runApp(LiquidGlassWidgets.wrap(
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => GlassNavigationShell(child: child!),
        home: const _Root(),
      ),
    ));
    await tester.pumpAndSettle();

    // resolveSettings returns its input instance when the scope is at rest;
    // anything else means resting glass is paying for the transition.
    final scope = capsuleScope(tester)!;
    const base = LiquidGlassSettings(blur: 5, thickness: 20);
    expect(scope.glassProgress, 1.0);
    expect(scope.contentSigma, 0.0);
    expect(scope.contentOpacity, 1.0);

    final element = find.byWidget(scope).evaluate().single;
    expect(
      identical(GlassMaterializeScope.resolveSettings(element, base), base),
      isTrue,
    );
  });
}

/// A root screen with a trailing action and no back button.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) => GlassScaffold(
        appBar: GlassAppBar.pinned(
          actions: [
            GlassBarItem.icon(
              icon: const Icon(CupertinoIcons.search),
              onTap: () {},
            ),
          ],
        ),
        body: const SizedBox.expand(),
      );
}

/// A destination with a back button and no actions — the capsule has nowhere
/// to morph to, so it must dissolve.
class _Detail extends StatelessWidget {
  const _Detail();

  @override
  Widget build(BuildContext context) => const GlassScaffold(
        appBar: GlassAppBar.pinned(title: Text('Trending'), actions: []),
        body: SizedBox.expand(),
      );
}

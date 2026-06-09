// Coverage-targeted tests for the platformViewBackdrop feature.
// Targets:
//   - adaptive_glass.dart: the canUsePremiumShader condition operands
//     (!platformViewBackdrop / quality / _canUseImpeller) and the grouped()
//     platformViewBackdrop pass-through.
//   - searchable_bottom_bar_internal.dart: the moving indicator's backgroundKey
//     `_iconLayerKey` branch, only taken when platformViewBackdrop is true.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: LiquidGlassWidgets.wrap(child: child)),
    );

final _tabs = [
  const GlassBottomBarTab(label: 'Home', icon: Icon(Icons.home)),
  const GlassBottomBarTab(label: 'Map', icon: Icon(Icons.map)),
];

void main() {
  group('platformViewBackdrop', () {
    testWidgets(
        'premium AdaptiveGlass evaluates the full canUsePremiumShader condition',
        (tester) async {
      // platformViewBackdrop defaults false → the local checks (!kIsWeb,
      // !platformViewBackdrop, quality == premium) all evaluate, then
      // _canUseImpeller — so every operand line executes under `flutter test`.
      await tester.pumpWidget(_wrap(const SizedBox(
        width: 200,
        height: 100,
        child: AdaptiveGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: 20),
          settings: LiquidGlassSettings(blur: 5),
          quality: GlassQuality.premium,
          child: SizedBox.expand(),
        ),
      )));
      await tester.pump();
      expect(find.byType(AdaptiveGlass), findsOneWidget);
    });

    testWidgets('AdaptiveGlass.grouped forwards platformViewBackdrop',
        (tester) async {
      await tester.pumpWidget(_wrap(
        AdaptiveGlass.grouped(
          shape: const LiquidRoundedSuperellipse(borderRadius: 20),
          quality: GlassQuality.premium,
          platformViewBackdrop: true,
          child: const SizedBox(width: 200, height: 100),
        ),
      ));
      await tester.pump();
      expect(find.byType(AdaptiveGlass), findsWidgets);
    });

    testWidgets(
        'GlassSearchableBottomBar(platformViewBackdrop) refracts the icon layer',
        (tester) async {
      // Exercises the indicator's `backgroundKey: platformViewBackdrop ?
      // _iconLayerKey : widget.backgroundKey` branch plus the background
      // grouped() pass-throughs and the search pill.
      await tester.pumpWidget(createTestApp(
        child: SizedBox(
          height: 90,
          width: 400,
          child: GlassSearchableBottomBar(
            tabs: _tabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
            quality: GlassQuality.premium,
            platformViewBackdrop: true,
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(GlassSearchableBottomBar), findsOneWidget);
    });
  });
}

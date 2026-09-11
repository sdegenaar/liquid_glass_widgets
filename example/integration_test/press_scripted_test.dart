// On-device run of the GlassButton press: still, touch-down, hold, drag down,
// drag back, release, pumped in real time so it doubles as the filming script
// — record the simulator with `xcrun simctl io <udid> recordVideo` while it
// runs and measure the frames the same way as the native reference. Between
// the beats it checks the settled press is the native growth for the button's
// size, and that the release comes back to rest.
//
//   cd example && flutter test integration_test/press_scripted_test.dart -d <device>

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/engine/stretch.dart';
import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  /// The uniform scale RawLiquidStretch applies to its child.
  double scaleOf(WidgetTester tester) {
    final stretch =
        tester.renderObject<RenderProxyBox>(find.byType(RawLiquidStretch));
    return stretch.child!.getTransformTo(stretch).entry(0, 0);
  }

  Future<void> run(
    WidgetTester tester,
    Widget button, {
    required double longestSide,
  }) async {
    await LiquidGlassWidgets.initialize();
    await tester.pumpWidget(LiquidGlassWidgets.wrap(
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: CupertinoPageScaffold(
          child: Stack(
            children: [
              const Positioned.fill(child: _Backdrop()),
              AdaptiveLiquidGlassLayer(
                settings: RecommendedGlassSettings.standard,
                child: Center(child: button),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1500));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(GlassButton)));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(
      scaleOf(tester),
      closeTo(1 + 17 / longestSide, 0.01),
      reason: 'settled, the press is the native growth for this size',
    );

    for (var i = 0; i < 15; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 1500));
    for (var i = 0; i < 15; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 800));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(scaleOf(tester), closeTo(1.0, 0.001), reason: 'back at rest');
  }

  testWidgets('circle: press · hold · drag · release', (tester) async {
    await run(
      tester,
      GlassButton(
        icon: const Icon(CupertinoIcons.plus),
        iconSize: 22,
        width: 56,
        height: 56,
        quality: GlassQuality.premium,
        label: 'Add',
        onTap: () {},
      ),
      longestSide: 56,
    );
  });

  testWidgets('pill: press · hold · drag · release', (tester) async {
    await run(
      tester,
      GlassButton.custom(
        width: 132,
        height: 44,
        shape: const LiquidRoundedRectangle(borderRadius: 22),
        quality: GlassQuality.premium,
        label: 'Label',
        onTap: () {},
        child: const Text(
          'Label',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      longestSide: 132,
    );
  });
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFBFD4F2), Color(0xFFE9C7D8), Color(0xFFF7D9A8)],
        ),
      ),
      child: Column(
        children: List.generate(
          16,
          (i) => Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(
                9,
                (j) => Expanded(
                  child: ColoredBox(
                    color: (i + j).isEven
                        ? const Color(0x22000000)
                        : const Color(0x00000000),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

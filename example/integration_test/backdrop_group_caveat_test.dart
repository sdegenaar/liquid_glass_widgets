// Shows what GlassBackdropGroup changes for glass that lies over other glass
// of the same group, for screenshots in the docs. Each variant is held on
// screen for a few seconds; record the device screen while it runs:
//
//   flutter drive --profile --no-dds -d <device> \
//     --driver=test_driver/perf_glass_driver.dart \
//     --target=integration_test/backdrop_group_caveat_test.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class _Scene extends StatelessWidget {
  const _Scene({super.key, required this.grouped, required this.tinted});

  final bool grouped;

  /// A red card, so where it is missing from the glass above shows plainly.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    const settings = LiquidGlassSettings.ios27Light;
    final cardSettings = tinted
        ? settings.copyWith(glassColor: const Color(0xCCFF3B30))
        : settings;
    final glass = Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/mountain_landscape.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // A glass card, and a glass button lying half over it.
        Positioned(
          left: 32,
          top: 180,
          width: 240,
          height: 150,
          child: GlassCard(
            useOwnLayer: true,
            quality: GlassQuality.premium,
            settings: cardSettings,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 230,
          top: 290,
          child: GlassIconButton(
            icon: const Icon(CupertinoIcons.heart_fill, color: Colors.black),
            onPressed: () {},
            useOwnLayer: true,
            quality: GlassQuality.premium,
            settings: settings,
          ),
        ),
        // A glass card lying over the tab bar, like a sheet's edge.
        Positioned(
          left: 60,
          right: 60,
          bottom: 70,
          height: 90,
          child: GlassCard(
            useOwnLayer: true,
            quality: GlassQuality.premium,
            settings: cardSettings,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: GlassTabBar.bottom(
              tabs: const [
                GlassTab(icon: Icon(CupertinoIcons.house), label: 'Home'),
                GlassTab(icon: Icon(CupertinoIcons.news), label: 'News'),
                GlassTab(icon: Icon(CupertinoIcons.person), label: 'Profile'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              quality: GlassQuality.premium,
              settings: settings,
            ),
          ),
        ),
        Positioned(
          left: 24,
          top: 70,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.black,
            child: Text(
              '${grouped ? 'GlassBackdropGroup' : 'no group'}'
              '${tinted ? ', red card' : ''}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ),
      ],
    );
    return grouped ? GlassBackdropGroup(child: glass) : glass;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('glass over glass, with and without a group', (tester) async {
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
    for (final (grouped, tinted) in [
      (false, false),
      (true, false),
      (false, true),
      (true, true),
    ]) {
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: _Scene(
            key: ValueKey((grouped, tinted)),
            grouped: grouped,
            tinted: tinted,
          ),
        ),
      ));
      final end = DateTime.now().add(const Duration(seconds: 8));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
  });
}

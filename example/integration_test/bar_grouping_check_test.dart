// Shows that the bars' default GlassBackdropGroup changes nothing on screen,
// for screenshots in the pull request. Each scene is held for a few seconds;
// record the device screen while it runs:
//
//   flutter drive --profile --no-dds -d <device> \
//     --driver=test_driver/perf_glass_driver.dart \
//     --target=integration_test/bar_grouping_check_test.dart
//
// 1. A tab bar with an extra button, its indicator dragged half way between
//    two tabs: the indicator lies over the pill and stays out of the group.
// 2. An app bar with three buttons.
// 3. Two glass buttons in one group, one of them fading at half opacity:
//    the fading one is drawn into a pass of its own and leaves the group.
// Each with groupBackdrop on and off, side by side in time.
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _settings = LiquidGlassSettings.ios27Light;

class _Scene extends StatelessWidget {
  const _Scene({super.key, required this.grouped, required this.label});

  final bool grouped;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fading = Opacity(
      opacity: 0.5,
      child: GlassIconButton(
        icon: const Icon(CupertinoIcons.star_fill, color: Colors.black),
        onPressed: () {},
        useOwnLayer: true,
        quality: GlassQuality.premium,
        settings: _settings,
      ),
    );
    final steady = GlassIconButton(
      icon: const Icon(CupertinoIcons.heart_fill, color: Colors.black),
      onPressed: () {},
      useOwnLayer: true,
      quality: GlassQuality.premium,
      settings: _settings,
    );
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/mountain_landscape.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: GlassAppBar(
              groupBackdrop: grouped,
              title: Text(label),
              actions: [
                for (final icon in const [
                  CupertinoIcons.search,
                  CupertinoIcons.bell,
                  CupertinoIcons.add,
                ])
                  GlassIconButton(
                    icon: Icon(icon, color: Colors.black),
                    onPressed: () {},
                    useOwnLayer: true,
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 40,
          top: 260,
          child: GlassBackdropGroup(
            enabled: grouped,
            child: Row(children: [steady, const SizedBox(width: 24), fading]),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: GlassTabBar.bottom(
              key: const ValueKey('tabs'),
              groupBackdrop: grouped,
              tabs: const [
                GlassTab(icon: Icon(CupertinoIcons.house), label: 'Home'),
                GlassTab(icon: Icon(CupertinoIcons.news), label: 'News'),
                GlassTab(icon: Icon(CupertinoIcons.music_note), label: 'Music'),
                GlassTab(icon: Icon(CupertinoIcons.person), label: 'Profile'),
              ],
              extraButton: GlassTabBarExtraButton(
                icon: const Icon(CupertinoIcons.search),
                label: 'Search',
                onTap: () {},
              ),
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      ],
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bars look the same with and without their group', (
    tester,
  ) async {
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
    for (final grouped in [true, false]) {
      final label = grouped ? 'grouped (default)' : 'groupBackdrop: false';
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: _Scene(
              key: ValueKey(grouped),
              grouped: grouped,
              label: label,
            ),
          ),
        ),
      );
      await _hold(tester, const Duration(seconds: 3));
      // Drag the indicator half way from the first tab to the second and
      // hold it there: the glass indicator lies over the pill.
      final tabs = find.byKey(const ValueKey('tabs'));
      final box = tester.getRect(tabs);
      final gesture = await tester.startGesture(
        Offset(box.left + box.width * 0.12, box.center.dy),
      );
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(Offset(box.width * 0.012, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _hold(tester, const Duration(seconds: 4));
      await gesture.up();
      await _hold(tester, const Duration(seconds: 2));
    }
  });
}

Future<void> _hold(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

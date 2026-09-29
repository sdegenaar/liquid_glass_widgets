// Frame timings of premium glass over moving content, for comparing glass
// settings with each other on a real device.
//
// Run in profile mode on a physical device (the iOS simulator only runs debug
// builds, and its timings say little about a phone GPU):
//
//   cd example
//   flutter drive --profile --no-dds --endless-trace-buffer -d <device> \
//     --driver=test_driver/perf_glass_driver.dart \
//     --target=integration_test/perf_glass_test.dart
//
// The driver writes one summary per scene and configuration to
// build/glass-perf/, including the raster thread times and, on Metal, the GPU
// time Impeller's GPUTracer records for every frame.
//
// Optional defines:
//   --dart-define=BENCH_ROUNDS=3        rounds over all configurations
//   --dart-define=BENCH_DARK=true       dark appearance (ios27Dark)
//   --dart-define=BENCH_CONFIGS=a,b     only these configurations
//   --dart-define=BENCH_SCENES=scroll   only these scenes
//   --dart-define=BENCH_PAUSE_MS=0      pause between scenes (for recordings)
//   --dart-define=BENCH_OVERLAY=true    Flutter's performance overlay (recordings)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/flutter_driver.dart' as driver
    show Timeline, TimelineSummary;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _rounds = int.fromEnvironment('BENCH_ROUNDS', defaultValue: 3);
const _dark = bool.fromEnvironment('BENCH_DARK');
const _onlyConfigs = String.fromEnvironment('BENCH_CONFIGS');
const _onlyScenes = String.fromEnvironment('BENCH_SCENES');
const _pauseMs = int.fromEnvironment('BENCH_PAUSE_MS', defaultValue: 0);
const _overlay = bool.fromEnvironment('BENCH_OVERLAY');

/// A glass configuration under test.
class _Config {
  const _Config(this.name, this.quality, this.settings, {this.group = false});

  final String name;
  final GlassQuality quality;
  final LiquidGlassSettings settings;

  /// Whether the glass reads the backdrop together (GlassBackdropGroup).
  final bool group;
}

LiquidGlassSettings get _ios27 =>
    _dark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light;

final _configs = <_Config>[
  const _Config('standard', GlassQuality.standard, LiquidGlassSettings()),
  const _Config('ios26', GlassQuality.premium, LiquidGlassSettings()),
  _Config('ios27_nofrost', GlassQuality.premium, _ios27.copyWith(frost: 0)),
  _Config(
    'ios27_weight1',
    GlassQuality.premium,
    _ios27.copyWith(frostWeight: 1),
  ),
  _Config('ios27', GlassQuality.premium, _ios27),
  const _Config(
    'ios26_group',
    GlassQuality.premium,
    LiquidGlassSettings(),
    group: true,
  ),
  _Config('ios27_group', GlassQuality.premium, _ios27, group: true),
]
    .where(
        (c) => _onlyConfigs.isEmpty || _onlyConfigs.split(',').contains(c.name))
    .toList();

bool _runs(String scene) =>
    _onlyScenes.isEmpty || _onlyScenes.split(',').contains(scene);

GlassThemeSettings _themeSettings(LiquidGlassSettings s) => GlassThemeSettings(
      glassColor: s.glassColor,
      thickness: s.thickness,
      blur: s.blur,
      blurWeight: s.blurWeight,
      frost: s.frost,
      frostOpacity: s.frostOpacity,
      frostClamp: s.frostClamp,
      frostWeight: s.frostWeight,
      chromaticAberration: s.chromaticAberration,
      lightAngle: s.lightAngle,
      lightIntensity: s.lightIntensity,
      ambientStrength: s.ambientStrength,
      fresnelStrength: s.fresnelStrength,
      refractiveIndex: s.refractiveIndex,
      saturation: s.saturation,
      specularSharpness: s.specularSharpness,
      edgeAbsorption: s.edgeAbsorption,
      rimShade: s.rimShade,
      rimShadeEnds: s.rimShadeEnds,
      rimLight: s.rimLight,
      lensModel: s.lensModel,
    );

const _images = [
  'assets/news_images/ai_mit.jpg',
  'assets/news_images/apple_bloomberg.jpg',
  'assets/news_images/climate_reuters.jpg',
  'assets/news_images/markets_wsj.jpg',
  'assets/news_images/science_nature.jpg',
  'assets/news_images/soccer_bbc.jpg',
  'assets/news_images/spacex_verge.jpg',
];

/// The bench screen: a photo and text list scrolling under an app bar with
/// three icon buttons, a floating button and a bottom tab bar, all glass.
/// With [cards], every row of the list is itself a glass card, so glass
/// moves with the content.
class _BenchScreen extends StatelessWidget {
  const _BenchScreen({super.key, required this.config, required this.cards});

  final _Config config;
  final bool cards;

  @override
  Widget build(BuildContext context) {
    final ink = _dark ? Colors.white : Colors.black;
    return Scaffold(
      backgroundColor:
          _dark ? const Color(0xFF101014) : const Color(0xFFF4F2EE),
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: GlassAppBar(
            title: Text(config.name, style: TextStyle(color: ink)),
            actions: [
              for (final icon in const [
                CupertinoIcons.search,
                CupertinoIcons.bell,
                CupertinoIcons.add,
              ])
                GlassIconButton(
                  icon: Icon(icon, color: ink),
                  onPressed: () {},
                  useOwnLayer: true,
                ),
            ],
          ),
        ),
      ),
      body: ListView.builder(
        key: const ValueKey('bench-list'),
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 140),
        itemCount: 200,
        itemBuilder: (context, i) {
          final row = Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _images[i % _images.length],
                  width: 88,
                  height: 64,
                  fit: BoxFit.cover,
                  cacheWidth: 264,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Headline number $i with a longer title that wraps',
                      maxLines: 2,
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Source · ${i % 12 + 1} min read',
                      style: TextStyle(color: ink.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ],
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: cards
                ? GlassCard(
                    useOwnLayer: true,
                    padding: const EdgeInsets.all(10),
                    child: row,
                  )
                : row,
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: GlassIconButton(
          icon: Icon(CupertinoIcons.pencil, color: ink),
          onPressed: () {},
          useOwnLayer: true,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: GlassTabBar.bottom(
          tabs: const [
            GlassTab(icon: Icon(CupertinoIcons.house), label: 'Home'),
            GlassTab(icon: Icon(CupertinoIcons.news), label: 'News'),
            GlassTab(icon: Icon(CupertinoIcons.person), label: 'Profile'),
          ],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
      ),
    );
  }
}

Widget _app(_Config config, {required bool cards}) {
  final variant = GlassThemeVariant(
    settings: _themeSettings(config.settings),
    quality: config.quality,
  );
  final app = LiquidGlassWidgets.wrap(
    theme: GlassThemeData(light: variant, dark: variant),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: _overlay,
      theme: ThemeData(
        brightness: _dark ? Brightness.dark : Brightness.light,
      ),
      home: _BenchScreen(
        key: ValueKey('${config.name}-$cards'),
        config: config,
        cards: cards,
      ),
    ),
  );
  return config.group ? GlassBackdropGroup(child: app) : app;
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _fling(WidgetTester tester, double dy) async {
  await tester.fling(
    find.byKey(const ValueKey('bench-list')),
    Offset(0, -dy),
    2500,
    warnIfMissed: false,
  );
  await _pumpFor(tester, const Duration(milliseconds: 1500));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Real frames from the engine: with the default policy the test drives the
  // frames itself, and those never reach the rasterizer.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('glass frame timings', (tester) async {
    // The monitor reports sustained over-budget frames as a FlutterError,
    // which fails a test; here slow frames are the measurement.
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);

    Future<void> scene(String name, _Config config, int round,
        {required bool cards, required Future<void> Function() action}) async {
      await tester.pumpWidget(_app(config, cards: cards));
      await _pumpFor(tester, const Duration(milliseconds: 1500));
      // Warm-up outside the measurement: first use of every shader and image.
      await _fling(tester, 400);
      await _fling(tester, -400);
      // Frame build (Dart), raster and GPU (Embedder) events, summarized
      // here so only the numbers travel back to the driver. Run with
      // --endless-trace-buffer: a scene is more than the ring buffer holds.
      final timeline = await binding.traceTimeline(
        action,
        streams: const ['Dart', 'Embedder'],
      );
      final summary = driver.TimelineSummary.summarize(
        driver.Timeline.fromJson(timeline.toJson()),
      ).summaryJson
        ..removeWhere((key, value) => value is List);
      (binding.reportData ??= {})['$name|${config.name}|$round'] = summary;
      if (_pauseMs > 0) {
        await _pumpFor(tester, const Duration(milliseconds: _pauseMs));
      }
    }

    for (var round = 0; round < _rounds; round++) {
      // Rotate the order every round, so drift in device temperature doesn't
      // always land on the same configuration.
      final order = [
        ..._configs.skip(round % _configs.length),
        ..._configs.take(round % _configs.length),
      ];
      for (final config in order) {
        if (_runs('scroll')) {
          await scene('scroll', config, round, cards: false, action: () async {
            for (var i = 0; i < 4; i++) {
              await _fling(tester, 1400);
              await _fling(tester, -1400);
            }
          });
        }
        if (_runs('cards')) {
          await scene('cards', config, round, cards: true, action: () async {
            for (var i = 0; i < 3; i++) {
              await _fling(tester, 1400);
              await _fling(tester, -1400);
            }
          });
        }
        if (_runs('modal')) {
          await scene('modal', config, round, cards: false, action: () async {
            final context = tester.element(find.byType(ListView));
            for (var i = 0; i < 3; i++) {
              GlassModalSheet.show<void>(
                context: context,
                settings: config.settings,
                quality: config.quality,
                builder: (context) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Sheet'),
                ),
              );
              await _pumpFor(tester, const Duration(milliseconds: 1200));
              Navigator.of(context).pop();
              await _pumpFor(tester, const Duration(milliseconds: 900));
            }
          });
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 40)));
}

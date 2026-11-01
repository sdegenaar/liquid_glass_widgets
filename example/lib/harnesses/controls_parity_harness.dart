// =============================================================================
// Dedicated Controls Parity Harness (iOS 27 vs Classic)
// =============================================================================
//
// Flutter counterpart to `tools/parity/ios_reference/ControlsParityApp.swift`.
// Run with:
//   cd example && flutter run -t lib/harnesses/controls_parity_harness.dart
//
// Features:
// - Live top-bar toggle between `GlassStyle.ios27` and `GlassStyle.classic`
//   via a single `GlassThemeData(style: _style)` setting!
// - Live background switcher (`Solid` / `Vivid` / `Stripes`)
// - Live Light / Dark appearance toggle
// - Side-by-side calibration layout for:
//   1. `GlassSegmentedControl`
//   2. `GlassSwitch` (On & Off)
//   3. `GlassSlider` (Continuous & Stepped)
//   4. `GlassButton` / `GlassIconButton`
//   5. `GlassSearchBar`
//   6. `GlassTabBar.bottom`
// =============================================================================

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(const ControlsParityHarnessApp());
}

class ControlsParityHarnessApp extends StatefulWidget {
  const ControlsParityHarnessApp({super.key});

  @override
  State<ControlsParityHarnessApp> createState() =>
      _ControlsParityHarnessAppState();
}

class _ControlsParityHarnessAppState extends State<ControlsParityHarnessApp> {
  bool _isDark = false;
  GlassStyle _style = GlassStyle.ios27;
  String _bgMode = 'solid'; // 'solid' | 'vivid' | 'stripes'
  int _selectedTab = 0;

  int _segmentIndex = 0;
  bool _switchOn = true;
  bool _switchOff = false;
  double _sliderContinuous = 0.50;
  double _sliderDiscrete = 0.75;

  static const _segments = [
    GlassSegment(label: 'Day'),
    GlassSegment(label: 'Week'),
    GlassSegment(label: 'Month'),
  ];

  void _cycleBgMode() {
    setState(() {
      switch (_bgMode) {
        case 'solid':
          _bgMode = 'vivid';
        case 'vivid':
          _bgMode = 'stripes';
        default:
          _bgMode = 'solid';
      }
    });
  }

  Widget _buildBackdrop() {
    if (_bgMode == 'vivid') {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(38, 115, 242, 1.0),
              Color.fromRGBO(140, 64, 230, 1.0),
              Color.fromRGBO(242, 77, 115, 1.0),
            ],
          ),
        ),
        child: SizedBox.expand(),
      );
    }
    if (_bgMode == 'stripes') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final stripeHeight = constraints.maxHeight / 24;
          return Column(
            children: List.generate(24, (idx) {
              final color = idx.isEven
                  ? (_isDark
                      ? const Color(0xFF383838)
                      : const Color(0xFFD1D1D1))
                  : (_isDark ? CupertinoColors.black : CupertinoColors.white);
              return Container(
                width: double.infinity,
                height: stripeHeight,
                color: color,
              );
            }),
          );
        },
      );
    }
    return ColoredBox(
      color: _isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      child: const SizedBox.expand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = GlassThemeData(
      style: _style,
      brightness: _isDark ? Brightness.dark : Brightness.light,
    );

    final surfaceStyle =
        _bgMode == 'solid' ? GlassSurfaceStyle.solid : GlassSurfaceStyle.glass;

    final labelColor = _isDark ? CupertinoColors.white : CupertinoColors.black;
    final secondaryColor =
        _isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: _isDark ? Brightness.dark : Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: GlassTheme(
        data: themeData,
        child: GlassScaffold(
          background: _buildBackdrop(),
          appBar: GlassAppBar(
            title: const Text('Controls Parity'),
            leading: GlassButton.custom(
              width: 72,
              height: 36,
              shape: const LiquidRoundedSuperellipse(borderRadius: 18),
              useOwnLayer: true,
              quality: GlassQuality.premium,
              onTap: () {
                setState(() {
                  _style = _style == GlassStyle.ios27
                      ? GlassStyle.classic
                      : GlassStyle.ios27;
                });
              },
              child: Text(
                _style == GlassStyle.ios27 ? 'iOS 27' : 'Classic',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            actions: [
              GlassButton.custom(
                width: 72,
                height: 36,
                shape: const LiquidRoundedSuperellipse(borderRadius: 18),
                useOwnLayer: true,
                quality: GlassQuality.premium,
                onTap: _cycleBgMode,
                child: Text(
                  _bgMode[0].toUpperCase() + _bgMode.substring(1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: Icon(
                  _isDark
                      ? CupertinoIcons.sun_max_fill
                      : CupertinoIcons.moon_fill,
                  color: _isDark
                      ? CupertinoColors.systemYellow
                      : CupertinoColors.systemIndigo,
                  size: 18,
                ),
                size: 36,
                useOwnLayer: true,
                quality: GlassQuality.premium,
                onPressed: () => setState(() => _isDark = !_isDark),
              ),
            ],
          ),
          bottomBar: GlassTabBar.bottom(
            selectedIndex: _selectedTab,
            onTabSelected: (i) => setState(() => _selectedTab = i),
            selectedIconColor: CupertinoColors.systemBlue.resolveFrom(context),
            selectedLabelStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemBlue.resolveFrom(context),
            ),
            tabs: const [
              GlassTab(
                label: 'Controls',
                icon: Icon(CupertinoIcons.slider_horizontal_3),
              ),
              GlassTab(
                label: 'Surfaces',
                icon: Icon(CupertinoIcons.layers_alt_fill),
              ),
              GlassTab(
                label: 'Lenses',
                icon: Icon(CupertinoIcons.sparkles),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 110, 16, 120),
              children: [
                GlassSearchBar(
                  placeholder: 'Search controls',
                  surfaceStyle: surfaceStyle,
                ),
                const SizedBox(height: 18),
                GlassGroupedSection(
                  header: const Text('SEGMENTED CONTROL'),
                  surfaceStyle: surfaceStyle,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: GlassSegmentedControl(
                        segments: _segments,
                        selectedIndex: _segmentIndex,
                        onSegmentSelected: (i) =>
                            setState(() => _segmentIndex = i),
                        quality: GlassQuality.premium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassGroupedSection(
                  header: const Text('SWITCHES (UISWITCH)'),
                  surfaceStyle: surfaceStyle,
                  children: [
                    GlassListTile(
                      title: const Text('Notifications (On)'),
                      trailing: GlassSwitch(
                        value: _switchOn,
                        width: 63,
                        height: 28,
                        quality: GlassQuality.premium,
                        onChanged: (v) => setState(() => _switchOn = v),
                      ),
                    ),
                    GlassListTile(
                      title: const Text('Low Power Mode (Off)'),
                      trailing: GlassSwitch(
                        value: _switchOff,
                        width: 63,
                        height: 28,
                        quality: GlassQuality.premium,
                        onChanged: (v) => setState(() => _switchOff = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassGroupedSection(
                  header: const Text('SLIDERS (UISLIDER)'),
                  surfaceStyle: surfaceStyle,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Continuous',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: labelColor,
                                ),
                              ),
                              Text(
                                '${(_sliderContinuous * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GlassSlider(
                            value: _sliderContinuous,
                            trackHeight: 6,
                            quality: GlassQuality.premium,
                            onChanged: (v) =>
                                setState(() => _sliderContinuous = v),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Stepped (25%)',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: labelColor,
                                ),
                              ),
                              Text(
                                '${(_sliderDiscrete * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GlassSlider(
                            value: _sliderDiscrete,
                            divisions: 4,
                            trackHeight: 6,
                            quality: GlassQuality.premium,
                            onChanged: (v) =>
                                setState(() => _sliderDiscrete = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassGroupedSection(
                  header: const Text('GLASS BUTTONS'),
                  surfaceStyle: surfaceStyle,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          GlassButton.custom(
                            width: 124,
                            height: 40,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 20,
                            ),
                            useOwnLayer: true,
                            quality: GlassQuality.premium,
                            onTap: () {},
                            child: Text(
                              'Regular Glass',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: labelColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GlassIconButton(
                            icon: const Icon(
                              CupertinoIcons.heart_fill,
                              size: 18,
                            ),
                            size: 40,
                            useOwnLayer: true,
                            quality: GlassQuality.premium,
                            onPressed: () {},
                          ),
                          const SizedBox(width: 12),
                          GlassButton.custom(
                            width: 104,
                            height: 40,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 20,
                            ),
                            useOwnLayer: true,
                            settings: (themeData.settingsFor(context) ??
                                    const GlassThemeSettings())
                                .applyTo(const LiquidGlassSettings())
                                .copyWith(
                                  bodyMode: GlassBodyMode.clear,
                                  frost: 0,
                                  saturation: 1.0,
                                  glassColor: CupertinoColors.systemBlue
                                      .resolveFrom(context),
                                ),
                            quality: GlassQuality.premium,
                            onTap: () {},
                            child: const Text(
                              'Prominent',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

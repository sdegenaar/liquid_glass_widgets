// =============================================================================
// Dedicated Controls Parity Harness (iOS 27 vs iOS 26 vs Classic)
// =============================================================================
//
// Flutter counterpart to `tools/parity/ios_reference/ControlsParityApp.swift`.
// Run with:
//   cd example && flutter run -t lib/harnesses/controls_parity_harness.dart
//
// Features:
// - Live top-bar toggle between `GlassStyle.ios27`, `GlassStyle.ios26`, and
//   `GlassStyle.classic` via a single `GlassThemeData(style: _style)` setting!
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

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _controlsCmdFile = '/tmp/lgw_controls_cmd.txt';

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
  bool _isDark = const bool.fromEnvironment('DARK');
  bool _lensesLifted = const bool.fromEnvironment('LIFT_LENSES');
  GlassStyle _style = switch (const String.fromEnvironment('STYLE')) {
    'classic' => GlassStyle.classic,
    'ios26' => GlassStyle.ios26,
    _ => GlassStyle.ios27,
  };
  String _bgMode = 'solid'; // 'solid' | 'vivid' | 'stripes'
  int _selectedTab = 0;

  int _segmentIndex = 0;
  bool _switchOn = true;
  bool _switchOff = false;
  double _sliderContinuous = 0.50;
  double _sliderDiscrete = 0.75;

  final GlobalKey _segKey = GlobalKey();
  final GlobalKey _switchOnKey = GlobalKey();
  final GlobalKey _switchOffKey = GlobalKey();
  final GlobalKey _sliderContKey = GlobalKey();
  final GlobalKey _sliderDiscKey = GlobalKey();
  final GlobalKey _tabBarKey = GlobalKey();
  final GlobalKey _bodyKey = GlobalKey();
  final GlobalKey _pullDownKey = GlobalKey();
  final GlobalKey _contextMenuBtnKey = GlobalKey();
  GlassMorphAnchor? _morphSheetAnchor;
  Timer? _cmdTimer;
  String? _lastCmd;
  final List<int> _activePointers = [];
  int _ptrEpoch = 900;

  @override
  void initState() {
    super.initState();
    final cmdFile = File(_controlsCmdFile);
    if (cmdFile.existsSync()) {
      try {
        cmdFile.deleteSync();
      } catch (_) {}
    }
    _cmdTimer = Timer.periodic(
      const Duration(milliseconds: 24),
      (_) => _pollCmd(),
    );
    // AUTO_TAB=N: select tab N programmatically after AUTO_TAB_DELAY_MS
    // (default 3000) so the indicator animation can be recorded without
    // synthetic touch input. Counterpart of native `-autoTab N`.
    const autoTab = int.fromEnvironment('AUTO_TAB', defaultValue: -1);
    if (autoTab >= 0) {
      const delayMs =
          int.fromEnvironment('AUTO_TAB_DELAY_MS', defaultValue: 3000);
      Future<void>.delayed(const Duration(milliseconds: delayMs), () {
        if (mounted) setState(() => _selectedTab = autoTab);
      });
    }
    if (_lensesLifted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _setLensesLifted(true);
        });
      });
    }
  }

  @override
  void dispose() {
    _cmdTimer?.cancel();
    super.dispose();
  }

  void _pollCmd() {
    final f = File(_controlsCmdFile);
    if (!f.existsSync()) return;
    final cmd = f.readAsStringSync().trim();
    if (cmd.isEmpty || cmd == _lastCmd) return;
    _lastCmd = cmd;
    _runCmd(cmd.split(RegExp(r'\s+')));
  }

  void _runCmd(List<String> args) {
    final innerCtx = _bodyKey.currentContext;
    switch (args[0]) {
      case 'style':
        setState(() {
          _style = switch (args.length > 1 ? args[1] : 'ios27') {
            'classic' => GlassStyle.classic,
            'ios26' => GlassStyle.ios26,
            _ => GlassStyle.ios27,
          };
        });
      case 'dark':
        setState(() => _isDark = args.length > 1 && args[1] == 'on');
      case 'bg':
        setState(() => _bgMode = args.length > 1 ? args[1] : 'solid');
      case 'tab':
        setState(() => _selectedTab = int.parse(args[1]));
      case 'pop':
        if (innerCtx != null) {
          final nav = Navigator.of(innerCtx, rootNavigator: true);
          if (nav.canPop()) {
            nav.pop();
          } else {
            // Dismiss any open OverlayPortal-based GlassMenu by tapping
            // outside the platter.
            final binding = WidgetsBinding.instance;
            _ptrEpoch += 1;
            final p = _ptrEpoch;
            const pos = Offset(10, 100);
            binding.handlePointerEvent(
              PointerDownEvent(pointer: p, position: pos),
            );
            Future<void>.delayed(const Duration(milliseconds: 40), () {
              binding.handlePointerEvent(
                PointerUpEvent(pointer: p, position: pos),
              );
            });
          }
        }
      case 'pulldown':
        final box =
            _pullDownKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final pos = box.localToGlobal(
            Offset(box.size.width * 0.5, box.size.height * 0.5),
          );
          final binding = WidgetsBinding.instance;
          _ptrEpoch += 1;
          final p = _ptrEpoch;
          binding
              .handlePointerEvent(PointerDownEvent(pointer: p, position: pos));
          Future<void>.delayed(const Duration(milliseconds: 40), () {
            binding
                .handlePointerEvent(PointerUpEvent(pointer: p, position: pos));
          });
        }
      case 'context_menu':
        if (innerCtx != null) _presentContextMenu(innerCtx);
      case 'half_sheet':
        if (innerCtx != null) _presentModalSheet(innerCtx, full: false);
      case 'full_sheet':
        if (innerCtx != null) _presentModalSheet(innerCtx, full: true);
      case 'morph_sheet':
        if (innerCtx != null) {
          _presentModalSheet(innerCtx, full: false, morph: true);
        }
      case 'glass_sheet':
        if (innerCtx != null) _presentGlassSheet(innerCtx);
    }
  }

  void _presentContextMenu(BuildContext innerCtx) {
    final box =
        _contextMenuBtnKey.currentContext?.findRenderObject() as RenderBox?;
    final rect = box != null && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size)
        : const Rect.fromLTWH(160, 260, 132, 36);
    showGlassContextMenu<void>(
      context: innerCtx,
      targetRect: rect,
      actions: [
        GlassContextMenuAction(
          icon: const Icon(CupertinoIcons.star_fill),
          iconPosition: GlassContextMenuIconPosition.leading,
          onPressed: () {},
          child: const Text('Favorite'),
        ),
        GlassContextMenuAction(
          icon: const Icon(CupertinoIcons.doc_on_doc),
          iconPosition: GlassContextMenuIconPosition.leading,
          onPressed: () {},
          child: const Text('Copy Link'),
        ),
        GlassContextMenuAction(
          icon: const Icon(CupertinoIcons.trash),
          iconPosition: GlassContextMenuIconPosition.leading,
          isDestructive: true,
          onPressed: () {},
          child: const Text('Delete'),
        ),
      ],
    );
  }

  void _presentModalSheet(
    BuildContext innerCtx, {
    required bool full,
    bool morph = false,
  }) {
    GlassModalSheet.show<void>(
      context: innerCtx,
      morphFrom: morph ? _morphSheetAnchor : null,
      initialState: full ? GlassSheetState.full : GlassSheetState.half,
      detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
      halfSize: 0.48,
      builder: (sheetCtx) => _OverlaysSheetContent(
        title: morph
            ? 'Morph Sheet'
            : (full ? 'Expanded Sheet' : 'Floating Glass Sheet'),
        isFull: full,
        onClose: () => Navigator.of(sheetCtx).maybePop(),
      ),
    );
  }

  void _presentGlassSheet(BuildContext innerCtx) {
    GlassSheet.show<void>(
      context: innerCtx,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GlassSheet Overlay',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(sheetCtx),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Resolves active GlassStyle preset (ios27, ios26, or classic) '
              'from the ambient GlassTheme across the modal route boundary.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel.resolveFrom(sheetCtx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setLensesLifted(bool lifted) {
    final binding = WidgetsBinding.instance;
    for (final p in _activePointers) {
      binding.handlePointerEvent(PointerCancelEvent(pointer: p));
    }
    _activePointers.clear();
    if (!lifted) return;
    _ptrEpoch += 10;
    final basePtr = _ptrEpoch;

    void pressAt(GlobalKey key, Offset localOffset, int pointer) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final global = box.localToGlobal(localOffset);
      _activePointers.add(pointer);
      binding.handlePointerEvent(
        PointerDownEvent(pointer: pointer, position: global),
      );
    }

    pressAt(_segKey, const Offset(56, 16), basePtr + 1);
    pressAt(_switchOnKey, const Offset(42.5, 14), basePtr + 2);
    pressAt(_switchOffKey, const Offset(20.5, 14), basePtr + 3);
    final contBox =
        _sliderContKey.currentContext?.findRenderObject() as RenderBox?;
    if (contBox != null && contBox.hasSize) {
      pressAt(
        _sliderContKey,
        Offset(contBox.size.width * 0.5, contBox.size.height * 0.5),
        basePtr + 4,
      );
    }
    final discBox =
        _sliderDiscKey.currentContext?.findRenderObject() as RenderBox?;
    if (discBox != null && discBox.hasSize) {
      pressAt(
        _sliderDiscKey,
        Offset(discBox.size.width * 0.75, discBox.size.height * 0.5),
        basePtr + 5,
      );
    }
    pressAt(_tabBarKey, const Offset(45, 31), basePtr + 6);

    // DRAG_TAB: slide the pressed tab-bar pointer to the right so the lifted
    // indicator can be captured mid-motion (jelly stretch + animated pinch).
    if (const bool.fromEnvironment('DRAG_TAB')) {
      final box = _tabBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final start = box.localToGlobal(const Offset(45, 31));
        const steps = 29;
        const stepDx = 2.0;
        for (var i = 1; i <= steps; i++) {
          Future<void>.delayed(Duration(milliseconds: 200 + 16 * i), () {
            if (!mounted) return;
            final next = Offset(start.dx + i * stepDx, start.dy);
            binding.handlePointerEvent(
              PointerMoveEvent(
                pointer: basePtr + 6,
                position: next,
                delta: const Offset(stepDx, 0),
              ),
            );
          });
        }
      }
    }
  }

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

    const surfaceStyle = GlassSurfaceStyle.solid;

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
                  _style = switch (_style) {
                    GlassStyle.ios27 => GlassStyle.ios26,
                    GlassStyle.ios26 => GlassStyle.classic,
                    GlassStyle.classic => GlassStyle.ios27,
                  };
                });
              },
              child: Text(
                switch (_style) {
                  GlassStyle.ios27 => 'iOS 27',
                  GlassStyle.ios26 => 'iOS 26',
                  GlassStyle.classic => 'Classic',
                },
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            actions: [
              GlassIconButton(
                icon: Icon(
                  _lensesLifted ? CupertinoIcons.eye_fill : CupertinoIcons.eye,
                  color: labelColor,
                  size: 16,
                ),
                size: 36,
                useOwnLayer: true,
                quality: GlassQuality.premium,
                onPressed: () {
                  setState(() => _lensesLifted = !_lensesLifted);
                  _setLensesLifted(_lensesLifted);
                },
              ),
              const SizedBox(width: 8),
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
            key: _tabBarKey,
            selectedIndex: _selectedTab,
            onTabSelected: (i) => setState(() => _selectedTab = i),
            selectedIconColor: CupertinoColors.systemBlue.resolveFrom(context),
            selectedLabelStyle: TextStyle(
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
              GlassTab(
                label: 'Settings',
                icon: Icon(CupertinoIcons.gear_alt_fill),
              ),
            ],
          ),
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (event.pointer < 900 && _lensesLifted) {
                setState(() => _lensesLifted = false);
                _setLensesLifted(false);
              }
            },
            child: SafeArea(
              top: false,
              bottom: false,
              child: ListView(
                key: _bodyKey,
                padding: const EdgeInsets.fromLTRB(16, 108, 16, 120),
                children: [
                  GlassSearchBar(
                    placeholder: 'Search controls',
                    surfaceStyle: surfaceStyle,
                  ),
                  const SizedBox(height: 24),
                  if (_selectedTab == 1) ...[
                    _buildOverlaysSections(
                      surfaceStyle: surfaceStyle,
                      labelColor: labelColor,
                      secondaryColor: secondaryColor,
                    ),
                    const SizedBox(height: 24),
                  ],
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
                          key: _segKey,
                          segments: _segments,
                          selectedIndex: _segmentIndex,
                          onSegmentSelected: (i) =>
                              setState(() => _segmentIndex = i),
                          quality: GlassQuality.premium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GlassGroupedSection(
                    header: const Text('SWITCHES (UISWITCH)'),
                    surfaceStyle: surfaceStyle,
                    children: [
                      GlassListTile(
                        title: const Text('Notifications (On)'),
                        trailing: GlassSwitch(
                          key: _switchOnKey,
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
                          key: _switchOffKey,
                          value: _switchOff,
                          width: 63,
                          height: 28,
                          quality: GlassQuality.premium,
                          onChanged: (v) => setState(() => _switchOff = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                              key: _sliderContKey,
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
                              key: _sliderDiscKey,
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
                  const SizedBox(height: 24),
                  GlassGroupedSection(
                    header: const Text('GLASS BUTTONS'),
                    surfaceStyle: surfaceStyle,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        child: Row(
                          children: [
                            GlassButton.custom(
                              width: 124,
                              height: 36,
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 18,
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
                                size: 17,
                              ),
                              size: 36,
                              useOwnLayer: true,
                              quality: GlassQuality.premium,
                              onPressed: () {},
                            ),
                            const SizedBox(width: 12),
                            GlassButton.custom(
                              width: 104,
                              height: 36,
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 18,
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
                  if (_selectedTab != 1) ...[
                    const SizedBox(height: 24),
                    _buildOverlaysSections(
                      surfaceStyle: surfaceStyle,
                      labelColor: labelColor,
                      secondaryColor: secondaryColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlaysSections({
    required GlassSurfaceStyle surfaceStyle,
    required Color labelColor,
    required Color secondaryColor,
  }) {
    return Builder(
      builder: (innerCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassGroupedSection(
            header: const Text('MENUS (UIMENU & .CONTEXTMENU)'),
            surfaceStyle: surfaceStyle,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    GlassPullDownButton(
                      key: _pullDownKey,
                      label: 'Pull-Down',
                      buttonWidth: 132,
                      buttonHeight: 36,
                      menuWidth: 220,
                      quality: GlassQuality.premium,
                      items: [
                        GlassMenuLabel(
                          child: Text(
                            'Sort By',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.08,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                        GlassMenuItem(
                          title: 'Name',
                          icon: const Icon(CupertinoIcons.textformat),
                          onTap: () {},
                        ),
                        GlassMenuItem(
                          title: 'Date Modified',
                          icon: const Icon(CupertinoIcons.calendar),
                          onTap: () {},
                        ),
                        const GlassMenuDivider(),
                        GlassMenuItem(
                          title: 'Delete All',
                          icon: const Icon(CupertinoIcons.trash),
                          isDestructive: true,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    GlassButton.custom(
                      key: _contextMenuBtnKey,
                      width: 132,
                      height: 36,
                      shape: const LiquidRoundedSuperellipse(
                        borderRadius: 18,
                      ),
                      useOwnLayer: true,
                      quality: GlassQuality.premium,
                      onTap: () => _presentContextMenu(innerCtx),
                      child: Text(
                        'Context Menu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassGroupedSection(
            header: const Text('MODAL SHEETS (.SHEET)'),
            surfaceStyle: surfaceStyle,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: GlassButton.custom(
                        height: 36,
                        shape: const LiquidRoundedSuperellipse(
                          borderRadius: 18,
                        ),
                        useOwnLayer: true,
                        quality: GlassQuality.premium,
                        onTap: () => _presentModalSheet(innerCtx, full: false),
                        child: Text(
                          'Half Sheet',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: labelColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassButton.custom(
                        height: 36,
                        shape: const LiquidRoundedSuperellipse(
                          borderRadius: 18,
                        ),
                        useOwnLayer: true,
                        quality: GlassQuality.premium,
                        onTap: () => _presentModalSheet(innerCtx, full: true),
                        child: Text(
                          'Full Sheet',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: labelColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassMorphTrigger(
                        builder: (ctx, anchor) {
                          _morphSheetAnchor = anchor;
                          return GlassButton.custom(
                            height: 36,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 18,
                            ),
                            useOwnLayer: true,
                            quality: GlassQuality.premium,
                            onTap: () => _presentModalSheet(
                              innerCtx,
                              full: false,
                              morph: true,
                            ),
                            child: Text(
                              'Morph Sheet',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: labelColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlaysSheetContent extends StatelessWidget {
  const _OverlaysSheetContent({
    required this.title,
    required this.onClose,
    this.isFull = false,
  });

  final String title;
  final VoidCallback onClose;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final style = GlassThemeData.of(context).style;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final cardColor = isFull
        ? (isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white)
        : (isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlassIconButton(
                size: 40,
                useOwnLayer: true,
                quality: GlassQuality.premium,
                icon: Icon(CupertinoIcons.xmark, size: 18, color: labelColor),
                onPressed: onClose,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active GlassStyle: ${style.name}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Half detent renders with Liquid Glass paraxial lensing, '
                    'frost, and rim lighting; expanding to Full crossfades '
                    'smoothly to the system solid background.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

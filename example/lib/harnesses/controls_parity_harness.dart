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
  GlassQuality? _quality = switch (Platform.environment['LGW_QUALITY'] ??
      const String.fromEnvironment('QUALITY')) {
    'standard' => GlassQuality.standard,
    'premium' => GlassQuality.premium,
    _ => null,
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
  final ScrollController _bodyScroll = ScrollController();
  final GlobalKey _pullDownKey = GlobalKey();
  final GlobalKey _contextMenuBtnKey = GlobalKey();
  GlassMorphAnchor? _morphSheetAnchor;
  VoidCallback? _toastDismiss;
  Timer? _cmdTimer;
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
    _bodyScroll.dispose();
    super.dispose();
  }

  void _pollCmd() {
    final f = File(_controlsCmdFile);
    if (!f.existsSync()) return;
    final String cmd;
    try {
      cmd = f.readAsStringSync().trim();
      f.deleteSync();
    } catch (_) {
      return;
    }
    if (cmd.isEmpty) return;
    for (final rawLine in cmd.split('\n')) {
      final line = rawLine.trim();
      if (line.isNotEmpty) {
        _runCmd(line.split(RegExp(r'\s+')));
      }
    }
  }

  void _runCmd(List<String> args) {
    final innerCtx = _bodyKey.currentContext;
    switch (args[0]) {
      case 'sim':
        if (args.length > 2 &&
            Directory.systemTemp.path
                .toUpperCase()
                .contains(args[1].toUpperCase())) {
          _runCmd(args.sublist(2));
        }
      case 'style':
        setState(() {
          _style = switch (args.length > 1 ? args[1] : 'ios27') {
            'classic' => GlassStyle.classic,
            'ios26' => GlassStyle.ios26,
            _ => GlassStyle.ios27,
          };
        });
        _refreshLiftedIfNeeded();
      case 'quality':
        setState(() {
          _quality = switch (args.length > 1 ? args[1] : 'auto') {
            'standard' || 'std' => GlassQuality.standard,
            'premium' || 'prem' => GlassQuality.premium,
            _ => null,
          };
        });
        _refreshLiftedIfNeeded();
      case 'dark':
        setState(() => _isDark = args.length > 1 && args[1] == 'on');
        _refreshLiftedIfNeeded();
      case 'bg':
        setState(() => _bgMode = args.length > 1 ? args[1] : 'solid');
      case 'tab':
        setState(() => _selectedTab = int.parse(args[1]));
      case 'lift':
        // `lift on` presses every hero control (switch, sliders, segmented
        // control, tab bar) so the lifted lens can be captured; `lift off`
        // releases them.
        setState(() => _lensesLifted = args.length > 1 && args[1] == 'on');
        _setLensesLifted(_lensesLifted);
      case 'drag_tab':
        final box = _tabBarKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final binding = WidgetsBinding.instance;
          final targetLocalX =
              args.length > 1 ? double.parse(args[1]) : 45.0 + 58.0;
          final start = box.localToGlobal(const Offset(45, 31));
          final totalDx = targetLocalX - 45.0;
          const steps = 24;
          final stepDx = totalDx / steps;
          final tabPtr = _ptrEpoch + 6;
          for (var i = 1; i <= steps; i++) {
            Future<void>.delayed(Duration(milliseconds: 14 * i), () {
              if (!mounted) return;
              final next = Offset(start.dx + i * stepDx, start.dy);
              binding.handlePointerEvent(
                PointerMoveEvent(
                  pointer: tabPtr,
                  position: next,
                  delta: Offset(stepDx, 0),
                ),
              );
            });
          }
        }
      case 'scroll':
        // `scroll <offset>` jumps the body list to an exact offset.
        if (_bodyScroll.hasClients) _bodyScroll.jumpTo(double.parse(args[1]));
      case 'pop':
        _toastDismiss?.call();
        _toastDismiss = null;
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
            const pos = Offset(200, 24); // status-bar strip: hits no control
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
      case 'dialog':
        if (innerCtx != null) _presentDialog(innerCtx);
      case 'dialog3':
        if (innerCtx != null) _presentDialog(innerCtx, threeActions: true);
      case 'action_sheet':
        if (innerCtx != null) _presentActionSheet(innerCtx);
      case 'toast':
        if (innerCtx != null) {
          _toastDismiss?.call();
          _toastDismiss = GlassToast.show(
            innerCtx,
            message: 'Settings saved',
            type: GlassToastType.success,
            duration: Duration.zero,
          );
        }
      case 'date_picker':
        if (innerCtx != null) showGlassDatePicker(context: innerCtx);
    }
  }

  void _presentDialog(BuildContext innerCtx, {bool threeActions = false}) {
    void close() => Navigator.of(innerCtx, rootNavigator: true).pop();
    if (threeActions) {
      GlassDialog.show<void>(
        context: innerCtx,
        quality: _quality,
        title: 'Save Changes?',
        message: 'Your edits will be lost if you do not save them.',
        actions: [
          GlassDialogAction(label: 'Save', onPressed: close),
          GlassDialogAction(
            label: "Don't Save",
            isDestructive: true,
            onPressed: close,
          ),
          GlassDialogAction(label: 'Cancel', onPressed: close),
        ],
      );
      return;
    }
    GlassDialog.show<void>(
      context: innerCtx,
      quality: _quality,
      title: 'Delete Photo?',
      message: 'This photo will be removed from all of your devices.',
      actions: [
        GlassDialogAction(label: 'Cancel', onPressed: close),
        GlassDialogAction(
          label: 'Delete',
          isDestructive: true,
          onPressed: close,
        ),
      ],
    );
  }

  void _presentActionSheet(BuildContext innerCtx) {
    showGlassActionSheet<void>(
      context: innerCtx,
      quality: _quality,
      title: 'Choose Action',
      message: 'Pick what to do with this item',
      actions: [
        GlassActionSheetAction(label: 'Share', onPressed: () {}),
        GlassActionSheetAction(
          label: 'Delete',
          style: GlassActionSheetStyle.destructive,
          onPressed: () {},
        ),
      ],
    );
  }

  void _presentContextMenu(BuildContext innerCtx) {
    final box =
        _contextMenuBtnKey.currentContext?.findRenderObject() as RenderBox?;
    final rect = box != null && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size)
        : const Rect.fromLTWH(160, 260, 132, 36);
    showGlassContextMenu<void>(
      context: innerCtx,
      quality: _quality ?? GlassQuality.premium,
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
      quality: _quality,
      morphFrom: morph ? _morphSheetAnchor : null,
      initialState: full ? GlassSheetState.full : GlassSheetState.half,
      detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
      halfSize: 0.48,
      builder: (sheetCtx) => _OverlaysSheetContent(
        title: morph
            ? 'Morph Sheet'
            : (full ? 'Expanded Sheet' : 'Floating Glass Sheet'),
        isFull: full,
        quality: _quality,
        onClose: () => Navigator.of(sheetCtx).maybePop(),
      ),
    );
  }

  void _presentGlassSheet(BuildContext innerCtx) {
    GlassSheet.show<void>(
      context: innerCtx,
      quality: _quality,
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

  void _refreshLiftedIfNeeded() {
    if (!_lensesLifted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lensesLifted) {
        _setLensesLifted(true);
      }
    });
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
    pressAt(_tabBarKey, Offset(45.0 + _selectedTab * 90.0, 31), basePtr + 6);

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
    final brightness = _isDark ? Brightness.dark : Brightness.light;
    final baseTheme = switch (_style) {
      GlassStyle.ios27 => GlassThemeData.ios27(brightness: brightness),
      GlassStyle.ios26 => GlassThemeData.ios26(brightness: brightness),
      GlassStyle.classic => GlassThemeData.classic(brightness: brightness),
    };
    final themeData = _quality == null
        ? baseTheme
        : GlassThemeData(
            style: _style,
            brightness: brightness,
            light: baseTheme.light.copyWith(quality: _quality),
            dark: baseTheme.dark.copyWith(quality: _quality),
          );
    final effectiveButtonQuality = _quality ?? GlassQuality.premium;

    const surfaceStyle = GlassSurfaceStyle.solid;

    final labelColor = _isDark ? CupertinoColors.white : CupertinoColors.black;
    final secondaryColor =
        _isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: CupertinoColors.systemBlue,
      ),
      home: GlassTheme(
        data: themeData,
        child: GlassScaffold(
          background: _buildBackdrop(),
          appBar: GlassAppBar(
            centerTitle: false,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            leading: GlassIconButton(
              icon: Icon(
                _lensesLifted ? CupertinoIcons.eye_fill : CupertinoIcons.eye,
                color: labelColor,
                size: 20,
              ),
              size: 44,
              useOwnLayer: true,
              quality: effectiveButtonQuality,
              onPressed: () {
                setState(() => _lensesLifted = !_lensesLifted);
                _setLensesLifted(_lensesLifted);
              },
            ),
            title: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassButton.custom(
                    width: 68,
                    height: 36,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 18),
                    useOwnLayer: true,
                    quality: effectiveButtonQuality,
                    onTap: () {
                      setState(() {
                        _style = switch (_style) {
                          GlassStyle.ios27 => GlassStyle.ios26,
                          GlassStyle.ios26 => GlassStyle.classic,
                          GlassStyle.classic => GlassStyle.ios27,
                        };
                      });
                      _refreshLiftedIfNeeded();
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
                  const SizedBox(width: 8),
                  GlassButton.custom(
                    width: 54,
                    height: 36,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 18),
                    useOwnLayer: true,
                    quality: effectiveButtonQuality,
                    onTap: () {
                      setState(() {
                        _quality = _quality == GlassQuality.standard
                            ? GlassQuality.premium
                            : GlassQuality.standard;
                      });
                      _refreshLiftedIfNeeded();
                    },
                    child: Text(
                      _quality == GlassQuality.standard ? 'Std' : 'Prem',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _quality == GlassQuality.standard
                            ? CupertinoColors.systemOrange.resolveFrom(context)
                            : labelColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              GlassContainer(
                width: 108,
                height: 44,
                shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                useOwnLayer: true,
                quality: effectiveButtonQuality,
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _cycleBgMode,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              _bgMode[0].toUpperCase() + _bgMode.substring(1),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: labelColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _isDark = !_isDark);
                          _refreshLiftedIfNeeded();
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              _isDark
                                  ? CupertinoIcons.sun_max_fill
                                  : CupertinoIcons.moon_fill,
                              color: _isDark
                                  ? CupertinoColors.systemYellow
                                  : CupertinoColors.systemIndigo,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomBar: GlassTabBar.bottom(
            key: _tabBarKey,
            quality: _quality,
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
                controller: _bodyScroll,
                padding: const EdgeInsets.fromLTRB(16, 114, 16, 120),
                children: [
                  GlassSearchBar(
                    placeholder: 'Search controls',
                    surfaceStyle: surfaceStyle,
                    quality: _quality,
                    height: 42,
                    searchIconColor: labelColor,
                    textStyle: TextStyle(
                      fontSize: 17,
                      letterSpacing: -0.41,
                      color: labelColor,
                    ),
                    placeholderStyle: TextStyle(
                      fontSize: 17,
                      letterSpacing: -0.41,
                      color: secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_selectedTab == 1) ...[
                    _buildOverlaysSections(
                      surfaceStyle: surfaceStyle,
                      labelColor: labelColor,
                      secondaryColor: secondaryColor,
                      buttonQuality: effectiveButtonQuality,
                    ),
                    const SizedBox(height: 28),
                  ],
                  GlassGroupedSection(
                    header: _buildSectionHeader(
                      'SEGMENTED CONTROL',
                      secondaryColor,
                    ),
                    margin: EdgeInsets.zero,
                    surfaceStyle: surfaceStyle,
                    quality: _quality,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 19,
                        ),
                        child: GlassSegmentedControl(
                          key: _segKey,
                          quality: _quality,
                          segments: _segments,
                          selectedIndex: _segmentIndex,
                          onSegmentSelected: (i) =>
                              setState(() => _segmentIndex = i),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  GlassGroupedSection(
                    header: _buildSectionHeader(
                      'SWITCHES (UISWITCH)',
                      secondaryColor,
                    ),
                    margin: EdgeInsets.zero,
                    surfaceStyle: surfaceStyle,
                    quality: _quality,
                    children: [
                      GlassListTile(
                        title: const Text('Notifications (On)'),
                        titleStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.41,
                          color: labelColor,
                        ),
                        trailing: GlassSwitch(
                          key: _switchOnKey,
                          quality: _quality,
                          value: _switchOn,
                          width: 63,
                          height: 28,
                          onChanged: (v) => setState(() => _switchOn = v),
                        ),
                      ),
                      GlassListTile(
                        title: const Text('Low Power Mode (Off)'),
                        titleStyle: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.41,
                          color: labelColor,
                        ),
                        trailing: GlassSwitch(
                          key: _switchOffKey,
                          quality: _quality,
                          value: _switchOff,
                          width: 63,
                          height: 28,
                          onChanged: (v) => setState(() => _switchOff = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  GlassGroupedSection(
                    header: _buildSectionHeader(
                      'SLIDERS (UISLIDER)',
                      secondaryColor,
                    ),
                    margin: EdgeInsets.zero,
                    surfaceStyle: surfaceStyle,
                    quality: _quality,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                                    letterSpacing: -0.24,
                                    color: labelColor,
                                  ),
                                ),
                                Text(
                                  '${(_sliderContinuous * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 15,
                                    letterSpacing: -0.24,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 31,
                              child: Center(
                                child: OverflowBox(
                                  minHeight: 46,
                                  maxHeight: 46,
                                  child: GlassSlider(
                                    key: _sliderContKey,
                                    quality: _quality,
                                    value: _sliderContinuous,
                                    trackHeight: 6,
                                    onChanged: (v) =>
                                        setState(() => _sliderContinuous = v),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                                    letterSpacing: -0.24,
                                    color: labelColor,
                                  ),
                                ),
                                Text(
                                  '${(_sliderDiscrete * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 15,
                                    letterSpacing: -0.24,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 31,
                              child: Center(
                                child: OverflowBox(
                                  minHeight: 46,
                                  maxHeight: 46,
                                  child: GlassSlider(
                                    key: _sliderDiscKey,
                                    quality: _quality,
                                    value: _sliderDiscrete,
                                    divisions: 4,
                                    trackHeight: 6,
                                    onChanged: (v) =>
                                        setState(() => _sliderDiscrete = v),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  GlassGroupedSection(
                    header: _buildSectionHeader(
                      'GLASS BUTTONS',
                      secondaryColor,
                    ),
                    margin: EdgeInsets.zero,
                    surfaceStyle: surfaceStyle,
                    quality: _quality,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 19, 16, 19),
                        child: Row(
                          children: [
                            GlassButton.custom(
                              width: 128,
                              height: 34.5,
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 18,
                              ),
                              useOwnLayer: true,
                              quality: effectiveButtonQuality,
                              onTap: () {},
                              child: Text(
                                'Regular Glass',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.41,
                                  color: labelColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GlassButton.custom(
                              width: 45,
                              height: 32,
                              shape: const LiquidRoundedSuperellipse(
                                borderRadius: 16,
                              ),
                              useOwnLayer: true,
                              quality: effectiveButtonQuality,
                              onTap: () {},
                              child: Icon(
                                CupertinoIcons.heart_fill,
                                size: 17,
                                color: labelColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GlassButton.custom(
                              width: 102,
                              height: 34.5,
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
                                    ambientStrength: 0.0,
                                    lightIntensity: 0.25,
                                    glassColor: const Color(0xFF0088FF),
                                  ),
                              quality: effectiveButtonQuality,
                              onTap: () {},
                              child: DecoratedBox(
                                decoration: const ShapeDecoration(
                                  color: Color(0xFF0088FF),
                                  shape: LiquidRoundedSuperellipse(
                                    borderRadius: 18,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Prominent',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.41,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_selectedTab != 1) ...[
                    const SizedBox(height: 28),
                    _buildOverlaysSections(
                      surfaceStyle: surfaceStyle,
                      labelColor: labelColor,
                      secondaryColor: secondaryColor,
                      buttonQuality: effectiveButtonQuality,
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

  Widget _buildSectionHeader(String text, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.24,
          color: secondaryColor,
        ),
      ),
    );
  }

  Widget _buildOverlaysSections({
    required GlassSurfaceStyle surfaceStyle,
    required Color labelColor,
    required Color secondaryColor,
    required GlassQuality buttonQuality,
  }) {
    return Builder(
      builder: (innerCtx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassGroupedSection(
            header: _buildSectionHeader(
              'MENUS (UIMENU & .CONTEXTMENU)',
              secondaryColor,
            ),
            margin: EdgeInsets.zero,
            surfaceStyle: surfaceStyle,
            quality: _quality,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    GlassPullDownButton(
                      key: _pullDownKey,
                      label: 'Pull-Down',
                      buttonWidth: 122,
                      buttonHeight: 34.5,
                      menuWidth: 220,
                      quality: buttonQuality,
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
                    GlassMenu(
                      menuWidth: 220,
                      quality: buttonQuality,
                      triggerBuilder: (context, toggle) => GlassIconButton(
                        size: 36,
                        useOwnLayer: true,
                        quality: buttonQuality,
                        icon: Icon(
                          CupertinoIcons.ellipsis,
                          size: 17,
                          color: labelColor,
                        ),
                        onPressed: toggle,
                      ),
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
                      width: 131,
                      height: 34.5,
                      shape: const LiquidRoundedSuperellipse(
                        borderRadius: 18,
                      ),
                      useOwnLayer: true,
                      quality: buttonQuality,
                      onTap: () => _presentContextMenu(innerCtx),
                      child: Text(
                        'Context Menu',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.41,
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
            header: _buildSectionHeader(
              'MODAL SHEETS (.SHEET)',
              secondaryColor,
            ),
            margin: EdgeInsets.zero,
            surfaceStyle: surfaceStyle,
            quality: _quality,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: GlassButton.custom(
                        height: 34.5,
                        shape: const LiquidRoundedSuperellipse(
                          borderRadius: 18,
                        ),
                        useOwnLayer: true,
                        quality: buttonQuality,
                        onTap: () => _presentModalSheet(innerCtx, full: false),
                        child: Text(
                          'Half Sheet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.32,
                            color: labelColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassButton.custom(
                        height: 34.5,
                        shape: const LiquidRoundedSuperellipse(
                          borderRadius: 18,
                        ),
                        useOwnLayer: true,
                        quality: buttonQuality,
                        onTap: () => _presentModalSheet(innerCtx, full: true),
                        child: Text(
                          'Full Sheet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.32,
                            color: labelColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassMorphTrigger(
                        builder: (ctx, anchor) {
                          _morphSheetAnchor = anchor;
                          return GlassButton.custom(
                            height: 34.5,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 18,
                            ),
                            useOwnLayer: true,
                            quality: buttonQuality,
                            onTap: () => _presentModalSheet(
                              innerCtx,
                              full: false,
                              morph: true,
                            ),
                            child: Text(
                              'Morph Sheet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.32,
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
    this.quality,
  });

  final String title;
  final VoidCallback onClose;
  final bool isFull;
  final GlassQuality? quality;

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
                quality: quality ?? GlassQuality.premium,
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

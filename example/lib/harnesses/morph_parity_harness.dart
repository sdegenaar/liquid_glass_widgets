// =============================================================================
// Dedicated Liquid Morph Parity Harness (iOS 27 Menu, Popover & Sheet Morphs)
// =============================================================================
//
// Calibrates `GlassMenu`, `GlassPullDownButton`, `GlassPopover`, and
// `GlassModalSheet` (source-trigger morph via `GlassMorphTrigger`) against
// native iOS 27 SwiftUI `Menu`, `.popover`, and `.navigationTransition(.zoom)`
// across trigger geometries and menu lengths:
//
//   1. Round `GlassIconButton` (44x44) with `GlassMenu`
//   2. Medium pill `GlassButton` (120x44) with `GlassMenu`
//   3. Wide centered `GlassButton` (260x44) with `GlassMenu`
//   4. Wide left-aligned `GlassButton` (240x44) with `GlassMenu`
//   5. Menu length variants: Short (2 items), Medium (5 items), Tall (10 items)
//   6. Other morph-engine consumers: `GlassPullDownButton`, `GlassPopover`,
//      and `GlassModalSheet` (`GlassMorphTrigger` + `morphFrom: anchor`)
//
// Driven interactively or via `/tmp/lgw_morph_cmd.txt` (one command per line):
//
//   len short|medium|tall          select 2, 5, or 10 menu items
//   align auto|topLeft|topCenter|topRight  set GlassMenu.menuAlignment
//   open round|pill|wide_center|wide_left|pulldown|popover|sheet_half|sheet_full
//   close                          dismiss active menu / popover / sheet
//   tap_item <index>               tap item <index> inside an open menu
//   stage off|round|pill|wide_center|wide_left  isolate single trigger on canvas
//   dark on|off                    switch dark / light appearance
//   bg contrast|solid|mid|vivid|stripes  switch backdrop for pixel tracking
//   style ios27|ios26|classic      switch active GlassStyle preset
//   quality premium|standard|auto  switch active GlassQuality tier
//   tap <x> <y>                    inject tap at logical (x, y)
//   ptr down|move|up <x> <y>       inject raw pointer event at logical (x, y)
//
// Run with:
//   cd example && flutter run -t lib/harnesses/morph_parity_harness.dart -d <udid>
// =============================================================================
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _morphCmdFile = '/tmp/lgw_morph_cmd.txt';

/// Menu item count presets used for open and return trajectory calibration.
enum MorphMenuLength {
  /// Short menu (2 items, ~114 pt height).
  short(2, 'Short (2)'),

  /// Medium menu (5 items, ~252 pt height).
  medium(5, 'Medium (5)'),

  /// Tall menu (10 items, ~482 pt height).
  tall(10, 'Tall (10)');

  const MorphMenuLength(this.itemCount, this.label);

  /// Number of [GlassMenuItem] rows in this preset.
  final int itemCount;

  /// Short segment label shown in the harness selector.
  final String label;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const MorphParityHarnessApp()));
}

/// Root application widget for the Liquid Morph parity harness.
class MorphParityHarnessApp extends StatefulWidget {
  /// Creates the Liquid Morph parity harness app.
  const MorphParityHarnessApp({super.key});

  @override
  State<MorphParityHarnessApp> createState() => _MorphParityHarnessAppState();
}

class _MorphParityHarnessAppState extends State<MorphParityHarnessApp> {
  bool _isDark = const bool.fromEnvironment('DARK', defaultValue: true);
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
  String _bgMode = const String.fromEnvironment(
    'BG',
    defaultValue: 'contrast',
  );

  MorphMenuLength _menuLength = MorphMenuLength.medium;
  GlassMenuAlignment _menuAlignment = GlassMenuAlignment.none;
  String _stageTarget = 'off';
  String _lastAction = 'Idle';

  final GlassMenuController _roundMenuCtrl = GlassMenuController();
  final GlassMenuController _pillMenuCtrl = GlassMenuController();
  final GlassMenuController _wideCenterMenuCtrl = GlassMenuController();
  final GlassMenuController _wideLeftMenuCtrl = GlassMenuController();
  final GlassMenuController _rightEdgeMenuCtrl = GlassMenuController();
  final GlassMenuController _bottomRoundMenuCtrl = GlassMenuController();
  final GlassMenuController _bottomWideMenuCtrl = GlassMenuController();

  final GlobalKey _bodyKey = GlobalKey();
  final GlobalKey _pullDownKey = GlobalKey();
  VoidCallback? _togglePopover;
  VoidCallback? _toggleRightPopover;
  VoidCallback? _toggleBottomPopover;
  VoidCallback? _closePopover;
  GlassMorphAnchor? _morphHalfAnchor;
  GlassMorphAnchor? _morphFullAnchor;
  GlassMorphAnchor? _morphBottomAnchor;

  Timer? _cmdTimer;
  Offset _lastPtr = Offset.zero;
  int _ptrEpoch = 700;

  @override
  void initState() {
    super.initState();
    final cmdFile = File(_morphCmdFile);
    if (cmdFile.existsSync()) {
      try {
        cmdFile.deleteSync();
      } catch (_) {}
    }
    _cmdTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _pollCmd(),
    );
  }

  @override
  void dispose() {
    _cmdTimer?.cancel();
    super.dispose();
  }

  void _pollCmd() {
    final f = File(_morphCmdFile);
    if (!f.existsSync()) return;
    final String raw;
    try {
      raw = f.readAsStringSync().trim();
      f.deleteSync();
    } catch (_) {
      return;
    }
    if (raw.isEmpty) return;
    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isNotEmpty) {
        _runCmd(line.split(RegExp(r'\s+')));
      }
    }
  }

  void _runCmd(List<String> args) {
    final innerCtx = _bodyKey.currentContext;
    switch (args[0]) {
      case 'len':
        if (args.length < 2) return;
        setState(() {
          _menuLength = switch (args[1]) {
            'short' || '2' => MorphMenuLength.short,
            'tall' || 'long' || '10' => MorphMenuLength.tall,
            _ => MorphMenuLength.medium,
          };
        });
      case 'align':
        if (args.length < 2) return;
        setState(() {
          _menuAlignment = switch (args[1]) {
            'topLeft' => GlassMenuAlignment.topLeft,
            'topCenter' => GlassMenuAlignment.topCenter,
            'topRight' => GlassMenuAlignment.topRight,
            'bottomLeft' => GlassMenuAlignment.bottomLeft,
            'bottomCenter' => GlassMenuAlignment.bottomCenter,
            'bottomRight' => GlassMenuAlignment.bottomRight,
            _ => GlassMenuAlignment.none,
          };
        });
      case 'stage':
        setState(() {
          _stageTarget = args.length > 1 ? args[1] : 'off';
        });
      case 'open':
        if (args.length < 2) return;
        _openTarget(args[1], innerCtx);
      case 'close' || 'pop':
        _closeActive(innerCtx);
      case 'tap_item':
        final index = args.length > 1 ? int.tryParse(args[1]) ?? 0 : 0;
        _tapOpenMenuItem(index);
      case 'dark':
        setState(() => _isDark = args.length < 2 || args[1] == 'on');
      case 'bg':
        setState(() => _bgMode = args.length > 1 ? args[1] : 'contrast');
      case 'style':
        setState(() {
          _style = switch (args.length > 1 ? args[1] : 'ios27') {
            'classic' => GlassStyle.classic,
            'ios26' => GlassStyle.ios26,
            _ => GlassStyle.ios27,
          };
        });
      case 'quality':
        setState(() {
          _quality = switch (args.length > 1 ? args[1] : 'auto') {
            'standard' || 'std' => GlassQuality.standard,
            'premium' || 'prem' => GlassQuality.premium,
            _ => null,
          };
        });
      case 'tap':
        if (args.length < 3) return;
        _injectTap(Offset(double.parse(args[1]), double.parse(args[2])));
      case 'ptr':
        if (args.length < 4) return;
        final pos = Offset(double.parse(args[2]), double.parse(args[3]));
        final binding = WidgetsBinding.instance;
        final PointerEvent event = switch (args[1]) {
          'down' => PointerDownEvent(position: pos, pointer: 77),
          'move' => PointerMoveEvent(
              position: pos,
              delta: pos - _lastPtr,
              pointer: 77,
            ),
          _ => PointerUpEvent(position: pos, pointer: 77),
        };
        _lastPtr = pos;
        binding.handlePointerEvent(event);
    }
  }

  void _openTarget(String target, BuildContext? innerCtx) {
    switch (target) {
      case 'round':
        _roundMenuCtrl.open();
      case 'pill':
        _pillMenuCtrl.open();
      case 'wide_center':
        _wideCenterMenuCtrl.open();
      case 'wide_left':
        _wideLeftMenuCtrl.open();
      case 'right_edge':
        _rightEdgeMenuCtrl.open();
      case 'bottom_round':
        _bottomRoundMenuCtrl.open();
      case 'bottom_wide':
        _bottomWideMenuCtrl.open();
      case 'pulldown':
        final box =
            _pullDownKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final center = box.localToGlobal(
            Offset(box.size.width * 0.5, box.size.height * 0.5),
          );
          _injectTap(center);
        }
      case 'popover':
        _togglePopover?.call();
      case 'right_popover':
        _toggleRightPopover?.call();
      case 'bottom_popover':
        _toggleBottomPopover?.call();
      case 'sheet_half':
        if (innerCtx != null && _morphHalfAnchor != null) {
          _presentMorphSheet(innerCtx, anchor: _morphHalfAnchor!, full: false);
        }
      case 'sheet_full':
        if (innerCtx != null && _morphFullAnchor != null) {
          _presentMorphSheet(innerCtx, anchor: _morphFullAnchor!, full: true);
        }
      case 'sheet_bottom':
        if (innerCtx != null && _morphBottomAnchor != null) {
          _presentMorphSheet(innerCtx,
              anchor: _morphBottomAnchor!, full: false);
        }
    }
  }

  void _closeActive(BuildContext? innerCtx) {
    var closedMenu = false;
    for (final ctrl in [
      _roundMenuCtrl,
      _pillMenuCtrl,
      _wideCenterMenuCtrl,
      _wideLeftMenuCtrl,
      _rightEdgeMenuCtrl,
      _bottomRoundMenuCtrl,
      _bottomWideMenuCtrl,
    ]) {
      if (ctrl.isOpen) {
        ctrl.close();
        closedMenu = true;
      }
    }
    if (closedMenu) return;

    if (innerCtx != null) {
      final nav = Navigator.of(innerCtx, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
        return;
      }
    }

    if (_closePopover != null) {
      _closePopover!.call();
      return;
    }

    // Fallback: dismiss OverlayPortal barriers (e.g. GlassPullDownButton) via
    // an outside tap in the safe top strip.
    _injectTap(const Offset(20, 24));
  }

  void _tapOpenMenuItem(int index) {
    // Synthesize a glide + release or tap on the open menu row via controller
    // or screen coordinates when needed.
    GlassMenuController? active;
    for (final ctrl in [
      _roundMenuCtrl,
      _pillMenuCtrl,
      _wideCenterMenuCtrl,
      _wideLeftMenuCtrl,
      _rightEdgeMenuCtrl,
      _bottomRoundMenuCtrl,
      _bottomWideMenuCtrl,
    ]) {
      if (ctrl.isOpen) {
        active = ctrl;
        break;
      }
    }
    if (active == null) return;
    // Trigger item selection callback and close deterministically.
    setState(() => _lastAction = 'Selected item ${index + 1}');
    active.close();
  }

  void _injectTap(Offset globalPos) {
    final binding = WidgetsBinding.instance;
    _ptrEpoch += 1;
    final p = _ptrEpoch;
    binding
        .handlePointerEvent(PointerDownEvent(pointer: p, position: globalPos));
    Future<void>.delayed(const Duration(milliseconds: 36), () {
      binding
          .handlePointerEvent(PointerUpEvent(pointer: p, position: globalPos));
    });
  }

  void _cycleBgMode() {
    setState(() {
      _bgMode = switch (_bgMode) {
        'contrast' => 'solid',
        'solid' => 'mid',
        'mid' => 'vivid',
        'vivid' => 'stripes',
        _ => 'contrast',
      };
    });
  }

  Widget _buildBackdrop() {
    switch (_bgMode) {
      case 'solid':
        return ColoredBox(
          color: _isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          child: const SizedBox.expand(),
        );
      case 'mid':
        return const ColoredBox(
          color: Color(0xFF808080),
          child: SizedBox.expand(),
        );
      case 'vivid':
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
      case 'stripes':
        return LayoutBuilder(
          builder: (context, constraints) {
            final stripeHeight = constraints.maxHeight / 24;
            return Column(
              children: List.generate(24, (idx) {
                final color = idx.isEven
                    ? (_isDark
                        ? const Color(0xFF343842)
                        : const Color(0xFFD0D5DF))
                    : (_isDark ? CupertinoColors.black : CupertinoColors.white);
                return SizedBox(
                  width: double.infinity,
                  height: stripeHeight,
                  child: ColoredBox(color: color),
                );
              }),
            );
          },
        );
      case 'contrast':
      default:
        // Clean uniform matte slate chosen so translucent glass platters and
        // specular rims maintain sharp edge contrast for automated pixel scans.
        return ColoredBox(
          color: _isDark ? const Color(0xFF10141E) : const Color(0xFFD5DCE6),
          child: const SizedBox.expand(),
        );
    }
  }

  static const List<(String, IconData)> _catalogItems = [
    ('Quick Look', CupertinoIcons.eye),
    ('Share', CupertinoIcons.share),
    ('Duplicate', CupertinoIcons.doc_on_doc),
    ('Move to Folder', CupertinoIcons.folder),
    ('Add Tag', CupertinoIcons.tag),
    ('Favorite', CupertinoIcons.star),
    ('Pin to Top', CupertinoIcons.pin),
    ('Lock Item', CupertinoIcons.lock),
    ('Archive', CupertinoIcons.archivebox),
    ('Delete', CupertinoIcons.trash),
  ];

  List<Widget> _buildMenuItems(MorphMenuLength length) {
    final count = length.itemCount;
    final result = <Widget>[];
    for (var i = 0; i < count; i++) {
      // For short (2-item) menus, use first item + destructive last item.
      final entry = (i == count - 1)
          ? _catalogItems.last
          : _catalogItems[i % (_catalogItems.length - 1)];
      final isDestructive = i == count - 1 && count >= 2;
      final bool attachSubmenu = entry.$1 == 'Move to Folder';
      result.add(
        GlassMenuItem(
          title: entry.$1,
          icon: Icon(entry.$2),
          isDestructive: isDestructive,
          submenu: attachSubmenu
              ? [
                  GlassMenuItem(
                    title: 'Projects',
                    icon: const Icon(CupertinoIcons.folder_fill),
                    submenu: [
                      GlassMenuItem(
                        title: '2026 Releases',
                        icon: const Icon(CupertinoIcons.sparkles),
                        onTap: () => setState(
                          () => _lastAction = '2026 Releases (${length.name})',
                        ),
                      ),
                      GlassMenuItem(
                        title: 'Design Specs',
                        icon: const Icon(CupertinoIcons.doc_text),
                        onTap: () => setState(
                          () => _lastAction = 'Design Specs (${length.name})',
                        ),
                      ),
                    ],
                    onTap: () {},
                  ),
                  GlassMenuItem(
                    title: 'Shared Workspace',
                    icon: const Icon(CupertinoIcons.person_2),
                    onTap: () => setState(
                      () => _lastAction = 'Shared Workspace (${length.name})',
                    ),
                  ),
                  GlassMenuItem(
                    title: 'Archive Vault',
                    icon: const Icon(CupertinoIcons.archivebox),
                    onTap: () => setState(
                      () => _lastAction = 'Archive Vault (${length.name})',
                    ),
                  ),
                ]
              : null,
          onTap: () =>
              setState(() => _lastAction = '${entry.$1} (${length.name})'),
        ),
      );
    }
    return result;
  }

  void _presentMorphSheet(
    BuildContext innerCtx, {
    required GlassMorphAnchor anchor,
    required bool full,
  }) {
    GlassModalSheet.show<void>(
      context: innerCtx,
      morphFrom: anchor,
      quality: _quality,
      initialState: full ? GlassSheetState.full : GlassSheetState.half,
      detents: full
          ? const {GlassSheetDetent.large}
          : const {GlassSheetDetent.medium, GlassSheetDetent.large},
      halfSize: 0.48,
      horizontalMargin: 8.0,
      bottomMargin: 8.0,
      showDragIndicator: !full,
      builder: (sheetCtx) => _MorphSheetContent(
        title: full ? 'Full Sheet Morph' : 'Half Sheet Morph',
        isFull: full,
        quality: _quality,
        onClose: () => Navigator.of(sheetCtx).maybePop(),
      ),
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
        : baseTheme.copyWith(
            light: baseTheme.light.copyWith(quality: _quality),
            dark: baseTheme.dark.copyWith(quality: _quality),
          );
    final buttonQuality = _quality ?? GlassQuality.premium;
    final labelColor = _isDark ? CupertinoColors.white : CupertinoColors.black;
    final secondaryColor =
        _isDark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);

    return GlassTheme(
      data: themeData,
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Morph Parity',
        theme: CupertinoThemeData(
          brightness: brightness,
          primaryColor: CupertinoColors.systemBlue,
        ),
        home: GlassScaffold(
          background: _buildBackdrop(),
          appBar: _buildAppBar(
            labelColor: labelColor,
            buttonQuality: buttonQuality,
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Builder(
              key: _bodyKey,
              builder: (innerCtx) {
                if (_stageTarget != 'off') {
                  return _buildStageView(
                    innerCtx,
                    labelColor: labelColor,
                    secondaryColor: secondaryColor,
                    buttonQuality: buttonQuality,
                  );
                }
                return Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 108, 16, 128),
                      children: [
                        _buildMenuLengthStrip(secondaryColor),
                        const SizedBox(height: 18),
                        _buildSectionCaption(
                          '1. GLASSMENU TRIGGER GEOMETRIES (${_menuLength.label.toUpperCase()})',
                          secondaryColor,
                        ),
                        const SizedBox(height: 10),
                        // Row A + B: Round 44x44 & Medium Pill 120x44
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildRoundMenuTrigger(
                                  labelColor: labelColor,
                                  buttonQuality: buttonQuality,
                                ),
                                const SizedBox(height: 6),
                                _buildMicroLabel('Round 44×44', secondaryColor),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMediumPillMenuTrigger(
                                  labelColor: labelColor,
                                  buttonQuality: buttonQuality,
                                ),
                                const SizedBox(height: 6),
                                _buildMicroLabel('Pill 120×44', secondaryColor),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Trigger C: Wide Centered 260x44
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildWideCenteredMenuTrigger(
                                labelColor: labelColor,
                                buttonQuality: buttonQuality,
                              ),
                              const SizedBox(height: 6),
                              _buildMicroLabel(
                                'Wide Centered 260×44',
                                secondaryColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Trigger D: Wide Left-Aligned 240x44 + Right-Edge 44x44
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildWideLeftMenuTrigger(
                                  labelColor: labelColor,
                                  buttonQuality: buttonQuality,
                                ),
                                const SizedBox(height: 6),
                                _buildMicroLabel(
                                  'Wide Left-Aligned 240×44',
                                  secondaryColor,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildRightEdgeMenuTrigger(
                                  labelColor: labelColor,
                                  buttonQuality: buttonQuality,
                                ),
                                const SizedBox(height: 6),
                                _buildMicroLabel('Right Edge', secondaryColor),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionCaption(
                          '2. OTHER LIQUID MORPH ENGINE WIDGETS',
                          secondaryColor,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            GlassPullDownButton(
                              key: _pullDownKey,
                              label: 'Pull-Down',
                              icon: const Icon(CupertinoIcons.ellipsis_circle),
                              buttonWidth: 140,
                              buttonHeight: 44,
                              menuWidth: 220,
                              menuAlignment: _menuAlignment,
                              quality: buttonQuality,
                              items: _buildMenuItems(_menuLength),
                            ),
                            _buildPopoverTrigger(
                              labelColor: labelColor,
                              secondaryColor: secondaryColor,
                              buttonQuality: buttonQuality,
                            ),
                            _buildRightEdgePopoverTrigger(
                              labelColor: labelColor,
                              buttonQuality: buttonQuality,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GlassMorphTrigger(
                                builder: (ctx, anchor) {
                                  _morphHalfAnchor = anchor;
                                  return GlassButton.custom(
                                    height: 44,
                                    shape: const LiquidRoundedSuperellipse(
                                      borderRadius: 22,
                                    ),
                                    useOwnLayer: true,
                                    quality: buttonQuality,
                                    onTap: () => _presentMorphSheet(
                                      innerCtx,
                                      anchor: anchor,
                                      full: false,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.layers_alt_fill,
                                          size: 17,
                                          color: labelColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Morph Half Sheet',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: labelColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlassMorphTrigger(
                                builder: (ctx, anchor) {
                                  _morphFullAnchor = anchor;
                                  return GlassButton.custom(
                                    height: 44,
                                    shape: const LiquidRoundedSuperellipse(
                                      borderRadius: 22,
                                    ),
                                    useOwnLayer: true,
                                    quality: buttonQuality,
                                    onTap: () => _presentMorphSheet(
                                      innerCtx,
                                      anchor: anchor,
                                      full: true,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons
                                              .arrow_up_right_square_fill,
                                          size: 16,
                                          color: labelColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Morph Full Sheet',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: labelColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            'Last action: $_lastAction  •  Align: ${_menuAlignment.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Pinned bottom bar for upward-opening menus, popovers & sheets
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: _buildBottomUpwardBar(
                        innerCtx,
                        labelColor: labelColor,
                        buttonQuality: buttonQuality,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({
    required Color labelColor,
    required GlassQuality buttonQuality,
  }) {
    return GlassAppBar(
      centerTitle: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      leading: GlassButton.custom(
        width: 68,
        height: 36,
        shape: const LiquidRoundedSuperellipse(borderRadius: 18),
        useOwnLayer: true,
        quality: buttonQuality,
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
      title: Center(
        child: GlassButton.custom(
          width: 78,
          height: 36,
          shape: const LiquidRoundedSuperellipse(borderRadius: 18),
          useOwnLayer: true,
          quality: buttonQuality,
          onTap: () {
            setState(() {
              _menuAlignment = switch (_menuAlignment) {
                GlassMenuAlignment.none => GlassMenuAlignment.topCenter,
                GlassMenuAlignment.topCenter => GlassMenuAlignment.topLeft,
                _ => GlassMenuAlignment.none,
              };
            });
          },
          child: Text(
            switch (_menuAlignment) {
              GlassMenuAlignment.none => 'Auto',
              GlassMenuAlignment.topCenter => 'Center',
              GlassMenuAlignment.topLeft => 'Left',
              _ => _menuAlignment.name,
            },
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ),
      ),
      actions: [
        GlassContainer(
          width: 112,
          height: 40,
          shape: const LiquidRoundedSuperellipse(borderRadius: 20),
          useOwnLayer: true,
          quality: buttonQuality,
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
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: labelColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isDark = !_isDark),
                  child: Center(
                    child: Icon(
                      _isDark
                          ? CupertinoIcons.sun_max_fill
                          : CupertinoIcons.moon_fill,
                      color: _isDark
                          ? CupertinoColors.systemYellow
                          : CupertinoColors.systemIndigo,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuLengthStrip(Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCaption('MENU LENGTH PRESET', secondaryColor),
        const SizedBox(height: 6),
        GlassSegmentedControl(
          quality: _quality,
          selectedIndex: _menuLength.index,
          onSegmentSelected: (idx) => setState(
            () => _menuLength = MorphMenuLength.values[idx],
          ),
          segments: [
            for (final len in MorphMenuLength.values)
              GlassSegment(label: len.label),
          ],
        ),
      ],
    );
  }

  Widget _buildRoundMenuTrigger({
    required Color labelColor,
    required GlassQuality buttonQuality,
  }) {
    return GlassMenu(
      controller: _roundMenuCtrl,
      menuWidth: 220,
      menuAlignment: _menuAlignment,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      quality: buttonQuality,
      items: _buildMenuItems(_menuLength),
      triggerBuilder: (context, toggle) => GlassIconButton(
        size: 44,
        useOwnLayer: true,
        quality: buttonQuality,
        semanticLabel: 'Round Menu Trigger',
        icon: Icon(
          CupertinoIcons.ellipsis,
          size: 20,
          color: labelColor,
        ),
        onPressed: toggle,
      ),
    );
  }

  Widget _buildMediumPillMenuTrigger({
    required Color labelColor,
    required GlassQuality buttonQuality,
  }) {
    return GlassMenu(
      controller: _pillMenuCtrl,
      menuWidth: 220,
      menuAlignment: _menuAlignment,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      quality: buttonQuality,
      items: _buildMenuItems(_menuLength),
      triggerBuilder: (context, toggle) => GlassButton.custom(
        width: 120,
        height: 44,
        shape: const LiquidRoundedSuperellipse(borderRadius: 22),
        useOwnLayer: true,
        quality: buttonQuality,
        label: 'Medium Pill Menu',
        onTap: toggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 16,
              color: labelColor,
            ),
            const SizedBox(width: 6),
            Text(
              'Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.32,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideCenteredMenuTrigger({
    required Color labelColor,
    required GlassQuality buttonQuality,
  }) {
    return GlassMenu(
      controller: _wideCenterMenuCtrl,
      menuWidth: 220,
      menuAlignment: _menuAlignment,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      quality: buttonQuality,
      items: _buildMenuItems(_menuLength),
      triggerBuilder: (context, toggle) => GlassButton.custom(
        width: 260,
        height: 44,
        shape: const LiquidRoundedSuperellipse(borderRadius: 22),
        useOwnLayer: true,
        quality: buttonQuality,
        label: 'Wide Centered Menu',
        onTap: toggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.sparkles,
              size: 17,
              color: labelColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Wide Centered (${_menuLength.itemCount} items)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.32,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLeftMenuTrigger({
    required Color labelColor,
    required GlassQuality buttonQuality,
  }) {
    return GlassMenu(
      controller: _wideLeftMenuCtrl,
      menuWidth: 220,
      menuAlignment: _menuAlignment,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      quality: buttonQuality,
      items: _buildMenuItems(_menuLength),
      triggerBuilder: (context, toggle) => GlassButton.custom(
        width: 240,
        height: 44,
        shape: const LiquidRoundedSuperellipse(borderRadius: 22),
        useOwnLayer: true,
        quality: buttonQuality,
        label: 'Wide Left Menu',
        onTap: toggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.folder,
                size: 17,
                color: labelColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Wide Left (${_menuLength.itemCount} items)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.32,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopoverTrigger({
    required Color labelColor,
    required Color secondaryColor,
    required GlassQuality buttonQuality,
  }) {
    return GlassPopover(
      popoverWidth: 260,
      popoverBorderRadius: 26,
      alignment: _menuAlignment,
      quality: buttonQuality,
      onClose: () => _closePopover = null,
      triggerBuilder: (context, toggle) {
        _togglePopover = toggle;
        return GlassButton.custom(
          width: 132,
          height: 44,
          shape: const LiquidRoundedSuperellipse(borderRadius: 22),
          useOwnLayer: true,
          quality: buttonQuality,
          label: 'Popover Trigger',
          onTap: toggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.info_circle,
                size: 17,
                color: labelColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Popover',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.32,
                  color: labelColor,
                ),
              ),
            ],
          ),
        );
      },
      contentBuilder: (popoverCtx, close) {
        _closePopover = close;
        final fg = CupertinoColors.label.resolveFrom(popoverCtx);
        final sub = CupertinoColors.secondaryLabel.resolveFrom(popoverCtx);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inspector Popover',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Uses GlassMorphController teardrop expansion and return '
                'physics with progressive backdrop blur ramp.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: sub,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: close,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.activeBlue.resolveFrom(popoverCtx),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRightEdgeMenuTrigger({
    required Color labelColor,
    required GlassQuality buttonQuality,
  }) {
    return GlassMenu(
      controller: _rightEdgeMenuCtrl,
      menuWidth: 220,
      menuAlignment: _menuAlignment,
      autoAdjustToScreen: true,
      menuPadding: const EdgeInsets.all(12),
      quality: buttonQuality,
      items: _buildMenuItems(_menuLength),
      triggerBuilder: (context, toggle) => GlassIconButton(
        size: 44,
        useOwnLayer: true,
        quality: buttonQuality,
        semanticLabel: 'Right Edge Menu Trigger',
        icon: Icon(
          CupertinoIcons.arrow_down_left_circle,
          size: 20,
          color: labelColor,
        ),
        onPressed: toggle,
      ),
    );
  }

  Widget _buildRightEdgePopoverTrigger({
    required Color labelColor,
    required GlassQuality buttonQuality,
  }) {
    return GlassPopover(
      popoverWidth: 240,
      popoverBorderRadius: 24,
      alignment: _menuAlignment,
      quality: buttonQuality,
      onClose: () => _closePopover = null,
      triggerBuilder: (context, toggle) {
        _toggleRightPopover = toggle;
        return GlassIconButton(
          size: 44,
          useOwnLayer: true,
          quality: buttonQuality,
          semanticLabel: 'Right Edge Popover Trigger',
          icon: Icon(
            CupertinoIcons.bubble_right,
            size: 19,
            color: labelColor,
          ),
          onPressed: toggle,
        );
      },
      contentBuilder: (popoverCtx, close) {
        _closePopover = close;
        final fg = CupertinoColors.label.resolveFrom(popoverCtx);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Right-edge clamped popover morphs cleanly back into trigger center.',
            style: TextStyle(fontSize: 14, color: fg),
          ),
        );
      },
    );
  }

  Widget _buildBottomUpwardBar(
    BuildContext innerCtx, {
    required Color labelColor,
    required GlassQuality buttonQuality,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Upward Round GlassMenu (44x44)
        GlassMenu(
          controller: _bottomRoundMenuCtrl,
          menuWidth: 220,
          menuAlignment: _menuAlignment,
          autoAdjustToScreen: true,
          menuPadding: const EdgeInsets.all(12),
          quality: buttonQuality,
          items: _buildMenuItems(_menuLength),
          triggerBuilder: (context, toggle) => GlassIconButton(
            size: 44,
            useOwnLayer: true,
            quality: buttonQuality,
            semanticLabel: 'Bottom Round Menu',
            icon: Icon(
              CupertinoIcons.chevron_up,
              size: 19,
              color: labelColor,
            ),
            onPressed: toggle,
          ),
        ),
        // 2. Upward Wide GlassMenu (168x44)
        GlassMenu(
          controller: _bottomWideMenuCtrl,
          menuWidth: 220,
          menuAlignment: _menuAlignment,
          autoAdjustToScreen: true,
          menuPadding: const EdgeInsets.all(12),
          quality: buttonQuality,
          items: _buildMenuItems(_menuLength),
          triggerBuilder: (context, toggle) => GlassButton.custom(
            width: 168,
            height: 44,
            shape: const LiquidRoundedSuperellipse(borderRadius: 22),
            useOwnLayer: true,
            quality: buttonQuality,
            label: 'Bottom Wide Menu',
            onTap: toggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.arrow_up_circle,
                  size: 17,
                  color: labelColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Upward Wide',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 3. Upward GlassPopover (44x44)
        GlassPopover(
          popoverWidth: 250,
          popoverBorderRadius: 24,
          alignment: _menuAlignment,
          quality: buttonQuality,
          onClose: () => _closePopover = null,
          triggerBuilder: (context, toggle) {
            _toggleBottomPopover = toggle;
            return GlassIconButton(
              size: 44,
              useOwnLayer: true,
              quality: buttonQuality,
              semanticLabel: 'Bottom Upward Popover',
              icon: Icon(
                CupertinoIcons.chat_bubble_text,
                size: 19,
                color: labelColor,
              ),
              onPressed: toggle,
            );
          },
          contentBuilder: (popoverCtx, close) {
            _closePopover = close;
            final fg = CupertinoColors.label.resolveFrom(popoverCtx);
            final sub = CupertinoColors.secondaryLabel.resolveFrom(popoverCtx);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upward Popover',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Opens upward from the bottom bar and recoils downward at ~183ms on close.',
                    style: TextStyle(fontSize: 13, color: sub),
                  ),
                ],
              ),
            );
          },
        ),
        // 4. Bottom FAB GlassMorphTrigger -> Half Sheet
        GlassMorphTrigger(
          builder: (ctx, anchor) {
            _morphBottomAnchor = anchor;
            return GlassIconButton(
              size: 44,
              useOwnLayer: true,
              quality: buttonQuality,
              semanticLabel: 'Bottom Morph Sheet',
              icon: Icon(
                CupertinoIcons.plus,
                size: 21,
                color: labelColor,
              ),
              onPressed: () => _presentMorphSheet(
                innerCtx,
                anchor: anchor,
                full: false,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Unobstructed single-trigger stage for automated pixel bounding-box scans.
  Widget _buildStageView(
    BuildContext innerCtx, {
    required Color labelColor,
    required Color secondaryColor,
    required GlassQuality buttonQuality,
  }) {
    if (_stageTarget == 'bottom_round' ||
        _stageTarget == 'bottom_wide' ||
        _stageTarget == 'bottom_popover') {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: switch (_stageTarget) {
            'bottom_wide' => GlassMenu(
                controller: _bottomWideMenuCtrl,
                menuWidth: 220,
                menuAlignment: _menuAlignment,
                autoAdjustToScreen: true,
                menuPadding: const EdgeInsets.all(12),
                quality: buttonQuality,
                items: _buildMenuItems(_menuLength),
                triggerBuilder: (context, toggle) => GlassButton.custom(
                  width: 240,
                  height: 44,
                  shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                  useOwnLayer: true,
                  quality: buttonQuality,
                  onTap: toggle,
                  child: Text(
                    'Bottom Wide',
                    style: TextStyle(fontSize: 15, color: labelColor),
                  ),
                ),
              ),
            'bottom_popover' => _buildBottomUpwardBar(
                innerCtx,
                labelColor: labelColor,
                buttonQuality: buttonQuality,
              ),
            _ => GlassMenu(
                controller: _bottomRoundMenuCtrl,
                menuWidth: 220,
                menuAlignment: _menuAlignment,
                autoAdjustToScreen: true,
                menuPadding: const EdgeInsets.all(12),
                quality: buttonQuality,
                items: _buildMenuItems(_menuLength),
                triggerBuilder: (context, toggle) => GlassIconButton(
                  size: 44,
                  useOwnLayer: true,
                  quality: buttonQuality,
                  icon: Icon(CupertinoIcons.chevron_up, color: labelColor),
                  onPressed: toggle,
                ),
              ),
          },
        ),
      );
    }

    final Widget staged = switch (_stageTarget) {
      'round' => Center(
          child: _buildRoundMenuTrigger(
            labelColor: labelColor,
            buttonQuality: buttonQuality,
          ),
        ),
      'pill' => Center(
          child: _buildMediumPillMenuTrigger(
            labelColor: labelColor,
            buttonQuality: buttonQuality,
          ),
        ),
      'wide_center' => Center(
          child: _buildWideCenteredMenuTrigger(
            labelColor: labelColor,
            buttonQuality: buttonQuality,
          ),
        ),
      'wide_left' => Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildWideLeftMenuTrigger(
              labelColor: labelColor,
              buttonQuality: buttonQuality,
            ),
          ),
        ),
      'right_edge' => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildRightEdgeMenuTrigger(
              labelColor: labelColor,
              buttonQuality: buttonQuality,
            ),
          ),
        ),
      _ => const SizedBox.shrink(),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 180),
      child: Column(
        children: [
          staged,
        ],
      ),
    );
  }

  Widget _buildSectionCaption(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: color,
      ),
    );
  }

  Widget _buildMicroLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

class _MorphSheetContent extends StatelessWidget {
  const _MorphSheetContent({
    required this.title,
    required this.isFull,
    required this.onClose,
    this.quality,
  });

  final String title;
  final bool isFull;
  final VoidCallback onClose;
  final GlassQuality? quality;

  @override
  Widget build(BuildContext context) {
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final cardColor = isFull
        ? (isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white)
        : (isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlassIconButton(
                size: 40,
                useOwnLayer: true,
                quality: quality ?? GlassQuality.premium,
                semanticLabel: 'Close Sheet',
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
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Presented from GlassMorphTrigger via GlassMorphAnchor. '
                'Dismissing hands the closing spring state back to the '
                'trigger to complete the underdamped catch.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: secondaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

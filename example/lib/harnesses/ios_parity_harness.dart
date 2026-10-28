// iOS 26/27 parity harness — the seven roadmap widgets, beside native SwiftUI.
//
// Mirrors tool/parity/ios_reference/ParityApp.swift screen for screen (same
// copy, same rows, same sizes) so the simulator screenshots of the two apps
// can be compared directly. Native captures live in tool/parity/captures/.
//
// Nothing here is a showcase: the harness is driven by a command file so a
// script can switch screens and put widgets into interactive states (swipe
// revealed, context menu open, cover presented) without rebuilding. Write one
// command per file write to /tmp/lgw_parity_cmd.txt:
//
//   tab <0-4>            select a screen
//   scroll <pixels>      scroll the current screen to an absolute offset
//   swipe <row> t|l|c    open trailing / leading actions of a contact row, or close
//   menu <row>           present the context menu for a contact row
//   edit on|off          toggle edit mode on the Edit Mode screen
//   cover                present the full-screen cover
//   expand <0-2> on|off  expand / collapse a disclosure group
//   dark on|off          switch the harness to dark / light appearance
//   ptr down|move|up x y inject a touch at logical (x, y) — works with the
//                        simulator window in the background
//
//   cd example && flutter run -t lib/harnesses/ios_parity_harness.dart -d <udid>
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart' show GestureBinding;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _cmdFile = '/tmp/lgw_parity_cmd.txt';
const _workspaceCmdFile =
    '/Users/sdegenaar/development/liquid_glass_widgets/tools/parity/captures/cmd.txt';

/// Whether the harness renders in dark appearance (`dark on|off` command).
/// Driven by command rather than the OS so captures are deterministic.
final _dark = ValueNotifier<bool>(false);

/// Dark-mode pill / button glass settings matching the Apple Music example.
const _kDarkPillGlassSettings = LiquidGlassSettings(
  glassColor: Color(0xCC1C1C1E),
  thickness: 30,
  blur: 2,
  lightIntensity: 0.18,
  chromaticAberration: 0.01,
  saturation: 1.2,
  fresnelStrength: 0.0,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const _App()));
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: _dark,
        builder: (context, dark, _) => GlassTheme(
          data: const GlassThemeData.ios27(),
          child: CupertinoApp(
            debugShowCheckedModeBanner: false,
            title: 'iOS Parity',
            theme: CupertinoThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: const _ParityHost(),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Host + command channel
// ---------------------------------------------------------------------------

class _ParityHost extends StatefulWidget {
  const _ParityHost();

  @override
  State<_ParityHost> createState() => _ParityHostState();
}

class _ParityHostState extends State<_ParityHost> {
  int _tab = 0;
  String _bgMode = 'default';
  Timer? _poll;
  String? _lastCmd;
  Offset _lastPtr = Offset.zero;

  final _scroll = ScrollController();
  late List<_Contact> _contacts;
  late List<GlassSwipeController> _swipe;
  late List<GlobalKey> _rowKeys;
  final _edit = GlassEditController(initialMode: GlassEditMode.active);
  final _expanded = ValueNotifier<List<bool>>([true, false, false]);
  final _emergencyContact = ValueNotifier<bool>(true);
  final _airDrop = ValueNotifier<bool>(true);
  final _sharePhoto = ValueNotifier<bool>(true);
  final _standaloneExpanded = ValueNotifier<bool>(true);
  final _pushNotifications = ValueNotifier<bool>(true);
  final _fullNameCtrl = TextEditingController(text: 'Alex Rivera');
  final _bioCtrl =
      TextEditingController(text: 'Product Design Director at Acme Corp.');
  final _passwordCtrl = TextEditingController(text: 'secretpassword');
  bool _showInputs = false;
  final _activeMenuIndex = ValueNotifier<int?>(null);
  final _navPath = GlassNavigationPath();
  GlassMorphAnchor? _morphFullAnchor;
  GlassMorphAnchor? _morphHalfAnchor;

  @override
  void initState() {
    super.initState();
    _contacts = List.of(_initialContacts);
    _swipe = List.generate(_contacts.length, (_) => GlassSwipeController());
    _rowKeys = List.generate(_contacts.length, (_) => GlobalKey());
    for (final path in [_cmdFile, _workspaceCmdFile]) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    _dark.addListener(_onDarkChanged);
    _navPath.addListener(_onNavPathChanged);
    _poll = Timer.periodic(const Duration(milliseconds: 16), (_) => _check());
  }

  void _onNavPathChanged() {
    if (mounted) setState(() {});
  }

  void _deleteContact(int index) {
    if (index < 0 || index >= _contacts.length) return;
    setState(() {
      _contacts.removeAt(index);
      if (index < _swipe.length) _swipe.removeAt(index);
      if (index < _rowKeys.length) _rowKeys.removeAt(index);
    });
  }

  void _toggleFavorite(int index) {
    if (index < 0 || index >= _contacts.length) return;
    setState(() {
      _contacts[index] = _contacts[index].copyWith(
        favorite: !_contacts[index].favorite,
      );
    });
  }

  void _onDarkChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _dark.removeListener(_onDarkChanged);
    _navPath.removeListener(_onNavPathChanged);
    _poll?.cancel();
    super.dispose();
  }

  void _check() {
    File? active;
    for (final path in [_workspaceCmdFile, _cmdFile]) {
      final f = File(path);
      if (f.existsSync()) {
        active = f;
        break;
      }
    }
    if (active == null) return;
    final cmd = active.readAsStringSync().trim();
    if (cmd.isEmpty || _lastCmd == cmd) return;
    _lastCmd = cmd;
    _run(cmd.split(RegExp(r'\s+')));
  }

  void _run(List<String> a) {
    switch (a[0]) {
      case 'tap':
        final pos = Offset(double.parse(a[1]), double.parse(a[2]));
        final binding = GestureBinding.instance;
        binding
            .handlePointerEvent(PointerDownEvent(position: pos, pointer: 78));
        Future.delayed(const Duration(milliseconds: 40), () {
          binding
              .handlePointerEvent(PointerUpEvent(position: pos, pointer: 78));
        });
      case 'drag':
        final start = Offset(double.parse(a[1]), double.parse(a[2]));
        final end = Offset(double.parse(a[3]), double.parse(a[4]));
        final steps = a.length > 5 ? int.parse(a[5]) : 16;
        final binding = GestureBinding.instance;
        var prev = start;
        var now = Duration.zero;
        binding.handlePointerEvent(
          PointerDownEvent(position: start, pointer: 79, timeStamp: now),
        );
        for (var i = 1; i <= steps; i++) {
          Future.delayed(Duration(milliseconds: 16 * i), () {
            final t = i / steps;
            final cur = Offset.lerp(start, end, t)!;
            final ts = Duration(milliseconds: 16 * i);
            binding.handlePointerEvent(
              PointerMoveEvent(
                position: cur,
                delta: cur - prev,
                pointer: 79,
                timeStamp: ts,
              ),
            );
            prev = cur;
            if (i == steps) {
              binding.handlePointerEvent(
                PointerUpEvent(position: end, pointer: 79, timeStamp: ts),
              );
            }
          });
        }
      case 'ptr':
        // ptr down|move|up <x> <y> — inject a touch at logical coordinates.
        final pos = Offset(double.parse(a[2]), double.parse(a[3]));
        final binding = GestureBinding.instance;
        final PointerEvent event = switch (a[1]) {
          'down' => PointerDownEvent(position: pos, pointer: 77),
          'move' =>
            PointerMoveEvent(position: pos, delta: pos - _lastPtr, pointer: 77),
          _ => PointerUpEvent(position: pos, pointer: 77),
        };
        _lastPtr = pos;
        binding.handlePointerEvent(event);
      case 'dark':
        _dark.value = a[1] == 'on';
        setState(() {});
      case 'bg':
        _bgMode = a.length > 1 ? a[1] : 'default';
        setState(() {});
      case 'pop':
        if (_tab == 4 && _navPath.isNotEmpty) {
          _navPath.pop();
          return;
        }
        try {
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) {
            nav.pop();
          }
        } catch (_) {}
      case 'tab':
        try {
          final nav = Navigator.of(context, rootNavigator: true);
          while (nav.canPop()) {
            nav.pop();
          }
        } catch (_) {}
        _navPath.popToRoot();
        setState(() => _tab = int.parse(a[1]));
      case 'scroll':
        if (_scroll.hasClients && _scroll.position.hasContentDimensions) {
          _scroll.jumpTo(double.parse(a[1]));
        }
      case 'swipe':
        final idx = int.parse(a[1]);
        if (idx >= _swipe.length) return;
        final c = _swipe[idx];
        switch (a[2]) {
          case 't':
            c.openTrailing();
          case 'l':
            c.openLeading();
          case 'offset':
            c.animateToOffset(double.parse(a[3]));
          case 'dismiss':
            c.dismiss();
          default:
            c.close();
        }
      case 'menu':
        final idx = int.parse(a[1]);
        if (idx >= _rowKeys.length) return;
        final box =
            _rowKeys[idx].currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        _activeMenuIndex.value = idx;
        showGlassContextMenu<void>(
          context: context,
          targetRect: rect,
          previewBuilder: (_) => _VipPreview(_contacts[idx]),
          previewChild: _rowPreview(idx),
          actions: _menuActions(idx),
        ).then((_) {
          if (mounted) _activeMenuIndex.value = null;
        });
      case 'menu_hold':
        final idx = int.parse(a[1]);
        if (idx >= _rowKeys.length) return;
        final box =
            _rowKeys[idx].currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        _activeMenuIndex.value = idx;
        showGlassContextMenu<void>(
          context: context,
          targetRect: rect,
          previewBuilder: (_) => _VipPreview(_contacts[idx]),
          previewChild: _rowPreview(idx),
          actions: _menuActions(idx),
          isInteractive: true,
          commitDuration: const Duration(seconds: 10),
        ).then((_) {
          if (mounted) _activeMenuIndex.value = null;
        });
      case 'edit':
        a[1] == 'on' ? _edit.startEditing() : _edit.stopEditing();
      case 'cover':
        _presentCover();
      case 'morph_full':
        _presentMorphSheet(full: true);
      case 'morph_half':
        _presentMorphSheet(full: false);
      case 'push':
        if (a.length > 1 && a[1] == 'deeper') {
          final current = _navPath.elements.lastOrNull as String? ??
              'Level 1: Optics Architecture';
          _navPath.append('$current -> Deeper');
        } else {
          _navPath.append('Level 1: Optics Architecture');
        }
      case 'expand':
        final v = [..._expanded.value];
        v[int.parse(a[1])] = a[2] == 'on';
        _expanded.value = v;
      case 'inputs':
        setState(() {
          _tab = 1;
          _showInputs = a[1] == 'on';
        });
      case 'toggle':
        switch (a[1]) {
          case '0':
            _emergencyContact.value = a[2] == 'on';
          case '1':
            _airDrop.value = a[2] == 'on';
          case '2':
            _sharePhoto.value = a[2] == 'on';
        }
      case 'picker_date':
        setState(() {
          _graphicalDate = DateTime(_now.year, _now.month, int.parse(a[1]));
        });
      case 'picker_multi':
        setState(() {
          if (a.length < 2 || a[1] == 'none') {
            _multi = {};
          } else {
            _multi = a[1]
                .split(',')
                .map((s) => DateTime(_now.year, _now.month, int.parse(s)))
                .toSet();
          }
        });
    }
  }

  void _presentCover() {
    final isDark = _dark.value;
    final buttonSettings = isDark ? _kDarkPillGlassSettings : null;
    showGlassFullScreenCover<void>(
      context: context,
      builder: (ctx) => GlassFullScreenCover(
        title: const Text('Modal Cover'),
        settings: buttonSettings,
        leading: GlassFullScreenCoverBarButton(
          label: 'Cancel',
          settings: buttonSettings,
          onPressed: () => Navigator.of(ctx).maybePop(),
        ),
        closeButtonLabel: 'Done',
        onDismiss: () {},
        child: const _CoverBody(),
      ),
    );
  }

  void _presentMorphSheet({required bool full}) {
    final isDark = _dark.value;
    final anchor = full ? _morphFullAnchor : _morphHalfAnchor;
    final sheetGlass =
        (isDark ? _kDarkPillGlassSettings : LiquidGlassSettings.ios27Light)
            .copyWith(blur: 10);
    GlassModalSheet.show<void>(
      context: context,
      morphFrom: anchor,
      halfSize: 459.33,
      fullSize: 812.0,
      // Same-method edge scans of 3x captures: a 7.33pt margin renders 0.67pt
      // wider per side than the native half detent, so native is 8.0pt.
      horizontalMargin: 8.0,
      bottomMargin: 7.33,
      barrierColor: const Color(0x33000000),
      settings: sheetGlass,
      initialState: full ? GlassSheetState.full : GlassSheetState.half,
      detents: full
          ? const {GlassSheetDetent.large}
          : const {GlassSheetDetent.medium, GlassSheetDetent.large},
      expandedColor: const Color(0xFFF2F2F7),
      expandedDarkColor: const Color(0xFF1C1C1E),
      showDragIndicator: !full,
      dragIndicatorTopPadding: 6.0,
      dragIndicatorHeight: 4.5,
      builder: (sheetCtx) => _MorphComposeSheetBody(
        title: full ? 'New Message' : 'Morph from trigger',
        full: full,
        onClose: () => Navigator.of(sheetCtx).maybePop(),
      ),
    );
  }

  Widget _rowPreview(int index) {
    if (index < 0 || index >= _contacts.length) return const SizedBox.shrink();
    final c = _contacts[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: _Avatar(c, 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          if (c.favorite)
            const Icon(
              CupertinoIcons.star_fill,
              size: 15,
              color: Color(0xFFFFCC00),
            ),
        ],
      ),
    );
  }

  List<Widget> _menuActions(int index) => [
        GlassContextMenuAction(
          icon: Icon(_contacts[index].favorite
              ? CupertinoIcons.star_slash
              : CupertinoIcons.star_fill),
          iconPosition: GlassContextMenuIconPosition.leading,
          child: Text(_contacts[index].favorite ? 'Unfavorite' : 'Favorite'),
          onPressed: () => _toggleFavorite(index),
        ),
        GlassContextMenuAction(
          icon: const Icon(CupertinoIcons.doc_on_doc),
          iconPosition: GlassContextMenuIconPosition.leading,
          child: const Text('Copy Phone'),
          onPressed: () {},
        ),
        GlassContextMenuAction(
          icon: const Icon(CupertinoIcons.trash),
          iconPosition: GlassContextMenuIconPosition.leading,
          isDestructive: true,
          child: const Text('Delete Contact'),
          onPressed: () => _swipe[index].dismiss(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _swipeAndMenu(),
      _disclosure(),
      _editMode(),
      _pickers(),
      _modalsAndNav(),
    ];
    final activePage = _tab == 2
        ? GlassEditScope(controller: _edit, child: pages[_tab])
        : pages[_tab];

    final isDark = _dark.value;
    final pageSettings =
        isDark ? _kDarkPillGlassSettings : LiquidGlassSettings.ios27Light;

    Widget? customBg;
    if (_bgMode == 'mid') {
      customBg = const ColoredBox(
        color: Color(0xFF808080),
        child: SizedBox.expand(),
      );
    } else if (_bgMode == 'vivid') {
      customBg = Column(
        children: [
          const Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromRGBO(38, 115, 242, 1),
                    Color.fromRGBO(140, 64, 230, 1),
                    Color.fromRGBO(242, 77, 115, 1),
                  ],
                ),
              ),
              child: SizedBox.expand(),
            ),
          ),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(
                    child: ColoredBox(color: Color.fromRGBO(255, 59, 48, 1))),
                Expanded(
                    child: ColoredBox(color: Color.fromRGBO(255, 148, 0, 1))),
                Expanded(
                    child: ColoredBox(color: Color.fromRGBO(51, 199, 89, 1))),
                Expanded(
                    child: ColoredBox(color: Color.fromRGBO(0, 122, 255, 1))),
                Expanded(
                    child: ColoredBox(color: Color.fromRGBO(176, 82, 222, 1))),
              ],
            ),
          ),
        ],
      );
    }

    return GlassScaffold(
      background: customBg,
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      settings: pageSettings,
      bottomEdgeFade:
          _bgMode == 'default' && !(_tab == 4 && _navPath.isNotEmpty),
      bottomBar: GlassTabBar.bottom(
        selectedIndex: _tab,
        onTabSelected: (idx) => setState(() => _tab = idx),
        quality: GlassQuality.premium,
        backgroundQuality: GlassQuality.premium,
        barHeight: 62,
        horizontalPadding: 21,
        verticalPadding: 21,
        iconSize: 27,
        iconLabelSpacing: 2,
        labelFontSize: 10,
        selectedIconColor: CupertinoColors.systemBlue.resolveFrom(context),
        tabs: const [
          GlassTab(
            icon: Icon(CupertinoIcons.hand_draw_fill),
            label: 'Swipe & Menu',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.chevron_down_circle_fill),
            label: 'Disclosure',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.pencil_circle_fill),
            label: 'Edit Mode',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.calendar_circle_fill),
            label: 'Pickers',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.arrow_up_right_square_fill),
            label: 'Modals & Nav',
          ),
        ],
      ),
      body: GlassSwipeActionScope(
        child: activePage,
      ),
    );
  }

  // -- shared page chrome ----------------------------------------------------

  Widget _page(String title, List<Widget> children, {Widget? trailing}) {
    return Stack(
      children: [
        ListView(
          key: ValueKey(title),
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 118, 16, 140),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w700, height: 1.2)),
            ),
            ...children,
          ],
        ),
        Positioned(
          top: 60,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ThemeToggle(),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _info(String text) => GlassContainer.card(
        surfaceStyle: GlassSurfaceStyle.solid,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(text,
            style: TextStyle(
                // Native `.footnote` renders ~5% wider than Flutter's 13pt
                // (measured on the iOS 27 simulator).
                fontSize: 13.7,
                height: 1.29,
                color: CupertinoColors.secondaryLabel.resolveFrom(context))),
      );

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.41,
                color: CupertinoColors.systemGrey)),
      );

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.41,
                color: CupertinoColors.systemGrey)),
      );

  // -- 0. Swipe & menu ------------------------------------------------------

  Widget _swipeAndMenu() {
    return _page('Swipe & Menu', [
      _info('Swipe left for Delete / Flag. Swipe right to Pin. Long press any '
          'row for Context Menu with VIP Preview.'),
      GlassGroupedSection(
        surfaceStyle: GlassSurfaceStyle.solid,
        margin: EdgeInsets.zero,
        header: _sectionHeader('Contacts (.swipeActions & .contextMenu)'),
        children: [
          for (var i = 0; i < _contacts.length; i++) ...[
            // Native dividers are inset to the text start and end at a 16pt
            // inset.
            if (i > 0) const GlassDivider(indent: 72, endIndent: 16),
            ValueListenableBuilder<int?>(
              key: ValueKey(_contacts[i].name),
              valueListenable: _activeMenuIndex,
              builder: (context, activeIdx, child) {
                return Opacity(
                  opacity: activeIdx == i ? 0.0 : 1.0,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: _rowKeys[i],
                child: GlassListTile(
                  swipeController: _swipe[i],
                  allowsFullSwipe: true,
                  onDismissed: () => _deleteContact(i),
                  contextMenuActions: _menuActions(i),
                  contextMenuPreviewBuilder: (_) => _VipPreview(_contacts[i]),
                  trailingSwipeActions: [
                    GlassSwipeAction(
                      icon: const Icon(CupertinoIcons.trash),
                      label: const Text('Delete'),
                      isDestructive: true,
                      onTap: () => _swipe[i].dismiss(),
                    ),
                    GlassSwipeAction(
                      icon: const Icon(CupertinoIcons.flag_fill),
                      label: const Text('Flag'),
                      backgroundColor: CupertinoColors.systemOrange,
                      onTap: () => _toggleFavorite(i),
                    ),
                  ],
                  leadingSwipeActions: [
                    GlassSwipeAction(
                      icon: const Icon(CupertinoIcons.pin_fill),
                      label: const Text('Pin'),
                      backgroundColor: CupertinoColors.systemBlue,
                      onTap: () => _toggleFavorite(i),
                    ),
                  ],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  leading: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: _Avatar(_contacts[i], 44)),
                  title: Text(_contacts[i].name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  subtitle: Text(_contacts[i].title,
                      style: const TextStyle(
                          fontSize: 13, color: CupertinoColors.systemGrey)),
                  trailing: _contacts[i].favorite
                      ? const Icon(CupertinoIcons.star_fill,
                          size: 15, color: Color(0xFFFFCC00))
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    ]);
  }

  // -- 1. Disclosure --------------------------------------------------------

  Widget _disclosure() {
    if (_showInputs) return _inputsAndWells();
    return ValueListenableBuilder<List<bool>>(
      valueListenable: _expanded,
      builder: (context, ex, _) => _page('Disclosure', [
        _info('SwiftUI DisclosureGroup rotates chevron 90° upon expansion and '
            'insets dividers under child rows.'),
        GlassGroupedSection(
          surfaceStyle: GlassSurfaceStyle.solid,
          margin: EdgeInsets.zero,
          header: _sectionHeader('Collapsible Sections (DisclosureGroup)'),
          children: [
            GlassDisclosureGroup(
              isExpanded: ex[0],
              onExpansionChanged: (v) => _setExpanded(0, v),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              leading: const Icon(CupertinoIcons.heart_fill,
                  color: CupertinoColors.systemRed, size: 20),
              title: const Text('Emergency & Medical',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: const Text('Blood type, conditions, alerts',
                  style: TextStyle(
                      fontSize: 12, color: CupertinoColors.systemGrey)),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(children: [
                    _kv('Emergency Contact', null,
                        trailing: ValueListenableBuilder<bool>(
                          valueListenable: _emergencyContact,
                          builder: (context, val, _) => GlassSwitch(
                            value: val,
                            quality: GlassQuality.premium,
                            onChanged: (v) => _emergencyContact.value = v,
                          ),
                        )),
                    _kv('Blood Type', 'O+'),
                    _kv('Medical ID', 'Active',
                        valueColor: CupertinoColors.systemGreen),
                  ]),
                ),
              ],
            ),
            // Native dividers inset to the text start of the preceding row.
            GlassDivider(indent: ex[0] ? 35 : 71, endIndent: 16),
            GlassDisclosureGroup(
              isExpanded: ex[1],
              onExpansionChanged: (v) => _setExpanded(1, v),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              leading: const Icon(CupertinoIcons.person_2_fill,
                  color: CupertinoColors.systemBlue, size: 20),
              title: const Text('Social Profiles & Handles',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: const Text('Online presence & profiles',
                  style: TextStyle(
                      fontSize: 12, color: CupertinoColors.systemGrey)),
              children: [
                // Native child blocks carry ~14pt top and ~13pt bottom
                // padding around the rows.
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 13),
                  child: Column(children: [
                    _kv('X / Twitter', '@alexrivera',
                        leading: const Icon(CupertinoIcons.chat_bubble_2_fill,
                            size: 22, color: CupertinoColors.systemBlue)),
                    _kv('GitHub', 'alexrivera',
                        leading: const Icon(
                            CupertinoIcons.chevron_left_slash_chevron_right,
                            size: 20,
                            color: CupertinoColors.systemPurple)),
                  ]),
                ),
              ],
            ),
            GlassDivider(indent: ex[1] ? 70 : 71, endIndent: 16),
            GlassDisclosureGroup(
              isExpanded: ex[2],
              onExpansionChanged: (v) => _setExpanded(2, v),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              leading: const Icon(CupertinoIcons.lock_shield_fill,
                  color: CupertinoColors.systemGreen, size: 20),
              title: const Text('Privacy & AirDrop Sharing',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              subtitle: const Text('Permissions and contact poster',
                  style: TextStyle(
                      fontSize: 12, color: CupertinoColors.systemGrey)),
              children: [
                _kv('AirDrop Discoverable', null,
                    trailing: ValueListenableBuilder<bool>(
                      valueListenable: _airDrop,
                      builder: (context, val, _) => GlassSwitch(
                        quality: GlassQuality.premium,
                        value: val,
                        onChanged: (v) => _airDrop.value = v,
                      ),
                    )),
                _kv('Share Name & Photo', null,
                    trailing: ValueListenableBuilder<bool>(
                      valueListenable: _sharePhoto,
                      builder: (context, val, _) => GlassSwitch(
                        quality: GlassQuality.premium,
                        value: val,
                        onChanged: (v) => _sharePhoto.value = v,
                      ),
                    )),
              ],
            ),
          ],
        ),
      ]),
    );
  }

  void _setExpanded(int i, bool v) {
    final l = [..._expanded.value];
    l[i] = v;
    _expanded.value = l;
  }

  Widget _inputsAndWells() {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return _page('Inputs & Wells', [
      GlassGroupedSection(
        surfaceStyle: GlassSurfaceStyle.solid,
        margin: EdgeInsets.zero,
        header: _sectionHeader('Solid Inputs in Card (tertiarySystemFill)'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. GlassSearchBar (auto-inherits solid)
                const GlassSearchBar(
                  placeholder: 'Search contacts...',
                  height: 36,
                ),
                const SizedBox(height: 12),
                // 2. GlassTextField with prefix icon (auto-inherits solid)
                GlassTextField(
                  controller: _fullNameCtrl,
                  prefixIcon: Icon(
                    CupertinoIcons.person,
                    size: 18,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 12),
                // 3. GlassTextArea (auto-inherits solid)
                GlassTextArea(
                  controller: _bioCtrl,
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                // 4. GlassPasswordField (auto-inherits solid)
                GlassPasswordField(
                  controller: _passwordCtrl,
                ),
                const SizedBox(height: 12),
                // 5. GlassPicker (auto-inherits solid)
                GlassPicker(
                  value: 'Product Design Director',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
      _header('Standalone Disclosure (GlassDisclosureGroup.standalone)'),
      ValueListenableBuilder<bool>(
        valueListenable: _standaloneExpanded,
        builder: (context, expanded, _) => GlassDisclosureGroup.standalone(
          surfaceStyle: GlassSurfaceStyle.solid,
          isExpanded: expanded,
          onExpansionChanged: (v) => _standaloneExpanded.value = v,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          leading: const Icon(
            CupertinoIcons.bell_fill,
            color: CupertinoColors.systemRed,
            size: 20,
          ),
          title: const Text(
            'Notifications & Alerts',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          children: [
            _kv(
              'Push Notifications',
              null,
              trailing: ValueListenableBuilder<bool>(
                valueListenable: _pushNotifications,
                builder: (context, val, _) => GlassSwitch(
                  value: val,
                  quality: GlassQuality.premium,
                  onChanged: (v) => _pushNotifications.value = v,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _kv('Alert Style', 'Banners'),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _kv(String k, String? v,
          {Widget? trailing, Color? valueColor, Widget? leading}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(width: 24, child: Center(child: leading)),
              const SizedBox(width: 11),
            ],
            Text(k, style: const TextStyle(fontSize: 17)),
            const Spacer(),
            if (v != null)
              Text(v,
                  style: TextStyle(
                      fontSize: 17,
                      color: valueColor ?? CupertinoColors.systemGrey)),
            if (trailing != null) trailing,
          ],
        ),
      );

  // -- 2. Edit mode ---------------------------------------------------------

  final _items = [
    'iPhone 18 Pro Glass Prototype',
    'Vision Pro Ultra Lensing',
    'Impeller Dual-Pipeline Shader',
    'Continuous Superellipse Squircle',
    'Adaptive Liquid Glass Chrome',
  ];

  final Set<String> _selected = {'Vision Pro Ultra Lensing'};

  Widget _editMode() {
    return AnimatedBuilder(
      animation: _edit,
      builder: (context, _) => _page(
        'Edit Mode',
        [
          _info('SwiftUI EditMode provides circular red delete buttons, inline '
              'Delete pills, 3-bar drag handles, and multi-selection.'),
          GlassReorderableList.grouped(
            surfaceStyle: GlassSurfaceStyle.solid,
            padding: EdgeInsets.zero,
            dividerIndent: 124,
            dividerEndIndent: 16,
            header:
                _sectionHeader('Edit Mode & Reordering (EditButton + ForEach)'),
            itemCount: _items.length,
            onReorder: (o, n) => setState(() {
              if (o < n) n -= 1;
              _items.insert(n, _items.removeAt(o));
            }),
            itemBuilder: (context, i) => GlassListTile(
              key: ValueKey(_items[i]),
              // Native row = 57.3pt (one line) / 76.3pt (two lines): 16pt text,
              // 19pt line, 19pt vertical inset. The 44pt handle sets the floor,
              // so the inset is split between the tile and the title.
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6.5),
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.64),
                child: Row(
                  children: [
                    const SizedBox(width: 3.6),
                    CustomPaint(
                      size: const Size(16, 16),
                      painter:
                          _DashedSquirclePainter(CupertinoColors.systemBlue),
                    ),
                    const SizedBox(width: 10.4),
                    Expanded(
                      child: Text(
                        _items[i],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.19,
                          letterSpacing: -0.32,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              canReorder: true,
              reorderIndex: i,
              canSelect: true,
              isSelected: _selected.contains(_items[i]),
              onSelectedChanged: (v) => setState(() {
                v ? _selected.add(_items[i]) : _selected.remove(_items[i]);
              }),
              onDelete: () => setState(() => _items.removeAt(i)),
            ),
          ),
        ],
        trailing: const GlassEditButton(),
      ),
    );
  }

  // -- 3. Pickers -----------------------------------------------------------

  final _now = DateTime.now();
  late DateTime _graphicalDate = _now;
  Set<DateTime> _multi = {};

  Widget _pickers() {
    return _page('Pickers', [
      _header('Wheel Picker (DatePickerStyle.wheel)'),
      GlassDatePicker.wheel(
        initialDateTime: _now,
        surfaceStyle: GlassSurfaceStyle.solid,
        onDateTimeChanged: (_) {},
      ),
      _header('Compact Picker (DatePickerStyle.compact)'),
      GlassContainer.card(
        surfaceStyle: GlassSurfaceStyle.solid,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15.5),
        child: Row(
          children: [
            const Text('Date & Time', style: TextStyle(fontSize: 17)),
            const Spacer(),
            GlassDatePicker.compact(
              initialDateTime: _now,
              mode: GlassDatePickerMode.dateAndTime,
              surfaceStyle: GlassSurfaceStyle.solid,
              onDateTimeChanged: (_) {},
            ),
          ],
        ),
      ),
      _header('Graphical Calendar (DatePickerStyle.graphical)'),
      GlassDatePicker.graphical(
        initialDateTime: _graphicalDate,
        firstDayOfWeek: 7,
        surfaceStyle: GlassSurfaceStyle.solid,
        onDateTimeChanged: (d) => setState(() => _graphicalDate = d),
      ),
      _header('Multi-Date Selection (MultiDatePicker)'),
      GlassContainer.card(
        surfaceStyle: GlassSurfaceStyle.solid,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassMultiDatePicker(
              selectedDates: _multi,
              displayedMonth: _now,
              firstDayOfWeek: 7,
              surfaceStyle: GlassSurfaceStyle.solid,
              onDatesChanged: (s) => setState(() => _multi = s),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 0.5,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selected dates count: ${_multi.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // -- 4. Modals & nav ------------------------------------------------------

  Widget _modalsAndNav() {
    final isDark = _dark.value;
    final accentBlue =
        isDark ? const Color(0xFF0091FF) : const Color(0xFF0088FF);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final rowTextStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.41,
      color: labelColor,
    );
    return GlassNavigationStack(
      path: _navPath,
      destinations: {
        String: (context, value) => _NavDetail(value as String),
      },
      root: ColoredBox(
        color: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        child: _page('Modals & Nav', [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Text(
              'Full-Screen Cover (.fullScreenCover)',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.41,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            margin: EdgeInsets.zero,
            children: [
              GlassListTile(
                onTap: _presentCover,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                title: Row(
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up_right_square_fill,
                      size: 20,
                      color: accentBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Present Full-Screen Cover',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.41,
                        color: accentBlue,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
            child: Text(
              'Declarative Navigation (NavigationStack)',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.41,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            margin: EdgeInsets.zero,
            dividerIndent: 56,
            children: [
              GlassNavigationLink<String>(
                value: 'Level 1: Optics Architecture',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                titleStyle: rowTextStyle,
                leading: Icon(
                  CupertinoIcons.sparkles,
                  size: 20,
                  color: accentBlue,
                ),
                title: const Text('Optics Architecture'),
              ),
              GlassNavigationLink<String>(
                value: 'Level 1: Impeller Backend',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                titleStyle: rowTextStyle,
                leading: Center(
                  child: CustomPaint(
                    size: const Size(20, 20),
                    painter: _CpuIconPainter(accentBlue),
                  ),
                ),
                title: const Text('Impeller Backend'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
            child: Text(
              'Liquid Morph Sheet (.navigationTransition(.zoom))',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.41,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          GlassGroupedSection(
            surfaceStyle: GlassSurfaceStyle.solid,
            margin: EdgeInsets.zero,
            children: [
              GlassMorphTrigger(
                builder: (ctx, anchor) {
                  _morphHalfAnchor = anchor;
                  return GlassListTile(
                    onTap: () => _presentMorphSheet(full: false),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    title: Row(
                      children: [
                        Icon(
                          CupertinoIcons.add_circled_solid,
                          size: 20,
                          color: accentBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Morph Half Sheet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.41,
                            color: accentBlue,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  );
                },
              ),
            ],
          ),
          // Measured against the native reference (3x captures): the compose
          // trigger's centre sits at y = 723.3pt there, 5.3pt lower than the
          // 158pt gap gave.
          const SizedBox(height: 163.33),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GlassMorphTrigger(
                builder: (ctx, anchor) {
                  _morphFullAnchor = anchor;
                  return GlassIconButton(
                    size: 62,
                    useOwnLayer: true,
                    icon: Icon(
                      CupertinoIcons.create,
                      size: 22,
                      color: labelColor,
                    ),
                    onPressed: () => _presentMorphSheet(full: true),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MorphComposeSheetBody extends StatelessWidget {
  const _MorphComposeSheetBody({
    required this.title,
    required this.full,
    required this.onClose,
  });

  final String title;
  final bool full;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final accentBlue =
        isDark ? const Color(0xFF0091FF) : const Color(0xFF0088FF);

    final platterColor = full
        ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF))
        : (isDark ? const Color(0x1FFFFFFF) : const Color(0x10000000));
    final dividerColor =
        CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlassIconButton(
                size: 44,
                settings: isDark
                    ? LiquidGlassSettings.ios27Dark
                    : LiquidGlassSettings.ios27Light,
                // Native `xmark` measures 16.7pt wide (3x capture); the
                // Cupertino glyph is 0.65x its font size.
                icon: Icon(CupertinoIcons.xmark, size: 25.5, color: labelColor),
                onPressed: onClose,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.41,
                    color: labelColor,
                  ),
                ),
              ),
              GlassIconButton(
                // Native sizes this button to its 30.6pt filled disc: a
                // 48.9pt glass ring (the X button stays 44.8pt).
                size: 49,
                settings: isDark
                    ? LiquidGlassSettings.ios27Dark
                    : LiquidGlassSettings.ios27Light,
                icon: Icon(
                  CupertinoIcons.arrow_up_circle_fill,
                  size: 36,
                  color: labelColor,
                ),
                onPressed: onClose,
              ),
            ],
          ),
          SizedBox(height: full ? 45 : 38),
          DecoratedBox(
            decoration: BoxDecoration(
              color: platterColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _fieldRow('To:', 'alex@acme.io', secondaryColor, accentBlue),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(height: 0.5, color: dividerColor),
                ),
                _fieldRow(
                  'From:',
                  's.degenaar@acme.io',
                  secondaryColor,
                  accentBlue,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(height: 0.5, color: dividerColor),
                ),
                _fieldRow(
                  'Subject:',
                  'iOS 27 Liquid Glass Morph Parity',
                  secondaryColor,
                  labelColor,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
            child: Text(
              'Message',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: secondaryColor,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: platterColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
              child: Text(
                'The sheet content emerges and scales continuously inside the '
                'expanding Liquid Glass portal during the morph transition, '
                'matching iOS 27 zoom transitions.',
                style: TextStyle(
                  fontSize: 17,
                  // Native body line pitch measures 20.9pt (3x capture).
                  height: 1.23,
                  letterSpacing: -0.41,
                  color: labelColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15.5),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 17, color: labelColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 17, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data + small widgets
// ---------------------------------------------------------------------------

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _dark,
      builder: (context, isDark, _) => GlassIconButton(
        size: 44,
        useOwnLayer: true,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
            key: ValueKey(isDark),
            size: 20,
            color: isDark
                ? CupertinoColors.systemYellow
                : CupertinoColors.systemIndigo,
          ),
        ),
        onPressed: () => _dark.value = !isDark,
      ),
    );
  }
}

class _Contact {
  const _Contact(this.name, this.title, this.phone, this.colors,
      {this.favorite = false});
  final String name, title, phone;
  final List<Color> colors;
  final bool favorite;

  _Contact copyWith({bool? favorite}) => _Contact(
        name,
        title,
        phone,
        colors,
        favorite: favorite ?? this.favorite,
      );
}

const _initialContacts = [
  _Contact('Alex Rivera', 'Product Design Director', '+1 (408) 555-0142',
      [Color(0xFF007AFF), Color(0xFF32ADE6)],
      favorite: true),
  _Contact('Jordan Lee', 'Engineering Lead', '+1 (408) 555-0189',
      [Color(0xFF5856D6), Color(0xFFAF52DE)],
      favorite: true),
  _Contact('Taylor Brooks', 'Creative Director', '+1 (408) 555-0167',
      [Color(0xFFFF2D55), Color(0xFFFF9500)]),
  _Contact('Morgan Davis', 'Principal Architect', '+1 (408) 555-0123',
      [Color(0xFFAF52DE), Color(0xFF007AFF)]),
];

class _Avatar extends StatelessWidget {
  const _Avatar(this.c, this.size);
  final _Contact c;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: c.colors),
        ),
        child: Text(c.name[0],
            style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white)),
      );
}

class _VipPreview extends StatelessWidget {
  const _VipPreview(this.c);
  final _Contact c;

  @override
  Widget build(BuildContext context) => Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: resolveGlassSolidSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(c, 64),
            const SizedBox(height: 12),
            Text(c.name,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(c.title,
                style: TextStyle(
                    fontSize: 15,
                    color:
                        CupertinoColors.secondaryLabel.resolveFrom(context))),
            const SizedBox(height: 12),
            Container(height: 0.5, color: CupertinoColors.separator),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.phone_fill,
                    size: 14, color: CupertinoColors.systemGreen),
                const SizedBox(width: 8),
                Text(c.phone, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      );
}

class _CoverBody extends StatelessWidget {
  const _CoverBody();

  @override
  Widget build(BuildContext context) {
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final accentBlue =
        isDark ? const Color(0xFF0091FF) : const Color(0xFF0088FF);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(78, 82),
            painter: _PortraitArrowForwardPainter(accentBlue),
          ),
          const SizedBox(height: 24),
          Text(
            'Full-Screen Cover Presentation',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.26,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'iOS fullScreenCover presentation style:\n• Slides in from bottom\n'
              '• Full viewport edge-to-edge\n• Rounded top corners on downward drag\n'
              '• Done/Cancel navigation bar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.33,
                letterSpacing: -0.24,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDetail extends StatelessWidget {
  const _NavDetail(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = GlassTheme.brightnessOf(context) == Brightness.dark;
    final accentBlue =
        isDark ? const Color(0xFF0091FF) : const Color(0xFF0088FF);
    return ColoredBox(
      color: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 120, bottom: 83),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.26,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Demonstrates typed NavigationStack routing with back button '
                      'and synchronized title.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.29,
                        letterSpacing: -0.41,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    minimumSize: const Size(0, 34),
                    color: accentBlue,
                    borderRadius: BorderRadius.circular(17),
                    onPressed: () {
                      final stack = GlassNavigationStack.maybeOf(context);
                      if (stack != null) {
                        stack.effectivePath.append('$value -> Deeper');
                      }
                    },
                    child: const Text(
                      'Push Deeper',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.41,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassAppBar.pinned(
              title: Text('Detail'),
              padding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Approximates SF Symbol `cpu` (chip body, inner die, and 2 pins per side).
class _CpuIconPainter extends CustomPainter {
  const _CpuIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.22,
        size.width * 0.56,
        size.height * 0.56,
      ),
      const Radius.circular(3.0),
    );
    canvas.drawRRect(body, stroke);

    final core = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.37,
        size.height * 0.37,
        size.width * 0.26,
        size.height * 0.26,
      ),
      const Radius.circular(1.2),
    );
    canvas.drawRRect(core, stroke);

    for (final t in const [0.38, 0.62]) {
      final p = size.width * t;
      // Top & bottom pins
      canvas.drawLine(
        Offset(p, size.height * 0.06),
        Offset(p, size.height * 0.22),
        stroke,
      );
      canvas.drawLine(
        Offset(p, size.height * 0.78),
        Offset(p, size.height * 0.94),
        stroke,
      );
      // Left & right pins
      canvas.drawLine(
        Offset(size.width * 0.06, p),
        Offset(size.width * 0.22, p),
        stroke,
      );
      canvas.drawLine(
        Offset(size.width * 0.78, p),
        Offset(size.width * 0.94, p),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_CpuIconPainter oldDelegate) => oldDelegate.color != color;
}

/// Approximates SF Symbol `rectangle.portrait.and.arrow.forward`.
class _PortraitArrowForwardPainter extends CustomPainter {
  const _PortraitArrowForwardPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = size.width * 0.06;
    final top = size.height * 0.06;
    final right = size.width * 0.64;
    final bottom = size.height * 0.94;
    final r = size.width * 0.12;
    final gapTop = size.height * 0.33;
    final gapBottom = size.height * 0.67;

    // Portrait rounded rectangle with a right-edge opening for the arrow.
    final rectPath = Path()
      ..moveTo(right, gapTop)
      ..lineTo(right, top + r)
      ..arcToPoint(
        Offset(right - r, top),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(left + r, top)
      ..arcToPoint(
        Offset(left, top + r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(left, bottom - r)
      ..arcToPoint(
        Offset(left + r, bottom),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(right - r, bottom)
      ..arcToPoint(
        Offset(right, bottom - r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(right, gapBottom);
    canvas.drawPath(rectPath, stroke);

    // Horizontal arrow exiting to the right.
    final cy = size.height * 0.50;
    final arrowStart = size.width * 0.36;
    final arrowEnd = size.width * 0.94;
    final head = size.width * 0.16;
    canvas.drawLine(Offset(arrowStart, cy), Offset(arrowEnd, cy), stroke);
    final headPath = Path()
      ..moveTo(arrowEnd - head, cy - head)
      ..lineTo(arrowEnd, cy)
      ..lineTo(arrowEnd - head, cy + head);
    canvas.drawPath(headPath, stroke);
  }

  @override
  bool shouldRepaint(_PortraitArrowForwardPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Dashed rounded square, approximating SF Symbol `app.dashed`.
class _DashedSquirclePainter extends CustomPainter {
  const _DashedSquirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.6),
      const Radius.circular(4),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 2.6), paint);
        d += 4.2;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedSquirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

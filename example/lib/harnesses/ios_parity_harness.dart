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
//
//   cd example && flutter run -t lib/harnesses/ios_parity_harness.dart -d <udid>
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _cmdFile = '/tmp/lgw_parity_cmd.txt';

/// Whether the harness renders in dark appearance (`dark on|off` command).
/// Driven by command rather than the OS so captures are deterministic.
final _dark = ValueNotifier<bool>(false);

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
        builder: (context, dark, _) => CupertinoApp(
          debugShowCheckedModeBanner: false,
          title: 'iOS Parity',
          theme: CupertinoThemeData(
              brightness: dark ? Brightness.dark : Brightness.light),
          home: const _ParityHost(),
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
  Timer? _poll;
  String? _lastCmd;

  final _scroll = ScrollController();
  final _swipe = List.generate(4, (_) => GlassSwipeController());
  final _rowKeys = List.generate(4, (_) => GlobalKey());
  final _edit = GlassEditController(initialMode: GlassEditMode.active);
  final _expanded = ValueNotifier<List<bool>>([true, false, false]);
  final _emergencyContact = ValueNotifier<bool>(true);
  final _airDrop = ValueNotifier<bool>(true);
  final _sharePhoto = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    final f = File(_cmdFile);
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    _dark.addListener(_onDarkChanged);
    _poll = Timer.periodic(const Duration(milliseconds: 250), (_) => _check());
  }

  void _onDarkChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _dark.removeListener(_onDarkChanged);
    _poll?.cancel();
    super.dispose();
  }

  void _check() {
    final f = File(_cmdFile);
    if (!f.existsSync()) return;
    final cmd = f.readAsStringSync().trim();
    if (cmd.isEmpty || _lastCmd == cmd) return;
    _lastCmd = cmd;
    _run(cmd.split(RegExp(r'\s+')));
  }

  void _run(List<String> a) {
    switch (a[0]) {
      case 'dark':
        _dark.value = a[1] == 'on';
        setState(() {});
      case 'pop':
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
        setState(() => _tab = int.parse(a[1]));
      case 'scroll':
        if (_scroll.hasClients) _scroll.jumpTo(double.parse(a[1]));
      case 'swipe':
        final c = _swipe[int.parse(a[1])];
        switch (a[2]) {
          case 't':
            c.openTrailing();
          case 'l':
            c.openLeading();
          default:
            c.close();
        }
      case 'menu':
        final box = _rowKeys[int.parse(a[1])].currentContext?.findRenderObject()
            as RenderBox?;
        if (box == null) return;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        showGlassContextMenu<void>(
          context: context,
          targetRect: rect,
          previewBuilder: (_) => _VipPreview(_contacts[int.parse(a[1])]),
          actions: _menuActions(),
        );
      case 'edit':
        a[1] == 'on' ? _edit.startEditing() : _edit.stopEditing();
      case 'cover':
        _presentCover();
      case 'push':
        Navigator.of(context).push(
          CupertinoPageRoute<void>(
            builder: (_) => const _NavDetail('Level 1: Optics Architecture'),
          ),
        );
      case 'expand':
        final v = [..._expanded.value];
        v[int.parse(a[1])] = a[2] == 'on';
        _expanded.value = v;
      case 'toggle':
        switch (a[1]) {
          case '0':
            _emergencyContact.value = a[2] == 'on';
          case '1':
            _airDrop.value = a[2] == 'on';
          case '2':
            _sharePhoto.value = a[2] == 'on';
        }
    }
  }

  void _presentCover() {
    showGlassFullScreenCover<void>(
      context: context,
      builder: (ctx) => GlassFullScreenCover(
        title: const Text('Modal Cover'),
        leading: GlassFullScreenCoverBarButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(ctx).maybePop(),
        ),
        closeButtonLabel: 'Done',
        onDismiss: () {},
        child: const _CoverBody(),
      ),
    );
  }

  List<Widget> _menuActions() => [
        GlassContextMenuAction(
          icon: const Icon(CupertinoIcons.star_fill),
          child: const Text('Favorite'),
          onPressed: () {},
        ),
        GlassContextMenuAction(
          icon: const Icon(CupertinoIcons.doc_on_doc),
          child: const Text('Copy Phone'),
          onPressed: () {},
        ),
        GlassContextMenuAction(
          icon: const Icon(CupertinoIcons.trash),
          isDestructive: true,
          child: const Text('Delete Contact'),
          onPressed: () {},
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
    final ios27Settings =
        isDark ? LiquidGlassSettings.ios27Dark : LiquidGlassSettings.ios27Light;

    return GlassScaffold(
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      settings: ios27Settings,
      bottomBar: GlassTabBar.bottom(
        selectedIndex: _tab,
        onTabSelected: (idx) => setState(() => _tab = idx),
        quality: GlassQuality.premium,
        backgroundQuality: GlassQuality.premium,
        tabs: const [
          GlassTab(
            icon: Icon(CupertinoIcons.hand_draw),
            label: 'Swipe',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.chevron_down_circle),
            label: 'Disclosure',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.pencil_circle),
            label: 'Edit',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.calendar),
            label: 'Pickers',
          ),
          GlassTab(
            icon: Icon(CupertinoIcons.arrow_up_right_square),
            label: 'Modals',
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
            KeyedSubtree(
              key: _rowKeys[i],
              child: GlassListTile(
                swipeController: _swipe[i],
                allowsFullSwipe: true,
                contextMenuActions: _menuActions(),
                contextMenuPreviewBuilder: (_) => _VipPreview(_contacts[i]),
                trailingSwipeActions: [
                  GlassSwipeAction(
                    icon: const Icon(CupertinoIcons.trash),
                    label: const Text('Delete'),
                    isDestructive: true,
                    onTap: () {},
                  ),
                  GlassSwipeAction(
                    icon: const Icon(CupertinoIcons.flag_fill),
                    label: const Text('Flag'),
                    backgroundColor: CupertinoColors.systemOrange,
                    onTap: () {},
                  ),
                ],
                leadingSwipeActions: [
                  GlassSwipeAction(
                    icon: const Icon(CupertinoIcons.pin_fill),
                    label: const Text('Pin'),
                    backgroundColor: CupertinoColors.systemBlue,
                    onTap: () {},
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
          ],
        ],
      ),
    ]);
  }

  // -- 1. Disclosure --------------------------------------------------------

  Widget _disclosure() {
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
            header:
                _sectionHeader('Edit Mode & Reordering (EditButton + ForEach)'),
            itemCount: _items.length,
            onReorder: (o, n) => setState(() {
              if (o < n) n -= 1;
              _items.insert(n, _items.removeAt(o));
            }),
            itemBuilder: (context, i) => GlassListTile(
              key: ValueKey(_items[i]),
              leading: const Icon(CupertinoIcons.app,
                  color: CupertinoColors.systemBlue),
              title: Text(_items[i], style: const TextStyle(fontSize: 17)),
              canReorder: true,
              reorderIndex: i,
              canSelect: true,
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
              onDateTimeChanged: (_) {},
            ),
          ],
        ),
      ),
      _header('Graphical Calendar (DatePickerStyle.graphical)'),
      GlassDatePicker.graphical(
        initialDateTime: _now,
        firstDayOfWeek: 7,
        surfaceStyle: GlassSurfaceStyle.solid,
        onDateTimeChanged: (_) {},
      ),
      _header('Multi-Date Selection (MultiDatePicker)'),
      GlassMultiDatePicker(
        selectedDates: _multi,
        displayedMonth: _now,
        firstDayOfWeek: 7,
        surfaceStyle: GlassSurfaceStyle.solid,
        onDatesChanged: (s) => setState(() => _multi = s),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8, left: 16),
        child: Text('Selected dates count: ${_multi.length}',
            style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context))),
      ),
    ]);
  }

  // -- 4. Modals & nav ------------------------------------------------------

  Widget _modalsAndNav() {
    return _page('Modals & Nav', [
      _header('Full-Screen Cover (.fullScreenCover)'),
      GlassGroupedSection(
        surfaceStyle: GlassSurfaceStyle.solid,
        margin: EdgeInsets.zero,
        children: [
          GlassListTile(
            onTap: _presentCover,
            leading: const Icon(CupertinoIcons.arrow_up_right_square_fill,
                color: CupertinoColors.systemBlue),
            title: const Text('Present Full-Screen Cover',
                style: TextStyle(color: CupertinoColors.systemBlue)),
            trailing: GlassListTile.chevron,
          ),
        ],
      ),
      _header('Declarative Navigation (NavigationStack)'),
      GlassGroupedSection(
        surfaceStyle: GlassSurfaceStyle.solid,
        margin: EdgeInsets.zero,
        children: [
          GlassNavigationLink<String>(
            leading: const Icon(CupertinoIcons.sparkles,
                color: CupertinoColors.systemBlue),
            title: const Text('Optics Architecture'),
            destination: (_) =>
                const _NavDetail('Level 1: Optics Architecture'),
          ),
          GlassNavigationLink<String>(
            leading: const Icon(CupertinoIcons.settings,
                color: CupertinoColors.systemBlue),
            title: const Text('Impeller Backend'),
            destination: (_) => const _NavDetail('Level 1: Impeller Backend'),
          ),
        ],
      ),
    ]);
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
}

const _contacts = [
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
          color: CupertinoColors.systemBackground.resolveFrom(context),
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
            const SizedBox(height: 4),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            const Icon(CupertinoIcons.square_arrow_right,
                size: 64, color: CupertinoColors.systemBlue),
            const SizedBox(height: 24),
            const Text('Full-Screen Cover Presentation',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
                    color: CupertinoColors.secondaryLabel.resolveFrom(context)),
              ),
            ),
          ],
        ),
      );
}

class _NavDetail extends StatelessWidget {
  const _NavDetail(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Detail')),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Demonstrates typed NavigationStack routing with back button '
                  'and synchronized title.',
                  textAlign: TextAlign.center,
                ),
              ),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                borderRadius: BorderRadius.circular(20),
                onPressed: () {},
                child: const Text('Push Deeper'),
              ),
            ],
          ),
        ),
      );
}

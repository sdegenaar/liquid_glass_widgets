/// Lists, Pickers & Navigation Demo — Interactive showcase of:
/// - [GlassSwipeActions] & [GlassContextMenu]
/// - [GlassDisclosureGroup]
/// - [GlassEditScope], [GlassEditButton] & [GlassReorderableList]
/// - [GlassDatePicker] (`.wheel`, `.compact`, `.graphical`) & [GlassMultiDatePicker]
/// - [GlassFullScreenCover] & [GlassNavigationStack] / [GlassNavigationLink]
///
/// Run standalone:
///   cd example && flutter run -t lib/demos/lists_pickers_and_nav_demo.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

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

/// Dark-mode bottom tab bar glass settings matching the Apple Music example.
const _kDarkBarGlassSettings = LiquidGlassSettings(
  glassColor: Color(0xAA1C1C1E),
  thickness: 30,
  blur: 2,
  chromaticAberration: 0.01,
  lightAngle: GlassDefaults.lightAngle,
  lightIntensity: 0.2,
  ambientStrength: 0,
  refractiveIndex: 1.2,
  fresnelStrength: 0.0,
  saturation: 1.2,
  specularSharpness: GlassSpecularSharpness.medium,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const _StandaloneDemoApp()));
}

class _StandaloneDemoApp extends StatelessWidget {
  const _StandaloneDemoApp();

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Lists, Pickers & Nav',
      theme: CupertinoThemeData(brightness: Brightness.dark),
      home: ListsPickersAndNavDemoPage(),
    );
  }
}

/// Interactive 5-tab showcase covering Lists, Pickers, Modals, and Navigation.
class ListsPickersAndNavDemoPage extends StatefulWidget {
  const ListsPickersAndNavDemoPage({super.key});

  @override
  State<ListsPickersAndNavDemoPage> createState() =>
      _ListsPickersAndNavDemoPageState();
}

class _ListsPickersAndNavDemoPageState
    extends State<ListsPickersAndNavDemoPage> {
  int _tab = 0;

  final _scroll = ScrollController();
  late List<_Contact> _contacts;
  late List<GlassSwipeController> _swipe;
  final _edit = GlassEditController(initialMode: GlassEditMode.active);
  final _expanded = ValueNotifier<List<bool>>([true, false, false]);
  final _emergencyContact = ValueNotifier<bool>(true);
  final _airDrop = ValueNotifier<bool>(true);
  final _sharePhoto = ValueNotifier<bool>(true);
  final _navPath = GlassNavigationPath();

  @override
  void initState() {
    super.initState();
    _resetContacts();
    _navPath.addListener(_onNavPathChanged);
  }

  void _resetContacts() {
    _contacts = List.of(_initialContacts);
    _swipe = List.generate(_contacts.length, (_) => GlassSwipeController());
  }

  void _onNavPathChanged() {
    if (mounted) setState(() {});
  }

  void _deleteContact(int index) {
    if (index < 0 || index >= _contacts.length) return;
    setState(() {
      _contacts.removeAt(index);
      if (index < _swipe.length) _swipe.removeAt(index);
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

  @override
  void dispose() {
    _navPath.removeListener(_onNavPathChanged);
    _scroll.dispose();
    _edit.dispose();
    _expanded.dispose();
    _emergencyContact.dispose();
    _airDrop.dispose();
    _sharePhoto.dispose();
    for (final c in _swipe) {
      c.dispose();
    }
    super.dispose();
  }

  bool _resolveIsDark(BuildContext context) =>
      CupertinoTheme.brightnessOf(context) == Brightness.dark;

  void _presentCover(BuildContext context) {
    final isDark = _resolveIsDark(context);
    final buttonSettings = isDark ? _kDarkPillGlassSettings : null;
    showGlassFullScreenCover<void>(
      context: context,
      builder: (ctx) => GlassTheme(
        data: const GlassThemeData.ios27(),
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: GlassFullScreenCover(
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
        ),
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
    final isDark = _resolveIsDark(context);
    final canPopOuter = Navigator.maybeOf(context)?.canPop() ?? false;
    final VoidCallback? onExitDemo =
        canPopOuter ? () => Navigator.of(context).maybePop() : null;

    final pageSettings =
        isDark ? _kDarkPillGlassSettings : LiquidGlassSettings.ios27Light;

    return GlassTheme(
      data: const GlassThemeData.ios27(),
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        child: Theme(
          data: isDark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
          child: Builder(
            builder: (themedContext) {
              final pages = <Widget>[
                _swipeAndMenu(themedContext, isDark, onExitDemo),
                _disclosure(themedContext, isDark, onExitDemo),
                _editMode(themedContext, isDark, onExitDemo),
                _pickers(themedContext, isDark, onExitDemo),
                _modalsAndNav(themedContext, isDark, onExitDemo),
              ];
              final activePage = _tab == 2
                  ? GlassEditScope(controller: _edit, child: pages[_tab])
                  : pages[_tab];

              return GlassScaffold(
                backgroundColor:
                    isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
                settings: pageSettings,
                bottomEdgeFade: !(_tab == 4 && _navPath.isNotEmpty),
                bottomBar: GlassTabBar.bottom(
                  selectedIndex: _tab,
                  onTabSelected: (idx) => setState(() => _tab = idx),
                  quality: GlassQuality.premium,
                  backgroundQuality: GlassQuality.premium,
                  settings: isDark ? _kDarkBarGlassSettings : null,
                  indicatorColor: isDark
                      ? CupertinoColors.label
                          .resolveFrom(themedContext)
                          .withValues(alpha: 0.20)
                      : null,
                  unselectedIconColor: isDark
                      ? CupertinoColors.label
                          .resolveFrom(themedContext)
                          .withValues(alpha: 0.9)
                      : null,
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
            },
          ),
        ),
      ),
    );
  }

  // -- shared page chrome ----------------------------------------------------

  Widget _page(
    BuildContext context,
    String title,
    List<Widget> children, {
    required bool isDark,
    required VoidCallback? onExitDemo,
    Widget? trailing,
  }) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    return Stack(
      children: [
        ListView(
          key: ValueKey(title),
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 118, 16, 140),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: labelColor,
                ),
              ),
            ),
            ...children,
          ],
        ),
        if (onExitDemo != null)
          Positioned(
            top: 60,
            left: 16,
            child: GlassIconButton(
              size: 44,
              useOwnLayer: true,
              icon: Icon(
                CupertinoIcons.chevron_left,
                size: 20,
                color: labelColor,
              ),
              onPressed: onExitDemo,
            ),
          ),
        if (trailing != null)
          Positioned(
            top: 60,
            right: 16,
            child: trailing,
          ),
      ],
    );
  }

  Widget _info(BuildContext context, String text) => GlassContainer.card(
        surfaceStyle: GlassSurfaceStyle.solid,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.7,
            height: 1.29,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      );

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
            color: CupertinoColors.systemGrey,
          ),
        ),
      );

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
            color: CupertinoColors.systemGrey,
          ),
        ),
      );

  // -- 0. Swipe & menu ------------------------------------------------------

  Widget _swipeAndMenu(
    BuildContext context,
    bool isDark,
    VoidCallback? onExitDemo,
  ) {
    return _page(
      context,
      'Swipe & Menu',
      [
        _info(
          context,
          'Swipe left for Delete / Flag. Swipe right to Pin. Long press any '
          'row for Context Menu with VIP Preview.',
        ),
        GlassGroupedSection(
          surfaceStyle: GlassSurfaceStyle.solid,
          margin: EdgeInsets.zero,
          dividerIndent: 72,
          header: _sectionHeader('Contacts (.swipeActions & .contextMenu)'),
          children: [
            for (var i = 0; i < _contacts.length; i++)
              GlassListTile(
                key: ValueKey(_contacts[i].name),
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
                  child: _Avatar(_contacts[i], 44),
                ),
                title: Text(
                  _contacts[i].name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _contacts[i].title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                trailing: _contacts[i].favorite
                    ? const Icon(
                        CupertinoIcons.star_fill,
                        size: 15,
                        color: Color(0xFFFFCC00),
                      )
                    : null,
              ),
          ],
        ),
        GlassGroupedSection(
          surfaceStyle: GlassSurfaceStyle.solid,
          margin: EdgeInsets.zero,
          header: _sectionHeader('Long labels'),
          children: [
            // A capsule stretches to fit its label on one line.
            GlassListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              title: const Text('One long action'),
              subtitle: const Text('Swipe left'),
              trailingSwipeActions: [
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Supprimer le téléchargement'),
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            ),
            // The longest labels share what is left of 80% of the row width.
            GlassListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              title: const Text('Three actions'),
              subtitle: const Text('Swipe left'),
              trailingSwipeActions: [
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Supprimer le téléchargement'),
                  isDestructive: true,
                  onTap: () {},
                ),
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.bookmark),
                  label: const Text('Ajouter aux favoris'),
                  backgroundColor: CupertinoColors.systemOrange,
                  onTap: () {},
                ),
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.flag_fill),
                  label: const Text('Reporter'),
                  backgroundColor: CupertinoColors.systemBlue,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ],
      isDark: isDark,
      onExitDemo: onExitDemo,
      trailing: _contacts.length < _initialContacts.length
          ? GlassIconButton(
              size: 44,
              useOwnLayer: true,
              icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 18),
              onPressed: () => setState(_resetContacts),
            )
          : null,
    );
  }

  // -- 1. Disclosure --------------------------------------------------------

  Widget _disclosure(
    BuildContext context,
    bool isDark,
    VoidCallback? onExitDemo,
  ) {
    return ValueListenableBuilder<List<bool>>(
      valueListenable: _expanded,
      builder: (context, ex, _) => _page(
        context,
        'Disclosure',
        [
          _info(
            context,
            'SwiftUI DisclosureGroup rotates chevron 90° upon expansion and '
            'insets dividers under child rows.',
          ),
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
                leading: const Icon(
                  CupertinoIcons.heart_fill,
                  color: CupertinoColors.systemRed,
                  size: 20,
                ),
                title: const Text(
                  'Emergency & Medical',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Blood type, conditions, alerts',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: Column(
                      children: [
                        _kv(
                          context,
                          'Emergency Contact',
                          null,
                          trailing: ValueListenableBuilder<bool>(
                            valueListenable: _emergencyContact,
                            builder: (context, val, _) => GlassSwitch(
                              value: val,
                              quality: GlassQuality.premium,
                              onChanged: (v) => _emergencyContact.value = v,
                            ),
                          ),
                        ),
                        _kv(context, 'Blood Type', 'O+'),
                        _kv(
                          context,
                          'Medical ID',
                          'Active',
                          valueColor: CupertinoColors.systemGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              GlassDivider(indent: ex[0] ? 35 : 71, endIndent: 16),
              GlassDisclosureGroup(
                isExpanded: ex[1],
                onExpansionChanged: (v) => _setExpanded(1, v),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                leading: const Icon(
                  CupertinoIcons.person_2_fill,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                title: const Text(
                  'Social Profiles & Handles',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Online presence & profiles',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 13),
                    child: Column(
                      children: [
                        _kv(
                          context,
                          'X / Twitter',
                          '@alexrivera',
                          leading: const Icon(
                            CupertinoIcons.chat_bubble_2_fill,
                            size: 22,
                            color: CupertinoColors.systemBlue,
                          ),
                        ),
                        _kv(
                          context,
                          'GitHub',
                          'alexrivera',
                          leading: const Icon(
                            CupertinoIcons.chevron_left_slash_chevron_right,
                            size: 20,
                            color: CupertinoColors.systemPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              GlassDivider(indent: ex[1] ? 70 : 71, endIndent: 16),
              GlassDisclosureGroup(
                isExpanded: ex[2],
                onExpansionChanged: (v) => _setExpanded(2, v),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                leading: const Icon(
                  CupertinoIcons.lock_shield_fill,
                  color: CupertinoColors.systemGreen,
                  size: 20,
                ),
                title: const Text(
                  'Privacy & AirDrop Sharing',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Permissions and contact poster',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                children: [
                  _kv(
                    context,
                    'AirDrop Discoverable',
                    null,
                    trailing: ValueListenableBuilder<bool>(
                      valueListenable: _airDrop,
                      builder: (context, val, _) => GlassSwitch(
                        quality: GlassQuality.premium,
                        value: val,
                        onChanged: (v) => _airDrop.value = v,
                      ),
                    ),
                  ),
                  _kv(
                    context,
                    'Share Name & Photo',
                    null,
                    trailing: ValueListenableBuilder<bool>(
                      valueListenable: _sharePhoto,
                      builder: (context, val, _) => GlassSwitch(
                        quality: GlassQuality.premium,
                        value: val,
                        onChanged: (v) => _sharePhoto.value = v,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        isDark: isDark,
        onExitDemo: onExitDemo,
      ),
    );
  }

  void _setExpanded(int i, bool v) {
    final l = [..._expanded.value];
    l[i] = v;
    _expanded.value = l;
  }

  Widget _kv(
    BuildContext context,
    String k,
    String? v, {
    Widget? trailing,
    Color? valueColor,
    Widget? leading,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(width: 24, child: Center(child: leading)),
              const SizedBox(width: 11),
            ],
            Text(
              k,
              style: TextStyle(
                fontSize: 17,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const Spacer(),
            if (v != null)
              Text(
                v,
                style: TextStyle(
                  fontSize: 17,
                  color: valueColor ?? CupertinoColors.systemGrey,
                ),
              ),
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

  Widget _editMode(
    BuildContext context,
    bool isDark,
    VoidCallback? onExitDemo,
  ) {
    return AnimatedBuilder(
      animation: _edit,
      builder: (context, _) => _page(
        context,
        'Edit Mode',
        [
          _info(
            context,
            'SwiftUI EditMode provides circular red delete buttons, inline '
            'Delete pills, 3-bar drag handles, and multi-selection.',
          ),
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
        isDark: isDark,
        onExitDemo: onExitDemo,
        trailing: const GlassEditButton(),
      ),
    );
  }

  // -- 3. Pickers -----------------------------------------------------------

  final _now = DateTime.now();
  late DateTime _graphicalDate = _now;
  Set<DateTime> _multi = {};

  Widget _pickers(
    BuildContext context,
    bool isDark,
    VoidCallback? onExitDemo,
  ) {
    return _page(
      context,
      'Pickers',
      [
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
              Text(
                'Date & Time',
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
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
      ],
      isDark: isDark,
      onExitDemo: onExitDemo,
    );
  }

  // -- 4. Modals & nav ------------------------------------------------------

  Widget _modalsAndNav(
    BuildContext context,
    bool isDark,
    VoidCallback? onExitDemo,
  ) {
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
        child: _page(
          context,
          'Modals & Nav',
          [
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
                  onTap: () => _presentCover(context),
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
          ],
          isDark: isDark,
          onExitDemo: onExitDemo,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data + small widgets
// ---------------------------------------------------------------------------

class _Contact {
  const _Contact(
    this.name,
    this.title,
    this.phone,
    this.colors, {
    this.favorite = false,
  });
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
  _Contact(
    'Alex Rivera',
    'Product Design Director',
    '+1 (408) 555-0142',
    [Color(0xFF007AFF), Color(0xFF32ADE6)],
    favorite: true,
  ),
  _Contact(
    'Jordan Lee',
    'Engineering Lead',
    '+1 (408) 555-0189',
    [Color(0xFF5856D6), Color(0xFFAF52DE)],
    favorite: true,
  ),
  _Contact(
    'Taylor Brooks',
    'Creative Director',
    '+1 (408) 555-0167',
    [Color(0xFFFF2D55), Color(0xFFFF9500)],
  ),
  _Contact(
    'Morgan Davis',
    'Principal Architect',
    '+1 (408) 555-0123',
    [Color(0xFFAF52DE), Color(0xFF007AFF)],
  ),
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
            colors: c.colors,
          ),
        ),
        child: Text(
          c.name[0],
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
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
            Text(
              c.name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              c.title,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 0.5, color: CupertinoColors.separator),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.phone_fill,
                  size: 14,
                  color: CupertinoColors.systemGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  c.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
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
              padding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    ).navigationTitle('Detail');
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

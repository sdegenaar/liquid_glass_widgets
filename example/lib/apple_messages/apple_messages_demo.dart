/// Apple Messages iOS 26 — GlassMenu Spring Physics Test Case
///
/// This is a clone of the iOS 26 Messages app, built
/// specifically to compare [GlassMenu] spring physics against the native
/// UIKit context menu implementation side-by-side on device.
///
/// Two menus are present — mirroring the real app:
///   • Top-left  "Edit" pill  → GlassMenu anchored topLeft
///     Items: Select Messages, Edit Pins, Set Up Name & Photo
///   • Top-right filter pill  → GlassMenu anchored topRight
///     Items: Messages (✓ checked), Spam, Recently Deleted, [divider], Manage Filtering
///
/// Run standalone:
///   flutter run -t lib/apple_messages/apple_messages_demo.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../constants/sf_symbols.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE  (matches iOS 26 dark Messages)
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF000000);
const _kSeparator = Color(0x33FFFFFF); // ~20% white
const _kAvatarBg = Color(0xFF3A3A50); // muted indigo — iOS default avatar bg
const _kBlue = Color(0xFF0A84FF); // iOS 26 blue

// Glass shared by both menu triggers — matches the "Edit" pill aesthetic
const _kTriggerGlass = LiquidGlassSettings(
  glassColor: Colors.white10,
  thickness: 18,
  blur: 3,
  lightIntensity: 0.4,
  ambientStrength: 0.08,
  chromaticAberration: 0.01,
  refractiveIndex: 1.2,
  saturation: 1.15,
);

// Glass for the search+compose bar (blended group — premium needed for merging)
const _kSearchGlass = LiquidGlassSettings(
  glassColor: Colors.white10, // slightly lighter, blends as a pair
  thickness: 18,
  blur: 2,
  lightIntensity: 0.4,
  ambientStrength: 0.2,
  chromaticAberration: 0.1,
  refractiveIndex: 1.2,
  saturation: 1.15,
);

// Glass for the menus themselves
const _kMenuGlass = LiquidGlassSettings(
  glassColor: Colors.white12,
  thickness: 18,
  blur: 6,
  lightIntensity: 0.6,
  ambientStrength: 0.1,
  chromaticAberration: 0.01,
  refractiveIndex: 1.2,
  saturation: 1.15,
);

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────

class _Conversation {
  const _Conversation({
    required this.name,
    required this.preview,
    required this.time,
    this.initial,
    this.isUnread = false,
    this.hasAttachment = false,
  });
  final String name;
  final String preview;
  final String time;
  final String? initial; // null → generic avatar icon
  final bool isUnread;
  final bool hasAttachment;
}

const _kConversations = [
  _Conversation(
    name: 'Mum',
    preview: 'Don\'t forget dinner on Sunday! 🍗',
    time: '5:41 pm',
    initial: 'M',
    isUnread: true,
  ),
  _Conversation(
    name: 'Work Group 💼',
    preview: 'Jake: Can everyone join the 3pm standup?',
    time: '4:56 pm',
    initial: 'W',
    isUnread: true,
  ),
  _Conversation(
    name: 'Alex',
    preview: 'You liked "Sounds good, see you there"',
    time: '11:06 am',
    initial: 'A',
  ),
  _Conversation(
    name: 'Priya',
    preview: 'Cheers! Safe travels 🙌',
    time: 'Tuesday',
    initial: 'P',
  ),
  _Conversation(
    name: 'Sam',
    preview: 'Attachment: 1 Photo',
    time: 'Tuesday',
    initial: 'S',
    hasAttachment: true,
  ),
  _Conversation(
    name: '+61 428 048 980',
    preview:
        'Hi! Just a reminder your appointment is Fri 9 May at 2:30 PM. Reply STOP to opt out.',
    time: 'Monday',
  ),
  _Conversation(
    name: '+61 482 092 063',
    preview:
        'Your parcel has been delivered to the front door. Track at auspost.com.au',
    time: 'Monday',
  ),
  _Conversation(
    name: 'Jordan',
    preview: 'haha yeah that was wild 😂',
    time: 'Monday',
    initial: 'J',
  ),
  _Conversation(
    name: 'Taylor',
    preview: 'Ok sounds good!',
    time: 'Sunday',
    initial: 'T',
  ),
  _Conversation(
    name: '+61 409 593 783',
    preview:
        'Hi! FREE flu vaccines are now available for ALL ages at participating pharmacies near you.',
    time: 'Sunday',
  ),
  _Conversation(
    name: 'Riley',
    preview: 'The reservation is at 7:30, don\'t be late lol',
    time: 'Saturday',
    initial: 'R',
    isUnread: true,
  ),
  _Conversation(
    name: 'Westpac',
    preview: 'Your statement is ready. Log in to view.',
    time: 'Saturday',
  ),
  _Conversation(
    name: 'Casey',
    preview: 'Can you send me that recipe again?',
    time: 'Fri',
    initial: 'C',
  ),
  _Conversation(
    name: 'Fitness First',
    preview: 'Your class is confirmed for tomorrow at 6:45 AM. See you there!',
    time: 'Fri',
  ),
  _Conversation(
    name: 'Dad',
    preview: 'Call me when you get a chance mate',
    time: 'Thu',
    initial: 'D',
    isUnread: true,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// APP ENTRY
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait — matches Messages on iPhone
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(
    child: const AppleMessagesDemoApp(),
    adaptiveQuality: true,
    // ignore: experimental_member_use
    adaptiveConfig: const GlassAdaptiveScopeConfig(
      // Left on intentionally for 0.9.1 — helps gather diagnostics
      // if the adaptive threshold fix doesn't hold on all hardware.
      debugLogDiagnostics: true,
    ),
  ));
}

class AppleMessagesDemoApp extends StatelessWidget {
  const AppleMessagesDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messages',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _kBg,
        colorScheme: const ColorScheme.dark(
          primary: _kBlue,
          surface: _kBg,
        ),
      ),
      home: const MessagesScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _scrollController = ScrollController();
  bool _headerCollapsed = false;

  // Tracks which filter is selected in the right menu
  String _activeFilter = 'Messages';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final collapsed =
        _scrollController.hasClients && _scrollController.offset > 60;
    if (collapsed != _headerCollapsed) {
      setState(() => _headerCollapsed = collapsed);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final botPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kBg,
      extendBody: true,
      body: Stack(
        children: [
          // ── Conversation list with edge fades ─────────────────────────
          // ShaderMask fades scroll content at both edges using alpha mask —
          // no clipping artefacts, content fades smoothly into/out of view.
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (Rect bounds) {
              // Top fade zone: from y=0 to (topPad+52+50) — covers nav bar
              // + 50px fade into the first rows.
              // Bottom fade zone: covers the search bar height + safe area.
              final topZone = topPad + 52 + 50;
              final bottomZone =
                  60.0 + botPad; // Fade only below the search bar
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors
                      .transparent, // Fades out smoothly at the bottom like the top
                ],
                stops: [
                  0.0,
                  topZone / bounds.height,
                  (bounds.height - bottomZone) / bounds.height,
                  1.0,
                ],
              ).createShader(bounds);
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Status bar space + nav bar height
                SliverToBoxAdapter(child: SizedBox(height: topPad + 52)),

                // Large "Messages" title (collapses on scroll)
                SliverToBoxAdapter(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _headerCollapsed ? 0 : 1,
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        'Messages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Conversation rows
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ConversationRow(
                      conversation: _kConversations[i],
                    ),
                    childCount: _kConversations.length,
                  ),
                ),

                // Bottom padding — minimal; content reaches the fade zone.
                // The _SearchBar ColoredBox covers the safe area visually.
                // Ensure last row scrolls fully above the search bar overlay.
                // 92 = top padding (8) + bar height (44) + min bottom padding (32)
                // + buffer (8); botPad covers the device safe area.
                SliverToBoxAdapter(child: SizedBox(height: 92 + botPad)),
              ],
            ),
          ),

          // ── Top navigation bar ───────────────────────────────────────────
          _NavBar(
            topPad: topPad,
            headerCollapsed: _headerCollapsed,
            activeFilter: _activeFilter,
            onFilterChanged: (filter) => setState(() => _activeFilter = filter),
          ),

          // ── Bottom search + compose bar ──────────────────────────────────
          // bottom: 0 — inner padding (widget.bottomPad) handles safe area
          // on both iOS (home indicator) and Android (gesture nav bar).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SearchBar(bottomPad: botPad),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAV BAR
// ─────────────────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.topPad,
    required this.headerCollapsed,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final double topPad;
  final bool headerCollapsed;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPad),
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Edit menu (top-left) ─────────────────────────────────
                  const _EditMenu(),
                  const Spacer(),

                  // Inline "Messages" title when scrolled
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: headerCollapsed ? 1 : 0,
                    child: const Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // ── Filter menu (top-right) ──────────────────────────────
                  _FilterMenu(
                    activeFilter: activeFilter,
                    onFilterChanged: onFilterChanged,
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

// ─────────────────────────────────────────────────────────────────────────────
// EDIT MENU  (top-left pill → opens downLeft)
// ─────────────────────────────────────────────────────────────────────────────

class _EditMenu extends StatelessWidget {
  const _EditMenu();

  @override
  Widget build(BuildContext context) {
    return GlassMenu(
      menuWidth: 230,
      glassSettings: _kMenuGlass,
      menuBorderRadius: 16,
      quality: GlassQuality.premium,
      triggerBuilder: (context, toggleMenu) => GlassButton.custom(
        onTap: toggleMenu,
        width: 68,
        height: 44,
        // True capsule pill — borderRadius = height/2
        shape: const LiquidRoundedSuperellipse(borderRadius: 22),
        settings: _kTriggerGlass,
        quality: GlassQuality.premium,
        useOwnLayer: true, // standalone — outside any LiquidGlassLayer
        child: const Center(
          child: Text(
            'Edit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
      items: [
        GlassMenuItem(
          title: 'Select Messages',
          icon: const Icon(SFSymbols.checkmark_circle),
          onTap: () {},
        ),
        GlassMenuItem(
          title: 'Edit Pins',
          icon: const Icon(SFSymbols.pin),
          onTap: () {},
        ),
        GlassMenuItem(
          title: 'Set Up Name & Photo',
          icon: const Icon(SFSymbols.person_crop_circle),
          onTap: () {},
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER MENU  (top-right hamburger → opens downRight, has checkmark)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return GlassMenu(
      menuWidth: 240,
      glassSettings: _kMenuGlass,
      menuBorderRadius: 16,
      quality: GlassQuality.premium,
      triggerBuilder: (context, toggleMenu) => GlassButton(
        onTap: toggleMenu,
        width: 44,
        height: 44,
        shape: const LiquidOval(), // 44×44 = perfect circle
        settings: _kTriggerGlass,
        quality: GlassQuality.premium,
        useOwnLayer: true, // standalone — outside any LiquidGlassLayer
        icon: const Icon(
          SFSymbols.line_horizontal_3_decrease,
          color: Colors.white,
          size: 24,
        ),
      ),
      items: [
        GlassMenuItem(
          title: 'Messages',
          icon: const Icon(SFSymbols.bubble_left_and_bubble_right),
          trailing: activeFilter == 'Messages'
              ? const Icon(SFSymbols.checkmark, color: Colors.white, size: 16)
              : null,
          onTap: () => onFilterChanged('Messages'),
        ),
        GlassMenuItem(
          title: 'Spam',
          icon: const Icon(SFSymbols.xmark_bin),
          trailing: activeFilter == 'Spam'
              ? const Icon(SFSymbols.checkmark, color: Colors.white, size: 16)
              : null,
          onTap: () => onFilterChanged('Spam'),
        ),
        GlassMenuItem(
          title: 'Recently Deleted',
          icon: const Icon(SFSymbols.trash),
          trailing: activeFilter == 'Recently Deleted'
              ? const Icon(SFSymbols.checkmark, color: Colors.white, size: 16)
              : null,
          onTap: () => onFilterChanged('Recently Deleted'),
        ),
        const GlassMenuDivider(),
        GlassMenuItem(
          title: 'Manage Filtering',
          onTap: () {},
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});
  final _Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Unread dot column (8px wide, left of avatar) ────────────
                SizedBox(
                  width: 12,
                  child: c.isUnread
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: _kBlue,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 4),

                // ── Avatar ──────────────────────────────────────────────────
                _Avatar(initial: c.initial),
                const SizedBox(width: 12),

                // ── Content ─────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: c.isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.time,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            SFSymbols.chevron_right,
                            size: 12,
                            color: Colors.white30,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.hasAttachment ? '📷  ${c.preview}' : c.preview,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Separator indented past the dot + avatar
          const Padding(
            padding: EdgeInsets.only(left: 76),
            child: Divider(height: 1, color: _kSeparator, thickness: 0.4),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({this.initial});
  final String? initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: _kAvatarBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: initial != null
          ? Text(
              initial!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            )
          : const Icon(
              SFSymbols.person_fill,
              color: Colors.white60,
              size: 28,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SEARCH + COMPOSE BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.bottomPad});
  final double bottomPad;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Search + Compose bar ─────────────────────────────────────────────
        // AdaptiveLiquidGlassLayer provides the rendering context.
        // LiquidGlassBlendGroup inside makes the search pill and circle button
        // liquid-merge when they are close together — matching native iOS 26.
        Padding(
          // Bottom padding: when there is a large safe-area inset (iOS home indicator)
          // we subtract 8 so the bar sits at the desired visual height (26px).
          // On devices with small or no insets (Android gesture nav, iPhone SE),
          // a minimum padding of 32 ensures it's not too close to the bottom edge.
          padding: EdgeInsets.fromLTRB(
              12, 8, 12, widget.bottomPad > 32 ? widget.bottomPad - 8 : 32),
          child: AdaptiveLiquidGlassLayer(
            settings: _kSearchGlass,
            quality: GlassQuality.premium,
            blendAmount: 20,
            child: LiquidGlassBlendGroup(
              blend: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Search pill — joins blend group
                  Expanded(
                    child: GlassSearchBar(
                      focusNode: _focusNode,
                      placeholder: 'Search',
                      useOwnLayer: false, // joins blend group
                      settings: _kSearchGlass,
                      quality: GlassQuality.premium,
                      showsCancelButton: true,
                      height: 44,
                      onChanged: (_) {},
                      onCancel: () {},
                    ),
                  ),

                  // Compose circle — joins blend group
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    child: AnimatedOpacity(
                      opacity: !_isFocused ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: !_isFocused
                          ? Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: GlassButton(
                                onTap: () {},
                                width: 44,
                                height: 44,
                                shape: const LiquidOval(),
                                settings: _kSearchGlass,
                                quality: GlassQuality.premium,
                                useOwnLayer: false, // joins blend group
                                stretch: 0.25,
                                icon: const Icon(
                                  SFSymbols.square_and_pencil,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

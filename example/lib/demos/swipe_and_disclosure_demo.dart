/// Swipe Actions & Disclosure Groups Demo — iOS 26/27 SwiftUI & Apple HIG Parity
///
/// Demonstrates [GlassSwipeActions] with authentic spring physics, full-swipe dismissal,
/// and [GlassDisclosureGroup] with smooth rotating chevrons and spring expansion.
///
/// Run standalone:
///   flutter run -t example/lib/demos/swipe_and_disclosure_demo.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(child: const _DemoApp()));
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Swipe & Disclosure Demo',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(brightness: Brightness.dark),
      builder: (context, child) => Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF07070B),
        ),
        child: child!,
      ),
      home: const SwipeAndDisclosureDemoPage(),
    );
  }
}

// =============================================================================
// Main Showcase Page
// =============================================================================

class SwipeAndDisclosureDemoPage extends StatefulWidget {
  const SwipeAndDisclosureDemoPage({super.key});

  @override
  State<SwipeAndDisclosureDemoPage> createState() =>
      _SwipeAndDisclosureDemoPageState();
}

class _SwipeAndDisclosureDemoPageState
    extends State<SwipeAndDisclosureDemoPage> {
  int _selectedSegment =
      0; // 0: Swipe Actions, 1: Edit & Reorder, 2: Disclosure, 3: Settings
  GlassSwipeActionStyle _actionStyle = GlassSwipeActionStyle.tintedGlass;
  String _lastActionStatus = 'Idle (Drag any row left or right)';

  // Ambient edit controller
  final GlassEditController _editController = GlassEditController();

  // Demo Mail items state
  late List<_MailItem> _mailItems;
  late List<String> _contactItems;

  // Toggle states for disclosure groups
  bool _twoFactorEnabled = true;
  bool _biometricsEnabled = true;
  bool _instantNotifications = true;
  bool _badgeCounts = false;

  @override
  void initState() {
    super.initState();
    _resetMailItems();
  }

  void _resetMailItems() {
    setState(() {
      _mailItems = [
        _MailItem(
          id: 1,
          sender: 'Craig Federighi',
          subject: 'Liquid Glass in iOS 26/27',
          preview:
              'The specular rim highlights and spring transitions are incredible.',
          time: '9:41 AM',
          isUnread: true,
          isPinned: true,
        ),
        _MailItem(
          id: 2,
          sender: 'SwiftUI Framework Team',
          subject: 'DisclosureGroup and swipeActions Parity',
          preview:
              'Seamless integration within grouped sections and full-swipe triggers.',
          time: 'Yesterday',
          isUnread: true,
          isPinned: false,
        ),
        _MailItem(
          id: 3,
          sender: 'Flutter Foundation',
          subject: 'Impeller Dual-Pipeline Rendering',
          preview:
              'Metal and Vulkan fragment shaders running at a locked 120 FPS.',
          time: 'Monday',
          isUnread: false,
          isPinned: false,
        ),
        _MailItem(
          id: 4,
          sender: 'App Store Review',
          subject: 'Liquid Glass Widgets Accepted',
          preview:
              'Your submission satisfies all iOS Human Interface Guidelines.',
          time: 'Oct 4',
          isUnread: false,
          isPinned: false,
        ),
      ];

      _contactItems = [
        'Craig Federighi',
        'Kate Lovett',
        'Tong Mu',
        'Tim Cook',
        'Jony Ive',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.7),
            radius: 1.5,
            colors: [
              Color(0xFF1B1838),
              Color(0xFF0F0C24),
              Color(0xFF07070B),
            ],
          ),
        ),
      ),
      child: GlassEditScope(
        controller: _editController,
        child: GlassScaffold(
          appBar: GlassAppBar.pinned(
            title: const Text('SwiftUI & HIG Parity'),
            actions: [
              const GlassBarItem.custom(
                child: GlassEditButton(),
              ),
              GlassBarItem.icon(
                icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                onTap: _resetMailItems,
              ),
            ],
          ),
          body: GlassSwipeActionScope(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 54,
                16,
                40,
              ),
              children: [
                _buildSegmentedHeader(),
                const SizedBox(height: 16),
                if (_selectedSegment == 0) ...[
                  _buildSwipeControls(),
                  const SizedBox(height: 16),
                  _buildMailSwipeSection(),
                ] else if (_selectedSegment == 1) ...[
                  _buildReorderableSection(),
                ] else if (_selectedSegment == 2) ...[
                  _buildDisclosureShowcase(),
                ] else ...[
                  _buildCombinedShowcase(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedHeader() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _selectedSegment,
        children: const {
          0: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('Swipe', style: TextStyle(fontSize: 12)),
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('Edit/Move', style: TextStyle(fontSize: 12)),
          ),
          2: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('Disclosure', style: TextStyle(fontSize: 12)),
          ),
          3: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('Settings', style: TextStyle(fontSize: 12)),
          ),
        },
        onValueChanged: (val) {
          if (val != null) {
            setState(() => _selectedSegment = val);
          }
        },
      ),
    );
  }

  // ===========================================================================
  // Swipe Actions Section
  // ===========================================================================

  Widget _buildSwipeControls() {
    return GlassContainer.card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                size: 16,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: 8),
              const Text(
                'Platter Material Style',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
              const Spacer(),
              CupertinoSlidingSegmentedControl<GlassSwipeActionStyle>(
                groupValue: _actionStyle,
                children: const {
                  GlassSwipeActionStyle.tintedGlass: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('iOS 26 Glass', style: TextStyle(fontSize: 11)),
                  ),
                  GlassSwipeActionStyle.solidVibrancy: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child:
                        Text('Solid Classic', style: TextStyle(fontSize: 11)),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) {
                    setState(() => _actionStyle = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.hand_draw,
                  size: 14,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastActionStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                      fontFamily: 'Courier',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMailSwipeSection() {
    if (_mailItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(
                CupertinoIcons.tray,
                size: 48,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(height: 12),
              const Text(
                'All items dismissed with full swipe!',
                style: TextStyle(color: CupertinoColors.secondaryLabel),
              ),
              const SizedBox(height: 14),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                onPressed: _resetMailItems,
                child:
                    const Text('Restore Items', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      );
    }

    return GlassGroupedSection(
      header: const Text('INBOX (FULL-SWIPE & RUBBER-BAND DAMPING)'),
      footer: const Text(
        'Swipe right for Pin & Unread. Swipe left for Delete & Flag.\n'
        'Pulling past 65% triggers full-swipe with haptic detent and row collapse.',
      ),
      children: [
        for (var i = 0; i < _mailItems.length; i++)
          _buildMailTile(_mailItems[i], i),
      ],
    );
  }

  Widget _buildMailTile(_MailItem item, int index) {
    return GlassListTile(
      key: ValueKey(item.id),
      onSwipeStateChanged: (state) {
        if (mounted) {
          setState(() {
            _lastActionStatus = 'Row #${item.id}: ${state.name}';
          });
        }
      },
      swipeActionStyle: _actionStyle,
      onDismissed: () {
        setState(() {
          _mailItems.removeWhere((m) => m.id == item.id);
          _lastActionStatus = 'Dismissed #${item.id} via full swipe';
        });
      },
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: item.isUnread
              ? CupertinoColors.activeBlue
              : CupertinoColors.transparent,
        ),
      ),
      title: Row(
        children: [
          if (item.isPinned) ...[
            const Icon(
              CupertinoIcons.pin_fill,
              size: 12,
              color: CupertinoColors.systemOrange,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              item.sender,
              style: TextStyle(
                fontWeight: item.isUnread ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            item.time,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.subject,
            style: TextStyle(
              fontSize: 13,
              color: item.isUnread
                  ? CupertinoColors.white
                  : CupertinoColors.systemGrey,
              fontWeight: item.isUnread ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey2,
            ),
          ),
        ],
      ),
      leadingSwipeActions: [
        GlassSwipeAction(
          icon: Icon(
            item.isUnread
                ? CupertinoIcons.envelope_open_fill
                : CupertinoIcons.envelope_badge_fill,
          ),
          label: Text(item.isUnread ? 'Read' : 'Unread'),
          backgroundColor: CupertinoColors.systemBlue,
          onTap: () {
            setState(() {
              item.isUnread = !item.isUnread;
              _lastActionStatus = 'Toggled read on #${item.id}';
            });
          },
        ),
        GlassSwipeAction(
          icon: Icon(
            item.isPinned
                ? CupertinoIcons.pin_slash_fill
                : CupertinoIcons.pin_fill,
          ),
          label: Text(item.isPinned ? 'Unpin' : 'Pin'),
          backgroundColor: CupertinoColors.systemOrange,
          onTap: () {
            setState(() {
              item.isPinned = !item.isPinned;
              _lastActionStatus = 'Toggled pin on #${item.id}';
            });
          },
        ),
      ],
      trailingSwipeActions: [
        // Outermost action: Delete (SwiftUI/UIKit actions[0] ordering)
        GlassSwipeAction(
          icon: const Icon(CupertinoIcons.trash_fill),
          label: const Text('Delete'),
          backgroundColor: CupertinoColors.systemRed,
          isDestructive: true,
          onTap: () {
            setState(() {
              _mailItems.removeWhere((m) => m.id == item.id);
              _lastActionStatus = 'Deleted #${item.id}';
            });
          },
        ),
        GlassSwipeAction(
          icon: const Icon(CupertinoIcons.flag_fill),
          label: const Text('Flag'),
          backgroundColor: CupertinoColors.systemOrange,
          onTap: () {
            setState(() {
              _lastActionStatus = 'Flagged #${item.id}';
            });
          },
        ),
        GlassSwipeAction(
          icon: const Icon(CupertinoIcons.ellipsis),
          label: const Text('More'),
          backgroundColor: CupertinoColors.systemGrey,
          closeOnTap: true,
          onTap: () {
            setState(() {
              _lastActionStatus = 'Tapped More on #${item.id}';
            });
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // Edit & Reorder Section (SwiftUI List + EditButton + onMove)
  // ===========================================================================

  Widget _buildReorderableSection() {
    final isEditing = GlassEditScope.isEditing(context);

    return Column(
      children: [
        GlassReorderableList.grouped(
          header: const Text('CONTACTS (EDIT MODE, REORDER & CONTEXT MENU)'),
          footer: const Text(
            'Tap "Edit" in the top-right toolbar to reveal red deletion badges and drag handles.\n'
            'Items elevate with liquid glass specular shadows and haptic feedback during reordering.\n'
            'Long-press or secondary click any contact to reveal native liquid glass context menu.',
          ),
          itemCount: _contactItems.length,
          itemBuilder: (context, index) {
            final name = _contactItems[index];
            return GlassContextMenu(
              key: ValueKey(name),
              enabled: !isEditing,
              actions: [
                GlassContextMenuAction(
                  icon: const Icon(CupertinoIcons.chat_bubble_fill),
                  child: const Text('Message'),
                  onPressed: () {
                    setState(() {
                      _lastActionStatus = 'Messaged $name';
                    });
                  },
                ),
                GlassContextMenuAction(
                  icon: const Icon(CupertinoIcons.phone_fill),
                  child: const Text('Voice Call'),
                  onPressed: () {
                    setState(() {
                      _lastActionStatus = 'Calling $name';
                    });
                  },
                ),
                GlassContextMenuAction(
                  icon: const Icon(CupertinoIcons.share),
                  child: const Text('Share Contact'),
                  onPressed: () {
                    setState(() {
                      _lastActionStatus = 'Shared $name';
                    });
                  },
                ),
                GlassContextMenuAction(
                  icon: const Icon(CupertinoIcons.trash_fill),
                  isDestructive: true,
                  child: const Text('Delete Contact'),
                  onPressed: () {
                    setState(() {
                      _contactItems.removeAt(index);
                      _lastActionStatus = 'Deleted $name via context menu';
                    });
                  },
                ),
              ],
              child: GlassListTile(
                leading: const Icon(CupertinoIcons.person_crop_circle),
                title: Text(name),
                canReorder: true,
                reorderIndex: index,
                onDelete: () {
                  setState(() {
                    _contactItems.removeAt(index);
                  });
                },
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) newIndex -= 1;
              final item = _contactItems.removeAt(oldIndex);
              _contactItems.insert(newIndex, item);
            });
          },
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassListTile(
            leading: const Icon(
              CupertinoIcons.plus_circle_fill,
              color: CupertinoColors.systemGreen,
            ),
            title: const Text(
              'Add New Contact',
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
            onTap: () {
              setState(() {
                _contactItems.add('New Contact #${_contactItems.length + 1}');
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassContextMenu(
            previewBuilder: (context) {
              return Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border.all(
                    color: CupertinoColors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: CupertinoColors.activeBlue,
                      ),
                      child: const Icon(
                        CupertinoIcons.person_fill,
                        size: 36,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Craig Federighi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SVP Software Engineering',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              );
            },
            actions: [
              GlassContextMenuAction(
                icon: const Icon(CupertinoIcons.chat_bubble_2_fill),
                child: const Text('Send iMessage'),
                onPressed: () {
                  setState(() {
                    _lastActionStatus = 'Messaged Craig Federighi';
                  });
                },
              ),
              GlassContextMenuAction(
                icon: const Icon(CupertinoIcons.videocam_fill),
                child: const Text('FaceTime HD'),
                onPressed: () {
                  setState(() {
                    _lastActionStatus = 'FaceTiming Craig Federighi';
                  });
                },
              ),
              GlassContextMenuAction(
                icon: const Icon(CupertinoIcons.bookmark_fill),
                isSelected: true,
                child: const Text('VIP Contact'),
                onPressed: () {
                  setState(() {
                    _lastActionStatus = 'Toggled VIP status';
                  });
                },
              ),
              GlassContextMenuAction(
                icon: const Icon(CupertinoIcons.trash_fill),
                isDestructive: true,
                child: const Text('Remove from VIP'),
                onPressed: () {
                  setState(() {
                    _lastActionStatus = 'Removed Craig from VIP';
                  });
                },
              ),
            ],
            child: GlassContainer.card(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.activeBlue,
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Craig Federighi (VIP Card Preview)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Long-press or secondary click for custom preview',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: CupertinoColors.tertiaryLabel,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassListTile(
            leading: const Icon(
              CupertinoIcons.fullscreen,
              color: CupertinoColors.activeBlue,
            ),
            title: const Text('Open Full-Screen Profile Cover'),
            subtitle:
                const Text('SwiftUI .fullScreenCover with swipe-to-dismiss'),
            trailing: const Icon(
              CupertinoIcons.arrow_up_right_square,
              size: 16,
              color: CupertinoColors.secondaryLabel,
            ),
            onTap: () {
              showGlassFullScreenCover(
                context: context,
                builder: (coverContext) => GlassFullScreenCover(
                  title: const Text('Contact Details'),
                  closeButtonLabel: 'Done',
                  onDismiss: () {
                    setState(() {
                      _lastActionStatus = 'Dismissed full-screen cover';
                    });
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Center(
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: CupertinoColors.activeBlue,
                              child: Icon(
                                CupertinoIcons.person_fill,
                                size: 54,
                                color: CupertinoColors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Craig Federighi',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Senior Vice President, Software Engineering\nApple Inc.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const GlassGroupedSection(
                        header: Text('COMMUNICATION'),
                        children: [
                          GlassListTile(
                            leading: Icon(CupertinoIcons.phone_fill,
                                color: CupertinoColors.systemGreen),
                            title: Text('Phone'),
                            subtitle: Text('+1 (408) 996-1010'),
                            trailing: Icon(CupertinoIcons.phone),
                          ),
                          GlassListTile(
                            leading: Icon(CupertinoIcons.mail_solid,
                                color: CupertinoColors.systemBlue),
                            title: Text('Email'),
                            subtitle: Text('craig@apple.com'),
                            trailing: Icon(CupertinoIcons.envelope),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GlassGroupedSection(
                        header: const Text('CALENDAR & SCHEDULE (DATEPICKER)'),
                        children: [
                          GlassListTile(
                            leading: const Icon(CupertinoIcons.calendar,
                                color: CupertinoColors.systemPurple),
                            title: const Text('Next Review'),
                            trailing: GlassDatePicker.compact(
                              initialDateTime: DateTime(2026, 10, 15, 14, 30),
                              mode: GlassDatePickerMode.dateAndTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GlassDatePicker.graphical(
                        initialDateTime: DateTime(2026, 10, 8),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Drag down anywhere or tap "Done" to dismiss.',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.tertiaryLabel
                                .resolveFrom(coverContext),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Disclosure Groups Section
  // ===========================================================================

  Widget _buildDisclosureShowcase() {
    return Column(
      children: [
        GlassGroupedSection(
          header: const Text('SECURITY & PRIVACY (SWIFTUI DISCLOSUREGROUP)'),
          footer: const Text(
            'Tapping header rotates chevron smoothly by 90° and drives spring height expansion.',
          ),
          children: [
            GlassDisclosureGroup(
              leading: const Icon(CupertinoIcons.lock_shield_fill,
                  color: CupertinoColors.systemGreen),
              title: const Text('Two-Factor Authentication'),
              subtitle: Text(
                _twoFactorEnabled ? 'Active (Biometrics + SMS)' : 'Disabled',
              ),
              initiallyExpanded: true,
              children: [
                GlassListTile(
                  title: const Text('Two-Factor Authentication'),
                  trailing: CupertinoSwitch(
                    value: _twoFactorEnabled,
                    onChanged: (val) => setState(() => _twoFactorEnabled = val),
                  ),
                ),
                GlassListTile(
                  title: const Text('Require Face ID / Touch ID'),
                  trailing: CupertinoSwitch(
                    value: _biometricsEnabled,
                    onChanged: (val) =>
                        setState(() => _biometricsEnabled = val),
                  ),
                ),
                GlassListTile(
                  title: const Text('Hardware Security Keys'),
                  trailing: GlassListTile.chevron,
                ),
                GlassListTile(
                  title: const Text('Trusted Phone Numbers'),
                  subtitle: const Text('+1 (555) 019-2834'),
                  trailing: GlassListTile.chevron,
                ),
              ],
            ),
            GlassDisclosureGroup(
              leading: const Icon(CupertinoIcons.bell_fill,
                  color: CupertinoColors.systemRed),
              title: const Text('Notification Delivery'),
              subtitle: const Text('Banners, Sounds & Previews'),
              children: [
                GlassListTile(
                  title: const Text('Immediate Delivery'),
                  trailing: CupertinoSwitch(
                    value: _instantNotifications,
                    onChanged: (val) =>
                        setState(() => _instantNotifications = val),
                  ),
                ),
                GlassListTile(
                  title: const Text('App Icon Badges'),
                  trailing: CupertinoSwitch(
                    value: _badgeCounts,
                    onChanged: (val) => setState(() => _badgeCounts = val),
                  ),
                ),
                GlassListTile(
                  title: const Text('Scheduled Summary'),
                  subtitle: const Text('8:00 AM, 6:00 PM'),
                  trailing: GlassListTile.chevron,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'STANDALONE CARD DISCLOSURE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: CupertinoColors.secondaryLabel,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassDisclosureGroup.standalone(
            leading: const Icon(CupertinoIcons.circle_grid_hex_fill,
                color: CupertinoColors.systemPurple),
            title: const Text('Storage & Cache Analysis'),
            subtitle: const Text('14.8 GB used of 256 GB'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cached Liquid Shaders (Impeller)',
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.35,
                        backgroundColor:
                            CupertinoColors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(
                          CupertinoColors.systemPurple,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pipeline Cache: 142 MB',
                          style: TextStyle(fontSize: 12),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () {},
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Combined iOS 26 Settings Section
  // ===========================================================================

  Widget _buildCombinedShowcase() {
    return Column(
      children: [
        GlassGroupedSection(
          header: const Text('INTEGRATED GROUPED SECTION'),
          footer: const Text(
            'Demonstrating swipe actions and nested disclosure groups working together '
            'inside the same GlassGroupedSection with shared superellipse clipping.',
          ),
          children: [
            GlassDisclosureGroup(
              leading: const Icon(CupertinoIcons.wifi,
                  color: CupertinoColors.systemBlue),
              title: const Text('Wi-Fi Networks'),
              subtitle: const Text('Connected to "Apple Park 5G"'),
              initiallyExpanded: true,
              children: [
                GlassListTile(
                  leading: const Icon(CupertinoIcons.checkmark_alt,
                      color: CupertinoColors.activeBlue, size: 16),
                  title: const Text('Apple Park 5G'),
                  subtitle: const Text('Security: WPA3 Enterprise'),
                  trailing: GlassListTile.infoButton,
                  trailingSwipeActions: [
                    GlassSwipeAction(
                      icon: const Icon(CupertinoIcons.xmark_circle_fill),
                      label: const Text('Forget'),
                      backgroundColor: CupertinoColors.systemRed,
                      onTap: () {},
                    ),
                  ],
                ),
                GlassListTile(
                  title: const Text('Guest-Network'),
                  trailing: const Icon(CupertinoIcons.lock_fill, size: 14),
                ),
              ],
            ),
            GlassListTile(
              leading: const Icon(CupertinoIcons.bluetooth,
                  color: CupertinoColors.systemBlue),
              title: const Text('Bluetooth'),
              subtitle: const Text('3 Devices Connected'),
              trailing: GlassListTile.chevron,
              trailingSwipeActions: [
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.power),
                  label: const Text('Turn Off'),
                  backgroundColor: CupertinoColors.systemGrey,
                  onTap: () {},
                ),
              ],
            ),
            GlassDisclosureGroup(
              leading: const Icon(CupertinoIcons.antenna_radiowaves_left_right,
                  color: CupertinoColors.systemGreen),
              title: const Text('Cellular Data Options'),
              children: [
                GlassListTile(
                  title: const Text('Voice & Data'),
                  subtitle: const Text('5G Auto'),
                  trailing: GlassListTile.chevron,
                ),
                GlassListTile(
                  title: const Text('Data Roaming'),
                  trailing: CupertinoSwitch(value: false, onChanged: (_) {}),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _MailItem {
  _MailItem({
    required this.id,
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
    required this.isUnread,
    required this.isPinned,
  });

  final int id;
  final String sender;
  final String subject;
  final String preview;
  final String time;
  bool isUnread;
  bool isPinned;
}

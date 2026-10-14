import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/contact_models.dart';
import '../theme/contacts_theme.dart';
import 'contact_detail_view.dart';
import 'contact_edit_sheet.dart';

/// The root Contacts list screen matching Apple Contacts (iOS 26/27).
///
/// Demonstrates:
/// - Pinned [GlassAppBar.pinned] with ambient [GlassEditButton]
/// - [GlassEditScope] + [GlassReorderableList.grouped] with drag reordering
/// - Row-level delete confirmation badges with 90° rotation & slide-in pill
/// - [GlassSwipeActions] with leading & trailing platters and full-swipe dismiss
/// - [GlassContextMenu] on long press with authentic specular preview & actions
/// - [GlassNavigationLink] for typed declarative navigation to [ContactDetailView]
/// - [showGlassFullScreenCover] to present [ContactEditSheet]
class ContactsListView extends StatefulWidget {
  const ContactsListView({super.key});

  @override
  State<ContactsListView> createState() => _ContactsListViewState();
}

class _ContactsListViewState extends State<ContactsListView> {
  final GlassEditController _editController = GlassEditController();
  final TextEditingController _searchController = TextEditingController();
  late List<ContactItem> _contacts;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _contacts = List.from(kInitialContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _addContact(ContactItem newContact) {
    setState(() {
      _contacts.insert(0, newContact);
    });
  }

  void _updateContact(ContactItem updated) {
    setState(() {
      final index = _contacts.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _contacts[index] = updated;
      }
    });
  }

  void _deleteContact(String id) {
    setState(() {
      _contacts.removeWhere((c) => c.id == id);
    });
  }

  void _openAddSheet() {
    showGlassFullScreenCover(
      context: context,
      builder: (ctx) => ContactEditSheet(
        onSave: _addContact,
      ),
    );
  }

  List<ContactItem> get _filteredContacts {
    if (_searchQuery.trim().isEmpty) return _contacts;
    final q = _searchQuery.toLowerCase();
    return _contacts
        .where((c) =>
            c.displayName.toLowerCase().contains(q) ||
            c.company.toLowerCase().contains(q) ||
            c.phone.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContacts;

    return ListenableBuilder(
      listenable: _editController,
      builder: (context, _) {
        return GlassEditScope(
          controller: _editController,
          child: GlassScaffold(
            background: const AppleContactsBackground(),
            appBar: GlassAppBar.pinned(
              title: const Text('Contacts'),
              buttonSettings: LiquidGlassSettings.ios27Dark,
              leading: [
                GlassBarItem.custom(
                  background: GlassBarItemBackground.none,
                  child: GlassButton(
                    icon: const Icon(
                      CupertinoIcons.chevron_left,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                    width: 44,
                    height: 44,
                    shape: const LiquidOval(),
                    quality: GlassQuality.premium,
                    useOwnLayer: true,
                    settings: LiquidGlassSettings.ios27Dark,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
              actions: [
                GlassBarItem.custom(
                  background: GlassBarItemBackground.none,
                  child: GlassEditButton.explicit(
                    isEditing: _editController.isEditing,
                    onPressed: _editController.toggle,
                  ),
                ),
              ],
            ),
            bottomBar: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.paddingOf(context).bottom + 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      height: 50,
                      useOwnLayer: true,
                      quality: GlassQuality.premium,
                      settings: LiquidGlassSettings.ios27Dark,
                      shape: const LiquidRoundedSuperellipse(borderRadius: 25),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.search,
                              color: CupertinoColors.secondaryLabel,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CupertinoTextField(
                                controller: _searchController,
                                placeholder: 'Search',
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                decoration: const BoxDecoration(),
                                cursorColor: ContactsTheme.blue,
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                ),
                                placeholderStyle: const TextStyle(
                                  color: CupertinoColors.secondaryLabel,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                                child: const Icon(
                                  CupertinoIcons.clear_circled_solid,
                                  color: CupertinoColors.secondaryLabel,
                                  size: 18,
                                ),
                              )
                            else
                              const Icon(
                                CupertinoIcons.mic_fill,
                                color: CupertinoColors.secondaryLabel,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GlassButton(
                    icon: const Icon(
                      CupertinoIcons.add,
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                    width: 50,
                    height: 50,
                    shape: const LiquidOval(),
                    quality: GlassQuality.premium,
                    useOwnLayer: true,
                    settings: LiquidGlassSettings.ios27Dark,
                    onTap: _openAddSheet,
                  ),
                ],
              ),
            ),
            body: GlassSwipeActionScope(
              child: Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      MediaQuery.paddingOf(context).top + 54,
                      0,
                      120,
                    ),
                    children: [
                      // My Card Row (Real iOS 27 Contacts style)
                      if (_searchQuery.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF3F3B56),
                                ),
                                child: const Center(
                                  child: Text(
                                    'SD',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Sebastian Degenaar',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'My Card',
                                    style: TextStyle(
                                      color: CupertinoColors.secondaryLabel,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Section Header "A"
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'A',
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 0.5,
                              color: const Color(0xFF2C2C2E),
                            ),
                          ],
                        ),
                      ),

                      // Plain Contacts List
                      for (int i = 0; i < filtered.length; i++)
                        _buildContactTile(
                            filtered[i], i, i == filtered.length - 1),

                      // Bottom Count Label
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          '${filtered.length} Contacts',
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                  // Alphabet Index (Vertical blue scroller on the right edge)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 60,
                    bottom: 90,
                    right: 4,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final letter in [
                            'A',
                            'B',
                            'C',
                            'D',
                            'E',
                            'F',
                            'G',
                            'H',
                            'I',
                            'J',
                            'K',
                            'L',
                            'M',
                            'N',
                            'O',
                            'P',
                            'Q',
                            'R',
                            'S',
                            'T',
                            'U',
                            'V',
                            'W',
                            'X',
                            'Y',
                            'Z',
                            '#'
                          ])
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 0.5),
                              child: Text(
                                letter,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactPreview(ContactItem contact) {
    return GlassContainer.card(
      quality: GlassQuality.premium,
      useOwnLayer: true,
      settings: ContactsTheme.cardSettings,
      shape: const LiquidRoundedSuperellipse(borderRadius: 20),
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    contact.avatarColor,
                    contact.avatarColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: CupertinoColors.white.withValues(alpha: 0.35),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: contact.avatarColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  contact.initials,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              contact.displayName,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (contact.company.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                contact.company,
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              contact.phone,
              style: const TextStyle(
                fontSize: 14,
                color: ContactsTheme.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(ContactItem contact, int index, bool isLast) {
    // When editing is inactive, wrap in ContextMenu and SwipeActions.
    return ListenableBuilder(
      key: ValueKey(contact.id),
      listenable: _editController,
      builder: (context, child) {
        final isEditing = _editController.isEditing;

        final tile = GlassListTile(
          key: ValueKey(contact.id),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: contact.avatarColor,
            ),
            child: Center(
              child: Text(
                contact.initials,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          title: Text(
            contact.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: contact.company.isNotEmpty ? Text(contact.company) : null,
          trailing:
              null, // Apple Contacts does not display chevrons next to contact names
          canDelete: isEditing,
          onDelete: () => _deleteContact(contact.id),
          canReorder: isEditing,
          reorderIndex: index,
        );

        final Widget content;
        if (isEditing) {
          content = tile;
        } else {
          // Standard interactive mode: GlassNavigationLink + GlassContextMenu + GlassSwipeActions
          content = GlassNavigationLink(
            destination: (ctx) => ContactDetailView(
              contact: contact,
              onContactUpdated: _updateContact,
              onContactDeleted: _deleteContact,
            ),
            child: GlassContextMenu(
              key: ValueKey(contact.id),
              quality: GlassQuality.premium,
              settings: ContactsTheme.cardSettings,
              previewBuilder: (_) => _buildContactPreview(contact),
              actions: [
                GlassContextMenuAction(
                  icon: const Icon(CupertinoIcons.bubble_left_fill),
                  onPressed: () {},
                  child: const Text('Send Message'),
                ),
                GlassContextMenuAction(
                  icon: const Icon(CupertinoIcons.phone_fill),
                  onPressed: () {},
                  child: const Text('Call'),
                ),
                GlassContextMenuAction(
                  icon: const Icon(CupertinoIcons.videocam_fill),
                  onPressed: () {},
                  child: const Text('FaceTime Video'),
                ),
                GlassContextMenuAction(
                  icon: const Icon(CupertinoIcons.share),
                  onPressed: () {},
                  child: const Text('Share Contact'),
                ),
                GlassContextMenuAction(
                  icon: const Icon(CupertinoIcons.trash_fill),
                  isDestructive: true,
                  onPressed: () => _deleteContact(contact.id),
                  child: const Text('Delete Contact'),
                ),
              ],
              child: GlassSwipeActions(
                style: GlassSwipeActionStyle.tintedGlass,
                leadingActions: [
                  GlassSwipeAction(
                    icon: const Icon(CupertinoIcons.phone_fill),
                    label: const Text('Call'),
                    backgroundColor: ContactsTheme.green,
                    onTap: () {},
                  ),
                  GlassSwipeAction(
                    icon: const Icon(CupertinoIcons.bubble_left_fill),
                    label: const Text('Message'),
                    backgroundColor: ContactsTheme.blue,
                    onTap: () {},
                  ),
                ],
                trailingActions: [
                  GlassSwipeAction(
                    icon: const Icon(CupertinoIcons.trash_fill),
                    label: const Text('Delete'),
                    backgroundColor: ContactsTheme.red,
                    isDestructive: true,
                    onTap: () => _deleteContact(contact.id),
                  ),
                  GlassSwipeAction(
                    icon: const Icon(CupertinoIcons.share),
                    label: const Text('Share'),
                    backgroundColor: ContactsTheme.orange,
                    onTap: () {},
                  ),
                ],
                onDismissed: () => _deleteContact(contact.id),
                child: tile,
              ),
            ),
          );
        }

        return Column(
          key: ValueKey('tile_col_${contact.id}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Container(
                  height: 0.5,
                  color: const Color(0xFF2C2C2E),
                ),
              ),
          ],
        );
      },
    );
  }
}

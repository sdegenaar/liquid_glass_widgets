import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/contact_models.dart';
import '../theme/contacts_theme.dart';
import 'contact_edit_sheet.dart';

/// Contact Detail View matching iOS 26/27 Apple Contacts.
///
/// Demonstrates:
/// - Pinned [GlassAppBar.pinned] with hero title
/// - Action quick-buttons with liquid glass styling
/// - [GlassDatePicker] compact pill & graphical calendar for birthday
/// - [GlassDisclosureGroup] for collapsible sections (Emergency, Socials, Sharing)
/// - [showGlassFullScreenCover] presenting [ContactEditSheet]
class ContactDetailView extends StatefulWidget {
  const ContactDetailView({
    super.key,
    required this.contact,
    required this.onContactUpdated,
    required this.onContactDeleted,
  });

  final ContactItem contact;
  final ValueChanged<ContactItem> onContactUpdated;
  final ValueChanged<String> onContactDeleted;

  @override
  State<ContactDetailView> createState() => _ContactDetailViewState();
}

class _ContactDetailViewState extends State<ContactDetailView> {
  late ContactItem _contact;
  bool _medicalIdShared = true;
  bool _shareLocation = false;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  void _openEditSheet() {
    showGlassFullScreenCover(
      context: context,
      builder: (ctx) => ContactEditSheet(
        contact: _contact,
        onSave: (updated) {
          setState(() => _contact = updated);
          widget.onContactUpdated(updated);
        },
      ),
    );
  }

  void _confirmDelete() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Contact'),
        content:
            Text('Are you sure you want to delete ${_contact.displayName}?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop(); // Dismiss alert
              widget.onContactDeleted(_contact.id);
              Navigator.of(context).pop(); // Back to list
            },
            child: const Text('Delete Contact'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: const AppleContactsBackground(),
      appBar: GlassAppBar.pinned(
        title: Text(_contact.displayName),
        actions: [
          GlassBarItem.custom(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _openEditSheet,
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: ContactsTheme.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 54,
          16,
          48,
        ),
        children: [
          const SizedBox(height: 12),

          // Hero Avatar with glowing border and specular shadow
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _contact.avatarColor,
                    _contact.avatarColor.withValues(alpha: 0.7),
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
                    color: _contact.avatarColor.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _contact.initials,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name & Company
          Center(
            child: Text(
              _contact.displayName,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          if (_contact.company.isNotEmpty || _contact.jobTitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${_contact.jobTitle.isNotEmpty ? '${_contact.jobTitle} · ' : ''}${_contact.company}',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Quick Action Buttons Row (Premium GlassButtons)
          _buildActionButtons(),
          const SizedBox(height: 24),

          // Phone & Email Section
          GlassGroupedSection(
            quality: GlassQuality.premium,
            settings: ContactsTheme.cardSettings,
            children: [
              GlassListTile(
                leading: const Icon(CupertinoIcons.phone,
                    color: ContactsTheme.green),
                title: const Text('phone'),
                subtitle: Text(_contact.phone),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              ),
              GlassListTile(
                leading:
                    const Icon(CupertinoIcons.mail, color: ContactsTheme.blue),
                title: const Text('email'),
                subtitle: Text(_contact.email),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Birthday & Date Section (GlassDatePicker.wheel)
          GlassGroupedSection(
            header: const Text(
              'BIRTHDAY (CIRCULAR WHEEL PICKER)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            children: [
              GlassListTile(
                leading: const Icon(CupertinoIcons.gift,
                    color: ContactsTheme.orange),
                title: const Text('Birthday'),
                trailing: Text(
                  '${_contact.birthday.year}-${_contact.birthday.month.toString().padLeft(2, '0')}-${_contact.birthday.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: ContactsTheme.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: GlassDatePicker.wheel(
                  quality: GlassQuality.premium,
                  settings: ContactsTheme.cardSettings,
                  initialDateTime: _contact.birthday,
                  mode: GlassDatePickerMode.date,
                  onDateTimeChanged: (newDate) {
                    setState(() {
                      _contact = _contact.copyWith(birthday: newDate);
                    });
                    widget.onContactUpdated(_contact);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Important Milestones (GlassMultiDatePicker)
          GlassGroupedSection(
            quality: GlassQuality.premium,
            settings: ContactsTheme.cardSettings,
            header: const Text(
              'MILESTONES (MULTIDATE PICKER)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: GlassMultiDatePicker(
                  quality: GlassQuality.premium,
                  settings: ContactsTheme.cardSettings,
                  tintColor: ContactsTheme.blue,
                  selectedDates: _contact.milestoneDates.toSet(),
                  onDatesChanged: (dates) {
                    setState(() {
                      _contact =
                          _contact.copyWith(milestoneDates: dates.toList());
                    });
                    widget.onContactUpdated(_contact);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Collapsible Disclosure Groups (GlassDisclosureGroup)
          GlassGroupedSection(
            quality: GlassQuality.premium,
            settings: ContactsTheme.cardSettings,
            header: const Text(
              'COLLAPSIBLE DISCLOSURE GROUPS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            children: [
              GlassDisclosureGroup(
                title: const Text('Emergency & Medical Details'),
                leading: const Icon(CupertinoIcons.heart_fill,
                    color: ContactsTheme.red),
                initiallyExpanded: _contact.emergencyContact,
                children: [
                  GlassListTile(
                    title: const Text('Emergency Contact'),
                    trailing: CupertinoSwitch(
                      activeTrackColor: ContactsTheme.green,
                      value: _contact.emergencyContact,
                      onChanged: (val) {
                        setState(() {
                          _contact = _contact.copyWith(emergencyContact: val);
                        });
                        widget.onContactUpdated(_contact);
                      },
                    ),
                  ),
                  GlassListTile(
                    title: const Text('Share Medical ID on Lock Screen'),
                    trailing: CupertinoSwitch(
                      activeTrackColor: ContactsTheme.green,
                      value: _medicalIdShared,
                      onChanged: (val) =>
                          setState(() => _medicalIdShared = val),
                    ),
                  ),
                ],
              ),
              GlassDisclosureGroup(
                title: const Text('Social Profiles & Handles'),
                leading:
                    const Icon(CupertinoIcons.at, color: ContactsTheme.purple),
                children: [
                  for (final profile in _contact.socialProfiles)
                    GlassListTile(
                      title: Text(profile),
                      trailing:
                          const Icon(CupertinoIcons.chevron_right, size: 16),
                    ),
                ],
              ),
              GlassDisclosureGroup(
                title: const Text('Privacy & AirDrop Sharing'),
                leading: const Icon(CupertinoIcons.shield_fill,
                    color: ContactsTheme.blue),
                children: [
                  GlassListTile(
                    title: const Text('Share Live Location'),
                    trailing: CupertinoSwitch(
                      activeTrackColor: ContactsTheme.green,
                      value: _shareLocation,
                      onChanged: (val) => setState(() => _shareLocation = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Delete Action
          GlassGroupedSection(
            quality: GlassQuality.premium,
            settings: ContactsTheme.cardSettings,
            children: [
              GlassListTile(
                onTap: _confirmDelete,
                leading:
                    const Icon(CupertinoIcons.trash, color: ContactsTheme.red),
                title: const Text(
                  'Delete Contact',
                  style: TextStyle(
                    color: ContactsTheme.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickAction('message', CupertinoIcons.bubble_left_fill),
        _buildQuickAction('call', CupertinoIcons.phone_fill),
        _buildQuickAction('video', CupertinoIcons.videocam_fill),
        _buildQuickAction('mail', CupertinoIcons.mail),
      ],
    );
  }

  Widget _buildQuickAction(String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassButton(
          icon: Icon(icon, color: ContactsTheme.blue, size: 22),
          onTap: () {},
          width: 72,
          height: 52,
          quality: GlassQuality.premium,
          useOwnLayer: true,
          settings: ContactsTheme.cardSettings,
          shape: const LiquidRoundedSuperellipse(borderRadius: 16),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: ContactsTheme.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

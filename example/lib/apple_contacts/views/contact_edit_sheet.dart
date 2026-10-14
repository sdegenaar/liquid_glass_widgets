import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/contact_models.dart';
import '../theme/contacts_theme.dart';

/// Full-screen sheet for creating or editing a contact in iOS 26/27 style.
///
/// Presented via [showGlassFullScreenCover] with native spring slide-up and
/// swipe-to-dismiss gesture physics.
class ContactEditSheet extends StatefulWidget {
  const ContactEditSheet({
    super.key,
    this.contact,
    required this.onSave,
  });

  final ContactItem? contact;
  final ValueChanged<ContactItem> onSave;

  @override
  State<ContactEditSheet> createState() => _ContactEditSheetState();
}

class _ContactEditSheetState extends State<ContactEditSheet> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late DateTime _birthday;
  late List<DateTime> _milestones;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _firstNameController = TextEditingController(text: c?.firstName ?? '');
    _lastNameController = TextEditingController(text: c?.lastName ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _companyController = TextEditingController(text: c?.company ?? '');
    _birthday = c?.birthday ?? DateTime(1995, 1, 1);
    _milestones = List.from(c?.milestoneDates ?? [_birthday]);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final updated = (widget.contact ??
            ContactItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              firstName: '',
              lastName: '',
              phone: '',
              email: '',
              jobTitle: '',
              company: '',
              birthday: _birthday,
            ))
        .copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      company: _companyController.text.trim(),
      birthday: _birthday,
      milestoneDates: _milestones,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.contact == null;

    return GlassFullScreenCover(
      quality: GlassQuality.premium,
      settings: ContactsTheme.cardSettings,
      backgroundColor: CupertinoColors.transparent,
      title: Text(isNew ? 'New Contact' : 'Edit Contact'),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).pop(),
        child:
            const Text('Cancel', style: TextStyle(color: ContactsTheme.blue)),
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _handleSave,
        child: const Text(
          'Done',
          style: TextStyle(
            color: ContactsTheme.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Stack(
        children: [
          const AppleContactsBackground(isModal: true),
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // Avatar circle
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        widget.contact?.avatarColor ?? ContactsTheme.blue,
                        (widget.contact?.avatarColor ?? ContactsTheme.blue)
                            .withValues(alpha: 0.7),
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
                        color:
                            (widget.contact?.avatarColor ?? ContactsTheme.blue)
                                .withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.contact?.initials ?? '?',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name and Company Fields
              GlassGroupedSection(
                quality: GlassQuality.premium,
                settings: ContactsTheme.cardSettings,
                children: [
                  _buildTextInput('First Name', _firstNameController),
                  _buildTextInput('Last Name', _lastNameController),
                  _buildTextInput('Company', _companyController),
                ],
              ),
              const SizedBox(height: 16),

              // Contact Details
              GlassGroupedSection(
                quality: GlassQuality.premium,
                settings: ContactsTheme.cardSettings,
                children: [
                  _buildTextInput('Phone', _phoneController,
                      keyboardType: TextInputType.phone),
                  _buildTextInput('Email', _emailController,
                      keyboardType: TextInputType.emailAddress),
                ],
              ),
              const SizedBox(height: 16),

              // Birthday Picker Section
              GlassGroupedSection(
                quality: GlassQuality.premium,
                settings: ContactsTheme.cardSettings,
                header: const Text(
                  'BIRTHDAY & DATES',
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
                    trailing: GlassDatePicker.compact(
                      quality: GlassQuality.premium,
                      settings: ContactsTheme.cardSettings,
                      tintColor: ContactsTheme.blue,
                      initialDateTime: _birthday,
                      onDateTimeChanged: (d) => setState(() => _birthday = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Important Milestones (MultiDatePicker)
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
                      selectedDates: _milestones.toSet(),
                      onDatesChanged: (dates) =>
                          setState(() => _milestones = dates.toList()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput(
    String placeholder,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: const BoxDecoration(),
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 17,
        ),
        placeholderStyle: TextStyle(
          color: CupertinoColors.placeholderText.resolveFrom(context),
          fontSize: 17,
        ),
      ),
    );
  }
}

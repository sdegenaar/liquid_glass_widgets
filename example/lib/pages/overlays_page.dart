import 'dart:math' as math;

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OverlaysPage extends StatefulWidget {
  const OverlaysPage({super.key});

  @override
  State<OverlaysPage> createState() => _OverlaysPageState();
}

class _OverlaysPageState extends State<OverlaysPage> {
  String _lastSheetResult = 'None';
  String _lastDialogResult = 'None';

  void _showBasicSheet() {
    GlassSheet.show(
      context: context,
      settings: const LiquidGlassSettings(
        thickness: 30,
        blur: 15,
        glassColor: Colors.white24,
        lightIntensity: 1.2,
        ambientStrength: 0.7,
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Success!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is a basic glass bottom sheet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GlassButton.custom(
              onTap: () => Navigator.pop(context, 'Dismissed'),
              width: double.infinity,
              height: 48,
              shape: const LiquidRoundedSuperellipse(borderRadius: 12),
              child: const Text(
                'Dismiss',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          _lastSheetResult = result;
        });
      }
    });
  }

  void _showCustomHeightSheet() {
    GlassSheet.show(
      context: context,
      settings: const LiquidGlassSettings(
        thickness: 30,
        blur: 15,
        glassColor: Colors.white24,
        lightIntensity: 1.2,
        ambientStrength: 0.7,
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Custom Height',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This sheet demonstrates a larger content area with draggable dismiss.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildFeatureList(),
            const SizedBox(height: 24),
            GlassButton.custom(
              onTap: () => Navigator.pop(context),
              width: double.infinity,
              height: 48,
              shape: const LiquidRoundedSuperellipse(borderRadius: 12),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomSettingsSheet() {
    GlassSheet.show(
      context: context,
      isScrollControlled: true,
      settings: const LiquidGlassSettings(
        thickness: 30,
        blur: 15,
        glassColor: Colors.blue,
        lightIntensity: 1.2,
        ambientStrength: 0.7,
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                color: Colors.blue,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Custom Glass Effect',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This sheet uses custom glass settings with blue tint and enhanced blur.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingRow('Thickness', '40'),
                    _buildSettingRow('Blur', '15'),
                    _buildSettingRow('Tint', 'Blue'),
                    _buildSettingRow('Light', '1.2'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassButton.custom(
                onTap: () => Navigator.pop(context),
                width: double.infinity,
                height: 48,
                shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                glowColor: Colors.blue.withValues(alpha: 0.3),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNonDismissibleSheet() {
    GlassSheet.show(
      context: context,
      settings: const LiquidGlassSettings(
        thickness: 30,
        blur: 15,
        glassColor: Colors.white24,
        lightIntensity: 1.2,
        ambientStrength: 0.7,
      ),
      isDismissible: false,
      enableDrag: false,
      showDragIndicator: false,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Important Notice',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This sheet cannot be dismissed by dragging or tapping outside. You must tap the button below.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GlassButton.custom(
                    onTap: () => Navigator.pop(context, 'Cancelled'),
                    height: 48,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                    glowColor: Colors.grey.withValues(alpha: 0.3),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton.custom(
                    onTap: () => Navigator.pop(context, 'Confirmed'),
                    height: 48,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                    glowColor: Colors.orange.withValues(alpha: 0.3),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          _lastSheetResult = result;
        });
      }
    });
  }

  void _showScrollableSheet() {
    GlassSheet.show(
      context: context,
      settings: const LiquidGlassSettings(
        thickness: 30,
        blur: 15,
        glassColor: Colors.white24,
        lightIntensity: 1.2,
        ambientStrength: 0.7,
      ),
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Scrollable Content',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This sheet contains scrollable content',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 20,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors
                              .primaries[index % Colors.primaries.length]
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Item ${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scrollable item description',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GlassButton.custom(
                onTap: () => Navigator.pop(context),
                width: double.infinity,
                height: 48,
                shape: const LiquidRoundedSuperellipse(borderRadius: 12),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showBasicDialog() {
    GlassDialog.show(
      context: context,
      title: 'Success',
      message: 'Your changes have been saved successfully.',
      actions: [
        GlassDialogAction(
          label: 'OK',
          onPressed: () => Navigator.pop(context, 'OK'),
        ),
      ],
    ).then((result) {
      if (result != null) {
        setState(() {
          _lastDialogResult = result;
        });
      }
    });
  }

  void _showTwoActionDialog() {
    GlassDialog.show(
      context: context,
      title: 'Delete Item?',
      message:
          'This action cannot be undone. Are you sure you want to delete this item?',
      actions: [
        GlassDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, 'Cancel'),
        ),
        GlassDialogAction(
          label: 'Delete',
          isDestructive: true,
          onPressed: () => Navigator.pop(context, 'Delete'),
        ),
      ],
    ).then((result) {
      if (result != null) {
        setState(() {
          _lastDialogResult = result;
        });
      }
    });
  }

  void _showThreeActionDialog() {
    GlassDialog.show(
      context: context,
      title: 'Save Changes?',
      message: 'You have unsaved changes. What would you like to do?',
      actions: [
        GlassDialogAction(
          label: 'Don\'t Save',
          onPressed: () => Navigator.pop(context, 'Don\'t Save'),
        ),
        GlassDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, 'Cancel'),
        ),
        GlassDialogAction(
          label: 'Save',
          isPrimary: true,
          onPressed: () => Navigator.pop(context, 'Save'),
        ),
      ],
    ).then((result) {
      if (result != null) {
        setState(() {
          _lastDialogResult = result;
        });
      }
    });
  }

  void _showCustomDialog() {
    GlassDialog.show(
      context: context,
      title: 'Custom Glass',
      message: 'This dialog uses custom glass settings with purple tint.',
      settings: const LiquidGlassSettings(
        thickness: 30,
        blur: 15,
        glassColor: Colors.purple,
        lightIntensity: 1.2,
      ),
      actions: [
        GlassDialogAction(
          label: 'Close',
          isPrimary: true,
          onPressed: () => Navigator.pop(context, 'Close'),
        ),
      ],
    ).then((result) {
      if (result != null) {
        setState(() {
          _lastDialogResult = result;
        });
      }
    });
  }

  Widget _buildFeatureList() {
    return Column(
      children: [
        _buildFeatureItem(CupertinoIcons.hand_raised_fill, 'Draggable'),
        const SizedBox(height: 12),
        _buildFeatureItem(CupertinoIcons.arrow_up_arrow_down, 'Resizable'),
        const SizedBox(height: 12),
        _buildFeatureItem(CupertinoIcons.sparkles, 'Glass Effect'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      fake: true, // Use backdrop filter for scrollable content
      settings: const LiquidGlassSettings(
          blur: 6,
          thickness: 30,
          ambientStrength: 0.5,
          lightAngle: 0.25 * math.pi,
          glassColor: Color.fromRGBO(255, 255, 255, 0.10),
          lightIntensity: .5),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overlays',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modal dialogs and bottom sheets',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // GlassSheet Section
                    const _SectionTitle(title: 'GlassSheet'),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Bottom Sheet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A simple bottom sheet with drag indicator and glass effect.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            onTap: _showBasicSheet,
                            width: double.infinity,
                            height: 48,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 12,
                            ),
                            glowColor: Colors.blue.withValues(alpha: 0.3),
                            child: const Text(
                              'Show Basic Sheet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Height',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sheet with customizable height and drag boundaries.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            onTap: _showCustomHeightSheet,
                            width: double.infinity,
                            height: 48,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 12,
                            ),
                            glowColor: Colors.purple.withValues(alpha: 0.3),
                            child: const Text(
                              'Show Custom Height',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Glass Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sheet with custom glass effect settings and blue tint.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            onTap: _showCustomSettingsSheet,
                            width: double.infinity,
                            height: 48,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 12,
                            ),
                            glowColor: Colors.cyan.withValues(alpha: 0.3),
                            child: const Text(
                              'Show Custom Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Non-Dismissible Sheet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sheet that cannot be dismissed by dragging or tapping outside.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            onTap: _showNonDismissibleSheet,
                            width: double.infinity,
                            height: 48,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 12,
                            ),
                            glowColor: Colors.orange.withValues(alpha: 0.3),
                            child: const Text(
                              'Show Non-Dismissible',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scrollable Content',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sheet with scrollable list of items.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            onTap: _showScrollableSheet,
                            width: double.infinity,
                            height: 48,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 12,
                            ),
                            glowColor: Colors.green.withValues(alpha: 0.3),
                            child: const Text(
                              'Show Scrollable',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.info_circle_fill,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sheet Result',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _lastSheetResult,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // GlassDialog Section
                    const _SectionTitle(title: 'GlassDialog'),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Dialog',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Simple alert with single action button.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            onTap: _showBasicDialog,
                            width: double.infinity,
                            height: 48,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 12,
                            ),
                            glowColor: Colors.green.withValues(alpha: 0.3),
                            child: const Text(
                              'Show Basic Dialog',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Two Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Confirmation dialog with Cancel and Delete actions.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            onTap: _showTwoActionDialog,
                            width: double.infinity,
                            height: 48,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 12,
                            ),
                            glowColor: Colors.red.withValues(alpha: 0.3),
                            child: const Text(
                              'Show Two Actions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Three Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'iOS-style save dialog with vertical button layout.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            onTap: _showThreeActionDialog,
                            width: double.infinity,
                            height: 48,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 12,
                            ),
                            glowColor: Colors.amber.withValues(alpha: 0.3),
                            child: const Text(
                              'Show Three Actions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Glass',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dialog with custom glass settings and purple tint.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassButton.custom(
                            onTap: _showCustomDialog,
                            width: double.infinity,
                            height: 48,
                            shape: const LiquidRoundedSuperellipse(
                              borderRadius: 12,
                            ),
                            glowColor: Colors.purple.withValues(alpha: 0.3),
                            child: const Text(
                              'Show Custom Glass',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.info_circle_fill,
                            color: Colors.purple,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dialog Result',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _lastDialogResult,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

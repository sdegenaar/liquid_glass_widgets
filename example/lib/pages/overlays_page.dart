import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';

class OverlaysPage extends StatefulWidget {
  const OverlaysPage({super.key});

  @override
  State<OverlaysPage> createState() => _OverlaysPageState();
}

class _OverlaysPageState extends State<OverlaysPage> {
  String _lastMenuSelection = 'None';

  // ── Sheet methods ──────────────────────────────────────────────────────

  void _showBasicSheet() {
    GlassSheet.show(
      context: context,
      settings: RecommendedGlassSettings.sheet,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill,
                color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Success!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'This is a basic glass bottom sheet',
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _SheetButton(label: 'Dismiss', onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showScrollableSheet() {
    GlassSheet.show(
      context: context,
      settings: RecommendedGlassSettings.sheet,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Scrollable Content',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 15,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => GlassCard(
                  settings: RecommendedGlassSettings.overlay,
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
                          child: Text('${index + 1}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('Item ${index + 1}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _SheetButton(
                  label: 'Close', onTap: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog methods ─────────────────────────────────────────────────────

  void _showBasicDialog() {
    GlassDialog.show(
      context: context,
      title: 'Success',
      message: 'Your changes have been saved successfully.',
      actions: [
        GlassDialogAction(
          label: 'OK',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showDestructiveDialog() {
    GlassDialog.show(
      context: context,
      title: 'Delete Item?',
      message: 'This action cannot be undone.',
      actions: [
        GlassDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        GlassDialogAction(
          label: 'Delete',
          isDestructive: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showSaveDialog() {
    GlassDialog.show(
      context: context,
      title: 'Save Changes?',
      message: 'You have unsaved changes. What would you like to do?',
      actions: [
        GlassDialogAction(
          label: 'Don\'t Save',
          onPressed: () => Navigator.pop(context),
        ),
        GlassDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        GlassDialogAction(
          label: 'Save',
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // ── Action Sheet methods ───────────────────────────────────────────────

  void _showPhotoActionSheet() {
    showGlassActionSheet(
      context: context,
      title: 'Photo Options',
      actions: [
        GlassActionSheetAction(
          label: 'Save to Photos',
          icon: Icon(CupertinoIcons.photo),
          onPressed: () {},
        ),
        GlassActionSheetAction(
          label: 'Share',
          icon: Icon(CupertinoIcons.share),
          onPressed: () {},
        ),
        GlassActionSheetAction(
          label: 'Copy',
          icon: Icon(CupertinoIcons.doc_on_doc),
          onPressed: () {},
        ),
        GlassActionSheetAction(
          label: 'Delete',
          icon: Icon(CupertinoIcons.trash),
          style: GlassActionSheetStyle.destructive,
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background: buildShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          leading: GlassButton(
            quality: GlassQuality.premium,
            icon: const Icon(CupertinoIcons.back),
            onTap: () => Navigator.of(context).pop(),
            width: 40,
            height: 40,
            iconSize: 20,
          ),
        ),
        body: GlassScrollEdgeEffect(
          topFadeHeight: MediaQuery.paddingOf(context).top + 44 + 40,
          fadeBottom: false,
          child: CustomScrollView(
            slivers: [
              // Space for the app bar + safe area
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).top + 44,
                ),
              ),
              // ── Large page title (iOS 26 inline style) ──────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    'Overlays',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── GlassSheet ───────────────────────────────────
                      const _SectionTitle(title: 'GlassSheet'),
                      const SizedBox(height: 16),
                      _ActionButton(
                        label: 'Basic Bottom Sheet',
                        glowColor: Colors.blue,
                        onTap: _showBasicSheet,
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        label: 'Scrollable Content',
                        glowColor: Colors.green,
                        onTap: _showScrollableSheet,
                      ),

                      const SizedBox(height: 40),

                      // ── GlassDialog ──────────────────────────────────
                      const _SectionTitle(title: 'GlassDialog'),
                      const SizedBox(height: 16),
                      _ActionButton(
                        label: 'Basic Alert',
                        glowColor: Colors.green,
                        onTap: _showBasicDialog,
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        label: 'Destructive Confirm',
                        glowColor: Colors.red,
                        onTap: _showDestructiveDialog,
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        label: 'Save Changes (3 Actions)',
                        glowColor: Colors.amber,
                        onTap: _showSaveDialog,
                      ),

                      const SizedBox(height: 40),

                      // ── GlassMenu ────────────────────────────────────
                      const _SectionTitle(title: 'GlassMenu'),
                      const SizedBox(height: 4),
                      _QualityLabel(label: 'Premium vs Standard'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              _QualityBadge(
                                  label: 'Premium', color: Colors.amber),
                              const SizedBox(height: 8),
                              GlassMenu(
                                quality: GlassQuality.premium,
                                triggerBuilder: (context, toggle) =>
                                    GlassButton(
                                  icon: Icon(CupertinoIcons.ellipsis),
                                  onTap: toggle,
                                  label: 'Premium',
                                ),
                                items: [
                                  GlassMenuItem(
                                    icon: Icon(CupertinoIcons.share),
                                    title: 'Share',
                                    onTap: () => setState(
                                        () => _lastMenuSelection = 'Share'),
                                  ),
                                  GlassMenuItem(
                                    icon: Icon(CupertinoIcons.pen),
                                    title: 'Edit',
                                    onTap: () => setState(
                                        () => _lastMenuSelection = 'Edit'),
                                  ),
                                  GlassMenuItem(
                                    icon: Icon(CupertinoIcons.trash),
                                    title: 'Delete',
                                    isDestructive: true,
                                    onTap: () => setState(
                                        () => _lastMenuSelection = 'Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              _QualityBadge(
                                  label: 'Standard', color: Colors.white38),
                              const SizedBox(height: 8),
                              GlassMenu(
                                quality: GlassQuality.standard,
                                triggerBuilder: (context, toggle) =>
                                    GlassButton(
                                  icon: Icon(CupertinoIcons.ellipsis),
                                  onTap: toggle,
                                  label: 'Standard',
                                ),
                                items: [
                                  GlassMenuItem(
                                    icon: Icon(CupertinoIcons.share),
                                    title: 'Share',
                                    onTap: () => setState(
                                        () => _lastMenuSelection = 'Share'),
                                  ),
                                  GlassMenuItem(
                                    icon: Icon(CupertinoIcons.pen),
                                    title: 'Edit',
                                    onTap: () => setState(
                                        () => _lastMenuSelection = 'Edit'),
                                  ),
                                  GlassMenuItem(
                                    icon: Icon(CupertinoIcons.trash),
                                    title: 'Delete',
                                    isDestructive: true,
                                    onTap: () => setState(
                                        () => _lastMenuSelection = 'Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ResultRow(
                        icon: CupertinoIcons.info_circle_fill,
                        label: 'Selection: $_lastMenuSelection',
                      ),

                      const SizedBox(height: 40),

                      // ── GlassPopover ──────────────────────────────────
                      const _SectionTitle(title: 'GlassPopover'),
                      const SizedBox(height: 4),
                      _QualityLabel(label: 'Premium vs Standard'),
                      const SizedBox(height: 16),

                      // ── Quality comparison row ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // ── Premium quality ──
                          Column(
                            children: [
                              _QualityBadge(
                                  label: 'Premium', color: Colors.amber),
                              const SizedBox(height: 8),
                              GlassPopover(
                                quality: GlassQuality.premium,
                                popoverWidth: 220,
                                popoverHeight: 160,
                                triggerBuilder: (context, toggle) =>
                                    GlassButton(
                                  icon: const Icon(CupertinoIcons.sparkles),
                                  onTap: toggle,
                                  label: 'Premium',
                                  quality: GlassQuality.premium,
                                  useOwnLayer: true,
                                ),
                                contentBuilder: (context, close) => Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.sparkles,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Liquid Glass',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Premium quality with full '
                                        'metaball morph blending '
                                        'between trigger and popover.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ── Standard quality ──
                          Column(
                            children: [
                              _QualityBadge(
                                  label: 'Standard', color: Colors.white38),
                              const SizedBox(height: 8),
                              GlassPopover(
                                quality: GlassQuality.standard,
                                popoverWidth: 220,
                                popoverHeight: 160,
                                triggerBuilder: (context, toggle) =>
                                    GlassButton(
                                  icon: const Icon(CupertinoIcons.info_circle),
                                  onTap: toggle,
                                  label: 'Standard',
                                  quality: GlassQuality.standard,
                                  useOwnLayer: true,
                                ),
                                contentBuilder: (context, close) => Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.info_circle,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Backdrop Filter',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Standard quality uses backdrop '
                                        'filter — lighter on GPU but '
                                        'without metaball blending.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Self-close use case ──
                      Text(
                        'Custom content with close callback',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: GlassPopover(
                          quality: GlassQuality.premium,
                          popoverWidth: 220,
                          popoverHeight: 240,
                          triggerBuilder: (context, toggle) => GlassButton(
                            icon: const Icon(CupertinoIcons.person_circle),
                            onTap: toggle,
                            label: 'Profile',
                            quality: GlassQuality.premium,
                            useOwnLayer: true,
                          ),
                          contentBuilder: (context, close) => Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple.shade400,
                                        Colors.blue.shade400,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.person_fill,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Jane Doe',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Flutter Developer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GlassButton.custom(
                                  onTap: close,
                                  width: 120,
                                  height: 36,
                                  shape: const LiquidRoundedSuperellipse(
                                      borderRadius: 18),
                                  child: const Text(
                                    'Done',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── GlassActionSheet ─────────────────────────────
                      const _SectionTitle(title: 'GlassActionSheet'),
                      const SizedBox(height: 16),
                      _ActionButton(
                        label: 'Photo Options',
                        glowColor: Colors.purple,
                        onTap: _showPhotoActionSheet,
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Helper Widgets
// =============================================================================

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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.glowColor,
    required this.onTap,
  });
  final String label;
  final Color glowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton.custom(
      onTap: onTap,
      width: double.infinity,
      height: 48,
      shape: const LiquidRoundedSuperellipse(borderRadius: 12),
      glowColor: glowColor.withValues(alpha: 0.3),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton.custom(
      onTap: onTap,
      width: double.infinity,
      height: 48,
      settings: RecommendedGlassSettings.overlay,
      shape: const LiquidRoundedSuperellipse(borderRadius: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _QualityLabel extends StatelessWidget {
  const _QualityLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

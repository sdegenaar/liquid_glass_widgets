import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';

class InteractivePage extends StatefulWidget {
  const InteractivePage({super.key});

  @override
  State<InteractivePage> createState() => _InteractivePageState();
}

class _InteractivePageState extends State<InteractivePage> {
  // Switch state
  bool _switch1 = false;
  bool _switch2 = true;
  bool _switch3 = false;

  // Segmented control state
  int _segment1 = 0;
  int _segment2 = 1;

  // Slider state
  double _slider1 = 0.5;
  double _slider2 = 0.7;

  // Chip state
  final Set<String> _selectedFilters = {'Flutter', 'iOS'};

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background: buildShowcaseBackground(),
      settings: RecommendedGlassSettings.standard,
      statusBarStyle: GlassStatusBarStyle.light,
      child: Scaffold(
        appBar: GlassAppBar(
          title: const Text(
            'Interactive',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: GlassButton(
            icon: const Icon(CupertinoIcons.back),
            onTap: () => Navigator.of(context).pop(),
            width: 40,
            height: 40,
            iconSize: 20,
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── GlassButton ──────────────────────────────────────
                    const _SectionTitle(title: 'GlassButton'),
                    const SizedBox(height: 4),
                    _QualityLabel(label: 'Premium vs Standard'),
                    const SizedBox(height: 16),
                    _QualityRow(
                      premiumLabel: 'Premium',
                      standardLabel: 'Standard',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton.custom(
                            onTap: () {},
                            height: 56,
                            quality: GlassQuality.premium,
                            useOwnLayer: true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.arrow_down_circle_fill,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                const Text(
                                  'Download',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassButton.custom(
                            onTap: () {},
                            height: 56,
                            quality: GlassQuality.standard,
                            useOwnLayer: true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.arrow_down_circle_fill,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                const Text(
                                  'Download',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GlassButton(
                          icon: Icon(CupertinoIcons.heart),
                          onTap: () {},
                          label: 'Favorite',
                          quality: GlassQuality.premium,
                          useOwnLayer: true,
                        ),
                        GlassButton(
                          icon: Icon(CupertinoIcons.star),
                          onTap: () {},
                          label: 'Star',
                          glowColor: Colors.amber.withValues(alpha: 0.3),
                          quality: GlassQuality.premium,
                          useOwnLayer: true,
                        ),
                        GlassButton(
                          icon: Icon(CupertinoIcons.share),
                          onTap: () {},
                          label: 'Share',
                          glowColor: Colors.blue.withValues(alpha: 0.3),
                        ),
                        GlassButton(
                          icon: Icon(CupertinoIcons.bookmark),
                          onTap: () {},
                          label: 'Save',
                          glowColor: Colors.green.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Shapes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GlassButton(
                          icon: Icon(CupertinoIcons.play_fill),
                          onTap: () {},
                          shape: const LiquidOval(),
                          glowColor: Colors.purple.withValues(alpha: 0.3),
                          quality: GlassQuality.premium,
                          useOwnLayer: true,
                        ),
                        GlassButton(
                          icon: Icon(CupertinoIcons.pause_fill),
                          onTap: () {},
                          shape: const LiquidRoundedRectangle(borderRadius: 16),
                          glowColor: Colors.blue.withValues(alpha: 0.3),
                        ),
                        GlassButton(
                          icon: Icon(CupertinoIcons.stop_fill),
                          onTap: () {},
                          shape: const LiquidRoundedSuperellipse(borderRadius: 16),
                          glowColor: Colors.red.withValues(alpha: 0.3),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── GlassIconButton ──────────────────────────────────
                    const _SectionTitle(title: 'GlassIconButton'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        GlassIconButton(
                          icon: Icon(CupertinoIcons.heart),
                          onPressed: () {},
                          glowColor: Colors.red.withValues(alpha: 0.3),
                        ),
                        GlassIconButton(
                          icon: Icon(CupertinoIcons.star),
                          onPressed: () {},
                          glowColor: Colors.yellow.withValues(alpha: 0.3),
                        ),
                        GlassIconButton(
                          icon: Icon(CupertinoIcons.bell),
                          onPressed: () {},
                          glowColor: Colors.blue.withValues(alpha: 0.3),
                        ),
                        GlassIconButton(
                          icon: Icon(CupertinoIcons.share),
                          onPressed: () {},
                          shape: GlassIconButtonShape.roundedSquare,
                          glowColor: Colors.green.withValues(alpha: 0.3),
                        ),
                        GlassIconButton(
                          icon: Icon(CupertinoIcons.settings),
                          onPressed: () {},
                          shape: GlassIconButtonShape.roundedSquare,
                          glowColor: Colors.purple.withValues(alpha: 0.3),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── GlassSegmentedControl ────────────────────────────
                    const _SectionTitle(title: 'GlassSegmentedControl'),
                    const SizedBox(height: 4),
                    _QualityLabel(label: 'Premium vs Standard'),
                    const SizedBox(height: 16),
                    _QualityRow(
                      premiumLabel: 'Premium',
                      standardLabel: 'Standard',
                    ),
                    const SizedBox(height: 12),
                    GlassSegmentedControl(
                      segments: const ['Daily', 'Weekly', 'Monthly'],
                      selectedIndex: _segment1,
                      onSegmentSelected: (i) => setState(() => _segment1 = i),
                      quality: GlassQuality.premium,
                      useOwnLayer: true,
                    ),
                    const SizedBox(height: 12),
                    GlassSegmentedControl(
                      segments: const ['Daily', 'Weekly', 'Monthly'],
                      selectedIndex: _segment1,
                      onSegmentSelected: (i) => setState(() => _segment1 = i),
                      quality: GlassQuality.standard,
                      useOwnLayer: true,
                    ),
                    const SizedBox(height: 24),
                    GlassSegmentedControl(
                      segments: const ['XS', 'S', 'M', 'L', 'XL'],
                      selectedIndex: _segment2,
                      onSegmentSelected: (i) => setState(() => _segment2 = i),
                      height: 28,
                      borderRadius: 14,
                    ),

                    const SizedBox(height: 40),

                    // ── GlassSwitch ──────────────────────────────────────
                    const _SectionTitle(title: 'GlassSwitch'),
                    const SizedBox(height: 4),
                    _QualityLabel(label: 'Premium vs Standard'),
                    const SizedBox(height: 16),
                    _SwitchComparisonRow(
                      title: 'Notifications',
                      value: _switch1,
                      onChanged: (v) => setState(() => _switch1 = v),
                    ),
                    const Divider(color: Colors.white12, height: 32),
                    _SwitchComparisonRow(
                      title: 'Dark Mode',
                      value: _switch2,
                      onChanged: (v) => setState(() => _switch2 = v),
                    ),
                    const Divider(color: Colors.white12, height: 32),
                    _SwitchComparisonRow(
                      title: 'Location',
                      value: _switch3,
                      onChanged: (v) => setState(() => _switch3 = v),
                    ),

                    const SizedBox(height: 40),

                    // ── GlassSlider ──────────────────────────────────────
                    const _SectionTitle(title: 'GlassSlider'),
                    const SizedBox(height: 4),
                    _QualityLabel(label: 'Premium vs Standard'),
                    const SizedBox(height: 16),
                    _SliderComparison(
                      value: _slider1,
                      onChanged: (v) => setState(() => _slider1 = v),
                    ),
                    const SizedBox(height: 24),
                    GlassSlider(
                      value: _slider2,
                      onChanged: (v) => setState(() => _slider2 = v),
                      activeColor: Colors.blue,
                      thumbColor: Colors.blue.shade100,
                    ),

                    const SizedBox(height: 40),

                    // ── GlassButtonGroup ─────────────────────────────────
                    const _SectionTitle(title: 'GlassButtonGroup'),
                    const SizedBox(height: 16),
                    Center(
                      child: GlassButtonGroup(
                        useOwnLayer: true,
                        children: [
                          GlassButton(
                            icon: Icon(CupertinoIcons.bold),
                            style: GlassButtonStyle.transparent,
                            onTap: () {},
                          ),
                          GlassButton(
                            icon: Icon(CupertinoIcons.italic),
                            style: GlassButtonStyle.transparent,
                            onTap: () {},
                          ),
                          GlassButton(
                            icon: Icon(CupertinoIcons.underline),
                            style: GlassButtonStyle.transparent,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── GlassPullDownButton ──────────────────────────────
                    const _SectionTitle(title: 'GlassPullDownButton'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GlassPullDownButton(
                          icon: Icon(CupertinoIcons.ellipsis_circle),
                          items: [
                            GlassMenuItem(
                              title: 'Copy',
                              icon: Icon(CupertinoIcons.doc_on_doc),
                              onTap: () {},
                            ),
                            GlassMenuItem(
                              title: 'Share',
                              icon: Icon(CupertinoIcons.share),
                              onTap: () {},
                            ),
                            GlassMenuItem(
                              title: 'Delete',
                              icon: Icon(CupertinoIcons.trash),
                              isDestructive: true,
                              onTap: () {},
                            ),
                          ],
                        ),
                        GlassPullDownButton(
                          label: 'Sort By',
                          icon: Icon(CupertinoIcons.arrow_up_arrow_down),
                          buttonWidth: 120,
                          items: [
                            GlassMenuItem(
                              title: 'Name',
                              onTap: () {},
                              trailing: Icon(CupertinoIcons.checkmark_alt,
                                  size: 16, color: Colors.white),
                            ),
                            GlassMenuItem(title: 'Date', onTap: () {}),
                            GlassMenuItem(title: 'Size', onTap: () {}),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── GlassBadge ───────────────────────────────────────
                    const _SectionTitle(title: 'GlassBadge'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        GlassBadge(
                          count: 5,
                          child: GlassButton(
                            icon: Icon(CupertinoIcons.bell),
                            onTap: () {},
                            width: 48,
                            height: 48,
                          ),
                        ),
                        GlassBadge(
                          count: 12,
                          child: GlassButton(
                            icon: Icon(CupertinoIcons.envelope),
                            onTap: () {},
                            width: 48,
                            height: 48,
                          ),
                        ),
                        GlassBadge(
                          count: 99,
                          child: GlassButton(
                            icon: Icon(CupertinoIcons.chat_bubble),
                            onTap: () {},
                            width: 48,
                            height: 48,
                          ),
                        ),
                        GlassBadge.dot(
                          dotColor: Colors.green,
                          child: GlassButton(
                            icon: Icon(CupertinoIcons.person),
                            onTap: () {},
                            width: 48,
                            height: 48,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── GlassChip ────────────────────────────────────────
                    const _SectionTitle(title: 'GlassChip'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        GlassChip(
                          label: 'Favorite',
                          icon: Icon(CupertinoIcons.heart_fill),
                          iconColor: Colors.pink,
                          onTap: () {},
                        ),
                        GlassChip(
                          label: 'Share',
                          icon: Icon(CupertinoIcons.share),
                          onTap: () {},
                        ),
                        GlassChip(
                          label: 'Star',
                          icon: Icon(CupertinoIcons.star_fill),
                          iconColor: Colors.yellow,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Flutter', 'Dart', 'iOS', 'Android']
                          .map((filter) {
                        final isSelected =
                            _selectedFilters.contains(filter);
                        return GlassChip(
                          label: filter,
                          selected: isSelected,
                          selectedColor:
                              Colors.blue.withValues(alpha: 0.4),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedFilters.remove(filter);
                              } else {
                                _selectedFilters.add(filter);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
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

class _QualityRow extends StatelessWidget {
  const _QualityRow({
    required this.premiumLabel,
    required this.standardLabel,
  });
  final String premiumLabel;
  final String standardLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QualityBadge(label: premiumLabel, color: Colors.amber),
        const Spacer(),
        _QualityBadge(label: standardLabel, color: Colors.white38),
      ],
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

/// Shows premium vs standard GlassSwitch side-by-side.
class _SwitchComparisonRow extends StatelessWidget {
  const _SwitchComparisonRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        // Premium
        GlassSwitch(
          value: value,
          onChanged: onChanged,
          quality: GlassQuality.premium,
          useOwnLayer: true,
        ),
        const SizedBox(width: 16),
        // Standard
        GlassSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Shows premium vs standard GlassSlider stacked.
class _SliderComparison extends StatelessWidget {
  const _SliderComparison({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QualityRow(premiumLabel: 'Premium', standardLabel: ''),
        const SizedBox(height: 8),
        GlassSlider(
          value: value,
          onChanged: onChanged,
          quality: GlassQuality.premium,
          useOwnLayer: true,
        ),
        const SizedBox(height: 8),
        Text(
          '${(value * 100).round()}%',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 20),
        _QualityRow(premiumLabel: '', standardLabel: 'Standard'),
        const SizedBox(height: 8),
        GlassSlider(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

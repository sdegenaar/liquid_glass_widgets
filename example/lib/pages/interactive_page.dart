import 'dart:math' as math;

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
  bool _switch1 = false;
  bool _switch2 = true;
  bool _switch3 = false;

  // Segmented control state
  int _selectedSegment1 = 0;
  int _selectedSegment2 = 1;
  int _selectedSegment3 = 0;

  // Premium showcase state
  bool _premiumSwitch = true;
  int _premiumSegment = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // =====================================================================
        // PREMIUM QUALITY SHOWCASE (Static Header)
        // =====================================================================
        _PremiumShowcase(
          switchValue: _premiumSwitch,
          onSwitchChanged: (value) => setState(() => _premiumSwitch = value),
          segmentValue: _premiumSegment,
          onSegmentChanged: (value) => setState(() => _premiumSegment = value),
        ),

        // =====================================================================
        // STANDARD QUALITY (Scrollable Content)
        // =====================================================================
        Expanded(
          child: AdaptiveLiquidGlassLayer(
            settings: RecommendedGlassSettings.interactive,
            quality: GlassQuality.standard,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Interactive',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Glass widgets for user interaction',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // GlassButton Section
                          const _SectionTitle(title: 'GlassButton'),
                          const SizedBox(height: 16),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Icon Buttons',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    GlassButton(
                                      icon: CupertinoIcons.heart,
                                      onTap: () {},
                                      label: 'Favorite',
                                    ),
                                    GlassButton(
                                      icon: CupertinoIcons.star,
                                      onTap: () {},
                                      label: 'Star',
                                      glowColor:
                                          Colors.amber.withValues(alpha: 0.3),
                                    ),
                                    GlassButton(
                                      icon: CupertinoIcons.share,
                                      onTap: () {},
                                      label: 'Share',
                                      glowColor:
                                          Colors.blue.withValues(alpha: 0.3),
                                    ),
                                    GlassButton(
                                      icon: CupertinoIcons.bookmark,
                                      onTap: () {},
                                      label: 'Save',
                                      glowColor:
                                          Colors.green.withValues(alpha: 0.3),
                                    ),
                                  ],
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
                                  'Different Shapes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GlassButton(
                                      icon: CupertinoIcons.play_fill,
                                      onTap: () {},
                                      shape: const LiquidOval(),
                                      glowColor:
                                          Colors.purple.withValues(alpha: 0.3),
                                    ),
                                    GlassButton(
                                      icon: CupertinoIcons.pause_fill,
                                      onTap: () {},
                                      shape: const LiquidRoundedRectangle(
                                        borderRadius: 16,
                                      ),
                                      glowColor:
                                          Colors.blue.withValues(alpha: 0.3),
                                    ),
                                    GlassButton(
                                      icon: CupertinoIcons.stop_fill,
                                      onTap: () {},
                                      shape: const LiquidRoundedSuperellipse(
                                        borderRadius: 16,
                                      ),
                                      glowColor:
                                          Colors.red.withValues(alpha: 0.3),
                                    ),
                                  ],
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
                                  'Different Sizes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GlassButton(
                                      icon: CupertinoIcons.plus,
                                      onTap: () {},
                                      width: 40,
                                      height: 40,
                                      iconSize: 18,
                                    ),
                                    GlassButton(
                                      icon: CupertinoIcons.plus,
                                      onTap: () {},
                                      width: 56,
                                      height: 56,
                                      iconSize: 24,
                                    ),
                                    GlassButton(
                                      icon: CupertinoIcons.plus,
                                      onTap: () {},
                                      width: 72,
                                      height: 72,
                                      iconSize: 32,
                                    ),
                                  ],
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
                                  'Custom Content',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: GlassButton.custom(
                                    onTap: () {},
                                    width: 200,
                                    height: 56,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.arrow_down_circle_fill,
                                          color: Colors.white,
                                          size: 20,
                                        ),
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
                          ),
                          const SizedBox(height: 16),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Disabled State',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        GlassButton(
                                          icon: CupertinoIcons.checkmark,
                                          onTap: () {},
                                          enabled: true,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Enabled',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        GlassButton(
                                          icon: CupertinoIcons.xmark,
                                          onTap: () {},
                                          enabled: false,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Disabled',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // GlassIconButton Section
                          const _SectionTitle(title: 'GlassIconButton'),
                          const SizedBox(height: 16),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Circular Buttons',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    GlassIconButton(
                                      icon: CupertinoIcons.heart,
                                      onPressed: () {},
                                      glowColor:
                                          Colors.red.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.star,
                                      onPressed: () {},
                                      glowColor:
                                          Colors.yellow.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.bell,
                                      onPressed: () {},
                                      glowColor:
                                          Colors.blue.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.share,
                                      onPressed: () {},
                                      glowColor:
                                          Colors.green.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.settings,
                                      onPressed: () {},
                                      glowColor:
                                          Colors.purple.withValues(alpha: 0.3),
                                    ),
                                  ],
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
                                  'Rounded Square Buttons',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    GlassIconButton(
                                      icon: CupertinoIcons.add,
                                      onPressed: () {},
                                      shape: GlassIconButtonShape.roundedSquare,
                                      glowColor:
                                          Colors.blue.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.minus,
                                      onPressed: () {},
                                      shape: GlassIconButtonShape.roundedSquare,
                                      glowColor:
                                          Colors.orange.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.search,
                                      onPressed: () {},
                                      shape: GlassIconButtonShape.roundedSquare,
                                      glowColor:
                                          Colors.cyan.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.trash,
                                      onPressed: () {},
                                      shape: GlassIconButtonShape.roundedSquare,
                                      glowColor:
                                          Colors.red.withValues(alpha: 0.3),
                                    ),
                                  ],
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
                                  'Different Sizes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    GlassIconButton(
                                      icon: CupertinoIcons.heart_fill,
                                      onPressed: () {},
                                      size: 32,
                                      glowColor:
                                          Colors.pink.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.heart_fill,
                                      onPressed: () {},
                                      size: 40,
                                      glowColor:
                                          Colors.pink.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.heart_fill,
                                      onPressed: () {},
                                      size: 48,
                                      glowColor:
                                          Colors.pink.withValues(alpha: 0.3),
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.heart_fill,
                                      onPressed: () {},
                                      size: 56,
                                      glowColor:
                                          Colors.pink.withValues(alpha: 0.3),
                                    ),
                                  ],
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
                                  'Toolbar Example',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Icon buttons working together in a toolbar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GlassIconButton(
                                      icon: CupertinoIcons.back,
                                      onPressed: () {},
                                    ),
                                    Row(
                                      children: [
                                        GlassIconButton(
                                          icon: CupertinoIcons.search,
                                          onPressed: () {},
                                        ),
                                        const SizedBox(width: 8),
                                        GlassIconButton(
                                          icon: CupertinoIcons.ellipsis,
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ],
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
                                  'Disabled State',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    GlassIconButton(
                                      icon: CupertinoIcons.heart,
                                      onPressed: () {},
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.heart,
                                      onPressed: null, // Disabled
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.star,
                                      onPressed: () {},
                                      shape: GlassIconButtonShape.roundedSquare,
                                    ),
                                    GlassIconButton(
                                      icon: CupertinoIcons.star,
                                      onPressed: null, // Disabled
                                      shape: GlassIconButtonShape.roundedSquare,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // GlassSegmentedControl Section
                          const _SectionTitle(title: 'GlassSegmentedControl'),
                          const SizedBox(height: 16),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Basic Usage',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GlassSegmentedControl(
                                  segments: const [
                                    'Daily',
                                    'Weekly',
                                    'Monthly'
                                  ],
                                  selectedIndex: _selectedSegment1,
                                  onSegmentSelected: (index) {
                                    setState(() {
                                      _selectedSegment1 = index;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Selected: ${[
                                    'Daily',
                                    'Weekly',
                                    'Monthly'
                                  ][_selectedSegment1]}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
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
                                  'Two Segments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GlassSegmentedControl(
                                  segments: const ['Grid', 'List'],
                                  selectedIndex: _selectedSegment2,
                                  onSegmentSelected: (index) {
                                    setState(() {
                                      _selectedSegment2 = index;
                                    });
                                  },
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
                                  'Many Segments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GlassSegmentedControl(
                                  segments: const ['XS', 'S', 'M', 'L', 'XL'],
                                  selectedIndex: _selectedSegment3,
                                  onSegmentSelected: (index) {
                                    setState(() {
                                      _selectedSegment3 = index;
                                    });
                                  },
                                  height: 28,
                                  borderRadius: 14,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // GlassButtonGroup Section
                          const _SectionTitle(title: 'GlassButtonGroup'),
                          const SizedBox(height: 16),
                          _ButtonGroupDemosCard(),

                          const SizedBox(height: 40),

                          // GlassPullDownButton Section
                          const _SectionTitle(title: 'GlassPullDownButton'),
                          const SizedBox(height: 16),
                          _PullDownButtonDemosCard(),

                          const SizedBox(height: 40),

                          // GlassSwitch Section
                          const _SectionTitle(title: 'GlassSwitch'),
                          const SizedBox(height: 16),
                          GlassCard(
                            child: Column(
                              children: [
                                _SwitchRow(
                                  title: 'Notifications',
                                  subtitle: 'Receive push notifications',
                                  value: _switch1,
                                  onChanged: (value) {
                                    setState(() {
                                      _switch1 = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white24, height: 1),
                                const SizedBox(height: 16),
                                _SwitchRow(
                                  title: 'Dark Mode',
                                  subtitle: 'Use dark theme',
                                  value: _switch2,
                                  onChanged: (value) {
                                    setState(() {
                                      _switch2 = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white24, height: 1),
                                const SizedBox(height: 16),
                                _SwitchRow(
                                  title: 'Location Services',
                                  subtitle: 'Allow location access',
                                  value: _switch3,
                                  onChanged: (value) {
                                    setState(() {
                                      _switch3 = value;
                                    });
                                  },
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
                                  'Custom Colors',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        GlassSwitch(
                                          value: true,
                                          onChanged: (value) {},
                                          activeColor: Colors.blue,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Blue',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        GlassSwitch(
                                          value: true,
                                          onChanged: (value) {},
                                          activeColor: Colors.purple,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Purple',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        GlassSwitch(
                                          value: true,
                                          onChanged: (value) {},
                                          activeColor: Colors.pink,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Pink',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // GlassSlider Section
                          const _SectionTitle(title: 'GlassSlider'),
                          const SizedBox(height: 16),
                          _SliderDemosCard(),

                          const SizedBox(height: 40),

                          // GlassChip Section
                          const _SectionTitle(title: 'GlassChip'),
                          const SizedBox(height: 16),
                          _ChipDemosCard(),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Premium Quality Showcase Widget
// =============================================================================

class _PremiumShowcase extends StatelessWidget {
  const _PremiumShowcase({
    required this.switchValue,
    required this.onSwitchChanged,
    required this.segmentValue,
    required this.onSegmentChanged,
  });

  final bool switchValue;
  final ValueChanged<bool> onSwitchChanged;
  final int segmentValue;
  final ValueChanged<int> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withValues(alpha: 0.3),
            Colors.blue.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: AdaptiveLiquidGlassLayer(
          // PREMIUM: Use shader-based glass
          settings: const LiquidGlassSettings(
            blur: 5,
            thickness: 40,
            refractiveIndex: 1.7,
            lightIntensity: 1.2,
            chromaticAberration: 0.8,
            ambientStrength: 0.6,
            lightAngle: 0.25 * math.pi,
            glassColor: Colors.white12,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'PREMIUM QUALITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Static Layout Only',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Best Visual Quality',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Shader-based rendering',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GlassSwitch(
                      value: switchValue,
                      onChanged: onSwitchChanged,
                      quality: GlassQuality.premium,
                      useOwnLayer: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassSegmentedControl(
                  segments: const ['Option A', 'Option B', 'Option C'],
                  height: 40,
                  selectedIndex: segmentValue,
                  onSegmentSelected: onSegmentChanged,
                  quality: GlassQuality.premium,
                  useOwnLayer: true,
                  backgroundColor: Colors.black38,
                  unselectedTextStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                  selectedTextStyle: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  indicatorColor: Colors.white38,
                  glassSettings: LiquidGlassSettings(
                    refractiveIndex: 1.21,
                    thickness: 30,
                    blur: 4,
                    saturation: 1.5,
                    lightIntensity: .7,
                    ambientStrength: .5,
                    lightAngle: 0.25 * math.pi,
                    glassColor: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        GlassSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// =============================================================================
// Slider Demos Widget
// =============================================================================

class _SliderDemosCard extends StatefulWidget {
  @override
  State<_SliderDemosCard> createState() => _SliderDemosCardState();
}

class _SliderDemosCardState extends State<_SliderDemosCard> {
  double _volumeValue = 0.5;
  double _brightnessValue = 0.7;
  double _discreteValue = 3.0;
  double _coloredValue = 0.3;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic Slider',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              GlassSlider(
                value: _volumeValue,
                onChanged: (value) {
                  setState(() => _volumeValue = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Volume: ${(_volumeValue * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
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
                'Discrete Steps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              GlassSlider(
                value: _discreteValue,
                min: 0,
                max: 5,
                divisions: 5,
                onChanged: (value) {
                  setState(() => _discreteValue = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Level: ${_discreteValue.round()}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
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
                'Custom Colors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              GlassSlider(
                value: _brightnessValue,
                onChanged: (value) {
                  setState(() => _brightnessValue = value);
                },
                activeColor: Colors.blue,
                thumbColor: Colors.blue.shade100,
              ),
              const SizedBox(height: 16),
              GlassSlider(
                value: _coloredValue,
                onChanged: (value) {
                  setState(() => _coloredValue = value);
                },
                activeColor: Colors.pink,
                thumbColor: Colors.pink.shade100,
                trackHeight: 6,
                thumbRadius: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Chip Demos Widget
// =============================================================================

class _ChipDemosCard extends StatefulWidget {
  @override
  State<_ChipDemosCard> createState() => _ChipDemosCardState();
}

class _ChipDemosCardState extends State<_ChipDemosCard> {
  final Set<String> _selectedFilters = {'Flutter', 'iOS'};
  final List<String> _tags = ['Travel', 'Food', 'Technology', 'Sports'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic Chips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GlassChip(
                    label: 'Technology',
                    onTap: () {},
                  ),
                  GlassChip(
                    label: 'Design',
                    onTap: () {},
                  ),
                  GlassChip(
                    label: 'Development',
                    onTap: () {},
                  ),
                ],
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
                'With Icons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GlassChip(
                    label: 'Favorite',
                    icon: CupertinoIcons.heart_fill,
                    iconColor: Colors.pink,
                    onTap: () {},
                  ),
                  GlassChip(
                    label: 'Share',
                    icon: CupertinoIcons.share,
                    onTap: () {},
                  ),
                  GlassChip(
                    label: 'Star',
                    icon: CupertinoIcons.star_fill,
                    iconColor: Colors.yellow,
                    onTap: () {},
                  ),
                ],
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
                'Dismissible Chips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return GlassChip(
                    label: tag,
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap X to remove',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
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
                'Filter Chips (Selectable)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Flutter', 'Dart', 'iOS', 'Android'].map((filter) {
                  final isSelected = _selectedFilters.contains(filter);
                  return GlassChip(
                    label: filter,
                    selected: isSelected,
                    selectedColor: Colors.blue.withValues(alpha: 0.4),
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
              const SizedBox(height: 8),
              Text(
                'Selected: ${_selectedFilters.join(", ")}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// =============================================================================
// Button Group Demos Widget
// =============================================================================

class _ButtonGroupDemosCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Joined Group (Toolbar)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GlassButtonGroup(
                  useOwnLayer: true, // Needs own layer to draw background
                  children: [
                    GlassButton(
                      icon: CupertinoIcons.bold,
                      style: GlassButtonStyle.transparent,
                      onTap: () {},
                    ),
                    GlassButton(
                      icon: CupertinoIcons.italic,
                      style: GlassButtonStyle.transparent,
                      onTap: () {},
                    ),
                    GlassButton(
                      icon: CupertinoIcons.underline,
                      style: GlassButtonStyle.transparent,
                      onTap: () {},
                    ),
                  ],
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
                'Navigation Group',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GlassButtonGroup(
                  useOwnLayer: true,
                  borderRadius: 20,
                  children: [
                    GlassButton(
                      icon: CupertinoIcons.back,
                      style: GlassButtonStyle.transparent,
                      width: 60,
                      onTap: () {},
                    ),
                    GlassButton(
                      icon: CupertinoIcons.forward,
                      style: GlassButtonStyle.transparent,
                      width: 60,
                      onTap: () {},
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
}

// =============================================================================
// Pull Down Button Demos Widget
// =============================================================================

class _PullDownButtonDemosCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toolbar Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GlassPullDownButton(
                    icon: CupertinoIcons.ellipsis_circle,
                    items: [
                      GlassMenuItem(
                        title: 'Copy',
                        icon: CupertinoIcons.doc_on_doc,
                        onTap: () {},
                      ),
                      GlassMenuItem(
                        title: 'Share',
                        icon: CupertinoIcons.share,
                        onTap: () {},
                      ),
                      GlassMenuItem(
                        title: 'Delete',
                        icon: CupertinoIcons.trash,
                        isDestructive: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                  GlassPullDownButton(
                    label: 'Sort By',
                    icon: CupertinoIcons.arrow_up_arrow_down,
                    buttonWidth: 120,
                    items: [
                      GlassMenuItem(
                        title: 'Name',
                        onTap: () {},
                        trailing: Icon(CupertinoIcons.checkmark_alt,
                            size: 16, color: Colors.white),
                      ),
                      GlassMenuItem(
                        title: 'Date',
                        onTap: () {},
                      ),
                      GlassMenuItem(
                        title: 'Size',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tap to reveal fluid menu',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SurfacesPage extends StatelessWidget {
  const SurfacesPage({super.key});

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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: const Text(
            'Surfaces',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: GlassButton(
            icon: CupertinoIcons.sidebar_left,
            onTap: () {},
            width: 40,
            height: 40,
            iconSize: 20,
          ),
          actions: [
            GlassButton(
              icon: CupertinoIcons.search,
              onTap: () {},
              width: 40,
              height: 40,
              iconSize: 20,
            ),
            GlassButton(
              icon: CupertinoIcons.ellipsis,
              onTap: () {},
              width: 40,
              height: 40,
              iconSize: 20,
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Glass surface widgets for navigation',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // GlassAppBar Section
                    const _SectionTitle(title: 'GlassAppBar'),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Navigation Bar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The GlassAppBar you see at the top of this page is a live example! It features:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Blurred glass background',
                          ),
                          const SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Leading widget support (sidebar button)',
                          ),
                          const SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Multiple action buttons',
                          ),
                          const SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Centered title',
                          ),
                          const SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Safe area handling',
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
                            'Usage Modes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _UsageMode(
                            title: 'Grouped Mode',
                            description:
                                'Wrap Scaffold in LiquidGlassLayer for best performance when using multiple glass widgets',
                            isRecommended: true,
                          ),
                          const SizedBox(height: 12),
                          _UsageMode(
                            title: 'Standalone Mode',
                            description:
                                'Set useOwnLayer: true to use the app bar without a parent layer',
                            isRecommended: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // GlassBottomBar Section
                    const _SectionTitle(title: 'GlassBottomBar'),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bottom Navigation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The GlassBottomBar at the bottom of this app is a live example! It features:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Draggable indicator with jelly physics',
                          ),
                          const SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Velocity-based snapping',
                          ),
                          const SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Rubber band resistance at edges',
                          ),
                          const SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Per-tab glow colors',
                          ),
                          const SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Optional extra button',
                          ),
                          const SizedBox(height: 8),
                          _FeatureItem(
                            icon: CupertinoIcons.checkmark_circle_fill,
                            text: 'Seamless glass blending',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.lightbulb_fill,
                                color: Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Try It Out!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Try these interactions with the bottom bar:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _TipItem(text: 'Tap a tab to switch pages'),
                          const SizedBox(height: 8),
                          _TipItem(
                            text:
                                'Drag the indicator left/right to switch tabs',
                          ),
                          const SizedBox(height: 8),
                          _TipItem(
                            text:
                                'Flick quickly to jump multiple tabs with velocity',
                          ),
                          const SizedBox(height: 8),
                          _TipItem(
                            text:
                                'Try dragging beyond the edges to feel the rubber band resistance',
                          ),
                          const SizedBox(height: 8),
                          _TipItem(
                            text:
                                'Watch the glow effects as you select different tabs',
                          ),
                        ],
                      ),
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

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _UsageMode extends StatelessWidget {
  const _UsageMode({
    required this.title,
    required this.description,
    required this.isRecommended,
  });

  final String title;
  final String description;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRecommended
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

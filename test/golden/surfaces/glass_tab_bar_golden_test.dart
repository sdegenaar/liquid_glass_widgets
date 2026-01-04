// ignore_for_file: avoid_redundant_argument_values

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassTabBar Golden Tests', () {
    goldenTest(
      'renders with labels only',
      fileName: 'glass_tab_bar_labels',
      tags: ['golden'],
      constraints: testScenarioConstraints,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'first tab selected',
            child: buildWithGradientBackground(
              Center(
                child: AdaptiveLiquidGlassLayer(
                  settings: settingsWithoutLighting,
                  child: GlassTabBar(
                    tabs: const [
                      GlassTab(label: 'Timeline'),
                      GlassTab(label: 'Mentions'),
                      GlassTab(label: 'Messages'),
                    ],
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'middle tab selected',
            child: buildWithGradientBackground(
              Center(
                child: AdaptiveLiquidGlassLayer(
                  settings: settingsWithoutLighting,
                  child: GlassTabBar(
                    tabs: const [
                      GlassTab(label: 'Timeline'),
                      GlassTab(label: 'Mentions'),
                      GlassTab(label: 'Messages'),
                    ],
                    selectedIndex: 1,
                    onTabSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders with icons only',
      fileName: 'glass_tab_bar_icons',
      tags: ['golden'],
      constraints: testScenarioConstraints,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'home selected',
            child: buildWithGradientBackground(
              Center(
                child: AdaptiveLiquidGlassLayer(
                  settings: settingsWithoutLighting,
                  child: GlassTabBar(
                    tabs: const [
                      GlassTab(icon: Icons.home),
                      GlassTab(icon: Icons.search),
                      GlassTab(icon: Icons.notifications),
                      GlassTab(icon: Icons.settings),
                    ],
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders with icons and labels',
      fileName: 'glass_tab_bar_icons_labels',
      tags: ['golden'],
      constraints: testScenarioConstraints,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'first selected',
            child: buildWithGradientBackground(
              Center(
                child: AdaptiveLiquidGlassLayer(
                  settings: settingsWithoutLighting,
                  child: GlassTabBar(
                    height: 56,
                    tabs: const [
                      GlassTab(icon: Icons.home, label: 'Home'),
                      GlassTab(icon: Icons.search, label: 'Search'),
                      GlassTab(icon: Icons.person, label: 'Profile'),
                    ],
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders with custom styling',
      fileName: 'glass_tab_bar_custom_styling',
      tags: ['golden'],
      constraints: testScenarioConstraints,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'custom colors',
            child: buildWithGradientBackground(
              Center(
                child: AdaptiveLiquidGlassLayer(
                  settings: settingsWithoutLighting,
                  child: GlassTabBar(
                    height: 60,
                    tabs: const [
                      GlassTab(label: 'Tab 1'),
                      GlassTab(label: 'Tab 2'),
                      GlassTab(label: 'Tab 3'),
                    ],
                    selectedIndex: 1,
                    onTabSelected: (_) {},
                    selectedLabelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    indicatorColor: Colors.blue.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders scrollable with many tabs',
      fileName: 'glass_tab_bar_scrollable',
      tags: ['golden'],
      constraints: testScenarioConstraints,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'many tabs',
            child: buildWithGradientBackground(
              Center(
                child: AdaptiveLiquidGlassLayer(
                  settings: settingsWithoutLighting,
                  child: GlassTabBar(
                    isScrollable: true,
                    tabs: List.generate(
                      8,
                      (i) => GlassTab(label: 'Category ${i + 1}'),
                    ),
                    selectedIndex: 3,
                    onTabSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders in standalone mode',
      fileName: 'glass_tab_bar_standalone',
      tags: ['golden'],
      constraints: testScenarioConstraints,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'with own layer',
            child: buildWithGradientBackground(
              Center(
                child: GlassTabBar(
                  useOwnLayer: true,
                  settings: settingsWithoutLighting,
                  tabs: const [
                    GlassTab(label: 'Tab 1'),
                    GlassTab(label: 'Tab 2'),
                    GlassTab(label: 'Tab 3'),
                  ],
                  selectedIndex: 1,
                  onTabSelected: (_) {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}

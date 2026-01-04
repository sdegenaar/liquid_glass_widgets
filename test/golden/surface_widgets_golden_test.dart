@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/interactive/glass_button.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/glass_app_bar.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/glass_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';

import '../shared/test_helpers.dart';

void main() {
  goldenTest(
    'GlassAppBar renders correctly',
    fileName: 'glass_app_bar',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      scenarioConstraints:
          const BoxConstraints.tightFor(width: 400, height: 100),
      children: [
        GoldenTestScenario(
          name: 'centered_title',
          child: buildWithGradientBackground(
            AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: const Material(
                color: Colors.transparent,
                child: GlassAppBar(
                  title: Text(
                    'App Title',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'with_actions',
          child: buildWithGradientBackground(
            AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: Material(
                color: Colors.transparent,
                child: GlassAppBar(
                  title: const Text(
                    'Title',
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    GlassButton(icon: Icons.search, onTap: () {}),
                    GlassButton(icon: Icons.more_horiz, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'GlassBottomBar renders correctly',
    fileName: 'glass_bottom_bar',
    pumpBeforeTest: pumpOnce,
    builder: () => GoldenTestGroup(
      scenarioConstraints:
          const BoxConstraints.tightFor(width: 400, height: 120),
      children: [
        GoldenTestScenario(
          name: 'three_tabs',
          child: buildWithGradientBackground(
            GlassBottomBar(
              tabs: const [
                GlassBottomBarTab(
                  label: 'Home',
                  icon: CupertinoIcons.home,
                ),
                GlassBottomBarTab(
                  label: 'Search',
                  icon: CupertinoIcons.search,
                ),
                GlassBottomBarTab(
                  label: 'Profile',
                  icon: CupertinoIcons.person,
                ),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'with_extra_button',
          child: buildWithGradientBackground(
            GlassBottomBar(
              tabs: const [
                GlassBottomBarTab(
                  label: 'Home',
                  icon: CupertinoIcons.home,
                ),
                GlassBottomBarTab(
                  label: 'Search',
                  icon: CupertinoIcons.search,
                ),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              extraButton: GlassBottomBarExtraButton(
                icon: CupertinoIcons.add,
                label: 'Add',
                onTap: () {},
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

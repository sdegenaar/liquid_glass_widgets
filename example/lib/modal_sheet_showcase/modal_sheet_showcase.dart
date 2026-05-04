/// GlassModalSheet showcase — demonstrates all sheet modes, peek geometry,
/// smart silence, and the Apple Maps-style floating sheet experience.
///
/// Run standalone:
///   flutter run -t lib/modal_sheet_showcase/modal_sheet_showcase.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(
      child: const ShowcaseApp(), adaptiveQuality: false));
}

class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  GlassQuality _quality = GlassQuality.standard;

  void _setQuality(GlassQuality quality) {
    setState(() => _quality = quality);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glass Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      home: ShowcaseHomeScreen(
        onQualityChanged: _setQuality,
        currentQuality: _quality,
      ),
    );
  }
}

class ShowcaseHomeScreen extends StatefulWidget {
  final ValueChanged<GlassQuality> onQualityChanged;
  final GlassQuality currentQuality;

  const ShowcaseHomeScreen({
    super.key,
    required this.onQualityChanged,
    required this.currentQuality,
  });

  @override
  State<ShowcaseHomeScreen> createState() => _ShowcaseHomeScreenState();
}

class _ShowcaseHomeScreenState extends State<ShowcaseHomeScreen> {
  bool _isSearching = false;
  bool _searchFieldFocused = false;
  int _selectedTab = 0; // 0=Standard, 1=Peek, 2=Apple Maps

  @override
  Widget build(BuildContext context) {
    final sysBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          if (_searchFieldFocused) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: Stack(
          children: [
            // Background Gradient
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF000000), Color(0xFF1C1C1E)],
                  ),
                ),
              ),
            ),

            // Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _buildBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: sysBottom > 0 ? sysBottom - 25 : 0),
        child: GlassSearchableBottomBar(
          selectedIndex: _selectedTab,
          interactionBehavior: GlassInteractionBehavior.scaleOnly,
          isSearchActive: _isSearching,
          onTabSelected: (index) => setState(() {
            _selectedTab = index;
            _isSearching = false;
          }),
          selectedIconColor: Colors.blue,
          unselectedIconColor: Colors.white60,
          quality: GlassQuality.premium,
          glassSettings: const LiquidGlassSettings(
            glassColor: Color(0xAA1C1C1E),
            blur: 25,
          ),
          searchConfig: GlassSearchBarConfig(
            hintText: 'Search Scenarios',
            onSearchToggle: (active) => setState(() {
              _isSearching = active;
              if (!active) _searchFieldFocused = false;
            }),
            onSearchFocusChanged: (focused) =>
                setState(() => _searchFieldFocused = focused),
          ),
          tabs: [
            GlassBottomBarTab(
              label: 'Standard',
              icon: const Icon(CupertinoIcons.layers_alt),
              activeIcon: const Icon(CupertinoIcons.layers_alt_fill),
            ),
            GlassBottomBarTab(
              label: 'Peek',
              icon: const Icon(Icons.unfold_more_rounded),
            ),
            GlassBottomBarTab(
              label: 'Apple Maps',
              icon: const Icon(CupertinoIcons.map),
              activeIcon: const Icon(CupertinoIcons.map_fill),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return _buildSearchState();
    }

    return Column(
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top + 12),
        _buildHeader(),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Showcase',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              Text(
                _getTabName(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildQualityToggle(),
        ],
      ),
    );
  }

  String _getTabName() {
    switch (_selectedTab) {
      case 0:
        return 'Standard Modal';
      case 1:
        return 'Standard Peek';
      case 2:
        return 'Apple Maps Style';
      default:
        return '';
    }
  }

  Widget _buildQualityToggle() {
    final qualities = GlassQuality.values;
    final currentIndex = qualities.indexOf(widget.currentQuality);

    return SizedBox(
      width: 160,
      child: GlassSegmentedControl(
        segments: const ['Standard', 'Premium', 'Minimal'],
        selectedIndex: currentIndex >= 0 ? currentIndex : 1,
        onSegmentSelected: (index) {
          widget.onQualityChanged(qualities[index]);
        },
        useOwnLayer: true,
        height: 28,
        borderRadius: 8,
        selectedTextStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        unselectedTextStyle: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Scenario Tile
          _buildScenarioTile(
            title: _getTabName(),
            description: _getTabDescription(),
            icon: _getTabIconData(),
            onTap: () {
              switch (_selectedTab) {
                case 0:
                  _showStandardExperience(context);
                  break;
                case 1:
                  _showStandardPeek(context);
                  break;
                case 2:
                  _showMapsExperience(context);
                  break;
              }
            },
          ),
          const SizedBox(height: 16),

          // Additional Scenarios for Standard Tab
          if (_selectedTab == 0) ...[
            _buildScenarioTile(
              title: 'Static Modal',
              description: 'Disabled glow and window scaling',
              icon: Icons.block_flipped,
              onTap: () => _showStaticModal(context),
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildScenarioTile(
              title: 'Smart Silence',
              description: 'Ignore sheet feedback on child touch',
              icon: Icons.volume_off_rounded,
              onTap: () => _showSmartSilence(context),
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildScenarioTile(
              title: 'Gradual Transition',
              description: 'Smooth glass to color fade',
              icon: Icons.gradient_rounded,
              onTap: () => _showGradualTransition(context),
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _buildScenarioTile(
              title: 'Top Fade',
              description: 'Gradient fade at the top edge',
              icon: Icons.expand_less_rounded,
              onTap: () => _showTopFade(context),
              color: Colors.pink,
            ),
            const SizedBox(height: 16),
            _buildScenarioTile(
              title: 'Transparent Barrier',
              description: 'No dimming behind the sheet',
              icon: Icons.visibility_off_rounded,
              onTap: () => _showTransparentBarrier(context),
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            _buildScenarioTile(
              title: 'Solid Half State',
              description: 'Opaque brown in Half state',
              icon: Icons.color_lens_rounded,
              onTap: () => _showSolidHalfState(context),
              color: Colors.brown,
            ),
            const SizedBox(height: 16),
            _buildScenarioTile(
              title: 'Dual Glass Setup',
              description: 'Different glass for Half vs Full',
              icon: Icons.exposure_rounded,
              onTap: () => _showDualGlassSetup(context),
              color: Colors.cyan,
            ),
            const SizedBox(height: 16),
            _buildScenarioTile(
              title: 'Custom Dimensions',
              description: 'Unique Peek/Half/Full sizes',
              icon: Icons.straighten_rounded,
              onTap: () => _showCustomDimensions(context),
              color: Colors.amber,
            ),
          ],

          // Peek Scenarios
          if (_selectedTab == 1) ...[
            _buildScenarioTile(
              title: 'Glass Panel',
              description: 'Standalone GlassPanel component demo',
              icon: Icons.window_rounded,
              onTap: () => _showGlassPanel(context),
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            GlassMenu(
              menuWidth: 240,
              quality: widget.currentQuality,
              glassSettings: LiquidGlassSettings(
                glassColor: Colors.transparent,
                thickness: 30,
                blur: 2,
                chromaticAberration: .01,
                lightAngle: GlassDefaults.lightAngle,
                lightIntensity: .5,
                ambientStrength: 0,
                refractiveIndex: 1.2,
                saturation: 1.2,
                //specularSharpness: GlassSpecularSharpness.medium,
              ),
              enableInteractionGlow: true, // Show touch-following glare
              glowRadius: 0.6,
              interactionScale: 1.00,
              triggerBuilder: (context, toggleMenu) => GlassButton(
                icon: const Icon(Icons.menu_open_rounded),
                onTap: toggleMenu,
              ),
              items: [
                GlassMenuItem(
                  title: 'Edit Content',
                  subtitle: 'Opens an edit view',
                  icon: const Icon(Icons.edit_rounded),
                  onTap: () {},
                ),
                const GlassMenuDivider(),
                GlassMenuItem(
                  title: 'Share Scenario',
                  icon: const Icon(Icons.share_rounded),
                  onTap: () {},
                ),
                GlassMenuItem(
                  title: 'Delete Demo',
                  icon: const Icon(Icons.delete_rounded),
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ],

          // Apple Maps Style Tab
          if (_selectedTab == 2) ...[
            _buildScenarioTile(
              title: 'Maps Experience',
              description: 'Interactive map with floating sheet',
              icon: Icons.map_rounded,
              onTap: () => _showMapsExperience(context),
              color: Colors.blue,
            ),
          ],

          const SizedBox(height: 120), // Padding for bottom bar
        ],
      ),
    );
  }

  Widget _buildScenarioTile({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return GlassButton.custom(
      width: double.infinity,
      height: 80,
      useOwnLayer: true,
      quality: GlassQuality.standard,
      shape: const LiquidRoundedSuperellipse(borderRadius: 20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  String _getTabDescription() {
    switch (_selectedTab) {
      case 0:
        return 'Standard interactive glass experience';
      case 1:
        return 'Starts as a small bar at the bottom';
      case 2:
        return 'Floating pill style like Apple Maps';
      default:
        return 'Explore glass effects';
    }
  }

  IconData _getTabIconData() {
    switch (_selectedTab) {
      case 0:
        return CupertinoIcons.layers_alt_fill;
      case 1:
        return Icons.unfold_more_rounded;
      case 2:
        return CupertinoIcons.map_fill;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  // ===========================================================================
  // Scenario Launch Methods (example2 pattern)
  // ===========================================================================

  void _showStandardExperience(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Standard Experience',
          subtitle:
              'Explore how interactive glass elements behave inside a glass sheet.',
        ),
      ),
    );
  }

  void _showStandardPeek(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      initialState: SheetState.peek,
      enablePeek: true,
      peekTopBorderRadius: 46,
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Standard Peek',
          subtitle: 'A full-width persistent bar at the bottom.',
        ),
      ),
    );
  }

  void _showGlassPanel(BuildContext context) {
    GlassSheet.show(
      context: context,
      quality: widget.currentQuality,
      builder: (context) => const GlassBackdropScope(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(24),
              child: GlassPanel(
                useOwnLayer: true,
                child: SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Glass Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'Standalone GlassPanel component demo.',
              style: TextStyle(color: Colors.white54),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showStaticModal(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      interactionScale: 1.0,
      enableInteractionGlow: false,
      enableSaturationGlow: false,
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Static Experience',
          subtitle:
              'This scenario has all tactile feedback disabled (no scaling, no glow).',
        ),
      ),
    );
  }

  void _showSmartSilence(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      suppressInteractionOnChildren: true,
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Smart Silence',
          subtitle:
              'In this mode, children dispatch an InteractionNotification. The sheet stays stable.',
          silenceInteractions: true,
        ),
      ),
    );
  }

  void _showGradualTransition(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      fillTransition: FillTransition.gradual,
      fillThreshold: 0.8,
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Gradual Experience',
          subtitle:
              'Watch as the glass smoothly transitions into a solid color during expansion.',
        ),
      ),
    );
  }

  void _showTopFade(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      enableTopFade: true,
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Top Fade Experience',
          subtitle:
              'A subtle gradient fade at the top of the sheet helps content blend smoothly.',
        ),
      ),
    );
  }

  void _showTransparentBarrier(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      barrierColor: Colors.transparent,
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Transparent Barrier',
          subtitle:
              'The background remains fully visible and interactive without any dimming layer.',
        ),
      ),
    );
  }

  void _showSolidHalfState(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      halfSettings: const LiquidGlassSettings(
        glassColor: Colors.brown,
        blur: 0,
        refractiveIndex: 1.0,
        thickness: 0,
      ),
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Solid Brown Half',
          subtitle:
              'Demonstrates overriding glass settings for a specific state (Half = Solid Brown).',
        ),
      ),
    );
  }

  void _showDualGlassSetup(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      halfSettings: const LiquidGlassSettings(thickness: 10, blur: 2),
      fullSettings: const LiquidGlassSettings(thickness: 40, blur: 15),
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Dynamic Glass Morphing',
          subtitle:
              'The material itself changes during expansion: Half (Thin) → Full (Thick Frosted).',
        ),
      ),
    );
  }

  void _showCustomDimensions(BuildContext context) {
    GlassModalSheet.show(
      context: context,
      quality: widget.currentQuality,
      peekSize: 150,
      halfSize: 0.35,
      fullSize: 0.8,
      builder: (context) => const GlassBackdropScope(
        child: BaseScenario(
          title: 'Custom Layout',
          subtitle:
              'Peek is taller (150px), Half is lower (35%), and Full only reaches 80% height.',
        ),
      ),
    );
  }

  void _showMapsExperience(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapsExperienceScreen(currentQuality: widget.currentQuality),
      ),
    );
  }

  Widget _buildSearchState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 64,
            color: Colors.blue.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Search active',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class MapsExperienceScreen extends StatelessWidget {
  final GlassQuality currentQuality;

  const MapsExperienceScreen({super.key, required this.currentQuality});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassModalSheetScaffold(
        mode: SheetMode.persistent,
        enablePeek: true,
        initialState: SheetState.peek,
        peekSize: 90,
        halfSize: 0.445,
        horizontalMargin: 5,
        bottomMargin: 6,
        peekWidth: 340,
        peekHorizontalMargin: 20,
        peekBottomMargin: 32,
        peekTopBorderRadius: 28,
        peekBottomRadius: 28,
        topBorderRadius: 40,
        bottomBorderRadius: 54,
        fullTopBorderRadius: 36,
        fillTransition: FillTransition.instant,
        halfSettings: LiquidGlassSettings(
          blur: 5,
          glassColor: Colors.blueGrey.withValues(alpha: 0.8),
        ),
        quality: currentQuality,
        body: Stack(
          children: [
            InteractiveViewer(
              maxScale: 5.0,
              minScale: 0.1,
              boundaryMargin: const EdgeInsets.all(1000),
              child: Image.asset(
                'assets/modal_sheet_showcase/map_bg.png',
                fit: BoxFit.cover,
                width: 2000,
                height: 2000,
              ),
            ),
            // Floating Back Button
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        sheet: BaseScenario(
          title: 'San Francisco',
          subtitle: 'Explore locations and transit in the bay area.',
        ),
      ),
    );
  }
}

// =============================================================================
// Scenario Widgets
// =============================================================================

/// A unified helper to build scenarios without boilerplate.
class BaseScenario extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool silenceInteractions;

  const BaseScenario({
    super.key,
    required this.title,
    required this.subtitle,
    this.silenceInteractions = false,
  });

  @override
  State<BaseScenario> createState() => _BaseScenarioState();
}

class _BaseScenarioState extends State<BaseScenario> {
  bool _switchValue = true;

  Widget _wrapIfSilenced({required Widget child}) {
    if (!widget.silenceInteractions) return child;
    return Listener(
      onPointerDown: (event) {
        InteractionNotification(event).dispatch(context);
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollData = ScrollControllerProvider.of(context);

    return ListView.builder(
      controller: scrollData?.controller,
      physics: scrollData?.physics,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: 30,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                const SizedBox(height: 25),

                // INTERACTIVE SECTION
                Row(
                  children: [
                    Expanded(
                      child: _wrapIfSilenced(
                        child: GlassButton.custom(
                          height: 50,
                          useOwnLayer: false,
                          shape: const LiquidRoundedSuperellipse(
                            borderRadius: 14,
                          ),
                          onTap: () {},
                          child: const Center(child: Text('Action A')),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _wrapIfSilenced(
                        child: GlassButton.custom(
                          height: 50,
                          useOwnLayer: false,
                          shape: const LiquidRoundedSuperellipse(
                            borderRadius: 14,
                          ),
                          onTap: () {},
                          child: const Center(child: Text('Action B')),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _wrapIfSilenced(
                      child: GlassSwitch(
                        value: _switchValue,
                        onChanged: (val) => setState(() => _switchValue = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            useOwnLayer: false,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item #$index',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Secondary information or description text goes here.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

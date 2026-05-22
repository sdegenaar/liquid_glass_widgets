import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets_example/constants/glass_settings.dart';
import 'package:liquid_glass_widgets_example/pages/containers_page.dart';
import 'package:liquid_glass_widgets_example/pages/feedback_page.dart';
import 'package:liquid_glass_widgets_example/pages/input_page.dart';
import 'package:liquid_glass_widgets_example/pages/interactive_page.dart';
import 'package:liquid_glass_widgets_example/pages/overlays_page.dart';
import 'package:liquid_glass_widgets_example/pages/surfaces_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized before loading shaders
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes the Liquid Glass library.
  await LiquidGlassWidgets.initialize();

  // wrap() puts a GlassBackdropScope at the root so every glass surface in the
  // app (GlassBottomBar, GlassAppBar, GlassCard, etc.) shares a single GPU
  // backdrop capture on Impeller — halving blit cost when multiple surfaces
  // are visible at once. On Skia/Web it is a no-op.
  runApp(LiquidGlassWidgets.wrap(child: const AppleLiquidGlassShowcaseApp()));
}

class AppleLiquidGlassShowcaseApp extends StatelessWidget {
  const AppleLiquidGlassShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apple Liquid Glass Showcase',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue,
          surface: Colors.black,
        ),
      ),
      home: const ShowcaseHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ShowcaseHomePage extends StatefulWidget {
  const ShowcaseHomePage({super.key});

  @override
  State<ShowcaseHomePage> createState() => _ShowcaseHomePageState();
}

class _ShowcaseHomePageState extends State<ShowcaseHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    ContainersPage(),
    InteractivePage(),
    FeedbackPage(),
    OverlaysPage(),
    SurfacesPage(),
    InputPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      background: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/wallpaper_dark.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
      child: Scaffold(
        extendBody: true,
        body: _pages[_selectedIndex],
        bottomNavigationBar: GlassBottomBar(
          quality: GlassQuality.premium,
          indicatorColor: Colors.black26,
          glassSettings: RecommendedGlassSettings.bottomBar,
          tabs: [
            GlassBottomBarTab(
              label: 'Home',
              icon: const Icon(CupertinoIcons.home),
              activeIcon: const Icon(CupertinoIcons.house_fill),
            ),
            GlassBottomBarTab(
              label: 'Containers',
              icon: const Icon(CupertinoIcons.square_stack_3d_up),
              activeIcon: const Icon(CupertinoIcons.square_stack_3d_up_fill),
            ),
            GlassBottomBarTab(
              label: 'Interactive',
              icon: const Icon(CupertinoIcons.hand_point_right),
              activeIcon: const Icon(CupertinoIcons.hand_point_right_fill),
            ),
            GlassBottomBarTab(
              label: 'Feedback',
              icon: const Icon(CupertinoIcons.hourglass),
              activeIcon: const Icon(CupertinoIcons.hourglass),
            ),
            GlassBottomBarTab(
              label: 'Overlays',
              icon: const Icon(CupertinoIcons.square_stack),
              activeIcon: const Icon(CupertinoIcons.square_stack_fill),
            ),
            GlassBottomBarTab(
              label: 'Surfaces',
              icon: const Icon(CupertinoIcons.rectangle_3_offgrid),
              activeIcon: const Icon(CupertinoIcons.rectangle_3_offgrid_fill),
            ),
            GlassBottomBarTab(
              label: 'Input',
              icon: const Icon(CupertinoIcons.keyboard),
            ),
          ],
          selectedIndex: _selectedIndex,
          onTabSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLiquidGlassLayer(
      settings: RecommendedGlassSettings.standard,
      quality: GlassQuality.standard, // Scrollable content - use standard
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
                    const SizedBox(height: 20),
                    const Text(
                      'Apple Liquid Glass',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Widget Showcase',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 40),
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.sparkles,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Explore the glass widget collection',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'This showcase demonstrates Apple Liquid Glass widgets following Apple\'s design philosophy of composable primitives.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Widget Categories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CategoryCard(
                      icon: Icon(CupertinoIcons.square_stack_3d_up_fill),
                      title: 'Containers',
                      description:
                          'GlassCard, GlassPanel, and GlassContainer for content',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(
                      icon: Icon(CupertinoIcons.hand_point_right_fill),
                      title: 'Interactive',
                      description:
                          'GlassButton, GlassSwitch, and GlassSegmentedControl',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(
                      icon: Icon(CupertinoIcons.hourglass),
                      title: 'Feedback',
                      description:
                          'GlassProgressIndicator for loading and progress',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(
                      icon: Icon(CupertinoIcons.square_stack_fill),
                      title: 'Overlays',
                      description:
                          'GlassSheet for modal dialogs and bottom sheets',
                      color: Colors.cyan,
                    ),
                    const SizedBox(height: 12),
                    _CategoryCard(
                      icon: Icon(CupertinoIcons.rectangle_3_offgrid_fill),
                      title: 'Surfaces',
                      description:
                          'GlassAppBar and GlassBottomBar for navigation',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    const _CategoryCard(
                      icon: Icon(CupertinoIcons.keyboard),
                      title: 'Input',
                      description: 'GlassTextField for text input',
                      color: Colors.pink,
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final Widget icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: icon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

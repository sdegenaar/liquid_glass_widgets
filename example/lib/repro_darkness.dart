import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(const ReproApp());
}

class ReproApp extends StatelessWidget {
  const ReproApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const ReproPage(),
    );
  }
}

class ReproPage extends StatefulWidget {
  const ReproPage({super.key});

  @override
  State<ReproPage> createState() => _ReproPageState();
}

class _ReproPageState extends State<ReproPage> {
  int _selectedIndex = 0;
  double _alpha = 0.6;

  @override
  void initState() {
    super.initState();
    final settings = LiquidGlassSettings.figma(
      refraction: 60,
      depth: 80,
      dispersion: 100,
      frost: 2,
      lightAngle: -45,
      lightIntensity: 70,
      glassColor: Colors.white,
    );
    debugPrint('[REPRO] Figma Mapping:');
    debugPrint('  Blur: ${settings.blur}');
    debugPrint('  Thickness: ${settings.thickness}');
    debugPrint('  Refractive Index: ${settings.refractiveIndex}');
    debugPrint('  Chromatic Aberration: ${settings.chromaticAberration}');
    debugPrint('  Light Intensity: ${settings.lightIntensity}');
    debugPrint('  Ambient Strength: ${settings.ambientStrength}');
    debugPrint('  Saturation: ${settings.saturation}');
    debugPrint('  Light Angle: ${settings.lightAngle}');
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScope.stack(
      background: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            ),
          ),
        ),
      ),
      content: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Background Content',
                style: TextStyle(color: Colors.white24, fontSize: 40),
              ),
              const SizedBox(height: 20),
              Slider(
                value: _alpha,
                min: 0.0,
                max: 1.0,
                onChanged: (v) => setState(() => _alpha = v),
              ),
              Text('Glass Alpha: ${_alpha.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              const Text('Reproduction Page',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        bottomNavigationBar: GlassBottomBar(
          glassSettings: LiquidGlassSettings.figma(
            refraction: 60,
            depth: 80,
            dispersion: 100,
            frost: 2,
            lightAngle: -45,
            lightIntensity: 70,
            glassColor: Colors.white.withValues(alpha: _alpha),
          ),
          indicatorSettings: LiquidGlassSettings.figma(
            refraction: 60,
            depth: 80,
            dispersion: 100,
            frost: 2,
            lightAngle: -45,
            lightIntensity: 70,
            glassColor: Colors.white.withValues(alpha: .2),
          ),
          quality: GlassQuality.standard,
          selectedIndex: _selectedIndex,
          tabs: const [
            GlassBottomBarTab(icon: Icon(Icons.public), label: 'Explore'),
            GlassBottomBarTab(icon: Icon(Icons.collections), label: 'Stories'),
            GlassBottomBarTab(icon: Icon(Icons.star), label: 'Bookmarks'),
            GlassBottomBarTab(icon: Icon(Icons.person), label: 'Profile'),
          ],
          barHeight: 60,
          extraButton: GlassBottomBarExtraButton(
            icon: const Icon(Icons.search),
            size: 60,
            label: 'Search',
            onTap: () {},
          ),
          iconSize: 20,
          onTabSelected: (index) {
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }
}

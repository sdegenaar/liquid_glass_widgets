import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'pages/home_page.dart';

/// Wanderlust - A luxury travel showcase app
///
/// This app demonstrates the capabilities of liquid_glass_widgets
/// in a real-world context, featuring stunning travel destinations
/// with glass morphism effects that enhance rather than hide imagery.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize liquid glass widgets to prevent white flash
  await LiquidGlassWidgets.initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WanderlustApp());
}

class WanderlustApp extends StatelessWidget {
  const WanderlustApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wanderlust',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.dark,
        ),
        fontFamily: 'SF Pro Display', // Falls back to system font
      ),
      home: const HomePage(),
    );
  }
}

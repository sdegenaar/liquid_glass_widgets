import 'package:cupertino_ui/cupertino_ui.dart';
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
      systemNavigationBarColor: Color(
        0x00000000,
      ), // Color(0x00000000) equivalent
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(LiquidGlassWidgets.wrap(child: const WanderlustApp()));
}

class WanderlustApp extends StatelessWidget {
  const WanderlustApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Wanderlust',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF4A90E2),
        // textTheme: CupertinoTextThemeData(
        //   textStyle: TextStyle(fontFamily: 'SF Pro Display'),
        // ),
      ),
      home: HomePage(),
    );
  }
}

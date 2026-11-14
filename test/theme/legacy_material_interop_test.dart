// Interoperability guard for host apps that have not yet migrated off
// `package:flutter/material.dart` onto `package:material_ui/material_ui.dart`.
//
// Because `liquid_glass_widgets` exposes only `flutter/widgets.dart` and
// `dart:ui` primitives across its Material-facing integration points
// (`PreferredSizeWidget`, `Brightness`, `BuildContext`), legacy `MaterialApp`
// consumers remain 100% compile-time and runtime compatible with 1.18.0+.

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  tearDown(() {
    LiquidGlassWidgets.wrap(child: const SizedBox.shrink());
  });

  testWidgets(
    'legacy flutter/material.dart MaterialApp + Scaffold + GlassAppBar interoperates cleanly',
    (tester) async {
      Brightness? resolvedBrightness;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: LiquidGlassWidgets.wrap(
            adaptiveQuality: false,
            brightnessResolver: Theme.maybeBrightnessOf,
            child: MaterialApp(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: ThemeMode.dark,
              home: Scaffold(
                appBar: const GlassAppBar(title: Text('Legacy Material Host')),
                body: Builder(
                  builder: (context) {
                    resolvedBrightness = GlassTheme.brightnessOf(context);
                    return GlassButton.custom(
                      onTap: () {},
                      child: const Text('Action'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Legacy Material Host'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(
        resolvedBrightness,
        Brightness.dark,
        reason:
            'Theme.maybeBrightnessOf from legacy flutter/material.dart must '
            'bridge ThemeMode.dark into GlassTheme.brightnessOf',
      );
    },
  );
}

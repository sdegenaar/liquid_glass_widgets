/// Apple Contacts iOS 26/27 — High-Fidelity Showcase Benchmark
///
/// Demonstrates the complete inventory of 7 High-Priority Liquid Glass Parity features:
///   1. [GlassSwipeActions] — swipe to call, message, or full-swipe delete
///   2. [GlassDisclosureGroup] — collapsible accordion sections with rotating chevrons
///   3. [GlassEditScope], [GlassEditButton], [GlassReorderableList] — ambient editing, delete badges, reorder handles
///   4. [GlassContextMenu] — authentic compression, specular preview platter, and actions
///   5. [GlassFullScreenCover] & [showGlassFullScreenCover] — modal presentation with spring physics
///   6. [GlassDatePicker] & [GlassMultiDatePicker] — compact date pill, inline calendar, and multi-date picker
///   7. [GlassNavigationStack] & [GlassNavigationLink] — declarative typed navigation
///
/// Run standalone:
///   flutter run -t example/lib/apple_contacts/apple_contacts_demo.dart
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

export 'models/contact_models.dart';
export 'theme/contacts_theme.dart';
export 'views/contact_detail_view.dart';
export 'views/contact_edit_sheet.dart';
export 'views/contacts_list_view.dart';

import 'views/contacts_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();

  runApp(LiquidGlassWidgets.wrap(
    adaptiveQuality: true,
    theme: GlassThemeData.simple(
      blur: 24,
      thickness: 20,
      quality: GlassQuality.premium,
    ),
    child: const AppleContactsDemoApp(),
  ));
}

class AppleContactsDemoApp extends StatelessWidget {
  const AppleContactsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Apple Contacts',
      theme: const CupertinoThemeData(brightness: Brightness.dark),
      builder: (context, child) => Theme(
        data: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: const Color(0xFF000000),
        ),
        child: GlassNavigationShell(child: child!),
      ),
      home: const GlassNavigationStack(
        root: ContactsListView(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

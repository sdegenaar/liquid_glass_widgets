// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/overlays/modal_theme_capture.dart';
import 'package:liquid_glass_widgets/utils/glass_brightness.dart';

class _ThemeSnapshot {
  const _ThemeSnapshot({
    required this.glassBrightness,
    required this.cupertinoBrightness,
    required this.resolvedLabel,
    required this.style,
    required this.primaryColor,
    required this.defaultFontSize,
    required this.mountCount,
  });

  final Brightness glassBrightness;
  final Brightness cupertinoBrightness;
  final Color resolvedLabel;
  final GlassStyle style;
  final Color primaryColor;
  final double? defaultFontSize;
  final int mountCount;
}

class _ThemeProbe extends StatefulWidget {
  const _ThemeProbe({required this.onRead});

  final ValueChanged<_ThemeSnapshot> onRead;

  @override
  State<_ThemeProbe> createState() => _ThemeProbeState();
}

class _ThemeProbeState extends State<_ThemeProbe> {
  static int totalMounts = 0;

  @override
  void initState() {
    super.initState();
    totalMounts++;
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    widget.onRead(
      _ThemeSnapshot(
        glassBrightness: GlassTheme.brightnessOf(context),
        cupertinoBrightness: CupertinoTheme.brightnessOf(context),
        resolvedLabel: CupertinoColors.label.resolveFrom(context),
        style: GlassThemeData.of(context).style,
        primaryColor: cupertinoTheme.primaryColor,
        defaultFontSize: DefaultTextStyle.of(context).style.fontSize,
        mountCount: totalMounts,
      ),
    );
    return const SizedBox(width: 40, height: 40, child: Text('Probe'));
  }
}

Widget _materialScaffoldHost({
  required Widget child,
  GlassThemeData? rootGlassTheme,
  ThemeMode themeMode = ThemeMode.system,
}) {
  return MaterialApp(
    themeMode: themeMode,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    builder: rootGlassTheme == null
        ? null
        : (context, appChild) => GlassTheme(
              data: rootGlassTheme,
              child: appChild!,
            ),
    home: GlassScaffold(body: Center(child: child)),
  );
}

void main() {
  setUp(() {
    _ThemeProbeState.totalMounts = 0;
  });

  group('Live theme and brightness updates across open modals', () {
    testWidgets(
      'GlassModalSheet.show updates brightness live from inside GlassScaffold '
      'without remounting sheet content',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  GlassModalSheet.show<void>(
                    context: context,
                    builder: (_) => _ThemeProbe(onRead: (s) => snapshot = s),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(snapshot!.glassBrightness, Brightness.light);
        expect(snapshot!.cupertinoBrightness, Brightness.light);
        expect(snapshot!.resolvedLabel.toARGB32(),
            CupertinoColors.label.color.toARGB32());
        expect(snapshot!.mountCount, 1);

        // Flip OS brightness while modal stays open.
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        expect(snapshot!.glassBrightness, Brightness.dark);
        expect(snapshot!.cupertinoBrightness, Brightness.dark);
        expect(snapshot!.resolvedLabel.toARGB32(),
            CupertinoColors.label.darkColor.toARGB32());
        expect(snapshot!.mountCount, 1,
            reason: 'Child must not remount on brightness change');

        // Flip back to light.
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        await tester.pumpAndSettle();

        expect(snapshot!.glassBrightness, Brightness.light);
        expect(snapshot!.cupertinoBrightness, Brightness.light);
        expect(snapshot!.resolvedLabel.toARGB32(),
            CupertinoColors.label.color.toARGB32());
        expect(snapshot!.mountCount, 1);
      },
    );

    testWidgets(
      'GlassModalSheet.show reacts live to programmatic root GlassTheme changes',
      (tester) async {
        final themeNotifier = ValueNotifier<GlassThemeData>(
          const GlassThemeData.ios27(brightness: Brightness.light),
        );
        addTearDown(themeNotifier.dispose);

        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          ValueListenableBuilder<GlassThemeData>(
            valueListenable: themeNotifier,
            builder: (context, themeData, _) => _materialScaffoldHost(
              rootGlassTheme: themeData,
              child: Builder(
                builder: (btnCtx) => CupertinoButton(
                  onPressed: () {
                    GlassModalSheet.show<void>(
                      context: btnCtx,
                      builder: (_) => _ThemeProbe(onRead: (s) => snapshot = s),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(snapshot!.glassBrightness, Brightness.light);
        expect(snapshot!.cupertinoBrightness, Brightness.light);
        expect(snapshot!.style, GlassStyle.ios27);

        themeNotifier.value =
            const GlassThemeData.classic(brightness: Brightness.dark);
        await tester.pumpAndSettle();

        expect(snapshot!.glassBrightness, Brightness.dark);
        expect(snapshot!.cupertinoBrightness, Brightness.dark);
        expect(snapshot!.style, GlassStyle.classic);
      },
    );

    testWidgets(
      'GlassSheet.show updates brightness live when system appearance changes',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  GlassSheet.show<void>(
                    context: context,
                    builder: (_) => _ThemeProbe(onRead: (s) => snapshot = s),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(snapshot!.glassBrightness, Brightness.light);
        expect(snapshot!.resolvedLabel.toARGB32(),
            CupertinoColors.label.color.toARGB32());

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();
        expect(snapshot!.glassBrightness, Brightness.dark);
        expect(snapshot!.resolvedLabel.toARGB32(),
            CupertinoColors.label.darkColor.toARGB32());
      },
    );

    testWidgets(
      'GlassDialog.show updates brightness live when system appearance changes',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  GlassDialog.show<void>(
                    context: context,
                    title: 'Alert',
                    content: _ThemeProbe(onRead: (s) => snapshot = s),
                    actions: [
                      GlassDialogAction(label: 'OK', onPressed: () {}),
                    ],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(snapshot!.glassBrightness, Brightness.light);
        expect(snapshot!.resolvedLabel.toARGB32(),
            CupertinoColors.label.color.toARGB32());

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();
        expect(snapshot!.glassBrightness, Brightness.dark);
        expect(snapshot!.resolvedLabel.toARGB32(),
            CupertinoColors.label.darkColor.toARGB32());
      },
    );

    testWidgets(
      'showGlassActionSheet updates brightness live when system appearance changes',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  showGlassActionSheet<void>(
                    context: context,
                    title: 'Choose',
                    actions: [
                      GlassActionSheetAction(label: 'Delete', onPressed: () {}),
                    ],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final titleContextLight = tester.element(find.text('Choose'));
        expect(GlassTheme.brightnessOf(titleContextLight), Brightness.light);
        expect(
          CupertinoColors.label.resolveFrom(titleContextLight).toARGB32(),
          CupertinoColors.label.color.toARGB32(),
        );

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        final titleContextDark = tester.element(find.text('Choose'));
        expect(GlassTheme.brightnessOf(titleContextDark), Brightness.dark);
        expect(
          CupertinoColors.label.resolveFrom(titleContextDark).toARGB32(),
          CupertinoColors.label.darkColor.toARGB32(),
        );
      },
    );

    testWidgets(
      'GlassToast.show updates brightness live when system appearance changes',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        VoidCallback? dismiss;
        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  dismiss = GlassToast.show(
                    context,
                    message: 'Saved',
                    duration: const Duration(seconds: 10),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final toastLightCtx = tester.element(find.text('Saved'));
        expect(GlassTheme.brightnessOf(toastLightCtx), Brightness.light);

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final toastDarkCtx = tester.element(find.text('Saved'));
        expect(GlassTheme.brightnessOf(toastDarkCtx), Brightness.dark);

        dismiss?.call();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'showGlassFullScreenCover updates brightness live when system appearance changes',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  showGlassFullScreenCover<void>(
                    context: context,
                    builder: (_) => GlassFullScreenCover(
                      child: _ThemeProbe(onRead: (s) => snapshot = s),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(snapshot!.glassBrightness, Brightness.light);

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();
        expect(snapshot!.glassBrightness, Brightness.dark);
      },
    );

    testWidgets(
      'showGlassContextMenu updates brightness live when system appearance changes',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  showGlassContextMenu<void>(
                    context: context,
                    targetRect: const Rect.fromLTWH(100, 200, 120, 44),
                    actions: [
                      GlassContextMenuAction(
                        child: const Text('Share'),
                        onPressed: () {},
                      ),
                    ],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final shareLight = tester.element(find.text('Share'));
        expect(GlassTheme.brightnessOf(shareLight), Brightness.light);

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        final shareDark = tester.element(find.text('Share'));
        expect(GlassTheme.brightnessOf(shareDark), Brightness.dark);
      },
    );

    testWidgets(
      'GlassPicker.showSheet updates brightness and DefaultTextStyle live',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  GlassPicker.showSheet<String>(
                    context: context,
                    title: 'Pick Fruit',
                    items: const ['Apple', 'Orange'],
                    itemBuilder: Text.new,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final lightCtx = tester.element(find.text('Pick Fruit'));
        expect(GlassTheme.brightnessOf(lightCtx), Brightness.light);
        expect(
          CupertinoColors.label.resolveFrom(lightCtx).toARGB32(),
          CupertinoColors.label.color.toARGB32(),
        );

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        final darkCtx = tester.element(find.text('Pick Fruit'));
        expect(GlassTheme.brightnessOf(darkCtx), Brightness.dark);
        expect(
          CupertinoColors.label.resolveFrom(darkCtx).toARGB32(),
          CupertinoColors.label.darkColor.toARGB32(),
        );
      },
    );

    testWidgets(
      'showGlassDatePicker updates brightness and surface color live',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () {
                  showGlassDatePicker(
                    context: context,
                    title: 'Pick Date',
                    initialDateTime: DateTime(2026, 11, 24),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final lightCtx = tester.element(find.text('Pick Date'));
        expect(GlassTheme.brightnessOf(lightCtx), Brightness.light);
        expect(
          CupertinoColors.systemBackground.resolveFrom(lightCtx).toARGB32(),
          CupertinoColors.systemBackground.color.toARGB32(),
        );

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        final darkCtx = tester.element(find.text('Pick Date'));
        expect(GlassTheme.brightnessOf(darkCtx), Brightness.dark);
        expect(
          CupertinoColors.systemBackground.resolveFrom(darkCtx).toARGB32(),
          CupertinoColors.systemBackground.darkElevatedColor.toARGB32(),
        );
      },
    );

    testWidgets(
      'GlassDatePicker compact popover updates brightness live',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: GlassDatePicker(
              style: GlassDatePickerStyle.compact,
              mode: GlassDatePickerMode.date,
              initialDateTime: DateTime(2026, 5, 24),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap compact date pill to open popover.
        await tester.tap(find.byType(GlassDatePicker));
        await tester.pumpAndSettle();

        final lightHeader = tester.element(find.text('May 2026'));
        expect(GlassTheme.brightnessOf(lightHeader), Brightness.light);
        final lightPlatter = tester.widget<ColoredBox>(
          find
              .ancestor(
                of: find.text('May 2026'),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(lightPlatter.color, const Color(0xECF9F9FB));

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        final darkHeader = tester.element(find.text('May 2026'));
        expect(GlassTheme.brightnessOf(darkHeader), Brightness.dark);
        final darkPlatter = tester.widget<ColoredBox>(
          find
              .ancestor(
                of: find.text('May 2026'),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(darkPlatter.color, const Color(0xE0252528));
      },
    );
  });

  group('Subtree theme preservation & synthetic theme skipping', () {
    testWidgets(
      'preserves subtree GlassTheme style below Navigator while keeping '
      'brightness live when brightness is null',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          MaterialApp(
            themeMode: ThemeMode.system,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: GlassTheme(
              data: const GlassThemeData.classic(),
              child: GlassScaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => CupertinoButton(
                      onPressed: () {
                        GlassModalSheet.show<void>(
                          context: context,
                          builder: (_) =>
                              _ThemeProbe(onRead: (s) => snapshot = s),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(snapshot!.style, GlassStyle.classic);
        expect(snapshot!.glassBrightness, Brightness.light);

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        expect(snapshot!.style, GlassStyle.classic);
        expect(snapshot!.glassBrightness, Brightness.dark);
      },
    );

    testWidgets(
      'preserves explicit brightness pin on subtree GlassTheme below Navigator',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: GlassTheme(
              data: const GlassThemeData.ios27(brightness: Brightness.dark),
              child: GlassScaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => CupertinoButton(
                      onPressed: () {
                        GlassModalSheet.show<void>(
                          context: context,
                          builder: (_) =>
                              _ThemeProbe(onRead: (s) => snapshot = s),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(snapshot!.glassBrightness, Brightness.dark);
        expect(snapshot!.cupertinoBrightness, Brightness.dark);
      },
    );

    testWidgets(
      'preserves user CupertinoTheme primaryColor below Navigator while '
      'keeping brightness live when brightness is null',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        const customPrimary = Color(0xFFFF3B30);
        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          CupertinoApp(
            home: CupertinoTheme(
              data: const CupertinoThemeData(primaryColor: customPrimary),
              child: GlassScaffold(
                body: Center(
                  child: Builder(
                    builder: (context) => CupertinoButton(
                      onPressed: () {
                        GlassModalSheet.show<void>(
                          context: context,
                          builder: (_) =>
                              _ThemeProbe(onRead: (s) => snapshot = s),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(snapshot!.primaryColor, customPrimary);
        expect(snapshot!.glassBrightness, Brightness.light);

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        expect(snapshot!.primaryColor, customPrimary);
        expect(snapshot!.glassBrightness, Brightness.dark);
      },
    );

    testWidgets(
      'skips GlassInternalGlassTheme and GlassInternalCupertinoTheme '
      '(e.g. GlassContentAwareScope bar) and does not leak trigger DefaultTextStyle',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          _materialScaffoldHost(
            rootGlassTheme: const GlassThemeData.ios27(),
            child: DefaultTextStyle(
              style: const TextStyle(fontSize: 42),
              child: GlassInternalGlassTheme(
                data: const GlassThemeData.classic(brightness: Brightness.dark),
                child: GlassInternalCupertinoTheme(
                  data: const CupertinoThemeData(brightness: Brightness.dark),
                  child: Builder(
                    builder: (context) => CupertinoButton(
                      onPressed: () {
                        GlassModalSheet.show<void>(
                          context: context,
                          builder: (_) =>
                              _ThemeProbe(onRead: (s) => snapshot = s),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(snapshot!.glassBrightness, Brightness.light);
        expect(snapshot!.style, GlassStyle.ios27);
        expect(snapshot!.defaultFontSize, isNot(42));
      },
    );

    testWidgets(
      'GlassTheme extends InheritedTheme so Flutter showDialog '
      'preserves subtree GlassTheme overrides',
      (tester) async {
        GlassStyle? dialogStyle;

        await tester.pumpWidget(
          MaterialApp(
            home: GlassTheme(
              data: const GlassThemeData.classic(),
              child: Builder(
                builder: (context) => CupertinoButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogCtx) {
                        dialogStyle = GlassThemeData.of(dialogCtx).style;
                        return const CupertinoAlertDialog(title: Text('Hi'));
                      },
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(dialogStyle, GlassStyle.classic);
      },
    );

    testWidgets(
      'preserves null CupertinoThemeData.brightness under CupertinoApp so '
      'local MediaQuery.platformBrightness overrides inside a modal still work',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        Brightness? previewBrightness;
        Color? previewLabel;

        await tester.pumpWidget(
          CupertinoApp(
            theme: const CupertinoThemeData(
              primaryColor: CupertinoColors.systemIndigo,
            ),
            home: GlassScaffold(
              body: Center(
                child: Builder(
                  builder: (context) => CupertinoButton(
                    onPressed: () {
                      GlassModalSheet.show<void>(
                        context: context,
                        builder: (sheetCtx) => MediaQuery(
                          data: MediaQuery.of(sheetCtx).copyWith(
                            platformBrightness: Brightness.dark,
                          ),
                          child: Builder(
                            builder: (previewCtx) {
                              previewBrightness =
                                  GlassTheme.brightnessOf(previewCtx);
                              previewLabel =
                                  CupertinoColors.label.resolveFrom(previewCtx);
                              return const SizedBox(width: 40, height: 40);
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(previewBrightness, Brightness.dark);
        expect(
          previewLabel!.toARGB32(),
          CupertinoColors.label.darkColor.toARGB32(),
        );
      },
    );

    testWidgets(
      'MaterialApp programmatic ThemeMode toggle updates open modal live '
      'when brightnessResolver is registered',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        addTearDown(() => glassExternalBrightnessResolver = null);

        final modeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
        addTearDown(modeNotifier.dispose);

        _ThemeSnapshot? snapshot;

        await tester.pumpWidget(
          LiquidGlassWidgets.wrap(
            brightnessResolver: Theme.maybeBrightnessOf,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: modeNotifier,
              builder: (context, mode, _) => _materialScaffoldHost(
                themeMode: mode,
                child: Builder(
                  builder: (btnCtx) => CupertinoButton(
                    onPressed: () {
                      GlassModalSheet.show<void>(
                        context: btnCtx,
                        builder: (_) =>
                            _ThemeProbe(onRead: (s) => snapshot = s),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(snapshot!.glassBrightness, Brightness.light);
        expect(snapshot!.cupertinoBrightness, Brightness.light);

        modeNotifier.value = ThemeMode.dark;
        await tester.pumpAndSettle();

        expect(snapshot!.glassBrightness, Brightness.dark);
        expect(snapshot!.cupertinoBrightness, Brightness.dark);
        expect(
          snapshot!.resolvedLabel.toARGB32(),
          CupertinoColors.label.darkColor.toARGB32(),
        );
      },
    );

    testWidgets(
      'nested modals opened from inside a modal both update brightness live',
      (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        _ThemeSnapshot? outerSnapshot;
        _ThemeSnapshot? innerSnapshot;

        await tester.pumpWidget(
          _materialScaffoldHost(
            child: Builder(
              builder: (rootCtx) => CupertinoButton(
                onPressed: () {
                  GlassModalSheet.show<void>(
                    context: rootCtx,
                    builder: (sheetCtx) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ThemeProbe(onRead: (s) => outerSnapshot = s),
                        CupertinoButton(
                          onPressed: () {
                            GlassDialog.show<void>(
                              context: sheetCtx,
                              title: 'Nested',
                              content: _ThemeProbe(
                                onRead: (s) => innerSnapshot = s,
                              ),
                              actions: [
                                GlassDialogAction(
                                  label: 'OK',
                                  onPressed: () {},
                                ),
                              ],
                            );
                          },
                          child: const Text('Open Nested'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open Outer'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Outer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open Nested'));
        await tester.pumpAndSettle();

        expect(outerSnapshot!.glassBrightness, Brightness.light);
        expect(innerSnapshot!.glassBrightness, Brightness.light);

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pumpAndSettle();

        expect(outerSnapshot!.glassBrightness, Brightness.dark);
        expect(innerSnapshot!.glassBrightness, Brightness.dark);
        expect(
          innerSnapshot!.resolvedLabel.toARGB32(),
          CupertinoColors.label.darkColor.toARGB32(),
        );
      },
    );
  });
}

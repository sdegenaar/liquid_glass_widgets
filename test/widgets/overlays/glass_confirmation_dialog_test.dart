import 'dart:ui' show SemanticsRole;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/overlays/glass_alert_platter.dart';

class _FrenchCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const _FrenchCupertinoLocalizations();

  @override
  String get cancelButtonLabel => 'Annuler';
}

class _FrenchCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FrenchCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const _FrenchCupertinoLocalizations(),
      );

  @override
  bool shouldReload(_FrenchCupertinoLocalizationsDelegate old) => false;
}

void _setPhoneViewport(
  WidgetTester tester, {
  Size size = const Size(402, 874),
  EdgeInsets padding = const EdgeInsets.only(top: 59, bottom: 34),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding(
    top: padding.top,
    bottom: padding.bottom,
    left: padding.left,
    right: padding.right,
  );
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();
  });
}

Widget _harness({
  required Widget child,
  GlassThemeData theme = const GlassThemeData.ios27(),
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
  bool highContrast = false,
}) {
  return GlassTheme(
    data: theme,
    child: CupertinoApp(
      theme: CupertinoThemeData(brightness: brightness),
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          platformBrightness: brightness,
          disableAnimations: disableAnimations,
          highContrast: highContrast,
        ),
        child: GlassAccessibilityScope(child: appChild!),
      ),
      home: CupertinoPageScaffold(child: child),
    ),
  );
}

void main() {
  group('GlassConfirmationDialogAction', () {
    test('defaults match iOS confirmation dialog contract', () {
      var called = false;
      final action = GlassConfirmationDialogAction(
        label: 'Share',
        onPressed: () => called = true,
      );

      expect(action.label, 'Share');
      expect(action.icon, isNull);
      expect(action.isDestructive, isFalse);
      expect(action.isPrimary, isFalse);
      expect(action.tintColor, isNull);
      expect(action.foregroundColor, isNull);
      expect(action.dismissOnPress, isTrue);

      action.onPressed!();
      expect(called, isTrue);
    });

    test('accepts null onPressed for disabled action', () {
      const action = GlassConfirmationDialogAction(
        label: 'Disabled',
        onPressed: null,
        isPrimary: true,
      );
      expect(action.onPressed, isNull);
    });
  });

  group('showGlassConfirmationDialog — unanchored (centered 320 pt platter)',
      () {
    testWidgets('shows title, message, stacked actions, and Cancel by default',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => Center(
              child: CupertinoButton(
                onPressed: () => showGlassConfirmationDialog<void>(
                  context: context,
                  title: 'Delete Draft?',
                  message: 'This draft cannot be recovered once deleted.',
                  actions: [
                    GlassConfirmationDialogAction(
                      label: 'Save Draft',
                      onPressed: () {},
                    ),
                    GlassConfirmationDialogAction(
                      label: 'Delete Draft',
                      isDestructive: true,
                      onPressed: () {},
                    ),
                  ],
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Draft?'), findsOneWidget);
      expect(
        find.text('This draft cannot be recovered once deleted.'),
        findsOneWidget,
      );
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Delete Draft'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Platter width matches calibrated 320 pt centered width.
      final cardRect = tester.getRect(find.byType(GlassContainer));
      expect(cardRect.width, closeTo(kGlassAlertPlatterWidth, 1.0));

      // Actions stack vertically even when labels are short.
      final saveY = tester.getCenter(find.text('Save Draft')).dy;
      final deleteY = tester.getCenter(find.text('Delete Draft')).dy;
      final cancelY = tester.getCenter(find.text('Cancel')).dy;
      expect(saveY, lessThan(deleteY));
      expect(deleteY, lessThan(cancelY));

      // Tapping Cancel dismisses the dialog.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Draft?'), findsNothing);
    });

    testWidgets('respects custom cancelLabel and showCancelButton: false',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  onPressed: () => showGlassConfirmationDialog<void>(
                    context: context,
                    title: 'Custom Cancel',
                    cancelLabel: 'Keep Editing',
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'Discard',
                        isDestructive: true,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  child: const Text('Custom'),
                ),
                CupertinoButton(
                  onPressed: () => showGlassConfirmationDialog<void>(
                    context: context,
                    title: 'No Cancel',
                    showCancelButton: false,
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'Proceed',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  child: const Text('Hidden'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);

      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hidden'));
      await tester.pumpAndSettle();
      expect(find.text('No Cancel'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets(
        'auto-dismisses on action tap without double-popping when onPressed returns a value',
        (tester) async {
      String? result;
      var homeVisible = true;

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => Center(
              child: CupertinoButton(
                onPressed: () async {
                  result = await showGlassConfirmationDialog<String>(
                    context: context,
                    title: 'Pick Format',
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'PNG',
                        onPressed: () => Navigator.of(context).pop('png'),
                      ),
                      GlassConfirmationDialogAction(
                        label: 'Keep Open',
                        dismissOnPress: false,
                        onPressed: () => result = 'kept',
                      ),
                    ],
                  );
                  homeVisible = context.mounted;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // dismissOnPress: false keeps the dialog mounted.
      await tester.tap(find.text('Keep Open'));
      await tester.pumpAndSettle();
      expect(result, 'kept');
      expect(find.text('Pick Format'), findsOneWidget);

      // Action that calls Navigator.pop(context, 'png') returns value and
      // does not double-pop the underlying page.
      await tester.tap(find.text('PNG'));
      await tester.pumpAndSettle();
      expect(result, 'png');
      expect(find.text('Pick Format'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(homeVisible, isTrue);
    });

    testWidgets(
        'disabled action ignores taps and primary action activates on Enter',
        (tester) async {
      var primaryActivated = false;

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => Center(
              child: CupertinoButton(
                onPressed: () => showGlassConfirmationDialog<void>(
                  context: context,
                  title: 'Publish?',
                  actions: [
                    const GlassConfirmationDialogAction(
                      label: 'Unavailable',
                      onPressed: null,
                    ),
                    GlassConfirmationDialogAction(
                      label: 'Publish Now',
                      isPrimary: true,
                      onPressed: () => primaryActivated = true,
                    ),
                  ],
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tapping disabled action does nothing and keeps dialog open.
      await tester.tap(find.text('Unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('Publish?'), findsOneWidget);

      // Pressing Enter activates the single enabled primary action & dismisses.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(primaryActivated, isTrue);
      expect(find.text('Publish?'), findsNothing);
    });

    testWidgets('scrolls long header while keeping actions pinned',
        (tester) async {
      final longMessage =
          List.filled(40, 'Long confirmation detail line.').join(' ');

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) => Center(
              child: CupertinoButton(
                onPressed: () => showGlassConfirmationDialog<void>(
                  context: context,
                  title: 'Terms & Archive',
                  message: longMessage,
                  actions: [
                    GlassConfirmationDialogAction(
                      label: 'Confirm',
                      onPressed: () {},
                    ),
                  ],
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('showGlassConfirmationDialog — source-anchored popover', () {
    testWidgets(
        'morphFrom renders calibrated 240 pt platter, omits Cancel by default, empties trigger while open, and restores on dismiss',
        (tester) async {
      _setPhoneViewport(tester);
      GlassMorphAnchor? capturedAnchor;
      var saved = false;

      await tester.pumpWidget(
        _harness(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 68, right: 16),
              child: GlassMorphTrigger(
                builder: (context, anchor) {
                  capturedAnchor = anchor;
                  return SizedBox(
                    width: 44,
                    height: 44,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => showGlassConfirmationDialog<void>(
                        context: context,
                        morphFrom: anchor,
                        title: 'Delete Draft?',
                        message: 'This draft cannot be recovered once deleted.',
                        actions: [
                          GlassConfirmationDialogAction(
                            label: 'Save Draft',
                            onPressed: () => saved = true,
                          ),
                          GlassConfirmationDialogAction(
                            label: 'Delete Draft',
                            isDestructive: true,
                            onPressed: () {},
                          ),
                        ],
                      ),
                      child: const Icon(CupertinoIcons.ellipsis),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(capturedAnchor, isNotNull);
      expect(capturedAnchor!.isPresenting, isFalse);

      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();

      expect(capturedAnchor!.isPresenting, isTrue);
      expect(find.text('Delete Draft?'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Delete Draft'), findsOneWidget);
      // Native iOS 26/27 omits Cancel when anchored.
      expect(find.text('Cancel'), findsNothing);

      // Anchored platter matches calibrated 240 pt width & stays inside screen.
      final platterRect = tester.getRect(find.byType(GlassAlertPlatterCard));
      expect(platterRect.width, closeTo(kGlassConfirmationPopoverWidth, 1.0));
      expect(platterRect.right, lessThanOrEqualTo(402.0 - 10.0 + 0.5));
      expect(platterRect.top, greaterThanOrEqualTo(59.0 - 0.5));

      // Tapping an action runs its callback, dismisses, and restores trigger.
      await tester.tap(find.text('Save Draft'));
      await tester.pumpAndSettle();

      expect(saved, isTrue);
      expect(find.text('Delete Draft?'), findsNothing);
      expect(capturedAnchor!.isPresenting, isFalse);
    });

    testWidgets(
        'anchored dialog allows explicit showCancelButton: true and barrier tap dismissal',
        (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(
        _harness(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 80, left: 20),
              child: GlassMorphTrigger(
                builder: (context, anchor) => CupertinoButton(
                  onPressed: () => showGlassConfirmationDialog<void>(
                    context: context,
                    morphFrom: anchor,
                    showCancelButton: true,
                    title: 'Anchored With Cancel',
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'Action',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  child: const Text('Trigger'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Anchored With Cancel'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap outside the popover (bottom-right of viewport) to dismiss.
      await tester.tapAt(const Offset(350, 750));
      await tester.pumpAndSettle();

      expect(find.text('Anchored With Cancel'), findsNothing);
    });

    testWidgets('barrierDismissible: false prevents outside tap dismissal',
        (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(
        _harness(
          child: Center(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () => showGlassConfirmationDialog<void>(
                  context: context,
                  morphFromRect: const Rect.fromLTWH(20, 100, 44, 44),
                  barrierDismissible: false,
                  title: 'Locked Dialog',
                  actions: [
                    GlassConfirmationDialogAction(
                      label: 'Acknowledge',
                      onPressed: () {},
                    ),
                  ],
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Locked Dialog'), findsOneWidget);

      // Outside tap should not dismiss.
      await tester.tapAt(const Offset(350, 750));
      await tester.pumpAndSettle();
      expect(find.text('Locked Dialog'), findsOneWidget);

      // Tapping action dismisses cleanly.
      await tester.tap(find.text('Acknowledge'));
      await tester.pumpAndSettle();
      expect(find.text('Locked Dialog'), findsNothing);
    });

    testWidgets('bottom-edge trigger flips upward and clamps inside safe area',
        (tester) async {
      _setPhoneViewport(tester);
      await tester.pumpWidget(
        _harness(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50, right: 16),
              child: GlassMorphTrigger(
                builder: (context, anchor) => CupertinoButton(
                  onPressed: () => showGlassConfirmationDialog<void>(
                    context: context,
                    morphFrom: anchor,
                    title: 'Bottom Action',
                    message: 'Should open upward inside safe area.',
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'Confirm',
                        onPressed: () {},
                      ),
                      GlassConfirmationDialogAction(
                        label: 'Delete',
                        isDestructive: true,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  child: const Text('Bottom'),
                ),
              ),
            ),
          ),
        ),
      );

      final triggerRect = tester.getRect(find.text('Bottom'));
      await tester.tap(find.text('Bottom'));
      await tester.pumpAndSettle();

      final platterRect = tester.getRect(find.byType(GlassAlertPlatterCard));
      // Opened upward (platter top is well above trigger top).
      expect(platterRect.top, lessThan(triggerRect.top));
      // Clamped above bottom safe area (874 - 34 - 10 = 830).
      expect(platterRect.bottom, lessThanOrEqualTo(874.0 - 34.0 - 10.0 + 0.5));
      expect(platterRect.right, lessThanOrEqualTo(402.0 - 10.0 + 0.5));
    });

    testWidgets(
        'restores GlassMorphTrigger anchor when route is abruptly removed',
        (tester) async {
      GlassMorphAnchor? capturedAnchor;
      late BuildContext rootContext;

      await tester.pumpWidget(
        _harness(
          child: Builder(
            builder: (context) {
              rootContext = context;
              return Center(
                child: GlassMorphTrigger(
                  builder: (ctx, anchor) {
                    capturedAnchor = anchor;
                    return CupertinoButton(
                      onPressed: () => showGlassConfirmationDialog<void>(
                        context: ctx,
                        morphFrom: anchor,
                        title: 'Abrupt Tear-down',
                        actions: [
                          GlassConfirmationDialogAction(
                            label: 'Done',
                            onPressed: () {},
                          ),
                        ],
                      ),
                      child: const Text('Open'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(capturedAnchor!.isPresenting, isTrue);

      // Abruptly replace route stack without normal closing morph.
      Navigator.of(rootContext, rootNavigator: true).pushAndRemoveUntil<void>(
        CupertinoPageRoute<void>(
          builder: (_) => const Center(child: Text('Replaced')),
        ),
        (route) => route.isFirst,
      );
      await tester.pumpAndSettle();

      expect(capturedAnchor!.isPresenting, isFalse);
    });

    testWidgets('respects Reduce Motion and ESC key dismissal', (tester) async {
      String? result;
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          child: Center(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () async {
                  result = await showGlassConfirmationDialog<String>(
                    context: context,
                    morphFromRect: const Rect.fromLTWH(160, 200, 80, 44),
                    title: 'Reduced Motion',
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'Select',
                        onPressed: () => Navigator.of(context).pop('selected'),
                      ),
                    ],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      // Frame 0 measures; frame 1 immediately shows at full settled state.
      await tester.pump();
      await tester.pump();

      expect(find.text('Reduced Motion'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();

      expect(find.text('Reduced Motion'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('exposes dialog semantics role and live brightness sync',
        (tester) async {
      final brightnessNotifier = ValueNotifier<Brightness>(Brightness.light);
      addTearDown(brightnessNotifier.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder<Brightness>(
          valueListenable: brightnessNotifier,
          builder: (context, brightness, _) => _harness(
            brightness: brightness,
            child: Center(
              child: Builder(
                builder: (ctx) => CupertinoButton(
                  onPressed: () => showGlassConfirmationDialog<void>(
                    context: ctx,
                    morphFromRect: const Rect.fromLTWH(160, 120, 44, 44),
                    title: 'Theme Sync',
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'Keep',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      final semanticsHandle = tester.ensureSemantics();
      try {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final dialogSemantics = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.role == SemanticsRole.dialog,
        );
        expect(dialogSemantics, findsOneWidget);

        final lightTitle = tester.widget<Text>(find.text('Theme Sync'));
        expect(
          lightTitle.style?.color?.toARGB32(),
          CupertinoColors.label.color.toARGB32(),
        );

        // Flip brightness to dark while dialog stays open.
        brightnessNotifier.value = Brightness.dark;
        await tester.pumpAndSettle();

        final darkTitle = tester.widget<Text>(find.text('Theme Sync'));
        expect(
          darkTitle.style?.color?.toARGB32(),
          CupertinoColors.label.darkColor.toARGB32(),
        );
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('asserts when both morphFrom and morphFromRect are passed',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          child: Center(
            child: GlassMorphTrigger(
              builder: (context, anchor) => CupertinoButton(
                onPressed: () => showGlassConfirmationDialog<void>(
                  context: context,
                  morphFrom: anchor,
                  morphFromRect: const Rect.fromLTWH(0, 0, 44, 44),
                  actions: [
                    GlassConfirmationDialogAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ],
                ),
                child: const Text('Invalid'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Invalid'));
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets(
        're-clamps horizontally and shrinks width on viewport rotation / resize',
        (tester) async {
      // Start in landscape (874×402) with trigger on the far right.
      _setPhoneViewport(
        tester,
        size: const Size(874, 402),
        padding: const EdgeInsets.only(left: 59, right: 59, bottom: 21),
      );

      await tester.pumpWidget(
        _harness(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, right: 64),
              child: GlassMorphTrigger(
                builder: (context, anchor) => CupertinoButton(
                  onPressed: () => showGlassConfirmationDialog<void>(
                    context: context,
                    morphFrom: anchor,
                    title: 'Rotate Me',
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'Keep',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final landscapeRect = tester.getRect(find.byType(GlassAlertPlatterCard));
      expect(landscapeRect.right, greaterThan(500.0));

      // Rotate to portrait (402×874) while open — popover must stay on-screen.
      tester.view.physicalSize = const Size(402, 874);
      tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
      await tester.pumpAndSettle();

      final portraitRect = tester.getRect(find.byType(GlassAlertPlatterCard));
      expect(portraitRect.right, lessThanOrEqualTo(402.0 - 10.0 + 0.5));
      expect(portraitRect.left, greaterThanOrEqualTo(10.0 - 0.5));

      // Shrink viewport narrower than 240 pt — platter width clamps cleanly.
      tester.view.physicalSize = const Size(220, 600);
      tester.view.padding = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      final narrowRect = tester.getRect(find.byType(GlassAlertPlatterCard));
      expect(narrowRect.width, closeTo(200.0, 1.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'settled anchored platter mounts zero Opacity, OverflowBox, or ImageFiltered wrappers',
        (tester) async {
      _setPhoneViewport(tester);

      await tester.pumpWidget(
        _harness(
          child: Center(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () => showGlassConfirmationDialog<void>(
                  context: context,
                  morphFromRect: const Rect.fromLTWH(160, 120, 44, 44),
                  title: 'Zero Opacity',
                  actions: [
                    GlassConfirmationDialogAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ],
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // No Opacity, OverflowBox, or enabled ImageFiltered should wrap the
      // settled card inside GlassContainer (AdaptiveGlass keeps a disabled
      // ImageFiltered(enabled: false) for state-preserving materialize).
      final platterElement = tester.element(find.byType(GlassAlertPlatterCard));
      final foundIdleMorphWrappers = <String>[];
      platterElement.visitAncestorElements((ancestor) {
        if (ancestor.widget is GlassContainer) return false;
        final w = ancestor.widget;
        if (w is Opacity ||
            w is OverflowBox ||
            (w is ImageFiltered && w.enabled)) {
          foundIdleMorphWrappers.add(w.toStringShort());
        }
        return true;
      });
      expect(foundIdleMorphWrappers, isEmpty);
    });

    testWidgets('uses localized CupertinoLocalizations cancelButtonLabel',
        (tester) async {
      await tester.pumpWidget(
        GlassTheme(
          data: const GlassThemeData.ios27(),
          child: CupertinoApp(
            localizationsDelegates: const [
              _FrenchCupertinoLocalizationsDelegate(),
            ],
            home: CupertinoPageScaffold(
              child: Center(
                child: Builder(
                  builder: (context) => CupertinoButton(
                    onPressed: () => showGlassConfirmationDialog<void>(
                      context: context,
                      title: 'Supprimer ?',
                      actions: [
                        GlassConfirmationDialogAction(
                          label: 'Supprimer',
                          isDestructive: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('dynamic barrierColor updates live across brightness switches',
        (tester) async {
      _setPhoneViewport(tester);
      final brightnessNotifier = ValueNotifier<Brightness>(Brightness.light);
      addTearDown(brightnessNotifier.dispose);

      const dynamicBarrier = CupertinoDynamicColor.withBrightness(
        color: Color(0x220000FF),
        darkColor: Color(0x66FF0000),
      );

      await tester.pumpWidget(
        ValueListenableBuilder<Brightness>(
          valueListenable: brightnessNotifier,
          builder: (context, brightness, _) => _harness(
            brightness: brightness,
            child: Center(
              child: Builder(
                builder: (ctx) => CupertinoButton(
                  onPressed: () => showGlassConfirmationDialog<void>(
                    context: ctx,
                    morphFromRect: const Rect.fromLTWH(160, 120, 44, 44),
                    barrierColor: dynamicBarrier,
                    title: 'Dynamic Barrier',
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'OK',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      ColoredBox findBarrierBox() => tester.widget<ColoredBox>(
            find.byWidgetPredicate(
              (w) =>
                  w is ColoredBox &&
                  (w.color.toARGB32() == const Color(0x220000FF).toARGB32() ||
                      w.color.toARGB32() == const Color(0x66FF0000).toARGB32()),
            ),
          );

      expect(
        findBarrierBox().color.toARGB32(),
        const Color(0x220000FF).toARGB32(),
      );

      brightnessNotifier.value = Brightness.dark;
      await tester.pumpAndSettle();

      expect(
        findBarrierBox().color.toARGB32(),
        const Color(0x66FF0000).toARGB32(),
      );
    });

    testWidgets('frame-0 pop restores GlassMorphTrigger immediately',
        (tester) async {
      _setPhoneViewport(tester);
      GlassMorphAnchor? capturedAnchor;
      late BuildContext hostContext;

      await tester.pumpWidget(
        _harness(
          child: Center(
            child: GlassMorphTrigger(
              builder: (context, anchor) {
                capturedAnchor = anchor;
                hostContext = context;
                return CupertinoButton(
                  onPressed: () => showGlassConfirmationDialog<void>(
                    context: context,
                    morphFrom: anchor,
                    title: 'Early Pop',
                    actions: [
                      GlassConfirmationDialogAction(
                        label: 'OK',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      // Pump 1 frame (starts opening) and pop immediately before morph settles.
      await tester.pump();
      Navigator.of(hostContext, rootNavigator: true).pop();
      await tester.pumpAndSettle();

      expect(capturedAnchor!.isPresenting, isFalse);
      expect(find.text('Early Pop'), findsNothing);
    });

    testWidgets('asserts when actions is empty and showCancelButton is false',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          child: Center(
            child: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () => showGlassConfirmationDialog<void>(
                  context: context,
                  morphFromRect: const Rect.fromLTWH(100, 100, 44, 44),
                  actions: const [],
                ),
                child: const Text('Empty'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Empty'));
      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}

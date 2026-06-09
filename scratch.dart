import 'package:flutter/widgets.dart';

Widget _wrapWithExtraBtnShadow(
    BuildContext context, Widget btn, ShapeBorder shape) {
  final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
  if (isDark) return btn;

  final effectiveSettings = InheritedLiquidGlass.ofOrDefault(context);
  final shadows = effectiveSettings.effectiveShadow;
  if (shadows.isEmpty) return btn;

  return Stack(
    fit: StackFit.passthrough,
    clipBehavior: Clip.none,
    children: [
      btn,
      Positioned.fill(
        child: IgnorePointer(
          child: ClipPath(
            clipBehavior: Clip.antiAlias,
            clipper: _InverseExtraBtnClipper(shape),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // we probably need borderRadius or just let BoxDecoration use shape?
                // Wait, BoxDecoration takes BoxShape.circle or borderRadius.
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

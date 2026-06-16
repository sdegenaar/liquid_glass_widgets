import re

with open('lib/widgets/surfaces/shared/bottom_bar_internal.dart', 'r') as f:
    content = f.read()

# Add import
import_str = "import '../../interactive/shared/liquid_rounded_superellipse.dart';\n"
new_import = import_str + "import '../../../src/renderer/liquid_shape.dart';\n"
content = content.replace(import_str, new_import)

# Find _buildHighQualityMode definition
old_func = """  Widget _buildHighQualityMode({
    required Alignment alignment,
    required double thickness,
    required double velocity,
    required Matrix4 jellyTransform,
    required double backgroundRadius,
    required double glassRadius,
    required Color indicatorColor,
  }) {
    return SizedBox(
      height: widget.barHeight,
      child: _wrapWithGlow(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Glass Background (Blur / Frosted Glass Layer — Cached)
            Positioned.fill(
              child: RepaintBoundary(
                child: AdaptiveGlass.grouped(
                  quality: widget.quality,
                  platformViewBackdrop: widget.platformViewBackdrop,
                  shape: _barShape,
                  child: const SizedBox.expand(),
                ),
              ),
            ),"""

new_func = """  Widget _buildHighQualityMode({
    required Alignment alignment,
    required double thickness,
    required double velocity,
    required Matrix4 jellyTransform,
    required double backgroundRadius,
    required double glassRadius,
    required Color indicatorColor,
  }) {
    // The width of the dent matches the pill width (which is expanded during drag)
    final double expansionOffset = widget.indicatorExpansion * thickness;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double tabWidth = constraints.maxWidth / widget.tabCount;
        final double dentWidth = tabWidth + expansionOffset * 2;
        final double dentDepth = 12.0 * thickness;

        final finalBarShape = LiquidShapeSymmetricDent(
          baseShape: _barShape,
          dentDepth: dentDepth,
          dentWidth: dentWidth,
          dentAlignmentX: alignment.x,
        );

        return SizedBox(
          height: widget.barHeight,
          child: _wrapWithGlow(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Glass Background (Blur / Frosted Glass Layer — Cached)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AdaptiveGlass.grouped(
                      quality: widget.quality,
                      platformViewBackdrop: widget.platformViewBackdrop,
                      shape: finalBarShape,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),"""

content = content.replace(old_func, new_func)

# Close LayoutBuilder at the end of the method
old_end = """            AnimatedGlassIndicator(
              velocity: velocity,
              itemCount: widget.tabCount,
              alignment: alignment,
              thickness: thickness,
              quality: widget.quality,
              indicatorColor: indicatorColor,
              isBackgroundIndicator: false,
              paintBackground: false,
              paintGlass: true,
              borderRadius: thickness < 1 ? backgroundRadius : glassRadius,
              padding: const EdgeInsets.all(4),
              expansion: widget.indicatorExpansion,
              settings: widget.indicatorSettings,
              backgroundKey: widget.platformViewBackdrop
                  ? _iconLayerKey
                  : widget.backgroundKey,
            ),
          ],
        ),
      ),
    );
  }"""

new_end = """            AnimatedGlassIndicator(
              velocity: velocity,
              itemCount: widget.tabCount,
              alignment: alignment,
              thickness: thickness,
              quality: widget.quality,
              indicatorColor: indicatorColor,
              isBackgroundIndicator: false,
              paintBackground: false,
              paintGlass: true,
              borderRadius: thickness < 1 ? backgroundRadius : glassRadius,
              padding: const EdgeInsets.all(4),
              expansion: widget.indicatorExpansion,
              settings: widget.indicatorSettings,
              backgroundKey: widget.platformViewBackdrop
                  ? _iconLayerKey
                  : widget.backgroundKey,
            ),
          ],
        ),
      ),
    );
      },
    );
  }"""

content = content.replace(old_end, new_end)

with open('lib/widgets/surfaces/shared/bottom_bar_internal.dart', 'w') as f:
    f.write(content)

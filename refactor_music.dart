import 'dart:io';

void main() {
  final file = File('/Users/sebastiand/IdeaProjects/liquid_glass_widgets/example/lib/apple_music/apple_music_demo.dart');
  var content = file.readAsStringSync();

  // 1. Update Constants
  content = content.replaceFirst('const _kBackground = Color(0xFF000000);', 
      'const _kBackground = CupertinoDynamicColor.withBrightness(color: Color(0xFFF2F2F7), darkColor: Color(0xFF000000));');
  content = content.replaceFirst('const _kCardGray = Color(0xFF2C2C2E);', 
      'const _kCardGray = CupertinoDynamicColor.withBrightness(color: Color(0xFFFFFFFF), darkColor: Color(0xFF2C2C2E));');

  // 2. Replace Text/Icon Colors with CupertinoColors
  content = content.replaceAll('Colors.white', 'CupertinoColors.label');
  // Handle withValues which might be used on label
  // Actually, CupertinoColors.secondaryLabel is better for alpha: 0.55
  content = content.replaceAll('CupertinoColors.label.withValues(alpha: 0.55)', 'CupertinoColors.secondaryLabel');
  content = content.replaceAll('CupertinoColors.label.withValues(alpha: 0.5)', 'CupertinoColors.secondaryLabel');
  content = content.replaceAll('CupertinoColors.label.withValues(alpha: 0.45)', 'CupertinoColors.secondaryLabel');
  content = content.replaceAll('CupertinoColors.label.withValues(alpha: 0.35)', 'CupertinoColors.tertiaryLabel');
  
  content = content.replaceAll('Colors.black', 'CupertinoColors.label'); // For Light mode? Apple Music text is white in dark mode.
  // Wait! Apple Music uses Colors.black for the "No Recent Searches" background!
  content = content.replaceAll('color: Colors.black', 'color: _kBackground.resolveFrom(context)');
  
  // 3. Resolve _kBackground in GlassScaffold, Container, ColoredBox, BoxDecoration
  content = content.replaceAll('color: _kBackground', 'color: _kBackground.resolveFrom(context)');
  content = content.replaceAll('ColoredBox(color: _kBackground)', 'ColoredBox(color: _kBackground.resolveFrom(context))');
  content = content.replaceAll('color: _kCardGray', 'color: _kCardGray.resolveFrom(context)');
  
  // 4. Update LiquidGlassSettings (not const anymore)
  content = content.replaceFirst(
'''const _kPillGlass = LiquidGlassSettings(
  glassColor: Color(0xCC1C1C1E),''',
'''LiquidGlassSettings _kPillGlass(BuildContext context) => LiquidGlassSettings(
  glassColor: CupertinoTheme.of(context).brightness == Brightness.dark ? const Color(0xCC1C1C1E) : const Color(0xCCF2F2F7),'''
  );
  content = content.replaceAll('settings: _kPillGlass,', 'settings: _kPillGlass(context),');

  // _barGlassSettings
  content = content.replaceAll('glassColor: const Color(0xAA1C1C1E),', 
    'glassColor: CupertinoTheme.of(context).brightness == Brightness.dark ? const Color(0xAA1C1C1E) : const Color(0xAAF2F2F7),');

  // 5. Remove const from widgets that now use resolveFrom(context)
  // We'll do this carefully. If a line has resolveFrom(context), we strip `const`.
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains('.resolveFrom(context)') || lines[i].contains('_kPillGlass(context)')) {
      lines[i] = lines[i].replaceAll('const ', '');
      lines[i] = lines[i].replaceAll(' const', '');
    }
  }
  
  file.writeAsStringSync(lines.join('\n'));
}

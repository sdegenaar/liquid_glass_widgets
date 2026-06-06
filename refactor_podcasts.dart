import 'dart:io';

void main() {
  final file = File('/Users/sebastiand/IdeaProjects/liquid_glass_widgets/example/lib/apple_podcasts/apple_podcasts_demo.dart');
  var content = file.readAsStringSync();

  // 1. Constants
  content = content.replaceFirst('const _kBackground = Color(0xFF000000);', 
      'const _kBackground = CupertinoDynamicColor.withBrightness(color: Color(0xFFF2F2F7), darkColor: Color(0xFF000000));');

  // 2. Text colors
  content = content.replaceAll('Colors.white.withValues(alpha: 0.8)', 'CupertinoColors.label');
  content = content.replaceAll('Colors.white.withValues(alpha: 0.7)', 'CupertinoColors.secondaryLabel');
  content = content.replaceAll('Colors.white.withValues(alpha: 0.5)', 'CupertinoColors.secondaryLabel');
  content = content.replaceAll('Colors.white.withValues(alpha: 0.2)', 'CupertinoColors.tertiaryLabel');
  content = content.replaceAll('Colors.white.withValues(alpha: 0.1)', 'CupertinoColors.tertiaryLabel');
  content = content.replaceAll('Colors.white.withValues(alpha: 1)', 'CupertinoColors.label');
  content = content.replaceAll('Colors.white54', 'CupertinoColors.secondaryLabel');
  content = content.replaceAll('Colors.white38', 'CupertinoColors.tertiaryLabel');
  content = content.replaceAll('Colors.white24', 'CupertinoColors.tertiaryLabel');
  content = content.replaceAll('Colors.white12', 'CupertinoColors.tertiaryLabel');
  content = content.replaceAll('Colors.white', 'CupertinoColors.label');

  // Black used for "No Recent Searches" background etc
  content = content.replaceAll('color: Colors.black', 'color: _kBackground.resolveFrom(context)');

  // 3. Resolve _kBackground in GlassScaffold, Container, ColoredBox
  content = content.replaceAll('color: _kBackground', 'color: _kBackground.resolveFrom(context)');
  content = content.replaceAll('ColoredBox(color: _kBackground)', 'ColoredBox(color: _kBackground.resolveFrom(context))');

  // 4. Remove const from widgets that now use resolveFrom(context) or CupertinoColors where needed
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains('CupertinoColors.tertiaryLabel') || 
        lines[i].contains('CupertinoColors.secondaryLabel') || 
        lines[i].contains('CupertinoColors.label') ||
        lines[i].contains('_kBackground.resolveFrom(context)')) {
      lines[i] = lines[i].replaceAll('const ', '');
      lines[i] = lines[i].replaceAll(' const ', ' ');
      // Handle trailing consts
      if (lines[i].endsWith(' const')) {
        lines[i] = lines[i].substring(0, lines[i].length - 6);
      }
    }
  }
  
  file.writeAsStringSync(lines.join('\n'));
}

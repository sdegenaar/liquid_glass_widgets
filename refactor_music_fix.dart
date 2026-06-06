import 'dart:io';

void main() {
  final file = File('/Users/sebastiand/IdeaProjects/liquid_glass_widgets/example/lib/apple_music/apple_music_demo.dart');
  var content = file.readAsStringSync();

  // Fix the bad replacements from previous run
  content = content.replaceAll('CupertinoColors.label38', 'CupertinoColors.tertiaryLabel');
  content = content.replaceAll('CupertinoColors.label70', 'CupertinoColors.secondaryLabel');
  content = content.replaceAll('CupertinoColors.label60', 'CupertinoColors.secondaryLabel');
  
  // Also strip const from lines that have CupertinoColors or _kBackground.resolveFrom
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].contains('CupertinoColors.tertiaryLabel') || 
        lines[i].contains('CupertinoColors.secondaryLabel') || 
        lines[i].contains('CupertinoColors.label') ||
        lines[i].contains('_kBackground.resolveFrom(context)') ||
        lines[i].contains('_kCardGray.resolveFrom(context)')) {
      lines[i] = lines[i].replaceAll('const ', '');
      lines[i] = lines[i].replaceAll(' const', '');
    }
  }
  
  file.writeAsStringSync(lines.join('\n'));
}

import 'dart:io';

void main() {
  final dir = Directory('example/lib/pages');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    var content = file.readAsStringSync();

    // Fix replacing regex
    content = content.replaceAllMapped(RegExp(r'const\s+(Text|TextStyle|Icon|SizedBox|Column|Row|Padding|Center|Expanded|GlassCard|GlassAppBar|_SectionHeader|Flexible|Align)\s*\('), (m) => '${m.group(1)}(');

    // Replace Colors.white with dynamic label
    content = content.replaceAll('color: Colors.white,', 'color: CupertinoColors.label.resolveFrom(context),');
    content = content.replaceAll('color: Colors.white)', 'color: CupertinoColors.label.resolveFrom(context))');
    
    // Replace Colors.white.withValues(...) with secondaryLabel or just keep withValues
    content = content.replaceAllMapped(RegExp(r'Colors\.white\.withValues\(([^)]+)\)'), (m) => 'CupertinoColors.label.resolveFrom(context).withValues(${m.group(1)})');
    
    // Replace other specific hardcoded whites if any
    content = content.replaceAll('Colors.white70', 'CupertinoColors.secondaryLabel.resolveFrom(context)');
    content = content.replaceAll('Colors.white60', 'CupertinoColors.tertiaryLabel.resolveFrom(context)');
    
    // Also remove const from arrays since they might contain these
    content = content.replaceAllMapped(RegExp(r'const\s+\[([^\]]+)\]'), (m) => '[${m.group(1)}]');

    file.writeAsStringSync(content);
  }
}

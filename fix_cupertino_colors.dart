import 'dart:io';

void fixFile(String path) {
  var file = File(path);
  var content = file.readAsStringSync();

  // 1. Remove const from TextStyle if it contains CupertinoColors
  content = content.replaceAllMapped(RegExp(r'const\s+TextStyle\s*\('), (match) {
    return 'TextStyle(';
  });

  // 2. Remove const from Text if it contains CupertinoColors
  content = content.replaceAllMapped(RegExp(r'const\s+Text\s*\('), (match) {
    return 'Text(';
  });

  // 3. Remove const from Icon if it contains CupertinoColors
  content = content.replaceAllMapped(RegExp(r'const\s+Icon\s*\('), (match) {
    return 'Icon(';
  });

  // 4. Remove const from Row if it contains CupertinoColors
  content = content.replaceAllMapped(RegExp(r'const\s+Row\s*\('), (match) {
    return 'Row(';
  });

  // 5. Add resolveFrom(context) to CupertinoColors
  content = content.replaceAllMapped(
      RegExp(r'CupertinoColors\.(label|secondaryLabel|tertiaryLabel|systemFill|white|black)(?!\.resolveFrom)'), (match) {
    return 'CupertinoColors.${match.group(1)}.resolveFrom(context)';
  });

  file.writeAsStringSync(content);
}

void main() {
  fixFile('example/lib/apple_news/apple_news_demo.dart');
  fixFile('example/lib/apple_music/apple_music_demo.dart');
  fixFile('example/lib/apple_podcasts/apple_podcasts_demo.dart');
  fixFile('example/lib/apple_messages/apple_messages_demo.dart');
}

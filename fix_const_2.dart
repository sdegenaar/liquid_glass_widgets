import 'dart:io';

void stripConst(String file, int lineNum) {
  var lines = File(file).readAsLinesSync();
  // Search upwards for the nearest "const " and remove it.
  for (int i = lineNum - 1; i >= 0 && i >= lineNum - 15; i--) {
    if (lines[i].contains('const ')) {
      lines[i] = lines[i].replaceFirst('const ', '');
      break;
    }
  }
  File(file).writeAsStringSync(lines.join('\n'));
}

void main() {
  stripConst('example/lib/pages/containers_page.dart', 51);
  stripConst('example/lib/pages/feedback_page.dart', 87);
  stripConst('example/lib/pages/input_page.dart', 70);
  stripConst('example/lib/pages/input_page.dart', 276);
  stripConst('example/lib/pages/inputs_page.dart', 57);
  stripConst('example/lib/pages/interactive_page.dart', 74);
  stripConst('example/lib/pages/overlays_page.dart', 298);
  stripConst('example/lib/pages/surfaces_page.dart', 49);
}

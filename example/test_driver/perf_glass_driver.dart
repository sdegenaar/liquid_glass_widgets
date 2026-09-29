// Driver for integration_test/perf_glass_test.dart: writes the per-scene
// timeline summaries the test collected to build/glass-perf/.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    timeout: const Duration(minutes: 45),
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      if (data == null) return;
      final directory = Directory('build/glass-perf');
      await directory.create(recursive: true);
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      await File('${directory.path}/summary-$stamp.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    },
  );
}

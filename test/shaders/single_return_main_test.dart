// Guards Windows Direct3D / Chrome ANGLE (HLSL FXC) compatibility in shaders/.
//
// On Windows D3D11 and Web (`flutter build web --wasm` via ANGLE), fragment
// shaders that mix `sampler2D` texture sampling with early/multiple `return;`
// statements inside `void main()` trigger Flutter 3.50+ `impellerc` warnings
// and can fail `d3dcompiler_47.dll` (FXC) compilation (flutter/flutter#190809).
//
// `glslangValidator --target-env vulkan1.0` permits early `OpReturn` in SPIR-V,
// so this source-level test enforces a single exit point in `void main()` on
// every CI platform during `flutter test`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _stripCommentsAndPreprocessor(String source) {
  final withoutBlock = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  final buffer = StringBuffer();
  for (final line in withoutBlock.split('\n')) {
    final commentIdx = line.indexOf('//');
    final stripped = commentIdx >= 0 ? line.substring(0, commentIdx) : line;
    if (stripped.trimLeft().startsWith('#')) continue;
    buffer.writeln(stripped);
  }
  return buffer.toString();
}

String _extractMainBody(String cleanSource, String path) {
  final match = RegExp(r'\bvoid\s+main\s*\(\s*(?:void)?\s*\)')
      .firstMatch(cleanSource);
  expect(match, isNotNull, reason: 'Missing void main() in $path');
  final openBrace = cleanSource.indexOf('{', match!.end);
  expect(
    openBrace,
    isNonNegative,
    reason: 'Missing opening { for main() in $path',
  );

  var depth = 0;
  for (var i = openBrace; i < cleanSource.length; i++) {
    if (cleanSource[i] == '{') depth++;
    if (cleanSource[i] == '}' && --depth == 0) {
      return cleanSource.substring(openBrace + 1, i);
    }
  }
  fail('Unbalanced braces in main() of $path');
}

void main() {
  group('Windows HLSL/FXC single-exit main() contract (flutter#190809)', () {
    final shaderDir = Directory('shaders');

    test(
      'no .frag shader has early or multiple return statements in main()',
      () {
        final fragFiles =
            shaderDir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.frag'))
                .toList()
              ..sort((a, b) => a.path.compareTo(b.path));

        expect(fragFiles, isNotEmpty);

        final offenders = <String>[];
        final trailingReturn = RegExp(r'\breturn\s*;\s*$');
        final anyReturn = RegExp(r'\breturn\b');

        for (final file in fragFiles) {
          final path = file.path.replaceAll(r'\', '/');
          final clean = _stripCommentsAndPreprocessor(file.readAsStringSync());
          final bodyWithoutTrailingReturn = _extractMainBody(
            clean,
            path,
          ).replaceFirst(trailingReturn, '');

          if (anyReturn.hasMatch(bodyWithoutTrailingReturn)) {
            offenders.add(path);
          }
        }

        expect(
          offenders,
          isEmpty,
          reason:
              'Early/multiple `return;` statements in `void main()` can fail '
              'HLSL/FXC shader compilation on Windows & Web (flutter/flutter#190809). '
              'Use structured `if / else` control flow instead in:\n'
              '${offenders.join('\n')}',
        );
      },
    );
  });
}

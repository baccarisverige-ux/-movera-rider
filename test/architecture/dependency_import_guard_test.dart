import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _dartFiles(String root) sync* {
  final dir = Directory(root);
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

void main() {
  test('removed duplicate panel package has no Dart imports', () {
    final files = <File>[
      ..._dartFiles('lib'),
      ..._dartFiles('test'),
      ..._dartFiles('integration_test'),
    ];
    final source = files.map((file) => file.readAsStringSync()).join('\n');

    expect(
      source,
      isNot(contains('package:flutter_sliding_up_panel/')),
    );
  });

  test('certified sheet dependencies remain in active source', () {
    final source = _dartFiles('lib')
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(source, contains('package:sliding_up_panel/'));
    expect(source, contains('package:smooth_sheets/'));
  });
}

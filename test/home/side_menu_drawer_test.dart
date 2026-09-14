import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('side menu closes drawer before pushing routes', () {
    final menu = File(
      'lib/features/home/presentation/side_menu.dart',
    ).readAsStringSync();
    expect(menu.contains('final nav = Navigator.of(context);'), isTrue);
    expect(menu.contains('Scaffold.of(context).closeDrawer();'), isTrue);
    expect(menu.contains('nav.push('), isTrue);
    expect(menu.contains('Navigator.push('), isFalse);
    final closeAt = menu.indexOf('Scaffold.of(context).closeDrawer();');
    final pushAt = menu.indexOf('nav.push(');
    expect(closeAt, greaterThan(0));
    expect(pushAt, greaterThan(closeAt));
  });
}

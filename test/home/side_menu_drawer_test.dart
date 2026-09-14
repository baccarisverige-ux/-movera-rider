import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'side menu closes drawer before pushing routes and reopens it after the pushed page is popped',
    () {
      final menu = File(
        'lib/features/home/presentation/side_menu.dart',
      ).readAsStringSync();
      expect(menu.contains('final nav = Navigator.of(context);'), isTrue);
      expect(menu.contains('final scaffold = Scaffold.of(context);'), isTrue);
      expect(menu.contains('scaffold.closeDrawer();'), isTrue);
      expect(menu.contains('await nav.push('), isTrue);
      expect(menu.contains('scaffold.openDrawer();'), isTrue);
      expect(menu.contains('Navigator.push('), isFalse);
      final closeAt = menu.indexOf('scaffold.closeDrawer();');
      final pushAt = menu.indexOf('await nav.push(');
      final openAt = menu.indexOf('scaffold.openDrawer();');
      expect(closeAt, greaterThan(0));
      expect(pushAt, greaterThan(closeAt));
      expect(openAt, greaterThan(pushAt));
    },
  );
}

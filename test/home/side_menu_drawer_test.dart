import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'side menu closes drawer before pushing routes and stays closed after back',
    () {
      final menu = File(
        'lib/features/home/presentation/side_menu.dart',
      ).readAsStringSync();
      expect(menu.contains('final nav = Navigator.of(context);'), isTrue);
      expect(menu.contains('final scaffold = Scaffold.of(context);'), isTrue);
      expect(menu.contains('scaffold.closeDrawer();'), isTrue);
      expect(menu.contains('scaffold.isDrawerOpen'), isTrue);
      expect(menu.contains('await WidgetsBinding.instance.endOfFrame;'), isTrue);
      expect(menu.contains('if (!nav.mounted) return;'), isTrue);
      expect(menu.contains('await nav.push('), isTrue);
      expect(menu.contains('openDrawer()'), isFalse);
      expect(menu.contains('Navigator.push('), isFalse);
      final closeAt = menu.indexOf('scaffold.closeDrawer();');
      final settledAt = menu.indexOf('scaffold.isDrawerOpen');
      final pushAt = menu.indexOf('await nav.push(');
      expect(closeAt, greaterThan(0));
      expect(settledAt, greaterThan(closeAt));
      expect(pushAt, greaterThan(settledAt));
    },
  );
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every screen a rider is meant to use needs a way in, and every control they
/// can tap needs to do something. Both classes of fault shipped: Notifications
/// and Saved Places were finished screens nothing ever opened, and three
/// buttons had empty handlers.
void main() {
  Iterable<File> presentation() => Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && f.path.contains('/presentation/'));

  test('no control is left with an empty handler', () {
    final dead = <String>[];
    final empty = RegExp(r'on(Pressed|Tap): \(\) \{\}');
    for (final file in presentation()) {
      if (empty.hasMatch(file.readAsStringSync())) dead.add(file.path);
    }
    expect(
      dead,
      isEmpty,
      reason: 'these render a tappable control that does nothing: $dead',
    );
  });

  test('Notifications, Messages and Saved Places are reachable', () {
    final menu = File(
      'lib/features/home/presentation/side_menu.dart',
    ).readAsStringSync();

    expect(menu.contains('NotificationScreen('), isTrue);
    expect(menu.contains('MessagesInbox('), isTrue);
    expect(menu.contains('SavedPlaces('), isTrue);
    expect(menu.contains("title: 'Notifications'"), isTrue);
    expect(menu.contains("title: 'Messages'"), isTrue);
    expect(menu.contains("title: 'Saved Places'"), isTrue);
  });

  test('every screen the side menu opens exists', () {
    final menu = File(
      'lib/features/home/presentation/side_menu.dart',
    ).readAsStringSync();
    for (final screen in const [
      'WalletHome',
      'RideHistory',
      'WalletScreen',
      'SafetyHub',
      'SupportHome',
      'ReferAndEarn',
      'NotificationScreen',
      'MessagesInbox',
      'SavedPlaces',
    ]) {
      expect(menu.contains('$screen('), isTrue, reason: screen);
    }
  });
}

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

  test('no rendered control is left with an empty handler', () {
    final dead = <String>[];
    final empty = RegExp(
      r'on(Pressed|Tap|LongPress|DoubleTap|Submitted)\\s*:\\s*'
      r'\\([^)]*\\)\\s*(?:async\\s*)?\\{\\s*\\}',
      multiLine: true,
    );

    for (final file in presentation()) {
      final source = file.readAsStringSync();
      for (final match in empty.allMatches(source)) {
        final handler = match.group(0) ?? '';
        final intentionalHomeMapNoop =
            file.path.endsWith('features/home/presentation/home.dart') &&
            handler.contains('onTap: (LatLng position) {}');
        if (!intentionalHomeMapNoop) {
          dead.add(file.path);
        }
      }
    }

    expect(
      dead,
      isEmpty,
      reason: 'these render a tappable/input control that does nothing: $dead',
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

  test('side-menu entries expose stable semantic button labels', () {
    final menu = File(
      'lib/features/home/presentation/side_menu.dart',
    ).readAsStringSync();

    expect(menu.contains('Semantics('), isTrue);
    expect(menu.contains('button: true'), isTrue);
    expect(menu.contains('label: title'), isTrue);
  });


  test('production navigation exposes no stale account or driver placeholders', () {
    final menu = File(
      'lib/features/home/presentation/side_menu.dart',
    ).readAsStringSync();
    final profile = File(
      'lib/features/profile/presentation/profile.dart',
    ).readAsStringSync();
    final account = File(
      'lib/features/profile/presentation/account_home.dart',
    ).readAsStringSync();

    expect(menu.contains('Become a driver'), isFalse);
    expect(menu.contains('_becomeDriverCard'), isFalse);
    expect(menu.contains('openDrawer()'), isFalse);

    expect(profile.contains('Demo account stays signed in.'), isFalse);
    expect(profile.contains('AppAssets.camera'), isFalse);
    expect(profile.contains("title: 'Log out'"), isFalse);

    expect(account.contains("child: Text(\n                'Log out'"), isFalse);
    expect(account.contains('Navigator.popUntil(context, (route) => route.isFirst)'), isFalse);
    expect(account.contains('Your Movera profile and account settings.'), isTrue);
  });

  test('public Safety bridge is navigation-only and QA mutations stay gated', () {
    final bootstrap = File('lib/app/bootstrap.dart').readAsStringSync();
    final hooks =
        File('lib/core/debug/web_qa_hooks_web.dart').readAsStringSync();

    expect(bootstrap.contains('installSafetyNavigationBridge(()'), isTrue);
    expect(
      bootstrap.indexOf('installSafetyNavigationBridge(()'),
      lessThan(bootstrap.indexOf('if (moveraQaHooksEnabled)')),
    );
    expect(bootstrap.contains('registerWebQaHooks();'), isTrue);
    expect(hooks.contains('void installSafetyNavigationBridge'), isTrue);
    expect(hooks.contains("'moveraOpenSafety'.toJS"), isTrue);
    expect(hooks.contains('void installMatchingQaHooks'), isTrue);
    expect(hooks.contains('if (!moveraQaHooksEnabled) return;'), isTrue);
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

  test('screen changes are not sequenced by fixed arbitrary delays', () {
    final offenders = <String>[];

    for (final file in presentation()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        if (!lines[i].contains('Future<void>.delayed') &&
            !lines[i].contains('Future.delayed')) {
          continue;
        }

        final end = (i + 16).clamp(0, lines.length);
        final window = lines.sublist(i, end).join('\n');
        if (window.contains('Navigator.push') ||
            window.contains('Navigator.of(context).push')) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'navigation must wait for route/frame lifecycle, not a guessed millisecond delay: $offenders',
    );
  });

}

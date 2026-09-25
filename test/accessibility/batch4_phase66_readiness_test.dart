import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production declares an explicit portrait orientation policy', () {
    final source = File('lib/app/bootstrap.dart').readAsStringSync();
    expect(source, contains('SystemChrome.setPreferredOrientations'));
    expect(source, contains('DeviceOrientation.portraitUp'));
    expect(source, contains('DeviceOrientation.portraitDown'));
  });

  test('localization generation and EN FR AR resources are configured', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final app = File('lib/app/app.dart').readAsStringSync();
    expect(pubspec, contains('flutter_localizations:'));
    expect(pubspec, contains('generate: true'));
    expect(File('lib/l10n/app_en.arb').existsSync(), isTrue);
    expect(File('lib/l10n/app_fr.arb').existsSync(), isTrue);
    expect(File('lib/l10n/app_ar.arb').existsSync(), isTrue);
    expect(app, contains('AppLocalizations.localizationsDelegates'));
    expect(app, contains('AppLocalizations.supportedLocales'));
  });
}

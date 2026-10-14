import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/feature_flags/feature_flags.dart';
import 'package:movera_rider/features/wallet/data/wallet_repository.dart';
import 'package:movera_rider/features/wallet/presentation/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('FLOW-11: the Business toggle is hidden while it does nothing', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WalletScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Business'), findsNothing);
    expect(find.text('Personal'), findsNothing);
  });

  testWidgets('FLOW-11: the toggle returns once Business is switched on', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WalletScreen(flags: FeatureFlags(enableBusinessProfile: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Business'), findsOneWidget);
  });

  testWidgets('FLOW-17: Payments shows the wallet after a top-up elsewhere', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WalletAndPaymentsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Payments'));
    await tester.pumpAndSettle();
    expect(find.text('Movera Wallet'), findsNothing);

    // A top-up lands while the Payments tab is already built.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Wallet'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(WalletStore.balanceKey, 150);
    });
    await tester.tap(find.widgetWithText(OutlinedButton, 'Payments'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Movera Wallet'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/wallet/application/wallet_controller.dart';
import 'package:movera_rider/features/wallet/presentation/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('cancelling add-card sheet leaves no partial payment state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WalletScreen()));
    await tester.pumpAndSettle();

    final addPayment = find.text('Add payment method');
    await tester.ensureVisible(addPayment);
    await tester.tap(addPayment);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Debit or credit card'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));
    await tester.enterText(fields.at(0), '4242424242424242');
    await tester.enterText(fields.at(1), 'Test Rider');
    await tester.enterText(fields.at(2), '12/30');
    await tester.enterText(fields.at(3), '123');
    await tester.pump();

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    final saved = await WalletController().loadPayments();
    expect(saved.defaultMethod, 'apple');
    expect(saved.extraMethods, isEmpty);
    expect(find.text('Card ending 4242'), findsNothing);
  });
}

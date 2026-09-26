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

  testWidgets('unavailable payment methods never collect credentials or save a method', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WalletScreen()));
    await tester.pumpAndSettle();

    final addPayment = find.text('Add payment method');
    await tester.ensureVisible(addPayment);
    await tester.tap(addPayment);
    await tester.pumpAndSettle();

    expect(find.text('Unavailable until secure card setup is connected'), findsOneWidget);
    expect(find.text('Unavailable until PayPal authorization is connected'), findsOneWidget);
    expect(find.text('Unavailable until Klarna authorization is connected'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('PayPal'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    final saved = await WalletController().loadPayments();
    expect(saved.defaultMethod, 'apple');
    expect(saved.extraMethods, isEmpty);
    expect(find.text('Connected'), findsNothing);
  });
}

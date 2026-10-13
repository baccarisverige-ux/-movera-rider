import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/payments/presentation/add_card_page.dart';
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

  testWidgets(
    'Add payment method opens Add card, which never collects card details',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: WalletScreen()));
      await tester.pumpAndSettle();

      // PayPal, Klarna and Swish as its own method are gone (owner request).
      expect(find.text('PayPal'), findsNothing);
      expect(find.text('Klarna'), findsNothing);
      expect(find.text('Swish'), findsNothing);
      expect(find.text('Pay in car'), findsOneWidget);

      final addPayment = find.text('Add payment method');
      await tester.ensureVisible(addPayment);
      await tester.tap(addPayment);
      await tester.pumpAndSettle();

      expect(find.byType(AddCardPage), findsOneWidget);
      expect(find.text(AddCardPage.unavailableNote), findsOneWidget);
      // No card number field until the secure payment partner is connected.
      expect(find.byType(TextField), findsNothing);
      final save = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(save.onPressed, isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      final saved = await WalletController().loadPayments();
      expect(saved.defaultMethod, 'cash');
      expect(saved.extraMethods, isEmpty);
    },
  );
}

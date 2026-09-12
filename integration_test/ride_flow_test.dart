import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movera_rider/app/app.dart';
import 'package:movera_rider/features/ride_booking/presentation/ride_restore_gate.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boot shows restore gate then material app', (tester) async {
    await tester.pumpWidget(const MoveraApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(RideRestoreGate), findsOneWidget);
  });
}

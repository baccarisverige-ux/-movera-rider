import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movera_rider/app/app.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launch shows rider home', (tester) async {
    await tester.pumpWidget(const MoveraApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

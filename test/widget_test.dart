import 'package:flutter_test/flutter_test.dart';
import 'package:riding_app/main.dart';

void main() {
  testWidgets('rider app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const MoveraRiderApp());
    await tester.pump();
    expect(find.byType(MoveraRiderApp), findsOneWidget);
  });
}

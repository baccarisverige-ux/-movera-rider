import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/main.dart';

void main() {
  testWidgets('rider app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const MoveraRiderApp());
    await tester.pump();
    expect(find.byType(MoveraRiderApp), findsOneWidget);
  });
}

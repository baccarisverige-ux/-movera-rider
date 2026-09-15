import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/support/application/support_controller.dart';
import 'package:movera_rider/features/support/data/support_repository.dart';
import 'package:movera_rider/features/support/presentation/support.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('support repository contains no seeded rides or live-agent claim', () {
    final repository = SupportRepository();
    final controller = SupportController(store: repository);
    final script = controller.chat();

    expect(controller.rides(), isEmpty);
    expect(script.welcome, contains('isn’t connected'));
    expect(script.issueAck, contains('can’t be sent'));
    expect(script.followUp, contains('is connected'));
    expect(script.welcome, isNot(contains('Mira')));
    expect(script.followUp, isNot(contains('agent will take it')));
  });

  testWidgets('Support home shows an honest empty ride state', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SupportHome()));
    await tester.pumpAndSettle();

    expect(find.text('Help'), findsOneWidget);
    expect(find.text('No rides to review'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(
      find.text('Completed or cancelled rides will appear here when real ride history is available.'),
      findsOneWidget,
    );
    expect(find.text('Browse all help topics'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Support messaging'), 180);
    expect(find.text('Support messaging'), findsOneWidget);

    expect(find.textContaining('Arlanda'), findsNothing);
    expect(find.textContaining('Södertälje'), findsNothing);
    expect(find.textContaining('Stureplan'), findsNothing);
    expect(find.textContaining('SEK 612'), findsNothing);
  });

  testWidgets('Support messages contain no fabricated active or closed cases', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SupportMessages()));
    await tester.pumpAndSettle();

    expect(find.text('No active cases'), findsOneWidget);
    expect(
      find.text('Support messaging is not connected in this build, so no active conversations are shown.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('No closed cases'), 160);
    expect(find.text('No closed cases'), findsOneWidget);
    expect(
      find.text('Closed support conversations will appear here when real support messaging is connected.'),
      findsOneWidget,
    );
    expect(find.text('I was charged for cancellation'), findsNothing);
    expect(find.text('I want to cancel my delayed order'), findsNothing);
    expect(find.text('29 October 2024'), findsNothing);
  });

  testWidgets('Support chat is explicit that messaging is unavailable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SupportChat()));
    await tester.pumpAndSettle();

    expect(find.textContaining('isn’t connected'), findsOneWidget);
    expect(find.text('Support messaging unavailable'), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(find.textContaining('agent will take it'), findsNothing);
  });
}

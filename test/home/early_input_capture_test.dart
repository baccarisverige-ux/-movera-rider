import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/shared/widgets/early_input_capture.dart';

void main() {
  late EarlyInputCapture capture;
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    capture = EarlyInputCapture();
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    capture.stop();
    controller.dispose();
    focusNode.dispose();
  });

  Future<void> type(String text) async {
    for (final character in text.split('')) {
      final key = character == ' '
          ? LogicalKeyboardKey.space
          : LogicalKeyboardKey(character.toLowerCase().codeUnitAt(0));
      await simulateKeyDownEvent(key, character: character);
      await simulateKeyUpEvent(key);
    }
  }

  testWidgets('keys typed before the field exists are not lost', (
    tester,
  ) async {
    capture.start();
    await type('Cen');
    // The field only appears once the sheet has opened.
    capture.attach(controller, focusNode);

    expect(controller.text, 'Cen');
    expect(controller.selection.baseOffset, 3);
  });

  testWidgets('keys typed after attach but before focus still land', (
    tester,
  ) async {
    capture.start();
    capture.attach(controller, focusNode);
    await type('Ce');

    expect(controller.text, 'Ce');
  });

  testWidgets('buffered text keeps its order across attach', (tester) async {
    capture.start();
    await type('Ce');
    capture.attach(controller, focusNode);
    await type('nt');

    expect(controller.text, 'Cent');
  });

  testWidgets('backspace deletes buffered text', (tester) async {
    capture.start();
    await type('Cex');
    await simulateKeyDownEvent(LogicalKeyboardKey.backspace);
    await simulateKeyUpEvent(LogicalKeyboardKey.backspace);
    capture.attach(controller, focusNode);

    expect(controller.text, 'Ce');
  });

  testWidgets('onChanged reports what the capture applied', (tester) async {
    final seen = <String>[];
    capture.onChanged = seen.add;
    capture.start();
    capture.attach(controller, focusNode);
    await type('Ce');

    expect(seen, ['C', 'Ce']);
  });

  testWidgets('capture stays out of the way once the field has focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller, focusNode: focusNode),
        ),
      ),
    );
    capture.start();
    capture.attach(controller, focusNode);
    focusNode.requestFocus();
    await tester.pump();

    await type('Z');
    // The field owns input now; the capture must not also append.
    expect(controller.text, isEmpty);
  });

  testWidgets('stop releases the keyboard handler', (tester) async {
    capture.start();
    capture.attach(controller, focusNode);
    capture.stop();
    await type('Z');

    expect(controller.text, isEmpty);
  });
}

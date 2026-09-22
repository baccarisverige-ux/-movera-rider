import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/messages/application/messages_controller.dart';
import 'package:movera_rider/features/messages/domain/messages.dart';

void main() {
  test('consecutive local sends are always Rider-authored', () {
    final times = <DateTime>[
      DateTime(2026, 9, 22, 9, 7),
      DateTime(2026, 9, 22, 9, 8),
    ];
    var index = 0;
    final controller = MessagesController(
      now: () => times[index++],
    );

    expect(controller.send('First'), isTrue);
    expect(controller.send('Second'), isTrue);

    expect(controller.messages, hasLength(2));
    expect(controller.messages.every((message) => message.fromRider), isTrue);
    expect(controller.messages[0].sentAt, times[0]);
    expect(controller.messages[1].sentAt, times[1]);
  });

  test('sending a Rider message never fabricates a Driver reply', () {
    final controller = MessagesController(
      now: () => DateTime(2026, 9, 22, 9, 7),
    );

    controller.send('Are you close?');

    expect(controller.messages, hasLength(1));
    expect(controller.messages.single.text, 'Are you close?');
    expect(controller.messages.single.fromRider, isTrue);
  });

  test('authoritative driver/system messages can be ingested without fabrication', () {
    final controller = MessagesController(
      now: () => DateTime(2026, 9, 22, 9, 9),
    );

    controller.receive(
      ChatMessage(
        text: 'I am outside',
        sender: ChatMessageSender.driver,
        sentAt: DateTime(2026, 9, 22, 9, 8),
      ),
    );
    controller.receive(
      ChatMessage(
        text: 'Your driver has arrived',
        sender: ChatMessageSender.system,
        kind: ChatMessageKind.systemEvent,
        sentAt: DateTime(2026, 9, 22, 9, 9),
      ),
    );

    expect(controller.messages, hasLength(2));
    expect(controller.unreadCount, 2);
    expect(controller.messages.first.fromRider, isFalse);
    expect(controller.messages.last.isSystem, isTrue);

    controller.markAllRead();
    expect(controller.unreadCount, 0);
    expect(controller.messages.every((message) => message.readAt != null), isTrue);
  });

  test('blank messages are rejected', () {
    final controller = MessagesController();

    expect(controller.send('   '), isFalse);
    expect(controller.messages, isEmpty);
  });

  test('same active ride reopens the same in-memory conversation', () {
    const rideId = 'messages-session-ride-001';
    final first = MessagesController.forRide(
      rideId,
      now: () => DateTime(2026, 9, 22, 9, 7),
    );
    first.send('I am at the entrance');

    final reopened = MessagesController.forRide(rideId);
    final otherRide = MessagesController.forRide('messages-session-ride-002');

    expect(reopened.messages, hasLength(1));
    expect(reopened.messages.single.text, 'I am at the entrance');
    expect(otherRide.messages, isEmpty);
  });
}

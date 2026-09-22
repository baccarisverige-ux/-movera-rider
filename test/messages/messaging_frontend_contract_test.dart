import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat has no hardcoded clock or alternating sender logic', () {
    final controller = File(
      'lib/features/messages/application/messages_controller.dart',
    ).readAsStringSync();
    final chat = File(
      'lib/features/messages/presentation/chat.dart',
    ).readAsStringSync();

    expect(controller.contains('messages.length.isEven'), isFalse);
    expect(controller.contains('fromRider: true'), isTrue);
    expect(chat.contains('10:00 AM'), isFalse);
    expect(chat.contains('TimeOfDay.fromDateTime'), isTrue);
  });

  test('active-trip chat is ride-scoped and Rider messages render on the right', () {
    final card = File(
      'lib/features/active_ride/presentation/waiting_sheet_bits.dart',
    ).readAsStringSync();
    final chat = File(
      'lib/features/messages/presentation/chat.dart',
    ).readAsStringSync();

    expect(card.contains('Chat('), isTrue);
    expect(card.contains('driverName: d.firstName'), isTrue);
    expect(card.contains('rideId: rideId'), isTrue);
    expect(chat.contains('MessagesController.forRide(widget.rideId)'), isTrue);
    expect(chat.contains('message.fromRider'), isTrue);
    expect(chat.contains('? RiderMessageBubble(message: message)'), isTrue);
    expect(chat.contains(': DriverMessageBubble(message: message)'), isTrue);
  });

  test('message inbox stays honest until real transport exists', () {
    final inbox = File(
      'lib/features/messages/presentation/messages.dart',
    ).readAsStringSync();

    expect(inbox.contains('No conversations yet'), isTrue);
    expect(inbox.contains('MessagesInbox'), isTrue);
    expect(inbox.contains('ListView.builder'), isFalse);
  });
}

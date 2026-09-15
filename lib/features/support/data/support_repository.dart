import 'package:movera_rider/features/support/domain/support.dart';

class SupportChatScript {
  const SupportChatScript({
    required this.welcome,
    this.issueAck =
        'Support messaging isn’t connected in this build yet, so this message can’t be sent to a support agent.',
    this.followUp =
        'Please use the available help and safety tools in the app until support messaging is connected.',
  });

  final String welcome;
  final String issueAck;
  final String followUp;
}

class SupportRepository {
  List<SupportRide> rides() => const [];

  SupportChatScript chat({SupportRide? ride}) {
    return const SupportChatScript(
      welcome:
          'Movera support messaging isn’t connected in this build yet. You can still browse help articles and use the available safety tools in the app.',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/messages/application/messages_controller.dart';
import 'package:movera_rider/features/messages/domain/messages.dart';
import 'package:movera_rider/features/messages/presentation/chat_appbar.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/custom_textfield.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class Chat extends StatefulWidget {
  const Chat({
    super.key,
    this.driverName,
    this.rideId,
    this.controller,
  });

  final String? driverName;
  final String? rideId;

  /// Optional injection seam for widget tests and, later, the transport adapter.
  final MessagesController? controller;

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final MessagesController _chat;
  bool showSendIcon = false;

  @override
  void initState() {
    super.initState();
    _chat = widget.controller ?? MessagesController.forRide(widget.rideId);
    _chat.markAllRead();
    _messageController.addListener(_onMessageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd(jump: true));
  }

  void _onMessageChanged() {
    final canSend = _messageController.text.trim().isNotEmpty;
    if (canSend == showSendIcon) return;
    setState(() => showSendIcon = canSend);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (!_chat.send(_messageController.text)) return;
    setState(() {});
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd({bool jump = false}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (jump) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFAFAFA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ResSize.h * 75),
        child: ChatAppBar(driverName: widget.driverName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          12.height,
          Expanded(
            child: _chat.messages.isEmpty
                ? const Center(
                    child: MoveraEmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No messages yet',
                      message:
                          'Your conversation with the driver will appear here when the ride is connected.',
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: _chat.messages.length,
                    itemBuilder: (context, index) {
                      final message = _chat.messages[index];
                      if (message.isSystem) {
                        return SystemMessageBubble(message: message);
                      }
                      return message.fromRider
                          ? RiderMessageBubble(message: message)
                          : DriverMessageBubble(message: message);
                    },
                  ),
          ),
          Container(
            height: ResSize.h * 100,
            width: double.infinity,
            color: AppColor.white,
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            alignment: Alignment.center,
            child: SizedBox(
              height: ResSize.h * 48,
              child: Row(
                children: [
                  Expanded(
                    child: customTextfield(
                      borderColor: Colors.transparent,
                      borderWidth: 0,
                      textColor: AppColor.black,
                      controller: _messageController,
                      fontSize: 14,
                      hint: 'Send message...',
                      fillColor: const Color(0xffF6F6F6),
                      borderRadius: 32,
                      hintTextColor: const Color(0xff969696),
                      contentHorizPadding: 14,
                      contentVertPadding: 14,
                    ),
                  ),
                  10.width,
                  Semantics(
                    button: true,
                    enabled: showSendIcon,
                    label: 'Send message',
                    onTap: showSendIcon ? _sendMessage : null,
                    child: ExcludeSemantics(
                      child: Material(
                        color: const Color(0xffF6F6F6),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: showSendIcon ? _sendMessage : null,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            height: ResSize.h * 48,
                            width: ResSize.w * 48,
                            child: Padding(
                              padding: EdgeInsets.all(ResSize.w * 12),
                              child: Image.asset(
                                AppAssets.send,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _messageTime(BuildContext context, DateTime? sentAt) {
  if (sentAt == null) return null;
  return TimeOfDay.fromDateTime(sentAt.toLocal()).format(context);
}

class RiderMessageBubble extends StatelessWidget {
  const RiderMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final time = _messageTime(context, message.sentAt);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResSize.w * 80,
        ResSize.h * 10,
        screenHorizPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              ResSize.w * 12,
              ResSize.h * 9,
              ResSize.w * 12,
              ResSize.h * 11,
            ),
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextWidget(
              text: message.text,
              color: AppColor.whiteText,
              fontSize: 14,
              fontWeight: fwNormal,
            ),
          ),
          if (time != null) ...[
            5.height,
            TextWidget(
              text: time,
              color: const Color(0xff858F94),
              fontSize: 12,
              fontWeight: fwNormal,
            ),
          ],
        ],
      ),
    );
  }
}

class DriverMessageBubble extends StatelessWidget {
  const DriverMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final time = _messageTime(context, message.sentAt);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenHorizPadding,
        ResSize.h * 10,
        ResSize.w * 80,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              ResSize.w * 12,
              ResSize.h * 9,
              ResSize.w * 12,
              ResSize.h * 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffF1F3F4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextWidget(
              text: message.text,
              fontSize: 14,
              color: AppColor.title,
              fontWeight: fwNormal,
            ),
          ),
          if (time != null) ...[
            5.height,
            TextWidget(
              text: time,
              color: const Color(0xff858F94),
              fontSize: 12,
              fontWeight: fwNormal,
            ),
          ],
        ],
      ),
    );
  }
}


class SystemMessageBubble extends StatelessWidget {
  const SystemMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final time = _messageTime(context, message.sentAt);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenHorizPadding,
        ResSize.h * 12,
        screenHorizPadding,
        0,
      ),
      child: Semantics(
        label: 'System message: ${message.text}',
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResSize.w * 14,
                vertical: ResSize.h * 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xffECEFF1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextWidget(
                text: message.text,
                fontSize: 12.5,
                color: AppColor.title,
                fontWeight: fwMedium,
              ),
            ),
            if (time != null) ...[
              4.height,
              TextWidget(
                text: time,
                color: const Color(0xff858F94),
                fontSize: 11,
                fontWeight: fwNormal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

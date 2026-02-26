import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/message.dart';
import 'package:juniper_journal/src/backend/db/repositories/chat_repo.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherAvatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.otherAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatRepo _chatRepo = ChatRepo();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;
  bool _hasScrolledToBottom = false;

  String? get _currentUserId => AuthService.instance.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _chatRepo.markAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      // Always scroll on first load; after that only scroll if already near bottom
      if (!_hasScrolledToBottom) {
        _scrollController.jumpTo(pos.maxScrollExtent);
        _hasScrolledToBottom = true;
        return;
      }
      if (pos.maxScrollExtent - pos.pixels < 100) {
        _scrollController.animateTo(
          pos.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _inputController.clear();

    final success = await _chatRepo.sendMessage(widget.conversationId, text);

    if (!mounted) return;
    if (!success) {
      _inputController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send. Try again.')),
      );
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(avatarUrl: widget.otherAvatarUrl, radius: 16),
            const SizedBox(width: 8),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatRepo.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Say hello!',
                          style: TextStyle(color: Colors.black38, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                _maybeScrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final msg = messages[index];
                    final isSent = msg.senderId == _currentUserId;
                    // Show the sender name above the first bubble in each consecutive group
                    final isFirstInGroup = index == 0 ||
                        messages[index - 1].senderId != msg.senderId;
                    final showSenderName = !isSent && isFirstInGroup;

                    return _MessageBubble(
                      message: msg,
                      isSent: isSent,
                      showSenderName: showSenderName,
                      senderFirstName: widget.otherUserName.split(' ').first,
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _inputController,
            sending: _sending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSent;
  final bool showSenderName;
  final String senderFirstName;

  const _MessageBubble({
    required this.message,
    required this.isSent,
    required this.showSenderName,
    required this.senderFirstName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment:
            isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderName && !isSent)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                senderFirstName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSent
                      ? AppColors.submitButton
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isSent ? 18 : 4),
                    bottomRight: Radius.circular(isSent ? 4 : 18),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSent ? Colors.white : Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // TODO: Implement media attachment
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            color: Colors.black54,
            onPressed: null,
          ),
          Expanded(
            child: Focus(
              onKeyEvent: (_, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey != LogicalKeyboardKey.enter) {
                  return KeyEventResult.ignored;
                }
                if (HardwareKeyboard.instance.isShiftPressed) {
                  final sel = controller.selection;
                  final text = controller.text;
                  final newText = text.replaceRange(sel.start, sel.end, '\n');
                  controller.value = controller.value.copyWith(
                    text: newText,
                    selection: TextSelection.collapsed(
                      offset: sel.start + 1,
                    ),
                  );
                  return KeyEventResult.handled;
                }
                onSend();
                return KeyEventResult.handled;
              },
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: sending ? Colors.grey.shade300 : AppColors.submitButton,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

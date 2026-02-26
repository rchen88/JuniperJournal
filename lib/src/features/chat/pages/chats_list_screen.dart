import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/db/models/conversation_preview.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/chat_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/friends_repo.dart';
import 'package:juniper_journal/src/features/chat/pages/chat_screen.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/widgets/user_avatar.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ChatRepo _chatRepo = ChatRepo();
  final FriendsRepo _friendsRepo = FriendsRepo();
  final TextEditingController _searchController = TextEditingController();

  List<ConversationPreview> _conversations = [];
  List<ConversationPreview> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    final data = await _chatRepo.getConversations();
    if (!mounted) return;
    setState(() {
      _conversations = data ?? [];
      _filtered = _applySearch(_conversations);
      _loading = false;
    });
  }

  void _onSearchChanged() {
    setState(() => _filtered = _applySearch(_conversations));
  }

  List<ConversationPreview> _applySearch(List<ConversationPreview> list) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return list;
    return list
        .where((c) => c.resolvedDisplayName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _openNewChat() async {
    final friends = await _friendsRepo.getFriends();
    if (!mounted) return;
    if (friends == null || friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No friends yet. Add friends to start a chat.'),
        ),
      );
      return;
    }
    final picked = await showModalBottomSheet<UserProfile>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FriendPickerSheet(friends: friends),
    );
    if (picked == null || !mounted) return;

    final conversationId = await _chatRepo.getOrCreateDm(picked.id);
    if (!mounted || conversationId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          otherUserName: picked.resolvedDisplayName,
          otherAvatarUrl: picked.avatarUrl,
        ),
      ),
    );
    if (!mounted) return;
    _loadConversations();
  }

  Future<bool> _confirmAndDelete(String conversationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'This will hide the conversation for you. The other person will still be able to see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    return _chatRepo.deleteConversation(conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Chats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _openNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.search, color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_filtered.isEmpty) return _buildEmptyState();
    return _buildConversationList();
  }

  Widget _buildEmptyState() {
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
          Text(
            _conversations.isEmpty ? 'No conversations yet' : 'No results',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          if (_conversations.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Tap + to start a chat',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _filtered.length,
        itemBuilder: (_, index) {
          final c = _filtered[index];
          return Dismissible(
            key: Key(c.conversationId),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 26,
              ),
            ),
            confirmDismiss: (_) => _confirmAndDelete(c.conversationId),
            onDismissed: (_) {
              setState(() {
                _conversations.removeWhere(
                  (x) => x.conversationId == c.conversationId,
                );
                _filtered.removeWhere(
                  (x) => x.conversationId == c.conversationId,
                );
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ConversationTile(
                  conversation: c,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: c.conversationId,
                          otherUserName: c.resolvedDisplayName,
                          otherAvatarUrl: c.otherAvatarUrl,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    _loadConversations();
                  },
                ),
                if (index < _filtered.length - 1)
                  const Divider(height: 1, indent: 76, endIndent: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationPreview conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final hasUnread = c.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            UserAvatar(avatarUrl: c.otherAvatarUrl, radius: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.resolvedDisplayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          hasUnread ? FontWeight.w700 : FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (c.lastMessage != null && c.lastMessage!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      c.lastMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread ? Colors.black87 : Colors.black54,
                        fontWeight:
                            hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.submitButton,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                child: Center(
                  child: Text(
                    c.unreadCount > 99 ? '99+' : '${c.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FriendPickerSheet extends StatelessWidget {
  final List<UserProfile> friends;

  const _FriendPickerSheet({required this.friends});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'New Message',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: friends.length,
            itemBuilder: (_, index) {
              final friend = friends[index];
              return ListTile(
                leading: UserAvatar(avatarUrl: friend.avatarUrl, radius: 22),
                title: Text(
                  friend.resolvedDisplayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.pop(context, friend),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/db/models/conversation_preview.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/chat_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/friends_repo.dart';
import 'package:juniper_journal/src/features/chat/pages/chat_screen.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';

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
    return list.where((c) {
      final name = (c.otherDisplayName ?? c.otherUsername ?? '').toLowerCase();
      return name.contains(query);
    }).toList();
  }

  Future<void> _openNewChat() async {
    final friends = await _friendsRepo.getFriends();
    if (!mounted) return;
    if (friends == null || friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No friends yet. Add friends to start a chat.')),
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

    final displayName =
        picked.displayName?.trim().isNotEmpty == true
            ? picked.displayName!
            : (picked.username?.trim().isNotEmpty == true
                ? '@${picked.username}'
                : 'User');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          otherUserName: displayName,
          otherAvatarUrl: picked.avatarUrl,
        ),
      ),
    );
    if (!mounted) return;
    _loadConversations();
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
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
                              _conversations.isEmpty
                                  ? 'No conversations yet'
                                  : 'No results',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            if (_conversations.isEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Tap + to start a chat',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (_, index) {
                            final c = _filtered[index];
                            final name =
                                c.otherDisplayName?.trim().isNotEmpty == true
                                    ? c.otherDisplayName!
                                    : (c.otherUsername?.trim().isNotEmpty == true
                                          ? '@${c.otherUsername}'
                                          : 'User');
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
                              confirmDismiss: (_) =>
                                  _chatRepo.deleteConversation(c.conversationId),
                              onDismissed: (_) {
                                final id = c.conversationId;
                                setState(() {
                                  _conversations.removeWhere(
                                    (x) => x.conversationId == id,
                                  );
                                  _filtered.removeWhere(
                                    (x) => x.conversationId == id,
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
                                            otherUserName: name,
                                            otherAvatarUrl: c.otherAvatarUrl,
                                          ),
                                        ),
                                      );
                                      if (!mounted) return;
                                      _loadConversations();
                                    },
                                  ),
                                  if (index < _filtered.length - 1)
                                    const Divider(
                                      height: 1,
                                      indent: 76,
                                      endIndent: 16,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
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
    final name = c.otherDisplayName?.trim().isNotEmpty == true
        ? c.otherDisplayName!
        : (c.otherUsername?.trim().isNotEmpty == true
              ? '@${c.otherUsername}'
              : 'User');
    final hasUnread = c.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE6E8EC),
              backgroundImage:
                  (c.otherAvatarUrl != null && c.otherAvatarUrl!.isNotEmpty)
                      ? NetworkImage(c.otherAvatarUrl!)
                      : null,
              child: (c.otherAvatarUrl == null || c.otherAvatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 26, color: Color(0xFF4A4A4A))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
              final name =
                  friend.displayName?.trim().isNotEmpty == true
                      ? friend.displayName!
                      : (friend.username?.trim().isNotEmpty == true
                          ? '@${friend.username}'
                          : 'User');
              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE6E8EC),
                  backgroundImage: (friend.avatarUrl != null &&
                          friend.avatarUrl!.isNotEmpty)
                      ? NetworkImage(friend.avatarUrl!)
                      : null,
                  child: (friend.avatarUrl == null || friend.avatarUrl!.isEmpty)
                      ? const Icon(
                          Icons.person,
                          size: 22,
                          color: Color(0xFF4A4A4A),
                        )
                      : null,
                ),
                title: Text(
                  name,
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

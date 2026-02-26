import 'package:flutter/foundation.dart';
import 'package:juniper_journal/src/backend/db/models/conversation_preview.dart';
import 'package:juniper_journal/src/backend/db/models/message.dart';
import 'package:juniper_journal/src/backend/db/supabase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepo {
  SupabaseClient get _client => SupabaseDatabase.instance.client;

  Future<List<ConversationPreview>?> getConversations() async {
    try {
      final data = await _client.rpc('get_my_conversations');
      return List<Map<String, dynamic>>.from(data as List)
          .map(ConversationPreview.fromMap)
          .toList();
    } catch (e, st) {
      debugPrint('getConversations error: $e\n$st');
      return null;
    }
  }

  Future<String?> getOrCreateDm(String otherUserId) async {
    try {
      final data = await _client
          .rpc('get_or_create_dm', params: {'other_user_id': otherUserId});
      return data?.toString();
    } catch (e, st) {
      debugPrint('getOrCreateDm error: $e\n$st');
      return null;
    }
  }

  Future<List<Message>?> getMessages(String conversationId) async {
    try {
      final data = await _client.rpc(
        'get_conversation_messages',
        params: {'conv_id': conversationId},
      );
      return List<Map<String, dynamic>>.from(data as List)
          .map(Message.fromMap)
          .toList();
    } catch (e, st) {
      debugPrint('getMessages error: $e\n$st');
      return null;
    }
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;
    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'content': content,
      });
      return true;
    } catch (e, st) {
      debugPrint('sendMessage error: $e\n$st');
      return false;
    }
  }

  Stream<List<Message>> streamMessages(String conversationId) async* {
    while (true) {
      final messages = await getMessages(conversationId);
      if (messages != null) yield messages;
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;
    try {
      await _client.from('conversation_deletions').upsert({
        'conversation_id': conversationId,
        'user_id': currentUserId,
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (e, st) {
      debugPrint('deleteConversation error: $e\n$st');
      return false;
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _client.rpc(
        'mark_conversation_read',
        params: {'conv_id': conversationId},
      );
    } catch (e, st) {
      debugPrint('markAsRead error: $e\n$st');
    }
  }
}

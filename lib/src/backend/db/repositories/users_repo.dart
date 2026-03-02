import 'package:flutter/foundation.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/supabase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersRepo {
  static const profilesTable = 'profiles';

  SupabaseClient get _client => SupabaseDatabase.instance.client;

  Future<UserProfile?> getCurrentUserProfile() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return null;

    try {
      final rows = await _client
          .from(profilesTable)
          .select('id, display_name, username, avatar_url, is_public_profile')
          .eq('id', currentUserId)
          .limit(1);

      if (rows.isEmpty) return null;
      return UserProfile.fromMap(Map<String, dynamic>.from(rows.first));
    } catch (e, st) {
      debugPrint('getCurrentUserProfile error: $e\n$st');
      return null;
    }
  }

  /// Creates or updates the current user's profile row.
  /// Call this after a successful signup to store the username.
  Future<void> upsertCurrentUserProfile({String? username}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final data = <String, dynamic>{
        'id': user.id,
        'is_public_profile': true,
      };
      if (username != null && username.trim().isNotEmpty) {
        data['username'] = username.trim();
      }
      await _client.from(profilesTable).upsert(data, onConflict: 'id');
    } catch (e, st) {
      debugPrint('upsertCurrentUserProfile error: $e\n$st');
    }
  }

  /// Inserts a profile row if one doesn't already exist.
  /// Safe to call on login — never overwrites existing data.
  Future<void> ensureProfileExists() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from(profilesTable).upsert(
        {'id': user.id, 'is_public_profile': true},
        ignoreDuplicates: true,
      );
    } catch (e, st) {
      debugPrint('ensureProfileExists error: $e\n$st');
    }
  }

  Future<bool> updateCurrentUserProfile({
    String? avatarUrl,
    String? displayName,
    bool? isPublicProfile,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final data = <String, dynamic>{'id': currentUserId};
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (displayName != null) data['display_name'] = displayName;
    if (isPublicProfile != null) data['is_public_profile'] = isPublicProfile;

    try {
      await _client.from(profilesTable).upsert(data, onConflict: 'id');
      return true;
    } catch (e, st) {
      debugPrint('updateCurrentUserProfile error: $e\n$st');
      return false;
    }
  }

  Future<List<UserProfile>?> searchPublicUsers({
    required String query,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      var request = _client
          .from(profilesTable)
          .select('id, display_name, username, avatar_url, is_public_profile')
          .eq('is_public_profile', true);

      if (currentUserId != null) {
        request = request.neq('id', currentUserId);
      }

      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        request = request.or(
          'display_name.ilike.%$trimmed%,username.ilike.%$trimmed%',
        );
      }

      final rows = await request.limit(30);
      return List<Map<String, dynamic>>.from(rows).map(UserProfile.fromMap).toList();
    } catch (e, st) {
      debugPrint('searchPublicUsers error: $e\n$st');
      return null;
    }
  }
}

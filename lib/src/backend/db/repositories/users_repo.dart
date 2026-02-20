import 'package:flutter/foundation.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/supabase_database.dart';

class UsersRepo {
  static const profilesTable = 'profiles';

  get _client => SupabaseDatabase.instance.client;

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
      return rows.map((r) => UserProfile.fromMap(r)).toList();
    } catch (e, st) {
      debugPrint('searchPublicUsers error: $e\n$st');
      return null;
    }
  }
}

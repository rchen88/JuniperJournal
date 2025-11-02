import 'package:flutter/foundation.dart';
import 'package:juniper_journal/src/backend/db/supabase_database.dart';

class ProjectsRepo {
  static const table = 'projects';
  final _client = SupabaseDatabase.instance.client;

  // ⬇️ Replace your old createProject with this version
  Future<Map<String, dynamic>?> createProject({
    required String projectName,
    required String problemStatement,
    required List<String> tags,
  }) async {
    try {
      final row = await _client
          .from('projects')
          .insert({
            'project_name': projectName,
            'problem_statement': problemStatement,
            'tags': tags.isEmpty ? null : tags, // avoid [] issues
          })
          .select()
          .single();
      return row;
    } catch (e, st) {
      debugPrint('createProject error: $e\n$st');
      return null;
    }
  }

  Future<bool> updateProblemStatement({
    required int id,
    required String problemStatement,
  }) async {
    try {
      await _client
          .from(table)
          .update({'problem_statement': problemStatement})
          .eq('id', id);
      return true;
    } catch (e, st) {
      debugPrint('updateProblemStatement error: $e\n$st');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProject(int id) async {
    try {
      return await _client.from(table).select().eq('id', id).single();
    } catch (e, st) {
      debugPrint('getProject error: $e\n$st');
      return null;
    }
  }
}
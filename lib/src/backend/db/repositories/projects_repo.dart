import 'package:flutter/foundation.dart';
import 'package:juniper_journal/src/backend/db/models/journal_entry.dart';
import 'package:juniper_journal/src/backend/db/models/project.dart';
import 'package:juniper_journal/src/backend/db/supabase_database.dart';

class ProjectsRepo {
  static const table = 'projects';
  static const journalEntriesTable = 'journal_entries';
  get _client => SupabaseDatabase.instance.client;

  Future<List<Project>?> getCurrentUserProjects() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final rows = await _client
          .from(table)
          .select('id, project_name, tags, project_image_url, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows).map(Project.fromMap).toList();
    } catch (e, st) {
      debugPrint('getCurrentUserProjects error: $e\n$st');
      return null;
    }
  }

  Future<List<Project>?> getProjectsByUserId({
    required String userId,
  }) async {
    try {
      final rows = await _client
          .from(table)
          .select('id, project_name, tags, project_image_url, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows).map(Project.fromMap).toList();
    } catch (e, st) {
      debugPrint('getProjectsByUserId error: $e\n$st');
      return null;
    }
  }

  Future<List<Project>?> getProjectsForFeed({
    required List<String> ownerIds,
  }) async {
    if (ownerIds.isEmpty) return [];

    try {
      final rows = await _client
          .from(table)
          .select(
            'id, user_id, project_name, problem_statement, tags, project_image_url, created_at, likes',
          )
          .inFilter('user_id', ownerIds)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows).map(Project.fromMap).toList();
    } catch (e, st) {
      debugPrint('getProjectsForFeed error: $e\n$st');
      return null;
    }
  }

  Future<Project?> createProject({
    required String projectName,
    required String problemStatement,
    required List<String> tags,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    try {
      final row = await _client
          .from('projects')
          .insert({
            'project_name': projectName,
            'problem_statement': problemStatement,
            'tags': tags.isEmpty ? null : tags, // avoid [] issues
            'user_id': user.id,
          })
          .select()
          .single();
      return Project.fromMap(row);
    } catch (e, st) {
      debugPrint('createProject error: $e\n$st');
      return null;
    }
  }

  Future<bool> likeProject({required String id}) async {
    try {
      await _client.rpc('like_project', params: {'p_project_id': id});
      return true;
    } catch (e, st) {
      debugPrint('likeProject error: $e\n$st');
      return false;
    }
  }

  Future<bool> unlikeProject({required String id}) async {
    try {
      await _client.rpc('unlike_project', params: {'p_project_id': id});
      return true;
    } catch (e, st) {
      debugPrint('unlikeProject error: $e\n$st');
      return false;
    }
  }

  Future<Set<String>> getLikedProjectIds({required List<String> projectIds}) async {
    final user = _client.auth.currentUser;
    if (user == null || projectIds.isEmpty) return {};
    try {
      final rows = await _client
          .from('project_likes')
          .select('project_id')
          .eq('user_id', user.id)
          .inFilter('project_id', projectIds);
      return Set<String>.from(
        List<Map<String, dynamic>>.from(rows).map((r) => r['project_id'].toString()),
      );
    } catch (e, st) {
      debugPrint('getLikedProjectIds error: $e\n$st');
      return {};
    }
  }

  Future<bool> updateProblemStatement({
    required String id,
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

  Future<Project?> getProject(int id) async {
    try {
      final row = await _client.from(table).select().eq('id', id).single();
      return Project.fromMap(row);
    } catch (e, st) {
      debugPrint('getProject error: $e\n$st');
      return null;
    }
  }

  Future<Project?> getProjectById(String id) async {
    try {
      final row = await _client
          .from(table)
          .select(
            'id, project_name, problem_statement, tags, project_image_url, created_at',
          )
          .eq('id', id)
          .single();
      return Project.fromMap(row);
    } catch (e, st) {
      debugPrint('getProjectById error: $e\n$st');
      return null;
    }
  }

  Future<bool> updateProjectMetadata({
    required String id,
    required String projectName,
    required String problemStatement,
    required List<String> tags,
    String? projectImageUrl,
  }) async {
    try {
      await _client
          .from(table)
          .update({
            'project_name': projectName,
            'problem_statement': problemStatement,
            'tags': tags,
            'project_image_url': projectImageUrl,
          })
          .eq('id', id);
      return true;
    } catch (e, st) {
      debugPrint('updateProjectMetadata error: $e\n$st');
      return false;
    }
  }

  Future<bool> deleteProject({required String id}) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // Clean dependent rows with user scoping for RLS-safe deletes.
      await _client
          .from(journalEntriesTable)
          .delete()
          .eq('project_id', id)
          .eq('user_id', user.id);

      final deletedRows = await _client
          .from(table)
          .delete()
          .eq('id', id)
          .eq('user_id', user.id)
          .select('id');

      return deletedRows.isNotEmpty;
    } catch (e, st) {
      debugPrint('deleteProject error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateTimeline({
    required String id,
    required List<Map<String, String>> timeline,
  }) async {
    try {
      await _client.from(table).update({'timeline': timeline}).eq('id', id);
      return true;
    } catch (e, st) {
      debugPrint('updateTimeline error: $e\n$st');
      return false;
    }
  }

  Future<List<Map<String, String>>?> getTimeline(String id) async {
    try {
      final result = await _client
          .from(table)
          .select('timeline')
          .eq('id', id)
          .single();
      final timeline = result['timeline'];
      if (timeline == null) return [];
      return (timeline as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    } catch (e, st) {
      debugPrint('getTimeline error: $e\n$st');
      return null;
    }
  }

  Future<bool> updateJournalLog({
    required String id,
    required String journalLogJson,
  }) async {
    try {
      await _client
          .from(table)
          .update({'journal_log': journalLogJson})
          .eq('id', id);
      return true;
    } catch (e, st) {
      debugPrint('updateJournalLog error: $e\n$st');
      return false;
    }
  }

  Future<List<JournalEntry>?> getJournalEntries({
    required String projectId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final result = await _client
          .from(journalEntriesTable)
          .select('id, title, content, created_at, updated_at, project_id')
          .eq('project_id', projectId)
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result).map(JournalEntry.fromMap).toList();
    } catch (e, st) {
      debugPrint('getJournalEntries error: $e\n$st');
      return null;
    }
  }

  Future<JournalEntry?> createJournalEntry({
    required String projectId,
    required String title,
    required List<dynamic> content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    try {
      final row = await _client
          .from(journalEntriesTable)
          .insert({
            'project_id': projectId,
            'user_id': user.id,
            'title': title,
            'content': content,
          })
          .select('id, title, content, created_at, updated_at, project_id')
          .single();

      return JournalEntry.fromMap(row);
    } catch (e, st) {
      debugPrint('createJournalEntry error: $e\n$st');
      return null;
    }
  }

  Future<bool> updateJournalEntry({
    required String entryId,
    String? title,
    List<dynamic>? content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;
    if (updates.isEmpty) return true;

    try {
      await _client
          .from(journalEntriesTable)
          .update(updates)
          .eq('id', entryId)
          .eq('user_id', user.id);
      return true;
    } catch (e, st) {
      debugPrint('updateJournalEntry error: $e\n$st');
      return false;
    }
  }

  Future<bool> deleteJournalEntry({required String entryId}) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from(journalEntriesTable)
          .delete()
          .eq('id', entryId)
          .eq('user_id', user.id);
      return true;
    } catch (e, st) {
      debugPrint('deleteJournalEntry error: $e\n$st');
      return false;
    }
  }

  Future<String?> getJournalLog(String id) async {
    try {
      final result = await _client
          .from(table)
          .select('journal_log')
          .eq('id', id)
          .single();
      return result['journal_log'] as String?;
    } catch (e, st) {
      debugPrint('getJournalLog error: $e\n$st');
      return null;
    }
  }

  Future<bool> updateSolution({
    required String id,
    required String solutionJson,
  }) async {
    try {
      await _client.from(table).update({'solution': solutionJson}).eq('id', id);
      return true;
    } catch (e, st) {
      debugPrint('updateSolution error: $e\n$st');
      return false;
    }
  }

  Future<String?> getSolution(String id) async {
    try {
      final result = await _client
          .from(table)
          .select('solution')
          .eq('id', id)
          .single();
      return result['solution'] as String?;
    } catch (e, st) {
      debugPrint('getSolution error: $e\n$st');
      return null;
    }
  }

  Future<bool> updateMaterialsCost({
    required String id,
    required List<Map<String, dynamic>> materials,
  }) async {
    try {
      await _client
          .from(table)
          .update({'materials_cost': materials})
          .eq('id', id);
      return true;
    } catch (e, st) {
      debugPrint('updateMaterialsCost error: $e\n$st');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getMaterialsCost(String id) async {
    try {
      final result = await _client
          .from(table)
          .select('materials_cost')
          .eq('id', id)
          .single();
      final materials = result['materials_cost'];
      if (materials == null) return [];
      return (materials as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e, st) {
      debugPrint('getMaterialsCost error: $e\n$st');
      return null;
    }
  }
}

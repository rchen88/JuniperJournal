import 'package:flutter/foundation.dart';
import 'package:juniper_journal/src/backend/db/supabase_database.dart';

class ProjectsRepo {
  static const table = 'projects';
  final _client = SupabaseDatabase.instance.client;

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

  Future<Map<String, dynamic>?> getProject(int id) async {
    try {
      return await _client.from(table).select().eq('id', id).single();
    } catch (e, st) {
      debugPrint('getProject error: $e\n$st');
      return null;
    }
  }

  Future<bool> updateTimeline({
    required String id,
    required List<Map<String, String>> timeline,
  }) async {
    try {
      await _client
          .from(table)
          .update({'timeline': timeline})
          .eq('id', id);
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
      await _client
          .from(table)
          .update({'solution': solutionJson})
          .eq('id', id);
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
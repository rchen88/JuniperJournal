import 'package:juniper_journal/src/backend/db/supabase_database.dart';

class LearningModuleRepo {
  static const table = 'learning_module';
  final _client = SupabaseDatabase.instance.client;

  Future<bool> createModule({
    required String moduleName,
    required String difficulty,
    required int ecoPoints,
  }) async {
    try {
      final response = await _client
          .from(table)
          .insert({
            'module_name': moduleName,
            'difficulty': difficulty,
            'eco_points': ecoPoints,
          })
          .select();

      // If insert succeeded, Supabase returns a non-empty List
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

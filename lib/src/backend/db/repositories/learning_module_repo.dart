import 'package:juniper_journal/src/backend/db/supabase_database.dart';

/// Repository class responsible for handling all database interactions
/// related to the `learning_module` table in Supabase.
///
/// This class provides an abstraction layer between the Flutter UI
/// and the Supabase backend, ensuring that database operations are
/// centralized, reusable, and isolated from presentation logic.
///
/// **Responsibilities:**
/// - Inserts new learning module records into the database.
/// - (Future) Can be extended to support reading, updating, and deleting modules.
/// - Converts UI-level data into structured Supabase API calls.
///
/// Using this repository pattern keeps your widget code clean and
/// makes it easier to maintain and test database logic independently.
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

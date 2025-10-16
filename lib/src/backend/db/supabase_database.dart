import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Singleton class responsible for initializing and providing a shared
/// instance of the Supabase client throughout the application.
///
/// This class centralizes all Supabase configuration and connection
/// logic to ensure a single, consistent database client is used
/// across repositories and services.
///
/// **Responsibilities:**
/// - Initializes the Supabase client using environment variables
///   defined in the `.env` file (`SUPABASE_URL`, `SUPABASE_KEY`).
/// - Exposes a globally accessible `client` instance for all database
///   operations (queries, inserts, updates, etc.).
/// - Prevents redundant Supabase initialization by using a singleton
///   pattern (`SupabaseDatabase.instance`).
///
/// **Usage:**
/// Call `await SupabaseDatabase.instance.init();` in `main()` before
/// running the app to ensure the client is properly initialized.
///

class SupabaseDatabase {
  SupabaseDatabase._();

  static final SupabaseDatabase instance = SupabaseDatabase._();

  late final SupabaseClient client;

  Future<void> init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_KEY']!,
    );
    client = Supabase.instance.client;
  }
}

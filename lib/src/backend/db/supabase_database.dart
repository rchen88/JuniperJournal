import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

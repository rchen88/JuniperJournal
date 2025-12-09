import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:juniper_journal/src/backend/db/supabase_database.dart';
import 'package:juniper_journal/src/frontend/home1/start.dart';
import 'package:juniper_journal/src/frontend/home_page/home.dart';
import 'src/frontend/learning_module/create_lm_template.dart';
import 'src/frontend/submission_template/create_submission_template.dart';
import 'src/frontend/learning_module/3d_learning.dart';


import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/frontend/home_page/home.dart';
import 'src/frontend/learning_module/create_lm_template.dart';
import 'src/frontend/submission_template/create_submission_template.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await SupabaseDatabase.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juniper Journal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const JuniperAuthScreen(),
    );
  }
}
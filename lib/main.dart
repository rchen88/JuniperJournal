import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:juniper_journal/src/backend/db/supabase_database.dart';
import 'package:juniper_journal/src/frontend/home1/start.dart';
import 'package:juniper_journal/src/frontend/home_page/home.dart';
import 'src/frontend/learning_module/create_lm_template.dart';
import 'src/frontend/submission_template/create_submission_template.dart';


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
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper that checks if user is logged in and shows appropriate screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;

    // Listen to auth state changes
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user is logged in
        final isLoggedIn = authService.isLoggedIn;

        if (isLoggedIn) {
          // User is logged in, show main app
          return const MyHomePage(title: 'Juniper Journal');
        } else {
          // User is not logged in, show auth screen
          return const JuniperAuthScreen();
        }
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        actions: [
          // Profile icon (placeholder for future profile picture)
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 20,
                color: Colors.green,
              ),
            ),
            tooltip: 'Profile',
            onPressed: () {
              // TODO: Navigate to profile screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Profile: ${user?.email ?? "Unknown"}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authService.signOut();
              // AuthWrapper will automatically redirect to login screen
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTemplateScreen(),
                  ),
                );
              },
              child: const Text('Go to Learning Module'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateSubmissionScreen(),
                  ),
                );
              },
              child: const Text('Go to Submission Template'),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JuniperAuthScreen()
                    , // Submission screen
                  ),
                );
              },
              child: const Text('Go to Login / Signup'),
            ),const SizedBox(height: 20),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeShellScreen()
                    , // Submission screen
                  ),
                );
              },
              child: const Text('Go to New Home Screen'),
            ),
      
          ],
        ),
      ),
    );
  }
}
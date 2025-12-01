import 'package:flutter/material.dart';
import '../../styling/app_colors.dart';

class JuniperAuthScreen extends StatelessWidget {
  const JuniperAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Green background gradient like the mockup
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8BD674), // light green
              Color(0xFF0B7D4E), // darker green
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // Centered logo
              Center(
                child: SizedBox(
                  height: 260,
                  child: Image.asset(
                    'assets/images/juniper_journal_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const Spacer(),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    _AuthButton(
                      label: 'Sign up',
                      onTap: () {
                        // TODO: Navigate to sign up screen
                      },
                    ),
                    const SizedBox(height: 16),
                    _AuthButton(
                      label: 'Log in',
                      onTap: () {
                        // TODO: Navigate to log in screen
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AuthButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

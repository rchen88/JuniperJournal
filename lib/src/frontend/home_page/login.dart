import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF6BB578); // adjust to match your palette

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ---------- Main scrollable content ----------
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60), // space under back arrow

                  // Heading
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Username / Email
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter Your Username / Email',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: green, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter Your Password',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: green, width: 1.4),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Forgot password
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign up text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?  "),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // OR divider
                  Row(
                    children: const [
                      Expanded(child: Divider(thickness: 0.8)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Or'),
                      ),
                      Expanded(child: Divider(thickness: 0.8)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(width: 10),
                          Text(
                            'Login with Google',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Back Arrow (matches your screenshot) ----------
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 26,
                  weight: 200,     // Thin, clean arrow like your image
                  color: Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/repositories/users_repo.dart';
import 'package:juniper_journal/src/shared/widgets/widgets.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
import 'package:juniper_journal/src/features/home_page/home_page.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usersRepo = UsersRepo();

  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  // Create nodes for easy flow
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();

    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Handles email/password signup
  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final result = await AuthService.instance.signUpWithEmail(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      username: _usernameCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 1️⃣ Signup failed
    if (!result.isSuccess) {
      _showError(result.friendlyErrorMessage ?? 'Signup failed.');
      return;
    }

    // 2️⃣ Logged in immediately (email confirmation OFF)
    if (result.session != null) {
      await _usersRepo.upsertCurrentUserProfile(
        username: _usernameCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // 3️⃣ Email confirmation required OR email already exists
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Check your email'),
        content: const Text(
          'If this email is new, you’ll receive a confirmation email.\n\n'
          'If you already have an account, please log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Log in'),
          ),
        ],
      ),
    );
  }


  /// Shows error message as SnackBar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black87,
          onPressed: _isLoading
          ? null
          : () => Navigator.maybePop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),

                // Title
                const Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                // Username
                TextFormField(
                  controller: _usernameCtrl,
                  focusNode: _usernameFocus,
                  decoration: authInputDecoration('Enter Your Username'),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Enter a username';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_emailFocus);
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  decoration: authInputDecoration('Enter Your Email'),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Enter your email';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocus);
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  decoration: authInputDecoration('Enter Your Password').copyWith(
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
                  validator: (v) {
                    final value = v ?? '';
                    if (value.isEmpty) return 'Enter a password';
                    if (value.contains(RegExp(r'\s'))) return 'Password cannot contain spaces';
                    if (value.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isLoading) {
                      _handleSignup();
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Sign up button
                SubmitButton(
                  label: 'Sign up',
                  isLoading: _isLoading,
                  onPressed: _handleSignup,
                  backgroundColor: AppColors.submitButton,
                ),
                const SizedBox(height: 20),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?  '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.submitButton ,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // Uncomment below to enable Google OAuth signup
                // const SizedBox(height: 24),
                // Row(
                //   children: const [
                //     Expanded(child: Divider(thickness: 0.8)),
                //     Padding(
                //       padding: EdgeInsets.symmetric(horizontal: 8.0),
                //       child: Text('Or'),
                //     ),
                //     Expanded(child: Divider(thickness: 0.8)),
                //   ],
                // ),
                // const SizedBox(height: 24),
                // SizedBox(
                //   width: double.infinity,
                //   height: 48,
                //   child: OutlinedButton(
                //     onPressed: _isLoading ? null : _handleGoogleSignup,
                //     style: OutlinedButton.styleFrom(
                //       side: const BorderSide(color: Colors.black12),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(10),
                //       ),
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         const SizedBox(width: 10),
                //         const Text(
                //           'Sign up with Google',
                //           style: TextStyle(
                //             color: Colors.black87,
                //             fontSize: 15,
                //             fontWeight: FontWeight.w500,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        )
      ),
    );
  }
}

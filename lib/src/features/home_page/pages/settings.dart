import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/repositories/users_repo.dart';
import 'package:juniper_journal/src/features/home_page/home_page.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService.instance;
  final _usersRepo = UsersRepo();

  late final TextEditingController _displayNameController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPublicProfile = true;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _usersRepo.getCurrentUserProfile();
    if (!mounted) return;
    setState(() {
      _displayNameController.text =
          profile?.displayName?.trim() ?? profile?.username?.trim() ?? '';
      _isPublicProfile = profile?.isPublicProfile ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveDisplayName() async {
    final name = _displayNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    final ok = await _usersRepo.updateCurrentUserProfile(displayName: name);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Name updated' : 'Failed to update name')),
    );
  }

  Future<void> _toggleVisibility(bool value) async {
    setState(() => _isPublicProfile = value);
    await _usersRepo.updateCurrentUserProfile(isPublicProfile: value);
  }

  Future<void> _sendPasswordReset() async {
    final email = _authService.currentUser?.email;
    if (email == null) return;
    await _authService.resetPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent')),
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const JuniperAuthScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account, profile, and all your data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Second confirmation — must type DELETE
    final confirmController = TextEditingController();
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Type DELETE to confirm'),
        content: TextField(
          controller: confirmController,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'DELETE',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, confirmController.text.trim() == 'DELETE'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete my account'),
          ),
        ],
      ),
    );
    confirmController.dispose();
    if (doubleConfirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    final ok = await _authService.deleteAccount();
    if (!mounted) return;

    if (!ok) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account. Please try again.')),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const JuniperAuthScreen()),
      (route) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppColors.border,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.6),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  children: [
                    _sectionHeader('Profile'),
                    _card([
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _displayNameController,
                                textCapitalization:
                                    TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Display Name',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: _isSaving ? null : _saveDisplayName,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text(
                          'Public Profile',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Allow others to find you in search',
                        ),
                        value: _isPublicProfile,
                        activeColor: AppColors.primary,
                        onChanged: _toggleVisibility,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionHeader('Account'),
                    _card([
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change Password'),
                        subtitle: const Text('Send a reset link to your email'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _sendPasswordReset,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.black54,
                        ),
                        title: const Text('Sign Out'),
                        onTap: _signOut,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _sectionHeader('Danger Zone'),
                    _card([
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: AppColors.error,
                        ),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Permanently remove your account and all data',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.error,
                        ),
                        onTap: _isSaving ? null : _deleteAccount,
                      ),
                    ]),
                  ],
                ),
                if (_isSaving)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black12,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

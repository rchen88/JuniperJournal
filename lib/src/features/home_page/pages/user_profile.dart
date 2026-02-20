import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/friend_request.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/friends_repo.dart';
import 'package:juniper_journal/src/features/home_page/pages/social_connections.dart';
import 'package:juniper_journal/src/services/media_service.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';

class UserProfilePage extends StatefulWidget {
  final Future<void> Function()? onSignOut;

  const UserProfilePage({super.key, this.onSignOut});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _authService = AuthService.instance;
  final _mediaService = MediaService();
  final _friendsRepo = FriendsRepo();

  String? _avatarUrl;
  String _displayName = 'User';
  String _email = '';
  bool _isPublicProfile = true;
  bool _isUploading = false;
  bool _isUpdatingVisibility = false;
  bool _isSigningOut = false;
  bool _isRequestsLoading = false;
  List<FriendRequest> _incomingRequests = const [];
  List<UserProfile> _friends = const [];
  final List<UserProfile> _followers = const [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadInitialSocialData();
  }

  Future<void> _loadInitialSocialData() async {
    setState(() => _isRequestsLoading = true);

    final requests = await _friendsRepo.getIncomingFriendRequests();
    final friends = await _friendsRepo.getFriends();
    if (!mounted) return;

    setState(() {
      _incomingRequests = requests ?? const [];
      _friends = friends ?? const [];
      _isRequestsLoading = false;
    });
  }

  void _loadUser() {
    final user = _authService.currentUser;
    final metadata = user?.userMetadata ?? {};
    final name =
        (metadata['display_name']?.toString().trim().isNotEmpty == true)
        ? metadata['display_name'].toString().trim()
        : (metadata['username']?.toString().trim().isNotEmpty == true)
        ? metadata['username'].toString().trim()
        : (user?.email?.split('@').first ?? 'User');

    setState(() {
      _displayName = name;
      _email = user?.email ?? '';
      _avatarUrl = metadata['avatar_url']?.toString();
      _isPublicProfile = metadata['is_public_profile'] as bool? ?? true;
    });
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    setState(() => _isUploading = true);

    final imageUrl = await _mediaService.pickAndUploadImage(
      source,
      folder: 'profile-images',
    );

    if (!mounted) return;

    if (imageUrl == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile image')),
      );
      return;
    }

    await _authService.updateProfile(avatarUrl: imageUrl);
    if (!mounted) return;

    setState(() {
      _avatarUrl = imageUrl;
      _isUploading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile image updated')));
  }

  void _showImageSourceSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Profile Photo'),
        message: const Text('Choose image source'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickProfileImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickProfileImage(ImageSource.gallery);
            },
            child: const Text('Choose from Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      if (widget.onSignOut != null) {
        await widget.onSignOut!.call();
      } else {
        await _authService.signOut();
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  Future<void> _loadIncomingRequests() async {
    setState(() => _isRequestsLoading = true);
    final requests = await _friendsRepo.getIncomingFriendRequests();
    if (!mounted) return;

    setState(() {
      _incomingRequests = requests ?? const <FriendRequest>[];
      _isRequestsLoading = false;
    });
  }

  Future<void> _acceptRequest(String requesterId) async {
    final ok = await _friendsRepo.acceptFriendRequest(requesterId: requesterId);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept friend request')),
      );
      return;
    }
    _loadIncomingRequests();
    _loadFriends();
  }

  Future<void> _declineRequest(String requesterId) async {
    final ok = await _friendsRepo.declineFriendRequest(
      requesterId: requesterId,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to decline friend request')),
      );
      return;
    }
    _loadIncomingRequests();
  }

  Future<void> _loadFriends() async {
    final friends = await _friendsRepo.getFriends();
    if (!mounted) return;

    setState(() {
      _friends = friends ?? const <UserProfile>[];
    });
  }

  Future<void> _openConnectionsPage(ConnectionsTab initialTab) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SocialConnectionsPage(
          friends: _friends,
          followers: _followers,
          initialTab: initialTab,
        ),
      ),
    );
  }

  Future<void> _updateVisibility(bool value) async {
    setState(() {
      _isPublicProfile = value;
      _isUpdatingVisibility = true;
    });

    final updatedUser = await _authService.updateProfile(
      isPublicProfile: value,
    );

    if (!mounted) return;

    if (updatedUser == null) {
      setState(() {
        _isPublicProfile = !value;
        _isUpdatingVisibility = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile visibility')),
      );
      return;
    }

    setState(() => _isUpdatingVisibility = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Profile is now public' : 'Profile is now private',
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.iconSecondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ?? () {},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Center(
          child: GestureDetector(
            onTap: _isUploading ? null : _showImageSourceSheet,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFFE8F4EC),
                  backgroundImage:
                      (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                      ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Color(0xFF5B7B63),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        if (_email.isNotEmpty)
          Center(
            child: Text(_email, style: const TextStyle(color: Colors.black54)),
          ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => _openConnectionsPage(ConnectionsTab.friends),
              child: Text('Friends ${_friends.length}'),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => _openConnectionsPage(ConnectionsTab.followers),
              child: Text('Followers ${_followers.length}'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'User Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              SwitchListTile.adaptive(
                secondary: const Icon(
                  Icons.public_outlined,
                  color: AppColors.iconSecondary,
                ),
                title: const Text('Public Profile'),
                subtitle: Text(
                  _isPublicProfile
                      ? 'Other users can find your profile'
                      : 'Only you can see your profile',
                  style: const TextStyle(fontSize: 12),
                ),
                value: _isPublicProfile,
                onChanged: _isUpdatingVisibility ? null : _updateVisibility,
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              _buildSettingsTile(icon: Icons.person_outline, title: 'Account'),
              Divider(height: 1, color: Colors.grey.shade200),
              _buildSettingsTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Privacy & Security',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Friend Requests',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: _isRequestsLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _incomingRequests.isEmpty
              ? const ListTile(
                  title: Text('No pending requests'),
                  subtitle: Text(
                    'When users add you, requests will appear here.',
                  ),
                )
              : Column(
                  children: _incomingRequests.map((request) {
                    final requesterId = request.requesterId;
                    final displayName =
                        request.displayName ?? request.username ?? 'Unknown User';
                    final username = request.username;
                    final avatarUrl = request.avatarUrl;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8F4EC),
                        backgroundImage:
                            (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(Icons.person, color: Color(0xFF5B7B63))
                            : null,
                      ),
                      title: Text(displayName),
                      subtitle: username != null && username.isNotEmpty
                          ? Text('@$username')
                          : null,
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          OutlinedButton(
                            onPressed: () => _declineRequest(requesterId),
                            child: const Text('Decline'),
                          ),
                          FilledButton(
                            onPressed: () => _acceptRequest(requesterId),
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _isSigningOut ? null : _handleSignOut,
          icon: _isSigningOut
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade200),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

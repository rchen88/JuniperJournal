import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/friends_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/users_repo.dart';
import 'package:juniper_journal/src/features/home_page/pages/search.dart';
import 'package:juniper_journal/src/services/media_service.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
import 'package:juniper_journal/src/shared/widgets/top_snack_bar.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, this.onProfileUpdated});

  final Future<void> Function()? onProfileUpdated;

  @override
  State<UserProfilePage> createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  final _authService = AuthService.instance;
  final _mediaService = MediaService();
  final _friendsRepo = FriendsRepo();
  final _projectsRepo = ProjectsRepo();
  final _usersRepo = UsersRepo();

  String? _avatarUrl;
  String _displayName = 'User';
  String _email = '';
  bool _isUploading = false;
  List<UserProfile> _friends = const [];
  Map<String, double> _friendPoints = {};
  double _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFriends();
    _loadAchievements();
  }

  /// Called by the parent shell whenever the Profile tab becomes active.
  void reload() {
    _loadUser();
    _loadFriends();
    _loadAchievements();
  }

  Future<void> _loadUser() async {
    final profile = await _usersRepo.getCurrentUserProfile();
    final email = _authService.currentUser?.email ?? '';
    if (!mounted) return;
    setState(() {
      _displayName = profile?.displayName?.trim().isNotEmpty == true
          ? profile!.displayName!
          : profile?.username?.trim().isNotEmpty == true
          ? '@${profile!.username}'
          : email.split('@').first;
      _email = email;
      _avatarUrl = profile?.avatarUrl;
    });
  }

  Future<void> _loadFriends() async {
    final friends = await _friendsRepo.getFriends();
    if (!mounted) return;
    setState(() => _friends = friends ?? const []);

    if (_friends.isEmpty) return;
    final points = await Future.wait(
      _friends.map((f) => _projectsRepo.getTotalEcoPointsForUser(f.id)),
    );
    if (!mounted) return;
    setState(() {
      _friendPoints = {
        for (var i = 0; i < _friends.length; i++) _friends[i].id: points[i],
      };
    });
  }

  Future<void> _deleteFriend(UserProfile friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(backgroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove friend?'),
        content: Text(
          '${friend.resolvedDisplayName} will be removed from your friends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await _friendsRepo.removeFriend(friendId: friend.id);
    if (!mounted) return;
    if (!ok) {
      showTopSnackBar(context, 'Failed to remove friend', isError: true);
      return;
    }
    _loadFriends();
  }

  Future<void> _loadAchievements() async {
    final points = await _projectsRepo.getTotalEcoPoints();
    if (!mounted) return;
    setState(() => _totalPoints = points);
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
      showTopSnackBar(context, 'Failed to upload profile image', isError: true);
      return;
    }
    await _usersRepo.updateCurrentUserProfile(avatarUrl: imageUrl);
    if (widget.onProfileUpdated != null) {
      await widget.onProfileUpdated!();
    }
    if (!mounted) return;
    setState(() {
      _avatarUrl = imageUrl;
      _isUploading = false;
    });
    showTopSnackBar(context, 'Profile image updated');
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

  // ── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _isUploading ? null : _showImageSourceSheet,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 4),
            ),
            child: ClipOval(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.avatarBackground,
                backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.avatarIcon,
                      )
                    : null,
              ),
            ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.camera_alt, size: 14, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  // ── Stats card ────────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _buildStatItem(
            Icons.star_border_outlined,
            'ECOPOINTS',
            _totalPoints.toStringAsFixed(0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildFriendsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_friends.length} Friends',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined, size: 22),
                    tooltip: 'Add friend',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeSearchScreen(),
                        ),
                      );
                      if (!mounted) return;
                      _loadFriends();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_friends.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Center(
              child: Text(
                'No friends yet.\nSearch for people to connect with!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
            ),
          )
        else
          ...List.generate(_friends.length, (index) {
            final friend = _friends[index];
            final avatarUrl = friend.avatarUrl;
            return Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.avatarBackground,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(
                            Icons.person,
                            color: AppColors.avatarIcon,
                            size: 22,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.resolvedDisplayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${(_friendPoints[friend.id] ?? 0).toStringAsFixed(0)} Points',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    onPressed: () => _deleteFriend(friend),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Layout uses a Stack so the white card can overlap the green header,
    // and the avatar can straddle their boundary.
    //
    // Green bar: 0–100px
    // White card: starts at 80px (overlaps green by 20px), rounded top
    // Avatar centre: at 100px → Positioned top: 44 (44 + 56 = 100)
    // Content padding-top: 88px (card-top 80 → avatar bottom 156 → delta 76 + 12 gap)
    return Stack(
      fit: StackFit.expand,
      children: [
        // Green top section
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(color: AppColors.primary),
        ),

        // White rounded card (main scrollable content)
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 88), // clears avatar
                  Center(
                    child: Text(
                      _displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _email.isNotEmpty ? _email : 'Member',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildFriendsContent(),
                ],
              ),
            ),
          ),
        ),

        // Avatar straddling the green/white boundary
        Positioned(
          top: 44,
          left: 0,
          right: 0,
          child: Center(child: _buildAvatar()),
        ),
      ],
    );
  }
}

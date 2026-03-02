import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/achievement.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/achievements_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/friends_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/users_repo.dart';
import 'package:juniper_journal/src/features/home_page/pages/search.dart';
import 'package:juniper_journal/src/services/media_service.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  final _authService = AuthService.instance;
  final _mediaService = MediaService();
  final _friendsRepo = FriendsRepo();
  final _achievementsRepo = AchievementsRepo();
  final _usersRepo = UsersRepo();

  String? _avatarUrl;
  String _displayName = 'User';
  String _email = '';
  bool _isUploading = false;
  List<UserProfile> _friends = const [];
  List<Achievement> _achievements = const [];
  bool _isLoadingAchievements = false;
  int _totalPoints = 0;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFriends();
    _loadAchievements();
  }

  /// Called by the parent shell whenever the Profile tab becomes active.
  void reload() {
    _loadFriends();
    _loadAchievements();
  }

  Future<void> _loadUser() async {
    final user = _authService.currentUser;
    setState(() => _email = user?.email ?? '');

    final profile = await _usersRepo.getCurrentUserProfile();
    if (!mounted) return;

    // Fall back through: profiles table → auth metadata → email prefix
    final metadata = user?.userMetadata ?? {};
    setState(() {
      _displayName = (profile?.displayName?.trim().isNotEmpty == true)
          ? profile!.displayName!.trim()
          : (profile?.username?.trim().isNotEmpty == true)
              ? profile!.username!.trim()
              : (metadata['display_name']?.toString().trim().isNotEmpty == true)
                  ? metadata['display_name'].toString().trim()
                  : (metadata['username']?.toString().trim().isNotEmpty == true)
                      ? metadata['username'].toString().trim()
                      : (user?.email?.split('@').first ?? 'User');
      _avatarUrl =
          (profile?.avatarUrl?.trim().isNotEmpty == true)
          ? profile!.avatarUrl
          : metadata['avatar_url']?.toString();
    });
  }

  Future<void> _loadFriends() async {
    final friends = await _friendsRepo.getFriends();
    if (!mounted) return;
    setState(() {
      _friends = friends ?? const [];
    });
  }

  Future<void> _deleteFriend(UserProfile friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove friend')),
      );
      return;
    }
    _loadFriends();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoadingAchievements = true);
    final results = await Future.wait([
      _achievementsRepo.getCurrentUserAchievements(),
      _achievementsRepo.getTotalPoints(),
    ]);
    if (!mounted) return;
    setState(() {
      _achievements = (results[0] as List<Achievement>?) ?? const [];
      _totalPoints = results[1] as int;
      _isLoadingAchievements = false;
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
    await Future.wait([
      _authService.updateProfile(avatarUrl: imageUrl),
      _usersRepo.updateCurrentUserProfile(avatarUrl: imageUrl),
    ]);
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
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipOval(
              child: CircleAvatar(
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
                : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
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
            '$_totalPoints',
          ),
          _buildStatDivider(),
          _buildStatItem(Icons.public_outlined, 'WORLD RANK', '—'),
          _buildStatDivider(),
          _buildStatItem(Icons.adjust, 'LOCAL RANK', '—'),
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

  Widget _buildStatDivider() =>
      Container(height: 40, width: 1, color: Colors.white38);

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabItem('Activity', 0),
          Container(width: 1, height: 22, color: Colors.grey.shade300),
          _buildTabItem('Friends', 1),
          Container(width: 1, height: 22, color: Colors.grey.shade300),
          _buildTabItem('Badge', 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedTab = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? Colors.black87 : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab content ───────────────────────────────────────────────────────────

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 1:
        return _buildFriendsContent();
      case 2:
        return _buildBadgesContent();
      default:
        return _buildActivityContent();
    }
  }

  Widget _buildActivityContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Showing last month activity',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              IconButton(
                icon: const Icon(Icons.tune, size: 20, color: Colors.black45),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (_isLoadingAchievements)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_achievements.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Center(
              child: Text(
                'No activity yet.\nStart a project to earn points!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
            ),
          )
        else
          ..._achievements.map(_buildActivityCard),
      ],
    );
  }

  Widget _buildActivityCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.occurredAt != null
                      ? _formatTimestamp(achievement.occurredAt!)
                      : '',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_upward, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    if (diff.inDays == 0) return 'Today, $h:$m $ampm';
    if (diff.inDays == 1) return 'Yesterday, $h:$m $ampm';
    return '${diff.inDays} days ago';
  }

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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE8F4EC),
                    backgroundImage:
                        (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(
                            Icons.person,
                            color: Color(0xFF5B7B63),
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
                          '0 Points',
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

  Widget _buildBadgesContent() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Text(
          'Badges coming soon!',
          style: TextStyle(color: Colors.black54, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ),
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
              color: Colors.white,
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
                  _buildTabBar(),
                  const SizedBox(height: 8),
                  _buildTabContent(),
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

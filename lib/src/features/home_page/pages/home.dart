import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/friend_request.dart';
import 'package:juniper_journal/src/backend/db/models/project.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/backend/db/repositories/friends_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/chat_repo.dart';
import 'package:juniper_journal/src/features/chat/chat.dart';
import 'package:juniper_journal/src/features/learning_module/learning_module.dart';
import 'package:juniper_journal/src/features/project/project.dart';
import 'package:juniper_journal/src/features/home_page/home_page.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _selectedIndex = 0;
  final _profileKey = GlobalKey<UserProfilePageState>();
  final ProjectsRepo _projectsRepo = ProjectsRepo();
  final FriendsRepo _friendsRepo = FriendsRepo();
  final ChatRepo _chatRepo = ChatRepo();
  int _unreadCount = 0;
  int _pendingRequestCount = 0;
  final Map<String, String> _ownerLabelByUserId = {};
  final Map<String, String?> _ownerAvatarByUserId = {};
  final Set<String> _likedProjectIds = {};
  Future<List<Project>?>? _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _loadFeedProjects();
    _loadUnreadCount();
    _loadPendingRequestCount();
  }

  Future<void> _loadPendingRequestCount() async {
    final requests = await _friendsRepo.getIncomingFriendRequests();
    if (!mounted) return;
    setState(() => _pendingRequestCount = requests?.length ?? 0);
  }

  Future<void> _showNotifications() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NotificationsSheet(friendsRepo: _friendsRepo),
    );
    if (!mounted) return;
    _loadPendingRequestCount();
  }

  Future<void> _loadUnreadCount() async {
    final conversations = await _chatRepo.getConversations();
    if (!mounted) return;
    setState(() {
      _unreadCount =
          conversations?.fold<int>(0, (sum, c) => sum + c.unreadCount) ?? 0;
    });
  }

  Future<void> _refreshProjects() async {
    final nextFuture = _loadFeedProjects();
    setState(() {
      _projectsFuture = nextFuture;
    });
    await nextFuture;
  }

  Future<List<Project>?> _loadFeedProjects() async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) return [];

    final friends = await _friendsRepo.getFriends();
    if (friends == null) return null;

    _ownerLabelByUserId
      ..clear()
      ..[currentUserId] = 'You';
    _ownerAvatarByUserId
      ..clear()
      ..[currentUserId] = AuthService
          .instance
          .currentUser
          ?.userMetadata?['avatar_url']
          ?.toString();
    final ownerIds = <String>{currentUserId};

    for (final friend in friends) {
      if (friend.id.isEmpty) continue;
      ownerIds.add(friend.id);
      final displayName = friend.displayName?.trim();
      final username = friend.username?.trim();
      _ownerLabelByUserId[friend.id] =
          (displayName != null && displayName.isNotEmpty)
          ? displayName
          : (username != null && username.isNotEmpty ? '@$username' : 'Friend');
      final avatarUrl = friend.avatarUrl?.trim();
      _ownerAvatarByUserId[friend.id] =
          (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null;
    }

    final projects = await _projectsRepo.getProjectsForFeed(ownerIds: ownerIds.toList());
    if (projects != null && projects.isNotEmpty) {
      final liked = await _projectsRepo.getLikedProjectIds(
        projectIds: projects.map((p) => p.id).toList(),
      );
      _likedProjectIds
        ..clear()
        ..addAll(liked);
    }
    return projects;
  }

  String _tabTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Explore';
      case 2:
        return 'Resources';
      case 3:
        return 'Profile';
      default:
        return 'Home';
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const JuniperAuthScreen()),
      (route) => false,
    );
  }

  Future<void> _openSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeSearchScreen()),
    );
    if (!mounted) return;
    _refreshProjects();
  }

  // Shows bottom sheet with create options
  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create New',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              _CreateOption(
                icon: Icons.school_outlined,
                title: 'Learning Module',
                subtitle: 'Create a new educational module',
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateTemplateScreen(),
                    ),
                  );
                  if (!mounted) return;
                  _refreshProjects();
                },
              ),
              const SizedBox(height: 12),
              _CreateOption(
                icon: Icons.assignment_outlined,
                title: 'Project Template',
                subtitle: 'Create a new project submission',
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateProjectScreen(),
                    ),
                  );
                  if (!mounted) return;
                  _refreshProjects();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------- Floating "+" Button ----------
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 72,
        width: 72,
        child: FloatingActionButton(
          elevation: 4,
          shape: const CircleBorder(),
          backgroundColor: AppColors.submitButton,
          onPressed: _showCreateOptions,
          child: const Icon(Icons.add, size: 32),
        ),
      ),

      // ---------- Bottom Navigation ----------
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavIcon(
                icon: Icons.home_outlined,
                isActive: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _BottomNavIcon(
                icon: Icons.landscape_outlined,
                isActive: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              const SizedBox(width: 40), // space for notch
              _BottomNavIcon(
                icon: Icons.article_outlined,
                isActive: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _BottomNavIcon(
                icon: Icons.person_outline,
                isActive: _selectedIndex == 3,
                onTap: () {
                  setState(() => _selectedIndex = 3);
                  _profileKey.currentState?.reload();
                },
              ),
            ],
          ),
        ),
      ),

      // ---------- BODY ----------
      body: SafeArea(
        // On the profile tab the green bar extends into the status-bar area,
        // so we disable the top safe-area inset and add it manually below.
        top: _selectedIndex != 3,
        child: Column(
          children: [
            // ---------- FIXED TOP BAR ----------
            Container(
              color: _selectedIndex == 3 ? AppColors.primary : null,
              padding: EdgeInsets.fromLTRB(
                16.0,
                _selectedIndex == 3
                    ? MediaQuery.of(context).padding.top + 8
                    : 8,
                16.0,
                8,
              ),
              child: _selectedIndex == 3
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Settings',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: _handleSignOut,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: _openSearch,
                              icon: const Icon(Icons.search, size: 28),
                            ),
                          ),
                        ),
                        Text(
                          _tabTitle(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: _showNotifications,
                                  icon: Badge(
                                    isLabelVisible: _pendingRequestCount > 0,
                                    label: Text(
                                      '$_pendingRequestCount',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ChatsListScreen(),
                                      ),
                                    );
                                    if (!mounted) return;
                                    _loadUnreadCount();
                                  },
                                  icon: Badge(
                                    isLabelVisible: _unreadCount > 0,
                                    label: Text(
                                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildProjectsSection(),
                  const _ComingSoonPlaceholder(),
                  const _ComingSoonPlaceholder(),
                  UserProfilePage(key: _profileKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsSection() {
    final projectsFuture =
        _projectsFuture ?? (_projectsFuture = _loadFeedProjects());

    return FutureBuilder<List<Project>?>(
      future: projectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _ProjectsMessage(
            title: 'Unable to load projects',
            subtitle: 'Pull to refresh and try again.',
            onRefresh: _refreshProjects,
          );
        }

        final projects = snapshot.data!;
        if (projects.isEmpty) {
          return _ProjectsMessage(
            title: 'No projects yet',
            subtitle: 'Tap + to create your first project.',
            onRefresh: _refreshProjects,
          );
        }

        final currentUserId = AuthService.instance.currentUser?.id;
        return RefreshIndicator(
          onRefresh: _refreshProjects,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = projects[index];
              final projectId = project.id;
              final projectName = project.projectName.trim().isNotEmpty
                  ? project.projectName.trim()
                  : 'Untitled Project';
              final tags = project.tags;
              final imageUrl = project.imageUrl;
              final ownerId = project.userId;
              final isOwner = ownerId != null && ownerId == currentUserId;
              final ownerLabel = ownerId == null
                  ? null
                  : _ownerLabelByUserId[ownerId];
              final ownerAvatarUrl = ownerId == null
                  ? null
                  : _ownerAvatarByUserId[ownerId];

              return _ProjectCard(
                projectId: projectId,
                name: projectName,
                ownerLabel: ownerLabel,
                ownerAvatarUrl: ownerAvatarUrl,
                tags: tags,
                imageUrl: imageUrl,
                description: project.problemStatement,
                initialLikes: project.likes,
                initialHasLiked: _likedProjectIds.contains(projectId),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDashboard(
                        projectId: projectId,
                        projectName: projectName,
                        tags: tags,
                        isOwner: isOwner,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  _refreshProjects();
                },
              );
            },
          ),
        );
      },
    );
  }

}

class _ComingSoonPlaceholder extends StatelessWidget {
  const _ComingSoonPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Coming soon',
        style: TextStyle(color: Colors.black54, fontSize: 16),
      ),
    );
  }
}

// Simple widget for bottom icons
class _BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Icon(icon, size: 28, color: isActive ? AppColors.submitButton : Colors.black54),
      ),
    );
  }
}

// Widget for create option in bottom sheet
class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.submitButton.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.submitButton, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final String projectId;
  final String name;
  final String? ownerLabel;
  final String? ownerAvatarUrl;
  final List<String> tags;
  final String? imageUrl;
  final String? description;
  final int initialLikes;
  final bool initialHasLiked;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.projectId,
    required this.name,
    required this.ownerLabel,
    required this.ownerAvatarUrl,
    required this.tags,
    required this.imageUrl,
    required this.onTap,
    this.description,
    this.initialLikes = 0,
    this.initialHasLiked = false,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  final ProjectsRepo _projectsRepo = ProjectsRepo();
  late int _likes;
  bool _hasLiked = false;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.initialLikes;
    _hasLiked = widget.initialHasLiked;
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;
    _isLiking = true;

    final prevLikes = _likes;
    final prevHasLiked = _hasLiked;

    setState(() {
      _hasLiked = !_hasLiked;
      _likes = _hasLiked ? prevLikes + 1 : prevLikes - 1;
    });

    final ok = _hasLiked
        ? await _projectsRepo.likeProject(id: widget.projectId)
        : await _projectsRepo.unlikeProject(id: widget.projectId);

    if (!mounted) return;
    setState(() {
      _isLiking = false;
      if (!ok) {
        _hasLiked = prevHasLiked;
        _likes = prevLikes;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty)
                    ? Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultBanner(),
                      )
                    : _buildDefaultBanner(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (widget.ownerLabel != null && widget.ownerLabel!.trim().isNotEmpty) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFE6E8EC),
                    backgroundImage:
                        (widget.ownerAvatarUrl != null &&
                            widget.ownerAvatarUrl!.trim().isNotEmpty)
                        ? NetworkImage(widget.ownerAvatarUrl!)
                        : null,
                    child:
                        (widget.ownerAvatarUrl == null ||
                            widget.ownerAvatarUrl!.trim().isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 14,
                            color: Color(0xFF4A4A4A),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.ownerLabel == 'You' ? 'by You' : 'by ${widget.ownerLabel}',
                    style: const TextStyle(
                      color: Color(0xFF1F2328),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: _handleLike,
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_florist,
                        size: 22,
                        color: _hasLiked ? const Color(0xFF2A7A38) : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_likes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _hasLiked ? const Color(0xFF2A7A38) : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 22,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (widget.description != null && widget.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.description!.trim(),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            if (widget.tags.isEmpty)
              const Text(
                'No tags',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.submitButton.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Color(0xFF2A7A38),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE4F5E8), Color(0xFFD2EAD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 30,
          color: Color(0xFF5A7A62),
        ),
      ),
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  final FriendsRepo friendsRepo;

  const _NotificationsSheet({required this.friendsRepo});

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  bool _isLoading = true;
  List<FriendRequest> _requests = const [];
  final Map<String, bool> _loadingByUserId = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final result = await widget.friendsRepo.getIncomingFriendRequests();
    if (!mounted) return;
    setState(() {
      _requests = result ?? [];
      _isLoading = false;
    });
  }

  Future<void> _accept(FriendRequest request) async {
    setState(() => _loadingByUserId[request.requesterId] = true);
    final ok = await widget.friendsRepo.acceptFriendRequest(
      requesterId: request.requesterId,
    );
    if (!mounted) return;
    setState(() => _loadingByUserId.remove(request.requesterId));
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to accept request')),
      );
      return;
    }
    _loadRequests();
  }

  Future<void> _decline(FriendRequest request) async {
    setState(() => _loadingByUserId[request.requesterId] = true);
    final ok = await widget.friendsRepo.declineFriendRequest(
      requesterId: request.requesterId,
    );
    if (!mounted) return;
    setState(() => _loadingByUserId.remove(request.requesterId));
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to decline request')),
      );
      return;
    }
    _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Friend Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_requests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No pending friend requests.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ..._requests.map((request) {
              final isActionLoading =
                  _loadingByUserId[request.requesterId] == true;
              final displayName =
                  (request.displayName?.trim().isNotEmpty == true)
                  ? request.displayName!.trim()
                  : (request.username?.trim().isNotEmpty == true
                      ? '@${request.username!.trim()}'
                      : 'User');
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE6F2E9),
                  backgroundImage:
                      (request.avatarUrl != null &&
                          request.avatarUrl!.isNotEmpty)
                      ? NetworkImage(request.avatarUrl!)
                      : null,
                  child:
                      (request.avatarUrl == null || request.avatarUrl!.isEmpty)
                      ? const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: isActionLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () => _decline(request),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            child: const Text('Decline'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () => _accept(request),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            child: const Text('Accept'),
                          ),
                        ],
                      ),
              );
            }),
        ],
      ),
    );
  }
}

class _ProjectsMessage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;

  const _ProjectsMessage({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(subtitle, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

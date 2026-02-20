import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/project.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/backend/db/repositories/friends_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
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
  final ProjectsRepo _projectsRepo = ProjectsRepo();
  final FriendsRepo _friendsRepo = FriendsRepo();
  final Map<String, String> _ownerLabelByUserId = {};
  final Map<String, String?> _ownerAvatarByUserId = {};
  Future<List<Project>?>? _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _loadFeedProjects();
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

    return _projectsRepo.getProjectsForFeed(ownerIds: ownerIds.toList());
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
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),

      // ---------- BODY ----------
      body: SafeArea(
        child: Column(
          children: [
            // ---------- FIXED TOP BAR ----------
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _openSearch,
                    icon: const Icon(Icons.search, size: 28),
                  ),
                  Text(
                    _tabTitle(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, size: 26),
                  ),
                ],
              ),
            ),

            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildProjectsSection(),
                  const Center(
                    child: Text(
                      'Coming soon',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Coming soon',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ),
                  UserProfilePage(onSignOut: _handleSignOut),
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
              final currentUserId = AuthService.instance.currentUser?.id;
              final isOwner = ownerId != null && ownerId == currentUserId;
              final ownerLabel = ownerId == null
                  ? null
                  : _ownerLabelByUserId[ownerId];
              final ownerAvatarUrl = ownerId == null
                  ? null
                  : _ownerAvatarByUserId[ownerId];

              return _ProjectCard(
                name: projectName,
                ownerLabel: ownerLabel,
                ownerAvatarUrl: ownerAvatarUrl,
                tags: tags,
                imageUrl: imageUrl,
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

class _ProjectCard extends StatelessWidget {
  final String name;
  final String? ownerLabel;
  final String? ownerAvatarUrl;
  final List<String> tags;
  final String? imageUrl;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.name,
    required this.ownerLabel,
    required this.ownerAvatarUrl,
    required this.tags,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                child: (imageUrl != null && imageUrl!.trim().isNotEmpty)
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultBanner(),
                      )
                    : _buildDefaultBanner(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (ownerLabel != null && ownerLabel!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFFE6E8EC),
                    backgroundImage:
                        (ownerAvatarUrl != null &&
                            ownerAvatarUrl!.trim().isNotEmpty)
                        ? NetworkImage(ownerAvatarUrl!)
                        : null,
                    child:
                        (ownerAvatarUrl == null ||
                            ownerAvatarUrl!.trim().isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 12,
                            color: Color(0xFF4A4A4A),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ownerLabel == 'You' ? 'by You' : 'by $ownerLabel',
                    style: const TextStyle(
                      color: Color(0xFF1F2328),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            if (tags.isEmpty)
              const Text(
                'No tags',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
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

import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/bulletin_post.dart';
import 'package:juniper_journal/src/backend/db/models/community.dart';
import 'package:juniper_journal/src/backend/db/models/design_challenge.dart';
import 'package:juniper_journal/src/backend/db/models/project.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/challenges_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/chat_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/communities_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/users_repo.dart';
import 'package:juniper_journal/src/features/chat/pages/chat_screen.dart';
import 'package:juniper_journal/src/features/community/pages/bulletin_comments_sheet.dart';
import 'package:juniper_journal/src/features/community/pages/bulletin_post_form.dart';
import 'package:juniper_journal/src/features/community/pages/challenge_detail_screen.dart';
import 'package:juniper_journal/src/features/community/pages/challenge_type_picker.dart';
import 'package:juniper_journal/src/features/community/pages/community_settings_screen.dart';
import 'package:juniper_journal/src/features/project/project.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/widgets/project_filter_sheet.dart';
import 'package:juniper_journal/src/shared/widgets/top_snack_bar.dart';

// ── CommunityHomeScreen ───────────────────────────────────────────────────────

class CommunityHomeScreen extends StatefulWidget {
  final Community community;

  const CommunityHomeScreen({super.key, required this.community});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabCtrl;

  final _communitiesRepo = CommunitiesRepo();
  final _projectsRepo = ProjectsRepo();
  final _usersRepo = UsersRepo();
  final _chatRepo = ChatRepo();

  // Projects data
  List<Project> _projects = [];
  List<Project> _filtered = [];
  bool _isLoading = true;

  // Owner info cache
  final Map<String, String> _ownerLabels = {};
  final Map<String, String?> _ownerAvatars = {};
  final Map<String, List<UserProfile>> _collaborators = {};
  final Set<String> _likedIds = {};
  final Set<String> _bookmarkedIds = {};

  // Chat
  int _chatUnread = 0;

  // Search + filters (Projects tab)
  final _searchCtrl = TextEditingController();
  Set<String> _subjectFilter = {};
  Set<String> _phaseFilter = {};
  Set<String> _scaleFilter = {};
  Set<String> _difficultyFilter = {};
  bool _showBookmarkedOnly = false;

  late Community _community;
  final _bulletinKey = GlobalKey<_BulletinTabContentState>();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _community = widget.community;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
        _loadChatUnread();
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Reinitialize after hot reload if the mixin wasn't active before.
    _tabCtrl ??= TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChatUnread() async {
    final convId = _community.conversationId;
    if (convId == null) return;
    final count = await _chatRepo.getUnreadCount(convId);
    if (mounted) setState(() => _chatUnread = count);
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final projects =
        await _communitiesRepo.getCommunityProjects(_community.id);

    if (!mounted) return;

    final ownerIds =
        projects.map((p) => p.userId).whereType<String>().toSet().toList();
    if (ownerIds.isNotEmpty) {
      try {
        final profiles = await _usersRepo.getProfilesByIds(ownerIds);
        for (final p in profiles) {
          final displayName = p.displayName?.trim();
          final username = p.username?.trim();
          _ownerLabels[p.id] = (displayName != null && displayName.isNotEmpty)
              ? displayName
              : (username != null && username.isNotEmpty
                  ? '@$username'
                  : 'User');
          _ownerAvatars[p.id] =
              (p.avatarUrl?.trim().isNotEmpty == true) ? p.avatarUrl : null;
        }
      } catch (_) {}
    }

    if (projects.isNotEmpty) {
      final ids = projects.map((p) => p.id).toList();

      final liked = await _projectsRepo.getLikedProjectIds(projectIds: ids);
      _likedIds
        ..clear()
        ..addAll(liked);

      final bookmarked =
          await _projectsRepo.getBookmarkedProjectIds(projectIds: ids);
      _bookmarkedIds
        ..clear()
        ..addAll(bookmarked);

      final collabMap = await _projectsRepo.getCollaboratorsForProjects(
        projectIds: projects.map((p) => p.id).toList(),
      );
      _collaborators
        ..clear()
        ..addAll(collabMap);
    }

    setState(() {
      _projects = projects;
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = _projects.where((p) {
      if (_showBookmarkedOnly && !_bookmarkedIds.contains(p.id)) return false;
      if (q.isNotEmpty && !p.projectName.toLowerCase().contains(q)) {
        return false;
      }
      if (_subjectFilter.isNotEmpty &&
          !_subjectFilter.contains(p.subjectDomain)) {
        return false;
      }
      if (_phaseFilter.isNotEmpty && !_phaseFilter.contains(p.progress)) {
        return false;
      }
      if (_scaleFilter.isNotEmpty &&
          !_scaleFilter.contains(p.projectScale)) {
        return false;
      }
      if (_difficultyFilter.isNotEmpty &&
          !_difficultyFilter.contains(p.difficulty)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunitySettingsScreen(community: _community),
      ),
    );
    if (!mounted) return;
    if (result == 'deleted') {
      Navigator.of(context).pop();
    } else if (result is Community) {
      setState(() => _community = result);
    }
  }

  Future<void> _openChat() async {
    final convId = _community.conversationId;
    if (convId == null) {
      showTopSnackBar(context, 'Chat not available yet');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convId,
          otherUserName: _community.name,
          otherAvatarUrl: _community.imageUrl,
          isGroup: true,
        ),
      ),
    );
    if (mounted) _loadChatUnread();
  }

  void _showFilterSheet({
    required String title,
    required List<FilterOption> options,
    required Set<String> selected,
    required void Function(Set<String>) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectFilterSheet(
        title: title,
        options: options,
        initialSelected: Set.from(selected),
        onApply: onApply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerColor = _community.bannerColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: bannerColor,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: _chatUnread > 0,
                  label: Text(
                    _chatUnread > 99 ? '99+' : '$_chatUnread',
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white, size: 22),
                ),
                onPressed: _openChat,
              ),
              if (_community.createdBy ==
                  AuthService.instance.currentUser?.id)
                IconButton(
                  icon: const Icon(Icons.more_horiz,
                      color: Colors.white, size: 22),
                  onPressed: _openSettings,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 54),
              title: Text(
                _community.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: bannerColor),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.2),
                      backgroundImage: (_community.imageUrl != null &&
                              _community.imageUrl!.isNotEmpty)
                          ? NetworkImage(_community.imageUrl!)
                          : null,
                      child: (_community.imageUrl == null ||
                              _community.imageUrl!.isEmpty)
                          ? const Icon(Icons.group,
                              size: 26, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl!,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Bulletin'),
                Tab(text: 'Projects'),
                Tab(text: 'Challenges'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl!,
          children: [
            _BulletinTabContent(key: _bulletinKey, communityId: _community.id),
            _buildProjectsTab(),
            _ChallengesTabContent(communityId: _community.id),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          elevation: 4,
          shape: const CircleBorder(),
          backgroundColor: AppColors.primary,
          onPressed: () => _showCreateOptions(context),
          child: const Icon(Icons.add, size: 30),
        ),
      ),
    );
  }

  // ── Projects tab ────────────────────────────────────────────────────────────

  Widget _buildProjectsTab() {
    final currentUserId = AuthService.instance.currentUser?.id;
    return Column(
      children: [
        // Search row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceInput,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(_applyFilters),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search projects',
                      hintStyle: TextStyle(
                          color: AppColors.hintText, fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: AppColors.textSecondary, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() {
                  _showBookmarkedOnly = !_showBookmarkedOnly;
                  _applyFilters();
                }),
                child: Icon(
                  _showBookmarkedOnly
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: _showBookmarkedOnly
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              const Text('Filter',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 10),
              _filterChip('SUBJECT', _subjectFilter, () {
                _showFilterSheet(
                  title: 'Subject',
                  options: kSubjectOptions,
                  selected: _subjectFilter,
                  onApply: (val) =>
                      setState(() {
                        _subjectFilter = val;
                        _applyFilters();
                      }),
                );
              }),
              _filterChip('PHASE', _phaseFilter, () {
                _showFilterSheet(
                  title: 'Phases',
                  options: kPhaseOptions,
                  selected: _phaseFilter,
                  onApply: (val) =>
                      setState(() {
                        _phaseFilter = val;
                        _applyFilters();
                      }),
                );
              }),
              _filterChip('SCALE', _scaleFilter, () {
                _showFilterSheet(
                  title: 'Scale',
                  options: kScaleOptions,
                  selected: _scaleFilter,
                  onApply: (val) =>
                      setState(() {
                        _scaleFilter = val;
                        _applyFilters();
                      }),
                );
              }),
              _filterChip('DIFFICULTY', _difficultyFilter, () {
                _showFilterSheet(
                  title: 'Difficulty',
                  options: kDifficultyOptions,
                  selected: _difficultyFilter,
                  onApply: (val) =>
                      setState(() {
                        _difficultyFilter = val;
                        _applyFilters();
                      }),
                );
              }),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.divider),

        // Project list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _projects.isEmpty
                            ? 'No projects yet'
                            : _showBookmarkedOnly
                                ? 'No bookmarked projects'
                                : 'No projects match your filters',
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final project = _filtered[i];
                          final ownerId = project.userId;
                          final isOwner = ownerId == currentUserId;
                          return _CommunityProjectCard(
                            project: project,
                            ownerLabel: ownerId != null
                                ? _ownerLabels[ownerId]
                                : null,
                            ownerAvatarUrl: ownerId != null
                                ? _ownerAvatars[ownerId]
                                : null,
                            collaborators:
                                _collaborators[project.id] ?? [],
                            initialLikes: project.likes,
                            initialHasLiked:
                                _likedIds.contains(project.id),
                            initialIsBookmarked:
                                _bookmarkedIds.contains(project.id),
                            onBookmarkChanged: (isBookmarked) {
                              setState(() {
                                if (isBookmarked) {
                                  _bookmarkedIds.add(project.id);
                                } else {
                                  _bookmarkedIds.remove(project.id);
                                }
                                _applyFilters();
                              });
                            },
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => ProjectDashboard(
                                  projectId: project.id,
                                  projectName: project.projectName,
                                  tags: project.tags,
                                  isOwner: isOwner,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip(
      String label, Set<String> activeFilter, VoidCallback onTap) {
    final active = activeFilter.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.primaryTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ── FAB actions ─────────────────────────────────────────────────────────────

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                const Text('Create',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(sheetCtx),
                    child: const Icon(Icons.close,
                        size: 22, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CreateTile(
                  icon: Icons.forum_outlined,
                  label: 'BULLETIN POST',
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final posted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BulletinPostForm(
                            communityId: _community.id),
                      ),
                    );
                    if (posted == true) {
                      _bulletinKey.currentState?._load();
                      _tabCtrl?.animateTo(0);
                    }
                  },
                ),
                _CreateTile(
                  icon: Icons.emoji_events_outlined,
                  label: 'DESIGN CHALLENGE',
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChallengeTypePicker(
                            communityId: _community.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _BulletinTabContent ───────────────────────────────────────────────────────

Color _categoryColor(String category) {
  switch (category) {
    case 'Design Feedback':
      return const Color(0xFF2C70BF);
    case 'Build & Materials':
      return const Color(0xFFD97706);
    case 'Impact & Measurement':
      return const Color(0xFF059669);
    case 'Question / Help':
      return const Color(0xFF7C3AED);
    case 'Collaboration':
      return const Color(0xFFDB2777);
    case 'Project Share':
      return const Color(0xFF0891B2);
    default: // Idea / Brainstorm
      return AppColors.primaryDark;
  }
}

class _BulletinTabContent extends StatefulWidget {
  final String communityId;

  const _BulletinTabContent({super.key, required this.communityId});

  @override
  State<_BulletinTabContent> createState() => _BulletinTabContentState();
}

class _BulletinTabContentState extends State<_BulletinTabContent> {
  final _repo = CommunitiesRepo();
  List<BulletinPost> _posts = [];
  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthService.instance.currentUser?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final posts = await _repo.getBulletinPosts(widget.communityId);
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined,
                size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Be the first to start a discussion',
              style: TextStyle(fontSize: 13, color: AppColors.hintText),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _posts.length,
        itemBuilder: (_, i) => _BulletinPostCard(
          post: _posts[i],
          communityId: widget.communityId,
          currentUserId: _currentUserId,
          onDeleted: (id) =>
              setState(() => _posts.removeWhere((p) => p.id == id)),
          onEdited: (_) => _load(),
        ),
      ),
    );
  }
}

// ── _BulletinPostCard ─────────────────────────────────────────────────────────

class _BulletinPostCard extends StatefulWidget {
  final BulletinPost post;
  final String communityId;
  final String? currentUserId;
  final void Function(String postId) onDeleted;
  final void Function(BulletinPost updated) onEdited;

  const _BulletinPostCard({
    required this.post,
    required this.communityId,
    required this.currentUserId,
    required this.onDeleted,
    required this.onEdited,
  });

  @override
  State<_BulletinPostCard> createState() => _BulletinPostCardState();
}

class _BulletinPostCardState extends State<_BulletinPostCard> {
  final _repo = CommunitiesRepo();
  bool _expanded = false;
  late int _commentCount;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.post.commentCount;
  }

  @override
  void didUpdateWidget(_BulletinPostCard old) {
    super.didUpdateWidget(old);
    if (old.post.commentCount != widget.post.commentCount) {
      _commentCount = widget.post.commentCount;
    }
  }

  bool get _isOwn => widget.currentUserId == widget.post.userId;

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppColors.textPrimary),
              title: const Text('Edit Post',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BulletinPostForm(
                      communityId: widget.communityId,
                      editPost: widget.post,
                    ),
                  ),
                );
                if (saved == true) {
                  widget.onEdited(widget.post); // triggers parent to reload
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Post',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _repo.deleteBulletinPost(widget.post.id);
                if (ok && mounted) {
                  widget.onDeleted(widget.post.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BulletinCommentsSheet(
        postId: widget.post.id,
        postTitle: widget.post.title,
        initialCommentCount: _commentCount,
        onCountChanged: (n) => setState(() => _commentCount = n),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final catColor = _categoryColor(post.category);
    final hasPhotos = post.imageUrls.isNotEmpty;
    final formattedDate = _formatDate(post.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photos (at the very top, full-bleed) ─────────────────────
          if (hasPhotos) _buildPhotosGrid(post.imageUrls),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Author row ──────────────────────────────────────────
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage:
                          (post.authorAvatarUrl?.trim().isNotEmpty == true)
                              ? NetworkImage(post.authorAvatarUrl!)
                              : null,
                      child:
                          (post.authorAvatarUrl?.trim().isNotEmpty != true)
                              ? const Icon(Icons.person_outline,
                                  size: 14, color: AppColors.primary)
                              : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.authorLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isOwn)
                      GestureDetector(
                        onTap: _showMenu,
                        child: const Icon(Icons.more_horiz,
                            color: AppColors.textSecondary, size: 22),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Title + category chip ───────────────────────────────
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        post.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Body (collapsible) ──────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        post.body,
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),

          // ── Footer ─────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Icon(Icons.local_florist_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                const Text('0',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: _openComments,
                  child: const Icon(Icons.chat_bubble_outline,
                      size: 18, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _openComments,
                  child: Text(
                    '$_commentCount',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(List<String> urls) {
    if (urls.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(urls[0], fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryTint,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.primary))),
      );
    }
    // 2+ images: side-by-side pair (show max 2)
    final show = urls.take(2).toList();
    final extra = urls.length - 2;
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.network(show[0], fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.primaryTint)),
          ),
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(show[1], fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.primaryTint)),
              if (extra > 0)
                Container(
                  color: Colors.black45,
                  child: Center(
                    child: Text(
                      '+$extra',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }
}

// ── _ChallengesTabContent ─────────────────────────────────────────────────────

class _ChallengesTabContent extends StatefulWidget {
  final String communityId;

  const _ChallengesTabContent({required this.communityId});

  @override
  State<_ChallengesTabContent> createState() => _ChallengesTabContentState();
}

class _ChallengesTabContentState extends State<_ChallengesTabContent> {
  final _repo = ChallengesRepo();
  List<DesignChallenge> _all = [];
  List<DesignChallenge> _filtered = [];
  final _searchCtrl = TextEditingController();
  Set<String> _typeFilter = {};
  bool _loading = true;

  static const _filterOptions = [
    ('pattern_change', 'PATTERN'),
    ('community_impact', 'COMMUNITY IMPACT'),
    ('build_and_create', 'BUILD & CREATE'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final challenges =
        await _repo.getCommunityChallenges(widget.communityId);
    if (!mounted) return;
    setState(() {
      _all = challenges;
      _loading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = _all.where((c) {
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
      if (_typeFilter.isNotEmpty && !_typeFilter.contains(c.type)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(_applyFilters),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search design challenges',
                hintStyle: TextStyle(color: AppColors.hintText, fontSize: 14),
                prefixIcon: Icon(Icons.search,
                    color: AppColors.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Type filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              const Text('Filter',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 10),
              ..._filterOptions.map((opt) {
                final isActive = _typeFilter.contains(opt.$1);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isActive) {
                      _typeFilter.remove(opt.$1);
                    } else {
                      _typeFilter.add(opt.$1);
                    }
                    _applyFilters();
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.divider),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _all.isEmpty
                            ? 'No challenges yet'
                            : 'No challenges match your search',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _ChallengeCard(
                          challenge: _filtered[i],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChallengeDetailScreen(
                                    challenge: _filtered[i]),
                              ),
                            );
                            _load();
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── _ChallengeCard ────────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final DesignChallenge challenge;
  final VoidCallback onTap;

  const _ChallengeCard({required this.challenge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final avatars = c.participantAvatars.take(4).toList();
    final extra = c.participantCount - avatars.length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: Colors.white.withValues(alpha: 0.2),
                child: (c.imageUrl?.isNotEmpty == true)
                    ? Image.network(c.imageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.emoji_events_outlined,
                        size: 24, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(c.typeLabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (c.dateRange.isNotEmpty)
                        Expanded(
                          child: Text(c.dateRange,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white
                                      .withValues(alpha: 0.75))),
                        ),
                      // Avatar stack
                      if (avatars.isNotEmpty)
                        SizedBox(
                          height: 22,
                          width: (avatars.length * 16 + 10).toDouble(),
                          child: Stack(
                            children: avatars.asMap().entries.map((e) {
                              return Positioned(
                                left: e.key * 16.0,
                                child: CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      e.value.isNotEmpty
                                          ? NetworkImage(e.value)
                                          : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      if (extra > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'More...',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white
                                    .withValues(alpha: 0.8)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _CreateTile ───────────────────────────────────────────────────────────────

class _CreateTile extends StatelessWidget {
  const _CreateTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              border:
                  Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

// ── _CommunityProjectCard ─────────────────────────────────────────────────────

class _CommunityProjectCard extends StatefulWidget {
  final Project project;
  final String? ownerLabel;
  final String? ownerAvatarUrl;
  final List<UserProfile> collaborators;
  final int initialLikes;
  final bool initialHasLiked;
  final bool initialIsBookmarked;
  final void Function(bool isBookmarked) onBookmarkChanged;
  final VoidCallback onTap;

  const _CommunityProjectCard({
    required this.project,
    this.ownerLabel,
    this.ownerAvatarUrl,
    required this.collaborators,
    required this.initialLikes,
    required this.initialHasLiked,
    required this.initialIsBookmarked,
    required this.onBookmarkChanged,
    required this.onTap,
  });

  @override
  State<_CommunityProjectCard> createState() => _CommunityProjectCardState();
}

class _CommunityProjectCardState extends State<_CommunityProjectCard> {
  final _projectsRepo = ProjectsRepo();
  int _likes = 0;
  bool _hasLiked = false;
  bool _isBookmarked = false;
  bool _isLiking = false;
  bool _isBookmarking = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.initialLikes;
    _hasLiked = widget.initialHasLiked;
    _isBookmarked = widget.initialIsBookmarked;
  }

  @override
  void didUpdateWidget(_CommunityProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIsBookmarked != widget.initialIsBookmarked &&
        !_isBookmarking) {
      _isBookmarked = widget.initialIsBookmarked;
    }
  }

  Future<void> _handleBookmark() async {
    if (_isBookmarking) return;
    _isBookmarking = true;
    final prev = _isBookmarked;
    setState(() => _isBookmarked = !_isBookmarked);
    final ok = _isBookmarked
        ? await _projectsRepo.bookmarkProject(id: widget.project.id)
        : await _projectsRepo.unbookmarkProject(id: widget.project.id);
    if (!mounted) return;
    setState(() {
      _isBookmarking = false;
      if (!ok) _isBookmarked = prev;
    });
    if (ok) widget.onBookmarkChanged(_isBookmarked);
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
        ? await _projectsRepo.likeProject(id: widget.project.id)
        : await _projectsRepo.unlikeProject(id: widget.project.id);
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
    final p = widget.project;
    final entryCount = p.journalEntryCount;

    // Build member avatar stack (owner + up to 2 collabs)
    final avatarUrls = <String?>[];
    avatarUrls.add(widget.ownerAvatarUrl);
    for (final c in widget.collaborators.take(2)) {
      avatarUrls.add(c.avatarUrl?.trim().isNotEmpty == true
          ? c.avatarUrl
          : null);
    }

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                    ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.projectName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleBookmark,
                        child: Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 20,
                          color: _isBookmarked
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Member avatars
                      SizedBox(
                        width: 29.0 + (avatarUrls.length - 1) * 18,
                        height: 29,
                        child: Stack(
                          children: [
                            for (var i = 0;
                                i < avatarUrls.length;
                                i++)
                              Positioned(
                                left: i * 18.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white,
                                        width: 1.5),
                                  ),
                                  child: CircleAvatar(
                                    radius: 13,
                                    backgroundColor:
                                        AppColors.primary
                                            .withValues(alpha: 0.12),
                                    backgroundImage:
                                        (avatarUrls[i] != null)
                                            ? NetworkImage(
                                                avatarUrls[i]!)
                                            : null,
                                    child: avatarUrls[i] == null
                                        ? const Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: AppColors.primary)
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Entry count
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          size: 13,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '$entryCount ${entryCount == 1 ? 'Journal Entry' : 'Journal Entries'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Likes + comments
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _handleLike,
                        child: Row(
                          children: [
                            Icon(Icons.local_florist,
                                size: 18,
                                color: _hasLiked
                                    ? AppColors.primary
                                    : Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text(
                              '$_likes',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: _hasLiked
                                      ? AppColors.primary
                                      : Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => CommentsSheet(
                            projectId: p.id,
                            projectName: p.projectName,
                            description: p.problemStatement,
                          ),
                        ),
                        child: Icon(Icons.chat_bubble_outline,
                            size: 18,
                            color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryTint, Color(0xFFD2EAD8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.landscape_outlined,
              size: 30, color: AppColors.avatarIcon),
        ),
      );
}

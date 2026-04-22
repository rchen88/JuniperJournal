import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/db/models/design_challenge.dart';
import 'package:juniper_journal/src/backend/db/models/project.dart';
import 'package:juniper_journal/src/backend/db/repositories/challenges_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/features/community/pages/challenge_detail_screen.dart';
import 'package:juniper_journal/src/features/project/project.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/widgets/project_filter_sheet.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabCtrl;
  final _searchCtrl = TextEditingController();
  final _challengeSearchCtrl = TextEditingController();
  final _projectsRepo = ProjectsRepo();
  final _challengesRepo = ChallengesRepo();

  List<Project> _projects = [];
  List<Project> _filtered = [];
  bool _loading = true;

  List<DesignChallenge> _challenges = [];
  List<DesignChallenge> _filteredChallenges = [];
  bool _challengesLoading = true;
  Set<String> _challengeTypeFilter = {};

  Set<String> _subjectFilter = {};
  Set<String> _phaseFilter = {};
  Set<String> _scaleFilter = {};
  Set<String> _difficultyFilter = {};

  Set<String> _bookmarkedIds = {};
  bool _showBookmarkedOnly = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProjects();
        _loadChallenges();
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    _tabCtrl ??= TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    _searchCtrl.dispose();
    _challengeSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    final projects = await _projectsRepo.getCurrentUserProjects();
    if (!mounted) return;
    final ids = projects?.map((p) => p.id).toList() ?? [];
    final bookmarked = ids.isEmpty
        ? <String>{}
        : await _projectsRepo.getBookmarkedProjectIds(projectIds: ids);
    if (!mounted) return;
    setState(() {
      _projects = projects ?? [];
      _bookmarkedIds = bookmarked;
      _loading = false;
      _applyFilters();
    });
  }

  Future<void> _loadChallenges() async {
    setState(() => _challengesLoading = true);
    final challenges = await _challengesRepo.getUserJoinedChallenges();
    if (!mounted) return;
    setState(() {
      _challenges = challenges;
      _challengesLoading = false;
      _applyChallengeFilters();
    });
  }

  void _applyChallengeFilters() {
    final q = _challengeSearchCtrl.text.trim().toLowerCase();
    _filteredChallenges = _challenges.where((c) {
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
      if (_challengeTypeFilter.isNotEmpty &&
          !_challengeTypeFilter.contains(c.type)) return false;
      return true;
    }).toList();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    _filtered = _projects.where((p) {
      if (q.isNotEmpty && !p.projectName.toLowerCase().contains(q)) {
        return false;
      }
      if (_showBookmarkedOnly && !_bookmarkedIds.contains(p.id)) return false;
      if (_subjectFilter.isNotEmpty) {
        // Tags are stored as 'domain|focus' — extract the domain part and
        // check if any of the project's domains intersect with the filter.
        final domains = p.tags
            .map((t) => t.split('|').first.trim())
            .toSet();
        if (!domains.any((d) => _subjectFilter.contains(d))) return false;
      }
      if (_phaseFilter.isNotEmpty &&
          !p.journalProgressValues.any((v) => _phaseFilter.contains(v))) {
        return false;
      }
      if (_scaleFilter.isNotEmpty &&
          !_scaleFilter.contains(p.projectScale)) return false;
      if (_difficultyFilter.isNotEmpty &&
          !_difficultyFilter.contains(p.difficulty)) return false;
      return true;
    }).toList();
  }

  void _openFilter(
    String title,
    List<FilterOption> options,
    Set<String> current,
    void Function(Set<String>) onApply,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectFilterSheet(
        title: title,
        options: options,
        initialSelected: current,
        onApply: onApply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar ──────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1)),
          ),
          child: TabBar(
            controller: _tabCtrl!,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Projects'),
              Tab(text: 'Challenges'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabCtrl!,
            children: [
              _buildProjectsTab(),
              _buildChallengesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsTab() {
    final hasFilters = _subjectFilter.isNotEmpty ||
        _phaseFilter.isNotEmpty ||
        _scaleFilter.isNotEmpty ||
        _difficultyFilter.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search row ───────────────────────────────────────────────────
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

        // ── Filter chips ─────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Text(
                hasFilters ? 'Filters Active' : 'Filter',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasFilters
                        ? AppColors.primary
                        : AppColors.textPrimary),
              ),
              const SizedBox(width: 10),
              _chip('SUBJECT', _subjectFilter, (v) {
                setState(() {
                  _subjectFilter = v;
                  _applyFilters();
                });
              }, kSubjectOptions),
              _chip('PHASE', _phaseFilter, (v) {
                setState(() {
                  _phaseFilter = v;
                  _applyFilters();
                });
              }, kPhaseOptions),
              _chip('SCALE', _scaleFilter, (v) {
                setState(() {
                  _scaleFilter = v;
                  _applyFilters();
                });
              }, kScaleOptions),
              _chip('DIFFICULTY', _difficultyFilter, (v) {
                setState(() {
                  _difficultyFilter = v;
                  _applyFilters();
                });
              }, kDifficultyOptions),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.divider),

        // ── Project list ─────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _projects.isEmpty
                            ? 'No projects yet'
                            : 'No projects match your search',
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProjects,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) {
                          final p = _filtered[i];
                          return _ProjectCard(
                            project: p,
                            initialIsBookmarked:
                                _bookmarkedIds.contains(p.id),
                            onBookmarkChanged: (bookmarked) {
                              setState(() {
                                if (bookmarked) {
                                  _bookmarkedIds.add(p.id);
                                } else {
                                  _bookmarkedIds.remove(p.id);
                                }
                                _applyFilters();
                              });
                            },
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => ProjectDashboard(
                                  projectId: p.id,
                                  projectName: p.projectName,
                                  tags: p.tags,
                                  isOwner: true,
                                ),
                              ),
                            ).then((_) => _loadProjects()),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _chip(
    String label,
    Set<String> current,
    void Function(Set<String>) onApply,
    List<FilterOption> options,
  ) {
    final active = current.isNotEmpty;
    return GestureDetector(
      onTap: () => _openFilter(label, options, current, onApply),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.primaryTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              active ? '$label (${current.length})' : label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.white : AppColors.primary,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onApply({}),
                child: Icon(Icons.close,
                    size: 12,
                    color: active ? AppColors.white : AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesTab() {
    const filterOptions = [
      ('pattern_change', 'PATTERN'),
      ('community_impact', 'COMMUNITY IMPACT'),
      ('build_and_create', 'BUILD & CREATE'),
    ];

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
              controller: _challengeSearchCtrl,
              onChanged: (_) => setState(_applyChallengeFilters),
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search design challenges',
                hintStyle:
                    TextStyle(color: AppColors.hintText, fontSize: 14),
                prefixIcon: Icon(Icons.search,
                    color: AppColors.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
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
              ...filterOptions.map((opt) {
                final isActive = _challengeTypeFilter.contains(opt.$1);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isActive) {
                      _challengeTypeFilter.remove(opt.$1);
                    } else {
                      _challengeTypeFilter.add(opt.$1);
                    }
                    _applyChallengeFilters();
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            isActive ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.divider),

        Expanded(
          child: _challengesLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredChallenges.isEmpty
                  ? Center(
                      child: Text(
                        _challenges.isEmpty
                            ? 'No joined challenges yet'
                            : 'No challenges match your search',
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChallenges,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: _filteredChallenges.length,
                        itemBuilder: (ctx, i) {
                          final c = _filteredChallenges[i];
                          return _JournalChallengeCard(
                            challenge: c,
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChallengeDetailScreen(challenge: c),
                              ),
                            ).then((_) => _loadChallenges()),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── _JournalChallengeCard ─────────────────────────────────────────────────────

class _JournalChallengeCard extends StatelessWidget {
  final DesignChallenge challenge;
  final VoidCallback onTap;

  const _JournalChallengeCard(
      {required this.challenge, required this.onTap});

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
                          color:
                              Colors.white.withValues(alpha: 0.8))),
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
                      if (avatars.isNotEmpty)
                        SizedBox(
                          height: 22,
                          width: (avatars.length * 16 + 10)
                              .toDouble(),
                          child: Stack(
                            children: avatars.asMap().entries.map((e) {
                              return Positioned(
                                left: e.key * 16.0,
                                child: CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.white,
                                  backgroundImage: e.value.isNotEmpty
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
                          child: Text('More...',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white
                                      .withValues(alpha: 0.8))),
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

// ── Project card ───────────────────────────────────────────────────────────

class _ProjectCard extends StatefulWidget {
  final Project project;
  final bool initialIsBookmarked;
  final void Function(bool) onBookmarkChanged;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.initialIsBookmarked,
    required this.onBookmarkChanged,
    required this.onTap,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  final _projectsRepo = ProjectsRepo();
  int _likes = 0;
  bool _hasLiked = false;
  bool _isLiking = false;
  bool _isBookmarked = false;
  bool _isBookmarking = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.project.likes;
    _isBookmarked = widget.initialIsBookmarked;
  }

  @override
  void didUpdateWidget(_ProjectCard old) {
    super.didUpdateWidget(old);
    if (old.initialIsBookmarked != widget.initialIsBookmarked) {
      _isBookmarked = widget.initialIsBookmarked;
    }
  }

  Future<void> _handleLike() async {
    if (_isLiking) return;
    _isLiking = true;
    final prev = _likes;
    final prevHad = _hasLiked;
    setState(() {
      _hasLiked = !_hasLiked;
      _likes = _hasLiked ? prev + 1 : prev - 1;
    });
    final ok = _hasLiked
        ? await _projectsRepo.likeProject(id: widget.project.id)
        : await _projectsRepo.unlikeProject(id: widget.project.id);
    if (!mounted) return;
    setState(() {
      _isLiking = false;
      if (!ok) {
        _hasLiked = prevHad;
        _likes = prev;
      }
    });
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
    setState(() => _isBookmarking = false);
    if (ok) {
      widget.onBookmarkChanged(_isBookmarked);
    } else {
      setState(() => _isBookmarked = prev);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final hasImage = p.imageUrl != null && p.imageUrl!.isNotEmpty;
    final entryCount = p.journalEntryCount;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
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
            // Cover image — full width
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: hasImage
                    ? Image.network(
                        p.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: title + entry count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.projectName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.menu_book_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Right: bookmark + likes + comments
                  Row(
                    children: [
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
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _handleLike,
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_florist,
                              size: 20,
                              color: _hasLiked
                                  ? AppColors.primaryDark
                                  : AppColors.borderLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_likes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _hasLiked
                                    ? AppColors.primaryDark
                                    : AppColors.borderLight,
                              ),
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
                        child: const Icon(Icons.chat_bubble_outline,
                            size: 20, color: AppColors.textSecondary),
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
        color: AppColors.primaryTint,
        child: const Center(
          child: Icon(Icons.eco_outlined, size: 48, color: AppColors.primary),
        ),
      );
}

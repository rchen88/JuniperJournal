import 'dart:async';
import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/challenges_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/users_repo.dart';
import 'package:juniper_journal/src/features/project/pages/project_dashboard.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/widgets/widgets.dart';

// Domain → Focus options
const _focusByDomain = <String, List<String>>{
  'Environment & Sustainability': [
    'Ecosystems & Biodiversity',
    'Climate & Weather Patterns',
    'Human Impact on Natural Systems',
    'Natural Resources & Conservation',
    'Pollution and Waste Management',
  ],
  'Engineering & Design': [
    'Defining and Delimiting Engineering Problems',
    'Designing Solutions and Prototyping',
    'Materials and Their Properties',
    'Iteration and Improvement Processes',
    'Sustainable Innovation and Practices',
  ],
  'Energy & Systems': [
    'Energy Sources and Forms',
    'Energy Transfer and Transformation',
    'Renewable and Nonrenewable Resources',
    'Efficiency and Conservation of Energy',
    'Energy Flow in Natural and Engineered Systems',
  ],
  'Community & Built Environment': [
    'Sustainable Communities and Urban Planning',
    'Green Building and Infrastructure',
    'Transportation and Mobility Systems',
    'Public Space Design and Equity',
    'Interaction Between Human and Natural Environments',
  ],
};

class CreateProjectScreen extends StatefulWidget {
  /// When set, the created project is linked to this challenge upon creation.
  final String? challengeId;

  /// Pre-fills and locks the difficulty to the challenge requirement.
  final String? lockedDifficulty;

  /// Pre-fills and locks the scale to the challenge requirement.
  final String? lockedScale;

  const CreateProjectScreen({
    super.key,
    this.challengeId,
    this.lockedDifficulty,
    this.lockedScale,
  });

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _problemController = TextEditingController();
  final _projectsRepo = ProjectsRepo();

  // Subject tags
  String? _activeDomain;
  String? _activeFocus;
  final List<({String domain, String focus})> _subjectTags = [];

  // Other fields
  String? _selectedDifficulty;
  String? _selectedScale;
  String? _selectedVisibility;

  // Members
  List<UserProfile> _pendingMembers = [];

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.lockedDifficulty;
    _selectedScale = widget.lockedScale;
    if (widget.challengeId != null) _selectedVisibility = 'Community Only';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  void _addSubjectTag() {
    if (_activeDomain == null || _activeFocus == null) return;
    final domain = _activeDomain!;
    final focus = _activeFocus!;
    // Prevent duplicates
    if (_subjectTags.any((t) => t.domain == domain && t.focus == focus)) {
      setState(() {
        _activeDomain = null;
        _activeFocus = null;
      });
      return;
    }
    setState(() {
      _subjectTags.add((domain: domain, focus: focus));
      _activeDomain = null;
      _activeFocus = null;
    });
  }

  Future<void> _openAddMemberDialog() async {
    final result = await showDialog<List<UserProfile>>(
      context: context,
      builder: (_) => _AddMemberDialog(existingMembers: List.from(_pendingMembers)),
    );
    if (result != null) {
      setState(() => _pendingMembers = result);
    }
  }

  Future<void> _handleCreate() async {
    if (_isCreating) return;
    final name = _nameController.text.trim();
    final problem = _problemController.text.trim();

    if (name.isEmpty) {
      _snack('Enter a project name');
      return;
    }
    if (problem.isEmpty) {
      _snack('Enter a problem statement');
      return;
    }
    if (_subjectTags.isEmpty) {
      _snack('Add at least one subject tag');
      return;
    }
    if (_selectedDifficulty == null) {
      _snack('Select a difficulty level');
      return;
    }
    if (_selectedScale == null) {
      _snack('Select a project scale');
      return;
    }
    if (_selectedVisibility == null) {
      _snack('Select a visibility setting');
      return;
    }

    setState(() => _isCreating = true);

    final tags = _subjectTags.map((t) => '${t.domain}|${t.focus}').toList();

    final project = await _projectsRepo.createProject(
      projectName: name,
      problemStatement: problem,
      tags: tags,
      difficulty: _selectedDifficulty,
      projectScale: _selectedScale,
      visibility: _selectedVisibility,
    );

    if (!mounted) return;

    if (project == null) {
      setState(() => _isCreating = false);
      _snack('Failed to create project. Please try again.');
      return;
    }

    for (final member in _pendingMembers) {
      await _projectsRepo.inviteCollaborator(
        projectId: project.id,
        userId: member.id,
      );
    }

    // If launched from a challenge, link the project
    if (widget.challengeId != null) {
      await ChallengesRepo().joinChallenge(
        challengeId: widget.challengeId!,
        projectId: project.id,
      );
    }

    if (!mounted) return;

    if (widget.challengeId != null) {
      // Return the project ID to the challenge detail screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProjectDashboard(
            projectId: project.id,
            projectName: project.projectName,
            tags: project.tags,
            challengeId: widget.challengeId,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ProjectDashboard(
            projectId: project.id,
            projectName: project.projectName,
            tags: project.tags,
          ),
        ),
        (route) => route.isFirst,
      );
    }
  }

  void _snack(String msg) {
    showTopSnackBar(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final canAddTag = _activeDomain != null && _activeFocus != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Project',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.6),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Project Name ────────────────────────────────────────────────
            _label('Project Name'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Problem Statement ───────────────────────────────────────────
            _label('Problem Statement'),
            const SizedBox(height: 10),
            TextField(
              controller: _problemController,
              maxLines: 5,
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Describe the challenge your project aims to address…',
                hintStyle: const TextStyle(color: AppColors.hintText, fontSize: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Subject Domain & Focus ──────────────────────────────────────
            _label('Subject Domain & Focus'),
            const SizedBox(height: 10),

            // Added tags
            if (_subjectTags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjectTags
                    .map((t) => _SubjectTagChip(
                          domain: t.domain,
                          focus: t.focus,
                          onRemove: () => setState(() => _subjectTags.remove(t)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Picker card
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Domain',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45)),
                  const SizedBox(height: 5),
                  PillSelector(
                    value: _activeDomain,
                    placeholder: 'Select',
                    items: _focusByDomain.keys.toList(),
                    onChanged: (v) => setState(() {
                      _activeDomain = v;
                      _activeFocus = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Icon(Icons.add,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 8),
                  Text('Focus',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black45)),
                  const SizedBox(height: 5),
                  PillSelector(
                    value: _activeFocus,
                    placeholder: _activeDomain == null
                        ? 'Pick domain first'
                        : 'Select',
                    items: _activeDomain != null
                        ? _focusByDomain[_activeDomain]!
                        : [],
                    onChanged: (v) =>
                        setState(() => _activeFocus = v),
                  ),
                  const SizedBox(height: 12),
                  // Add button — full width, prominent
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canAddTag ? _addSubjectTag : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: Icon(Icons.add,
                          size: 16,
                          color: canAddTag ? Colors.white : Colors.grey.shade400),
                      label: Text(
                        'Add Combination',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: canAddTag ? Colors.white : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Difficulty ──────────────────────────────────────────────────
            _label('Difficulty'),
            const SizedBox(height: 10),
            widget.lockedDifficulty != null
                ? _LockedPill(value: widget.lockedDifficulty!)
                : PillSelector(
                    value: _selectedDifficulty,
                    placeholder: 'Select Difficulty',
                    items: const ['Easy', 'Moderate', 'Hard'],
                    onChanged: (v) => setState(() => _selectedDifficulty = v),
                  ),

            const SizedBox(height: 24),

            // ── Project Scale ───────────────────────────────────────────────
            _label('Project Scale'),
            const SizedBox(height: 10),
            widget.lockedScale != null
                ? _LockedPill(value: widget.lockedScale!)
                : PillSelector(
                    value: _selectedScale,
                    placeholder: 'Select Scale',
                    items: const ['Small', 'Medium', 'Large'],
                    onChanged: (v) => setState(() => _selectedScale = v),
                  ),

            const SizedBox(height: 24),

            // ── Visibility ──────────────────────────────────────────────────
            _label('Visibility'),
            const SizedBox(height: 10),
            if (widget.challengeId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Community Only', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              PillSelector(
                value: _selectedVisibility,
                placeholder: 'Select Visibility',
                items: const ['Private', 'Friends Only', 'Public'],
                onChanged: (v) => setState(() => _selectedVisibility = v),
              ),

            const SizedBox(height: 24),

            // ── Add Member ──────────────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Add Member',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openAddMemberDialog,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Icon(Icons.add, size: 16, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),

            if (_pendingMembers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pendingMembers
                    .map((m) => _MemberChip(profile: m))
                    .toList(),
              ),
            ],

            const SizedBox(height: 40),

            // ── Create ──────────────────────────────────────────────────────
            SubmitButton(
              label: 'Create',
              isLoading: _isCreating,
              backgroundColor: AppColors.primary,
              onPressed: _handleCreate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
}

// ── _LockedPill ───────────────────────────────────────────────────────────────

class _LockedPill extends StatelessWidget {
  const _LockedPill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.lock_outline,
              size: 14, color: AppColors.primary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

// ── _SubjectTagChip ──────────────────────────────────────────────────────────

class _SubjectTagChip extends StatelessWidget {
  const _SubjectTagChip({
    required this.domain,
    required this.focus,
    required this.onRemove,
  });

  final String domain;
  final String focus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              '$domain • $focus',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── _MemberChip ──────────────────────────────────────────────────────────────

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                ? const Icon(Icons.person_outline, size: 12, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            profile.resolvedDisplayName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// ── _AddMemberDialog ─────────────────────────────────────────────────────────

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.existingMembers});

  final List<UserProfile> existingMembers;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _searchController = TextEditingController();
  final _usersRepo = UsersRepo();
  Timer? _debounce;

  UserProfile? _ownerProfile;
  List<UserProfile> _members = [];
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.existingMembers);
    _loadOwner();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOwner() async {
    final profile = await _usersRepo.getCurrentUserProfile();
    if (mounted) setState(() => _ownerProfile = profile);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _searchController.text.trim();
      if (q.isEmpty) {
        if (mounted) setState(() => _searchResults = []);
        return;
      }
      if (mounted) setState(() => _isSearching = true);
      final results = await _usersRepo.searchPublicUsers(query: q) ?? [];
      final excluded = {
        ..._members.map((m) => m.id),
        if (_ownerProfile != null) _ownerProfile!.id,
        if (AuthService.instance.currentUser != null) AuthService.instance.currentUser!.id,
      };
      if (mounted) {
        setState(() {
          _searchResults = results.where((u) => !excluded.contains(u.id)).toList();
          _isSearching = false;
        });
      }
    });
  }

  void _addMember(UserProfile user) {
    setState(() {
      _members.add(user);
      _searchResults.clear();
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.primary, size: 22),
                  ),
                  const Expanded(
                    child: Text(
                      'Add Member',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
              const SizedBox(height: 20),

              // Search
              const Text(
                'Search',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                autofocus: false,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add People',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),

              // Search results
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: _searchResults
                        .map((user) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                backgroundImage:
                                    (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                        ? NetworkImage(user.avatarUrl!)
                                        : null,
                                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                    ? const Icon(Icons.person_outline,
                                        size: 16, color: AppColors.primary)
                                    : null,
                              ),
                              title: Text(
                                user.resolvedDisplayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: user.username != null
                                  ? Text(user.username!,
                                      style: const TextStyle(fontSize: 12))
                                  : null,
                              onTap: () => _addMember(user),
                            ))
                        .toList(),
                  ),
                ),

              const SizedBox(height: 16),

              // Group section
              const Text(
                'Group',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    if (_ownerProfile != null)
                      _MemberRow(
                        profile: _ownerProfile!,
                        label: 'Project Owner',
                      ),
                    ..._members.map(
                      (m) => _MemberRow(
                        profile: m,
                        label: 'Project Member',
                        onRemove: () => setState(() => _members.remove(m)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Done
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _members),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Done',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _MemberRow ───────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.profile,
    required this.label,
    this.onRemove,
  });

  final UserProfile profile;
  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage:
                (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
            child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                ? const Icon(Icons.person_outline,
                    size: 18, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.resolvedDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (profile.username != null && profile.username!.isNotEmpty)
                  Text(
                    profile.username!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: label == 'Project Owner' ? AppColors.primary : Colors.grey.shade500,
              fontWeight: label == 'Project Owner' ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/challenge_participant.dart';
import 'package:juniper_journal/src/backend/db/models/design_challenge.dart';
import 'package:juniper_journal/src/backend/db/models/impact_entry.dart';
import 'package:juniper_journal/src/backend/db/repositories/challenges_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/features/project/pages/collaborators_sheet.dart';
import 'package:juniper_journal/src/features/project/project.dart';
import 'package:juniper_journal/src/services/media_service.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
import 'package:juniper_journal/src/shared/widgets/top_snack_bar.dart';

class ProjectDashboard extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<String> tags;
  final bool isOwner;
  final String? challengeId;
  final ProjectsRepo? projectsRepo;
  final ChallengesRepo? challengesRepo;
  final MediaService? mediaService;

  const ProjectDashboard({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.tags,
    this.isOwner = true,
    this.challengeId,
    this.projectsRepo,
    this.challengesRepo,
    this.mediaService,
  });

  @override
  State<ProjectDashboard> createState() => _ProjectDashboardState();
}

class _ProjectDashboardState extends State<ProjectDashboard> {
  late final ProjectsRepo _projectsRepo;
  late final ChallengesRepo _challengesRepo;
  MediaService? _mediaService;

  late String _projectName;
  late List<String> _tags;
  String? _imageUrl;
  String? _description;
  String? _ownerUserId;
  String? _difficulty;
  String? _projectScale;
  bool _isLoading = true;
  bool _isUpdatingImage = false;

  ChallengeParticipant? _challengeParticipation;
  DesignChallenge? _challenge;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _projectsRepo = widget.projectsRepo ?? ProjectsRepo();
    _challengesRepo = widget.challengesRepo ?? ChallengesRepo();
    _mediaService = widget.mediaService;
    _projectName = widget.projectName;
    _tags = List<String>.from(widget.tags);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProject();
    });
  }

  Future<void> _loadProject() async {
    final project = await _projectsRepo.getProjectById(widget.projectId);
    final participation = await _challengesRepo
        .getParticipationByProjectId(widget.projectId);
    DesignChallenge? challenge;
    if (participation != null) {
      challenge = await _challengesRepo.getChallengeById(participation.challengeId);
    }
    if (!mounted) return;
    setState(() {
      if (project != null) {
        _projectName = project.projectName.isNotEmpty ? project.projectName : _projectName;
        _tags = project.tags.isNotEmpty ? project.tags : _tags;
        _imageUrl = project.imageUrl;
        _description = project.problemStatement;
        _ownerUserId = project.userId;
        _difficulty = project.difficulty;
        _projectScale = project.projectScale;
      }
      _challengeParticipation = participation;
      _challenge = challenge;
      _isLoading = false;
    });
  }

  Future<void> _submitToChallenge() async {
    final participation = _challengeParticipation;
    if (participation == null) return;

    // Refresh challenge to get latest state
    final challenge =
        await _challengesRepo.getChallengeById(participation.challengeId);
    if (!mounted) return;

    if (challenge == null) {
      showTopSnackBar(context, 'Could not load challenge details', isError: true);
      return;
    }

    // Block if challenge has ended
    if (challenge.isPast) {
      showTopSnackBar(context, 'This challenge has ended', isError: true);
      return;
    }

    // Fetch project data needed for requirement checks
    final results = await Future.wait([
      _projectsRepo.getImpactEntries(projectId: widget.projectId),
      _projectsRepo.getJournalEntries(projectId: widget.projectId),
      if (challenge.minGroupMembers > 1)
        _projectsRepo.getProjectCollaborators(projectId: widget.projectId),
    ]);
    if (!mounted) return;

    final impactEntries = (results[0] as List?)?.cast<ImpactEntry>() ?? <ImpactEntry>[];
    final journalCount = (results[1] as List?)?.length ?? 0;
    final collaboratorCount = challenge.minGroupMembers > 1
        ? (results[2] as List?)?.length ?? 0
        : 0;

    final unmet = <String>[];

    // Journal entries
    if (challenge.requiredJournalEntries > 0 &&
        journalCount < challenge.requiredJournalEntries) {
      unmet.add(
          '$journalCount/${challenge.requiredJournalEntries} journal entries');
    }

    // Group members (collaborators + owner)
    if (challenge.minGroupMembers > 1) {
      final totalMembers = collaboratorCount + 1;
      if (totalMembers < challenge.minGroupMembers) {
        final needed = challenge.minGroupMembers - 1;
        unmet.add(
            'need $needed more member${needed == 1 ? '' : 's'} (group challenge)');
      }
    }

    // Required metrics — at least 1 impact entry per required metric
    for (final metric in challenge.requiredMetrics) {
      final has = impactEntries
          .any((e) => e.metric.toLowerCase() == metric.toLowerCase());
      if (!has) unmet.add('missing $metric impact entry');
    }

    // Required patterns — at least 1 impact entry per required pattern
    for (final pattern in challenge.requiredPatterns) {
      final has = impactEntries
          .any((e) => e.patternType.toLowerCase() == pattern.toLowerCase());
      if (!has) unmet.add('missing $pattern pattern entry');
    }

    // Measurement required
    if (challenge.measurementRequired) {
      final has = impactEntries.any((e) => e.measurement != null);
      if (!has) unmet.add('at least 1 impact entry must include a measurement');
    }

    if (unmet.isNotEmpty) {
      showTopSnackBar(
        context,
        'Requirements not met. Please check the challenge details.',
        isError: true,
      );
      return;
    }

    setState(() => _submitting = true);
    final ok =
        await _challengesRepo.submitToChallenge(participation.challengeId);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      showTopSnackBar(context, 'Submitted successfully!');
      _loadProject();
    } else {
      showTopSnackBar(context, 'Failed to submit. Please try again.', isError: true);
    }
  }

  Future<void> _openCollaborators() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CollaboratorsSheet(
        projectId: widget.projectId,
        projectName: _projectName,
        isOwner: _ownerUserId != null &&
            _ownerUserId == AuthService.instance.currentUser?.id,
        ownerUserId: _ownerUserId,
      ),
    );
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectSettingsScreen(projectId: widget.projectId),
      ),
    );
    if (result == null || !mounted) return;
    if (result['deleted'] == true) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _projectName = result['project_name']?.toString() ?? _projectName;
      _imageUrl = result.containsKey('project_image_url')
          ? result['project_image_url']?.toString()
          : _imageUrl;
      _tags = (result['tags'] as List?)
              ?.map((t) => t.toString())
              .where((t) => t.isNotEmpty)
              .toList() ??
          _tags;
    });
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    if (!widget.isOwner || _isUpdatingImage) return;

    setState(() => _isUpdatingImage = true);
    final imageUrl = await (_mediaService ??= MediaService())
        .pickAndUploadImage(source, folder: 'project-images');
    if (!mounted) return;

    if (imageUrl == null) {
      setState(() => _isUpdatingImage = false);
      return;
    }

    final success = await _projectsRepo.updateProjectImage(
      id: widget.projectId,
      projectImageUrl: imageUrl,
    );
    if (!mounted) return;

    setState(() {
      if (success) _imageUrl = imageUrl;
      _isUpdatingImage = false;
    });

    showTopSnackBar(
      context,
      success ? 'Cover image updated' : 'Failed to update cover image',
      isError: !success,
    );
  }

  Future<void> _removeCoverImage() async {
    if (!widget.isOwner || _isUpdatingImage) return;

    setState(() => _isUpdatingImage = true);
    final success = await _projectsRepo.updateProjectImage(
      id: widget.projectId,
      projectImageUrl: null,
    );
    if (!mounted) return;

    setState(() {
      if (success) _imageUrl = null;
      _isUpdatingImage = false;
    });

    showTopSnackBar(
      context,
      success ? 'Cover image removed' : 'Failed to remove cover image',
      isError: !success,
    );
  }

  Future<void> _showCoverImageSheet() async {
    if (!widget.isOwner || _isUpdatingImage) return;

    final hasImage = _imageUrl != null && _imageUrl!.isNotEmpty;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Project Cover Image'),
        message: const Text('Choose image source'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickCoverImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickCoverImage(ImageSource.gallery);
            },
            child: const Text('Choose from Gallery'),
          ),
          if (hasImage)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _removeCoverImage();
              },
              child: const Text('Remove Cover Image'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _projectName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isOwner)
            IconButton(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined),
              color: AppColors.textPrimary,
              tooltip: 'Project Settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroImage(),
                  const SizedBox(height: 16),

                  // Project name
                  Text(
                    _projectName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Meta pills (only rendered when at least one field is set)
                  if (_difficulty != null || _projectScale != null) ...[
                    const SizedBox(height: 8),
                    _buildMetaPillsRow(),
                  ],

                  // Challenge submit pill (owner only)
                  if (widget.isOwner && _challengeParticipation != null) ...[
                    const SizedBox(height: 12),
                    Center(child: _buildSubmitPill()),
                  ],

                  const Divider(height: 28, color: AppColors.divider),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (_description != null && _description!.trim().isNotEmpty)
                        ? _description!.trim()
                        : 'No description provided.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2×2 action grid
                  _buildActionGrid(),
                ],
              ),
            ),
    );
  }

  // ── Action grid ────────────────────────────────────────────────────────────

  Widget _buildHeroImage() {
    final hasImage = _imageUrl != null && _imageUrl!.isNotEmpty;
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(
                _imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
              )
            else
              _buildCoverPlaceholder(),
            if (widget.isOwner)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    shape: BoxShape.circle,
                  ),
                  child: _isUpdatingImage
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 21,
                        ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!widget.isOwner) return image;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: _showCoverImageSheet, child: image),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: AppColors.avatarBackground,
      child: const Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 40,
          color: AppColors.avatarIcon,
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    final items = [
      _GridItem(
        label: 'Impact Entry',
        icon: Icons.bar_chart_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImpactLogScreen(
              projectId: widget.projectId,
              projectName: _projectName,
              isOwner: widget.isOwner,
            ),
          ),
        ),
      ),
      _GridItem(
        label: 'Timeline',
        icon: Icons.tune_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InteractiveTimelinePage(
              projectId: widget.projectId,
              projectName: _projectName,
              tags: _tags,
              isOwner: widget.isOwner,
            ),
          ),
        ),
      ),
      _GridItem(
        label: 'Materials & Cost',
        icon: Icons.attach_money_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaterialsCostPage(
              projectId: widget.projectId,
              projectName: _projectName,
              tags: _tags,
              isOwner: widget.isOwner,
            ),
          ),
        ),
      ),
      _GridItem(
        label: 'Journal Entry',
        icon: Icons.menu_book_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JournalLogScreen(
              projectId: widget.projectId,
              projectName: _projectName,
              tags: _tags,
              embedded: false,
              isOwner: widget.isOwner,
            ),
          ),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: items.map(_buildGridCard).toList(),
    );
  }

  Widget _buildGridCard(_GridItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Icon(item.icon, color: AppColors.primary, size: 22),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ── Supporting widgets ─────────────────────────────────────────────────────

  Widget _buildSubmitPill() {
    final submitted = _challengeParticipation?.hasSubmitted ?? false;
    final isPast = _challenge?.isPast ?? false;

    if (isPast) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Text(
              'Challenge Closed',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _submitting ? null : _submitToChallenge,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: submitted ? AppColors.primaryTint : AppColors.primary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: submitted ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_submitting)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            else
              Icon(
                submitted ? Icons.refresh : Icons.upload_outlined,
                size: 16,
                color: submitted ? AppColors.primary : Colors.white,
              ),
            const SizedBox(width: 6),
            Text(
              submitted ? 'Resubmit to Challenge' : 'Submit to Challenge',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: submitted ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaPillsRow() {
    final items = <Widget>[];

    if (_difficulty != null && _difficulty!.isNotEmpty) {
      items.add(_buildMetaItem('Difficulty', _difficulty!.toUpperCase()));
    }
    if (_projectScale != null && _projectScale!.isNotEmpty) {
      if (items.isNotEmpty) {
        items.add(const VerticalDivider(width: 32, color: AppColors.divider));
      }
      items.add(_buildMetaItem('Scale', _projectScale!.toUpperCase()));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _GridItem ─────────────────────────────────────────────────────────────────

class _GridItem {
  const _GridItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

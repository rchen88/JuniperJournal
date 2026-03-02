import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/features/project/project.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';

class ProjectDashboard extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<String> tags;
  final bool isOwner;

  const ProjectDashboard({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.tags,
    this.isOwner = true,
  });

  @override
  State<ProjectDashboard> createState() => _ProjectDashboardState();
}

class _ProjectDashboardState extends State<ProjectDashboard> {
  final _projectsRepo = ProjectsRepo();

  late String _projectName;
  late List<String> _tags;
  String? _imageUrl;
  String? _description;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _projectName = widget.projectName;
    _tags = List<String>.from(widget.tags);
    _loadProject();
  }

  Future<void> _loadProject() async {
    final project = await _projectsRepo.getProjectById(widget.projectId);
    if (!mounted) return;
    setState(() {
      if (project != null) {
        _projectName = project.projectName.isNotEmpty
            ? project.projectName
            : _projectName;
        _tags = project.tags.isNotEmpty ? project.tags : _tags;
        _imageUrl = project.imageUrl;
        _description = project.problemStatement;
      }
      _isLoading = false;
    });
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
      _tags =
          (result['tags'] as List?)
              ?.map((t) => t.toString())
              .where((t) => t.isNotEmpty)
              .toList() ??
          _tags;
    });
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: Colors.black45,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              tabs: const [Tab(text: 'Submission'), Tab(text: 'Log')],
            ),
          ),
        ),
      ),
    );
  }

  // ── Submission tab ────────────────────────────────────────────────────────

  Widget _buildSubmissionTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: (_imageUrl != null && _imageUrl!.isNotEmpty)
                  ? Image.network(_imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFEAF2EC),
                      child: const Center(
                        child: Icon(
                          Icons.landscape_outlined,
                          size: 40,
                          color: Color(0xFF5A7A62),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Project name
          Text(
            _projectName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          // Achievement row
          _buildAchievementRow(),
          const Divider(height: 28, color: Color(0xFFE5E5EA)),

          // Difficulty / Cost / Impact
          _buildMetaPillsRow(),
          const Divider(height: 28, color: Color(0xFFE5E5EA)),

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
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Section entry rows
          _buildSectionRow(
            'Problem Statement',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DefineProblemStatementScreen(
                  projectId: widget.projectId,
                  projectName: _projectName,
                  tags: _tags,
                ),
              ),
            ),
          ),
          _buildSectionRow(
            'Journal Entries',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JournalLogScreen(
                  projectId: widget.projectId,
                  projectName: _projectName,
                  tags: _tags,
                ),
              ),
            ),
          ),
          _buildSectionRow(
            'Metrics',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MetricsPage(
                  projectId: widget.projectId,
                  projectName: _projectName,
                  tags: _tags,
                ),
              ),
            ),
          ),
          _buildSectionRow(
            'Timeline',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InteractiveTimelinePage(
                  projectId: widget.projectId,
                  projectName: _projectName,
                  tags: _tags,
                ),
              ),
            ),
          ),
          _buildSectionRow(
            'Materials & Cost',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MaterialsCostPage(
                  projectId: widget.projectId,
                  projectName: _projectName,
                  tags: _tags,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementRow() {
    final tag = _tags.isNotEmpty ? _tags.first : null;
    return Row(
      children: [
        const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 20),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Complete your first milestone',
            style: TextStyle(fontSize: 13, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tag != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        const Icon(Icons.bookmark_border, size: 22, color: AppColors.primary),
        const SizedBox(width: 4),
        const Icon(Icons.group_outlined, size: 22, color: AppColors.primary),
      ],
    );
  }

  Widget _buildMetaPillsRow() {
    // TODO: wire real values from DB when difficulty/costLevel/impactLevel
    // columns are added to the projects table.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetaItem('Difficulty', 'EASY'),
          const VerticalDivider(width: 32, color: Color(0xFFE5E5EA)),
          _buildMetaItem('Cost Level', 'LOW COST'),
          const VerticalDivider(width: 32, color: Color(0xFFE5E5EA)),
          _buildMetaItem('Impact Level', 'HIGH IMPACT'),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Widget _buildSectionRow(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Log tab ───────────────────────────────────────────────────────────────

  Widget _buildLogTab() {
    return JournalLogScreen(
      projectId: widget.projectId,
      projectName: _projectName,
      tags: _tags,
      embedded: true,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: TabBarView(
          children: [_buildSubmissionTab(), _buildLogTab()],
        ),
      ),
    );
  }
}

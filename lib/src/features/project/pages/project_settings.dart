import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/repositories/challenges_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/features/project/pages/collaborators_sheet.dart';
import 'package:juniper_journal/src/services/media_service.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
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

typedef _SubjectTag = ({String domain, String focus});

class ProjectSettingsScreen extends StatefulWidget {
  final String projectId;
  final ProjectsRepo? projectsRepo;
  final MediaService? mediaService;

  const ProjectSettingsScreen({
    super.key,
    required this.projectId,
    this.projectsRepo,
    this.mediaService,
  });

  @override
  State<ProjectSettingsScreen> createState() => _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends State<ProjectSettingsScreen> {
  late final ProjectsRepo _projectsRepo;
  late final MediaService _mediaService;
  final _formKey = GlobalKey<FormState>();

  final _projectNameController = TextEditingController();
  final _problemStatementController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _projectImageUrl;
  String? _ownerUserId;

  // Subject tags
  String? _activeDomain;
  String? _activeFocus;
  final List<_SubjectTag> _subjectTags = [];

  String? _selectedDifficulty;
  String? _selectedScale;
  String? _selectedVisibility;

  @override
  void initState() {
    super.initState();
    _projectsRepo = widget.projectsRepo ?? ProjectsRepo();
    _mediaService = widget.mediaService ?? MediaService();
    _loadProject();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _problemStatementController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    final project = await _projectsRepo.getProjectById(widget.projectId);
    if (!mounted) return;

    if (project == null) {
      setState(() => _isLoading = false);
      showTopSnackBar(context, 'Failed to load project settings', isError: true);
      return;
    }

    _projectNameController.text = project.projectName;
    _problemStatementController.text = project.problemStatement ?? '';
    _projectImageUrl = project.imageUrl;
    _ownerUserId = project.userId;

    // Parse stored "Domain|Focus" tag strings
    final tags = project.tags
        .map((s) {
          final parts = s.split('|');
          if (parts.length == 2) {
            return (domain: parts[0].trim(), focus: parts[1].trim());
          }
          return null;
        })
        .whereType<_SubjectTag>()
        .toList();

    setState(() {
      _subjectTags
        ..clear()
        ..addAll(tags);
      _selectedDifficulty = project.difficulty;
      _selectedScale = project.projectScale;
      _selectedVisibility = project.visibility;
      _isLoading = false;
    });
  }

  Future<void> _pickProjectImage(ImageSource source) async {
    final imageUrl = await _mediaService.pickAndUploadImage(
      source,
      folder: 'project-images',
    );
    if (!mounted || imageUrl == null) return;
    setState(() => _projectImageUrl = imageUrl);
  }

  Future<void> _showImageSourceSheet() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Project Image'),
        message: const Text('Choose image source'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickProjectImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickProjectImage(ImageSource.gallery);
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

  void _addSubjectTag() {
    if (_activeDomain == null || _activeFocus == null) return;
    final domain = _activeDomain!;
    final focus = _activeFocus!;
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

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final tags = _subjectTags.map((t) => '${t.domain}|${t.focus}').toList();

    final success = await _projectsRepo.updateProjectMetadata(
      id: widget.projectId,
      projectName: _projectNameController.text.trim(),
      problemStatement: _problemStatementController.text.trim(),
      tags: tags,
      projectImageUrl: _projectImageUrl,
      difficulty: _selectedDifficulty,
      projectScale: _selectedScale,
      visibility: _selectedVisibility,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!success) {
      showTopSnackBar(context, 'Failed to update project settings', isError: true);
      return;
    }

    Navigator.of(context).pop({
      'project_name': _projectNameController.text.trim(),
      'tags': tags,
      'project_image_url': _projectImageUrl,
    });
  }

  Future<void> _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete project?'),
        content: const Text(
          'This will permanently delete the project and associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    // Remove challenge participation before deleting the project
    await ChallengesRepo().leaveChallenge(projectId: widget.projectId);
    final success = await _projectsRepo.deleteProject(id: widget.projectId);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!success) {
      showTopSnackBar(context, 'Failed to delete project', isError: true);
      return;
    }

    Navigator.of(context).pop({'deleted': true});
  }

  @override
  Widget build(BuildContext context) {
    final canAddTag = _activeDomain != null && _activeFocus != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.border),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Project Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.6),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project image
                    Center(
                      child: GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.accent,
                          backgroundImage: (_projectImageUrl != null &&
                                  _projectImageUrl!.isNotEmpty)
                              ? NetworkImage(_projectImageUrl!)
                              : null,
                          child: (_projectImageUrl == null ||
                                  _projectImageUrl!.isEmpty)
                              ? const Icon(Icons.camera_alt, size: 28)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Tap image to update',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Project Name
                    _fieldLabel('Project Name'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _projectNameController,
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Project name is required'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Problem Statement
                    _fieldLabel('Problem Statement'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _problemStatementController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        hintText: 'Describe the challenge this project solves',
                        hintStyle: const TextStyle(color: AppColors.hintText),
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

                    // Subject Domain & Focus
                    _fieldLabel('Subject Domain & Focus'),
                    const SizedBox(height: 10),
                    if (_subjectTags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _subjectTags
                            .map((t) => _SubjectTagChip(
                                  domain: t.domain,
                                  focus: t.focus,
                                  onRemove: () =>
                                      setState(() => _subjectTags.remove(t)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppColors.primary.withValues(alpha: 0.18)),
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
                            onChanged: (v) => setState(
                                () => _activeFocus = v),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  canAddTag ? _addSubjectTag : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                              ),
                              icon: Icon(Icons.add,
                                  size: 16,
                                  color: canAddTag
                                      ? Colors.white
                                      : Colors.grey.shade400),
                              label: Text(
                                'Add Combination',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: canAddTag
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Difficulty
                    _fieldLabel('Difficulty'),
                    const SizedBox(height: 10),
                    PillSelector(
                      value: _selectedDifficulty,
                      placeholder: 'Select Difficulty',
                      items: const ['Easy', 'Moderate', 'Hard'],
                      onChanged: (v) => setState(() => _selectedDifficulty = v),
                    ),
                    const SizedBox(height: 24),

                    // Project Scale
                    _fieldLabel('Project Scale'),
                    const SizedBox(height: 10),
                    PillSelector(
                      value: _selectedScale,
                      placeholder: 'Select Scale',
                      items: const ['Small', 'Medium', 'Large'],
                      onChanged: (v) => setState(() => _selectedScale = v),
                    ),
                    const SizedBox(height: 24),

                    // Visibility
                    _fieldLabel('Visibility'),
                    const SizedBox(height: 10),
                    if (_selectedVisibility == 'Community Only')
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
                    const SizedBox(height: 32),

                    // Collaborators
                    _fieldLabel('Collaborators'),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => CollaboratorsSheet(
                            projectId: widget.projectId,
                            projectName: _projectNameController.text,
                            isOwner: _ownerUserId != null &&
                                _ownerUserId ==
                                    AuthService.instance.currentUser?.id,
                            ownerUserId: _ownerUserId,
                          ),
                        ),
                        icon: const Icon(Icons.group_outlined),
                        label: const Text('Manage Collaborators'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SubmitButton(
                      label: 'Save Settings',
                      isLoading: _isSaving,
                      backgroundColor: AppColors.primary,
                      onPressed: _saveSettings,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _deleteProject,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Project'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/services/media_service.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
import 'package:juniper_journal/src/shared/widgets/widgets.dart';

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

  final List<String> _availableTags = const [
    'EDUCATIONAL IMPACT',
    'WATER',
    'WASTE',
    'CARBON EMISSIONS',
  ];
  final List<String> _selectedTags = [];

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load project settings')),
      );
      return;
    }

    _projectNameController.text = project.projectName;
    _problemStatementController.text = project.problemStatement ?? '';
    _projectImageUrl = project.imageUrl;

    _selectedTags
      ..clear()
      ..addAll(project.tags);

    setState(() => _isLoading = false);
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

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final success = await _projectsRepo.updateProjectMetadata(
      id: widget.projectId,
      projectName: _projectNameController.text.trim(),
      problemStatement: _problemStatementController.text.trim(),
      tags: List<String>.from(_selectedTags),
      projectImageUrl: _projectImageUrl,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update project settings')),
      );
      return;
    }

    Navigator.of(context).pop({
      'project_name': _projectNameController.text.trim(),
      'tags': List<String>.from(_selectedTags),
      'project_image_url': _projectImageUrl,
    });
  }

  Future<void> _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
    final success = await _projectsRepo.deleteProject(id: widget.projectId);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete project')));
      return;
    }

    Navigator.of(context).pop({'deleted': true});
  }

  Widget _buildTagSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _availableTags.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        return GestureDetector(
          onTap: () => setState(() {
            isSelected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD2E2DA),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFF5DB075), width: 1)
                  : null,
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Color(0xFF5DB075),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppColors.border,
          ),
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
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.6),
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
                    Center(
                      child: GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.accent,
                          backgroundImage:
                              (_projectImageUrl != null &&
                                  _projectImageUrl!.isNotEmpty)
                              ? NetworkImage(_projectImageUrl!)
                              : null,
                          child:
                              (_projectImageUrl == null ||
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
                    const Text(
                      'Project Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _projectNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Project name is required'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Problem Statement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _problemStatementController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Describe the challenge this project solves',
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTagSelector(),
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
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

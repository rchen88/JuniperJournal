import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
import 'package:juniper_journal/src/shared/widgets/widgets.dart';
import '../../../backend/db/repositories/projects_repo.dart';
import 'project_dashboard.dart';

class DefineProblemStatementScreen extends StatefulWidget {
  final String? projectId;
  final String projectName;
  final List<String> tags;
  final bool isNewProject;

  const DefineProblemStatementScreen({
    super.key,
    this.projectId,
    required this.projectName,
    required this.tags,
    this.isNewProject = false,
  });

  @override
  State<DefineProblemStatementScreen> createState() =>
      _DefineProblemStatementScreenState();
}

class _DefineProblemStatementScreenState
    extends State<DefineProblemStatementScreen> {
  final _problemController = TextEditingController();
  final _projectsRepo = ProjectsRepo();

  bool _isSaving = false;
  bool _hasChanges = false;
  DateTime? _lastSavedAt;
  Timer? _autoSaveTimer;

  final List<String> _difficultyLevels = ['Basic', 'Intermediate', 'Advanced'];
  final List<String> _subjectDomains = [
    'Environment & Sustainability',
    'Engineering & Design',
    'Energy & Systems',
    'Community & The Built Environment',
  ];
  final List<String> _progressOptions = [
    'Discovering',
    'Ideating',
    'Prototyping',
    'Testing & Iterating',
    'Implemented',
  ];

  String? _selectedDifficulty;
  String? _selectedDomain;
  String? _selectedProgress;

  @override
  void initState() {
    super.initState();
    _problemController.addListener(() => _hasChanges = true);
    if (!widget.isNewProject) {
      _autoSaveTimer = Timer.periodic(const Duration(minutes: 5), (_) => _autoSave());
      _loadProject();
    }
  }

  Future<void> _loadProject() async {
    final project = await _projectsRepo.getProjectById(widget.projectId!);
    if (!mounted) return;
    _problemController.removeListener(() => _hasChanges = true);
    _problemController.text = project?.problemStatement ?? '';
    _problemController.addListener(() => _hasChanges = true);
    setState(() {
      _selectedDifficulty = project?.difficulty;
      _selectedDomain = project?.subjectDomain;
      _selectedProgress = project?.progress;
      _hasChanges = false;
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _problemController.dispose();
    super.dispose();
  }

  String? get _savedLabel {
    if (_lastSavedAt == null) return null;
    final h = _lastSavedAt!.hour % 12 == 0 ? 12 : _lastSavedAt!.hour % 12;
    final m = _lastSavedAt!.minute.toString().padLeft(2, '0');
    final ampm = _lastSavedAt!.hour < 12 ? 'AM' : 'PM';
    return 'Saved $h:$m $ampm';
  }

  Future<bool> _persist() async {
    return _projectsRepo.updateProjectConfiguration(
      id: widget.projectId!,
      problemStatement: _problemController.text.trim(),
      difficulty: _selectedDifficulty,
      subjectDomain: _selectedDomain,
      progress: _selectedProgress,
    );
  }

  Future<void> _autoSave() async {
    if (_isSaving || !_hasChanges) return;
    setState(() => _isSaving = true);
    final ok = await _persist();
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (ok) {
        _lastSavedAt = DateTime.now();
        _hasChanges = false;
      }
    });
  }

  // Used by back button and PopScope for existing projects.
  Future<void> _saveAndPop() async {
    if (_isSaving) return;
    final navigator = Navigator.of(context);
    if (widget.isNewProject) {
      navigator.pop();
      return;
    }
    setState(() => _isSaving = true);
    await _persist();
    if (!mounted) return;
    setState(() => _isSaving = false);
    navigator.pop();
  }

  // Used by the Complete button for new projects only.
  Future<void> _complete() async {
    if (_isSaving) return;

    if (_problemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a problem statement.')),
      );
      return;
    }
    if (_selectedDomain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject domain.')),
      );
      return;
    }
    if (_selectedDifficulty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a difficulty level.')),
      );
      return;
    }
    if (_selectedProgress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a progress stage.')),
      );
      return;
    }

    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);

    final project = await _projectsRepo.createProject(
      projectName: widget.projectName,
      problemStatement: _problemController.text.trim(),
      tags: widget.tags,
      difficulty: _selectedDifficulty,
      subjectDomain: _selectedDomain,
      progress: _selectedProgress,
    );

    if (!mounted) return;

    if (project == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create project. Please try again.')),
      );
      return;
    }

    setState(() => _isSaving = false);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ProjectDashboard(
          projectId: project.id,
          projectName: widget.projectName,
          tags: widget.tags,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _showPicker(
    List<String> items,
    String? current,
    ValueChanged<String?> onChanged,
  ) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => ListTile(
              title: Text(item),
              trailing: current == item
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                onChanged(item);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndPop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              size: 30,
              color: AppColors.primary,
            ),
            onPressed: _saveAndPop,
          ),
          centerTitle: false,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.projectName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_savedLabel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    _savedLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags row
              if (widget.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...widget.tags.map((tag) => _TagChip(label: tag)),
                    const _PillAddButton(),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Problem Statement
              _sectionLabel('Problem Statement'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _problemController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'Describe the challenge your project aims to address…',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Subject Domain
              _sectionLabel('Subject Domain'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _PillDropdown(
                    value: _selectedDomain,
                    placeholder: 'Select Domain',
                    style: _PillStyle.outlined,
                    onTap: () => _showPicker(
                      _subjectDomains,
                      _selectedDomain,
                      (v) => setState(() {
                        _selectedDomain = v;
                        _hasChanges = true;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _PillAddButton(),
                ],
              ),
              const SizedBox(height: 24),

              // Difficulty
              _sectionLabel('Difficulty'),
              const SizedBox(height: 10),
              _PillDropdown(
                value: _selectedDifficulty,
                placeholder: 'Select Difficulty',
                style: _PillStyle.salmon,
                onTap: () => _showPicker(
                  _difficultyLevels,
                  _selectedDifficulty,
                  (v) => setState(() {
                    _selectedDifficulty = v;
                    _hasChanges = true;
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Progress
              _sectionLabel('Progress'),
              const SizedBox(height: 10),
              _PillDropdown(
                value: _selectedProgress,
                placeholder: 'Select Progress',
                style: _PillStyle.salmon,
                onTap: () => _showPicker(
                  _progressOptions,
                  _selectedProgress,
                  (v) => setState(() {
                    _selectedProgress = v;
                    _hasChanges = true;
                  }),
                ),
              ),
              if (widget.isNewProject) ...[
                const SizedBox(height: 40),
                SubmitButton(
                  label: 'Complete',
                  isLoading: _isSaving,
                  backgroundColor: AppColors.primary,
                  onPressed: _complete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      );
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

enum _PillStyle { outlined, salmon }

class _PillDropdown extends StatelessWidget {
  const _PillDropdown({
    required this.value,
    required this.placeholder,
    required this.style,
    required this.onTap,
  });

  final String? value;
  final String placeholder;
  final _PillStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = (value ?? placeholder).toUpperCase();

    final Color bg;
    final Color textColor;
    final BoxBorder? border;

    switch (style) {
      case _PillStyle.outlined:
        bg = const Color(0xFFE8F5E9);
        textColor = AppColors.primary;
        border = Border.all(color: AppColors.primary.withValues(alpha: 0.35));
      case _PillStyle.salmon:
        bg = const Color(0xFFFFD6D6);
        textColor = const Color(0xFFD45C5C);
        border = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: textColor),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _PillAddButton extends StatelessWidget {
  const _PillAddButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Icon(Icons.add, size: 16, color: Colors.black45),
    );
  }
}

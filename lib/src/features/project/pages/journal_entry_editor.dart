import 'dart:async';
import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';

class JournalEntryEditorScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<String> tags;
  final String entryId;
  final String initialTitle;
  final List<dynamic> initialContent;

  const JournalEntryEditorScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.tags,
    required this.entryId,
    required this.initialTitle,
    required this.initialContent,
  });

  @override
  State<JournalEntryEditorScreen> createState() =>
      _JournalEntryEditorScreenState();
}

class _JournalEntryEditorScreenState extends State<JournalEntryEditorScreen> {
  final _projectsRepo = ProjectsRepo();
  final _focusNode = FocusNode();
  late final TextEditingController _titleController;
  late final FleatherController _editorController;

  bool _isSaving = false;
  bool _hasChanges = false;
  DateTime? _lastSavedAt;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);

    ParchmentDocument doc;
    try {
      doc = ParchmentDocument.fromJson(widget.initialContent);
    } catch (_) {
      doc = ParchmentDocument();
    }
    _editorController = FleatherController(document: doc);
    _editorController.addListener(() => _hasChanges = true);
    _titleController.addListener(() => _hasChanges = true);

    // Auto-save every 5 minutes.
    _autoSaveTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _autoSave(),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _editorController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Save helpers ──────────────────────────────────────────────────────────

  Future<bool> _persist() async {
    final content =
        jsonDecode(jsonEncode(_editorController.document)) as List<dynamic>;
    return _projectsRepo.updateJournalEntry(
      entryId: widget.entryId,
      title: _titleController.text.trim(),
      content: content,
    );
  }

  /// Silent background save — updates the "Saved" timestamp, no navigation.
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

  /// Save then pop — used by the Save button and back navigation.
  Future<void> _saveAndPop() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final ok = await _persist();
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save entry')),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  // ── Saved status label ────────────────────────────────────────────────────

  String? get _savedLabel {
    if (_lastSavedAt == null) return null;
    final h = _lastSavedAt!.hour % 12 == 0 ? 12 : _lastSavedAt!.hour % 12;
    final m = _lastSavedAt!.minute.toString().padLeft(2, '0');
    final ampm = _lastSavedAt!.hour < 12 ? 'AM' : 'PM';
    return 'Saved $h:$m $ampm';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // PopScope intercepts both the system back gesture and the Android back
    // button. canPop: false blocks the default pop; we save first, then pop.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
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
            onPressed: _saveAndPop,
          ),
          title: TextField(
            controller: _titleController,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
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
            else ...[
              if (_savedLabel != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
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
              TextButton(
                onPressed: _saveAndPop,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
          shape: const Border(
            bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.6),
          ),
        ),
        body: Column(
          children: [
            FleatherToolbar.basic(controller: _editorController),
            const Divider(height: 1),
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: FleatherEditor(
                  controller: _editorController,
                  focusNode: _focusNode,
                  padding: const EdgeInsets.only(bottom: 40),
                  autofocus: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

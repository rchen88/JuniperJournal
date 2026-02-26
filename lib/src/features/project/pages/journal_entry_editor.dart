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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editorController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final content = jsonDecode(jsonEncode(_editorController.document))
        as List<dynamic>;

    final ok = await _projectsRepo.updateJournalEntry(
      entryId: widget.entryId,
      title: _titleController.text.trim(),
      content: content,
    );

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
          onPressed: () => Navigator.pop(context),
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
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}

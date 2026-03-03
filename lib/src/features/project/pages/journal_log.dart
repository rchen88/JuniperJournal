import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:juniper_journal/src/backend/db/models/journal_entry.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/features/project/pages/journal_entry_editor.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';

class JournalLogScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<String> tags;
  /// When true, skips the Scaffold/AppBar so this widget can be embedded
  /// directly inside a TabBarView or other parent scaffold.
  final bool embedded;
  /// When false, hides create/delete controls and prevents editing.
  final bool isOwner;

  const JournalLogScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.tags,
    this.embedded = false,
    this.isOwner = true,
  });

  @override
  State<JournalLogScreen> createState() => _JournalLogScreenState();
}

class _JournalLogScreenState extends State<JournalLogScreen> {
  final _projectsRepo = ProjectsRepo();

  bool _isLoading = true;
  List<JournalEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);

    var entries = await _projectsRepo.getJournalEntries(
      projectId: widget.projectId,
    );
    if (entries == null) {
      if (!mounted) return;
      setState(() {
        _entries = const <JournalEntry>[];
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _createEntry() async {
    final nextNumber = _entries.length + 1;
    final doc = jsonDecode(jsonEncode(ParchmentDocument())) as List<dynamic>;

    final created = await _projectsRepo.createJournalEntry(
      projectId: widget.projectId,
      title: 'Entry $nextNumber',
      content: doc,
    );

    if (!mounted) return;
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create journal entry')),
      );
      return;
    }

    await _openEntry(created);
  }

  Future<void> _openEntry(JournalEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryEditorScreen(
          projectId: widget.projectId,
          projectName: widget.projectName,
          tags: widget.tags,
          entryId: entry.id,
          initialTitle: entry.title.isNotEmpty ? entry.title : 'Entry',
          initialContent: entry.content.isNotEmpty
              ? entry.content
              : (jsonDecode(jsonEncode(ParchmentDocument())) as List<dynamic>),
        ),
      ),
    );

    if (!mounted) return;
    _loadEntries();
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This journal entry will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _projectsRepo.deleteJournalEntry(
      entryId: entry.id,
    );
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete entry')));
      return;
    }

    _loadEntries();
  }

  String _formattedDate(DateTime? value) {
    if (value == null) return 'No date';
    return DateFormat('MMM d, yyyy • h:mm a').format(value.toLocal());
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final list = _entries.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No journal entries yet.',
                  textAlign: TextAlign.center,
                ),
                if (widget.isOwner) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _createEntry,
                    icon: const Icon(Icons.add),
                    label: const Text('New Entry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadEntries,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.isOwner ? () => _openEntry(entry) : null,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.book_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title.isNotEmpty
                                    ? entry.title
                                    : 'Untitled Entry',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formattedDate(
                                  entry.updatedAt ?? entry.createdAt,
                                ),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isOwner)
                          IconButton(
                            tooltip: 'Delete entry',
                            onPressed: () => _deleteEntry(entry),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.black45,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );

    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Embedded mode: return body only, no Scaffold or AppBar.
    if (widget.embedded) {
      return Stack(
        children: [
          _buildBody(),
          if (widget.isOwner && !_isLoading && _entries.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                onPressed: _createEntry,
                icon: const Icon(Icons.add),
                label: const Text('New Entry'),
              ),
            ),
        ],
      );
    }

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
        title: Text(
          '${widget.projectName} Journal',
          style: const TextStyle(
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
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _createEntry,
              icon: const Icon(Icons.add),
              label: const Text('New Entry'),
            )
          : null,
      body: SafeArea(child: _buildBody()),
    );
  }
}

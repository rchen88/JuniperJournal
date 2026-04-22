import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/services/media_service.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/widgets/pill_selector.dart';
import 'package:juniper_journal/src/shared/widgets/top_snack_bar.dart';

// ── Progress options ──────────────────────────────────────────────────────────

const _progressOptions = [
  'Discovering',
  'Ideating',
  'Prototyping',
  'Testing & Iterating',
  'Implemented',
];

// ── Public screen ─────────────────────────────────────────────────────────────

class JournalEntryEditorScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<String> tags;
  final String entryId;
  final String initialTitle;
  final List<dynamic> initialContent;
  final String? initialProgress;
  final bool readOnly;

  const JournalEntryEditorScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.tags,
    required this.entryId,
    required this.initialTitle,
    required this.initialContent,
    this.initialProgress,
    this.readOnly = false,
  });

  @override
  State<JournalEntryEditorScreen> createState() =>
      _JournalEntryEditorScreenState();
}

class _JournalEntryEditorScreenState extends State<JournalEntryEditorScreen> {
  final _projectsRepo = ProjectsRepo();
  final _mediaService = MediaService();

  late final TextEditingController _titleController;
  String? _progress;

  final List<_Block> _blocks = [];
  int? _focusedIndex;

  bool _isSaving = false;
  bool _hasChanges = false;
  DateTime? _lastSavedAt;
  Timer? _autoSaveTimer;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _titleController.addListener(() => _hasChanges = true);
    _progress = widget.initialProgress;

    _initBlocks();

    if (!widget.readOnly) {
      _autoSaveTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _autoSave(),
      );
    }
  }

  void _initBlocks() {
    final raw = widget.initialContent;
    // Detect our custom format: list of maps with a "type" key
    final isCustom = raw.isNotEmpty &&
        raw.first is Map &&
        (raw.first as Map).containsKey('type');

    if (isCustom) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final block = _Block.fromJson(item);
          _listenToBlock(block);
          _blocks.add(block);
        }
      }
    }

    // Always have at least one body block
    if (_blocks.isEmpty) {
      final block = _Block.body('');
      _listenToBlock(block);
      _blocks.add(block);
    }
  }

  void _listenToBlock(_Block block) {
    block.textController?.addListener(() => _hasChanges = true);
    block.captionController?.addListener(() => _hasChanges = true);
    if (block.focusNode != null) {
      block.focusNode!.addListener(() {
        if (block.focusNode!.hasFocus) {
          final currentIdx = _blocks.indexOf(block);
          if (currentIdx != -1) setState(() => _focusedIndex = currentIdx);
        }
      });
      // Backspace at position 0: move cursor to the end of the previous line
      // without merging or deleting any content.
      block.focusNode!.onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          final ctrl = block.textController;
          if (ctrl != null) {
            final sel = ctrl.selection;
            if (sel.isCollapsed && sel.start == 0) {
              final idx = _blocks.indexOf(block);
              if (idx > 0) {
                final prev = _blocks[idx - 1];
                if (prev.focusNode != null && prev.textController != null) {
                  prev.focusNode!.requestFocus();
                  // Defer selection so it runs after the focus-in handler
                  // (which would otherwise select-all the newly focused field).
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final end = prev.textController!.text.length;
                    prev.textController!.selection =
                        TextSelection.collapsed(offset: end);
                  });
                }
              }
              return KeyEventResult.handled; // always consume — never delete content
            }
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  List<dynamic> _blocksToJson() =>
      _blocks.map((b) => b.toJson()).toList();

  Future<bool> _persist() async {
    return _projectsRepo.updateJournalEntry(
      entryId: widget.entryId,
      title: _titleController.text.trim(),
      content: _blocksToJson(),
      progress: _progress,
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

  Future<void> _saveAndPop() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final ok = await _persist();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      showTopSnackBar(context, 'Failed to save entry', isError: true);
      return;
    }
    Navigator.of(context).pop();
  }

  String? get _savedLabel {
    if (_lastSavedAt == null) return null;
    final h = _lastSavedAt!.hour % 12 == 0 ? 12 : _lastSavedAt!.hour % 12;
    final m = _lastSavedAt!.minute.toString().padLeft(2, '0');
    final ampm = _lastSavedAt!.hour < 12 ? 'AM' : 'PM';
    return 'Saved $h:$m $ampm';
  }

  // ── Block operations ────────────────────────────────────────────────────────

  void _insertAfterFocused(_Block newBlock) {
    _listenToBlock(newBlock);
    final insertAt = (_focusedIndex ?? _blocks.length - 1) + 1;
    setState(() {
      _blocks.insert(insertAt, newBlock);
      _focusedIndex = insertAt;
      _hasChanges = true;
    });
    // Request focus for text blocks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      newBlock.focusNode?.requestFocus();
    });
  }

  void _removeBlock(int index) {
    if (_blocks.length <= 1) return; // always keep at least one block
    setState(() {
      _blocks[index].dispose();
      _blocks.removeAt(index);
      _focusedIndex = null;
      _hasChanges = true;
    });
  }

  void _toggleHeaderBody() {
    final idx = _focusedIndex;
    if (idx == null || idx >= _blocks.length) return;
    final block = _blocks[idx];
    if (block.type != _BlockType.header && block.type != _BlockType.body) return;
    setState(() {
      block.type =
          block.type == _BlockType.header ? _BlockType.body : _BlockType.header;
      _hasChanges = true;
    });
  }

  // Split the line at the cursor: text before cursor stays in this line, text
  // after moves to a new body line inserted directly below.
  // Uses indexOf(block) instead of the closure-captured index so it stays
  // correct even if blocks were inserted/removed since the last rebuild.
  void _splitLineAtCursor(_Block block) {
    final idx = _blocks.indexOf(block);
    if (idx == -1) return;

    final ctrl = block.textController!;
    final cursor = ctrl.selection.isValid
        ? ctrl.selection.baseOffset
        : ctrl.text.length;
    final before = ctrl.text.substring(0, cursor);
    final after = ctrl.text.substring(cursor);

    ctrl.value = TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    );

    final newBlock = _Block.body(after);
    _listenToBlock(newBlock);
    setState(() {
      _blocks.insert(idx + 1, newBlock);
      _focusedIndex = idx + 1;
      _hasChanges = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      newBlock.focusNode?.requestFocus();
      newBlock.textController?.selection =
          const TextSelection.collapsed(offset: 0);
    });
  }

  Future<void> _insertImage(ImageSource source) async {
    final url = await _mediaService.pickAndUploadImage(
      source,
      folder: 'journal-images',
    );
    if (url == null || !mounted) return;
    _insertAfterFocused(_Block.image(url: url));
  }

  Future<void> _showInsertTableDialog() async {
    final result = await showDialog<({int rows, int cols})>(
      context: context,
      builder: (_) => const _TableSizeDialog(),
    );
    if (result == null || !mounted) return;
    _insertAfterFocused(_Block.table(rows: result.rows, cols: result.cols));
  }

  Future<void> _showInsertMathDialog() async {
    final latex = await showDialog<String>(
      context: context,
      builder: (_) => const _MathInputDialog(),
    );
    if (latex == null || latex.isEmpty || !mounted) return;
    _insertAfterFocused(_Block.math(latex));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            if (_progress != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _progress!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _blocks.length; i++)
                      _buildBlock(i, _blocks[i]),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndPop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Progress selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PillSelector(
                    value: _progress,
                    placeholder: 'Select phase',
                    items: _progressOptions,
                    onChanged: (v) => setState(() {
                      _progress = v;
                      _hasChanges = true;
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),

            // Toolbar
            _buildToolbar(),
            const Divider(height: 1, color: AppColors.divider),

            // Block content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < _blocks.length; i++)
                      _buildBlock(i, _blocks[i]),
                    // Tap empty space to focus last text block
                    GestureDetector(
                      onTap: () {
                        final lastText = _blocks.lastWhere(
                          (b) => b.focusNode != null,
                          orElse: () => _blocks.last,
                        );
                        lastText.focusNode?.requestFocus();
                      },
                      behavior: HitTestBehavior.translucent,
                      child: const SizedBox(height: 80, width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios,
            size: 18, color: AppColors.primary),
        onPressed: widget.readOnly
            ? () => Navigator.of(context).pop()
            : _saveAndPop,
      ),
      title: widget.readOnly
          ? Text(
              _titleController.text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            )
          : TextField(
              controller: _titleController,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
      actions: widget.readOnly
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Read Only',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ]
          : [
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
                        style: const TextStyle(fontSize: 11, color: Colors.black38),
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
        bottom: BorderSide(color: AppColors.divider, width: 0.6),
      ),
    );
  }

  Widget _buildToolbar() {
    final focusedBlock = _focusedIndex != null && _focusedIndex! < _blocks.length
        ? _blocks[_focusedIndex!]
        : null;
    final isTextBlock = focusedBlock?.type == _BlockType.header ||
        focusedBlock?.type == _BlockType.body;
    final isHeader = focusedBlock?.type == _BlockType.header;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // TT — toggle header/body
          _ToolbarBtn(
            child: _TtIcon(
              active: isHeader,
              enabled: isTextBlock,
            ),
            active: isHeader,
            onTap: isTextBlock ? _toggleHeaderBody : null,
            tooltip: 'Toggle header / body',
          ),
          // Square — no-op
          _ToolbarBtn(
            icon: Icons.crop_square_outlined,
            disabled: true,
            tooltip: 'Selection',
          ),
          // Paintbrush — no-op
          _ToolbarBtn(
            icon: Icons.brush_outlined,
            disabled: true,
            tooltip: 'Style',
          ),
          Container(width: 1, height: 28, color: AppColors.divider),
          // Camera
          _ToolbarBtn(
            icon: Icons.camera_alt_outlined,
            onTap: () => _insertImage(ImageSource.camera),
            tooltip: 'Take photo',
          ),
          // Gallery image
          _ToolbarBtn(
            icon: Icons.image_outlined,
            onTap: () => _insertImage(ImageSource.gallery),
            tooltip: 'Add image from gallery',
          ),
          // Table
          _ToolbarBtn(
            icon: Icons.table_chart_outlined,
            onTap: _showInsertTableDialog,
            tooltip: 'Insert table',
          ),
          // Math / π
          _ToolbarBtn(
            icon: Icons.functions_outlined,
            onTap: _showInsertMathDialog,
            tooltip: 'Insert formula',
          ),
        ],
      ),
    );
  }

  // ── Block builders ──────────────────────────────────────────────────────────

  Widget _buildBlock(int index, _Block block) {
    switch (block.type) {
      case _BlockType.header:
      case _BlockType.body:
        return _buildTextBlock(index, block);
      case _BlockType.image:
        return _buildImageBlock(index, block);
      case _BlockType.table:
        return _buildTableBlock(index, block);
      case _BlockType.math:
        return _buildMathBlock(index, block);
    }
  }

  Widget _buildTextBlock(int index, _Block block) {
    final isHeader = block.type == _BlockType.header;
    return Padding(
      padding: EdgeInsets.only(bottom: isHeader ? 6 : 2),
      child: widget.readOnly
          ? SelectableText(
              block.textController?.text ?? '',
              style: isHeader
                  ? const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    )
                  : const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.55,
                    ),
            )
          : TextField(
              controller: block.textController,
              focusNode: block.focusNode,
              maxLines: isHeader ? 1 : null,
              textInputAction: isHeader
                  ? TextInputAction.newline
                  : TextInputAction.newline,
              onSubmitted: isHeader ? (_) => _splitLineAtCursor(block) : null,
              onChanged: isHeader
                  ? (_) => _hasChanges = true
                  : (value) {
                      _hasChanges = true;
                      if (!value.contains('\n')) return;
                      final idx = value.indexOf('\n');
                      final before = value.substring(0, idx);
                      final after = value.substring(idx + 1);
                      block.textController!.value = TextEditingValue(
                        text: before,
                        selection: TextSelection.collapsed(offset: before.length),
                      );
                      final newBlock = _Block.body(after);
                      _listenToBlock(newBlock);
                      final blockIdx = _blocks.indexOf(block);
                      setState(() {
                        _blocks.insert(blockIdx + 1, newBlock);
                        _focusedIndex = blockIdx + 1;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        newBlock.focusNode?.requestFocus();
                        newBlock.textController?.selection =
                            TextSelection.collapsed(offset: 0);
                      });
                    },
              style: isHeader
                  ? const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    )
                  : const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.55,
                    ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
              ),
            ),
    );
  }

  Widget _buildImageBlock(int index, _Block block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _ImageBlockWidget(
        block: block,
        isSelected: !widget.readOnly && _focusedIndex == index,
        onSelect: widget.readOnly ? null : () => setState(() => _focusedIndex = index),
        onRemove: widget.readOnly ? null : () => _removeBlock(index),
        onMarkChanged: widget.readOnly ? null : () => _hasChanges = true,
      ),
    );
  }

  Widget _buildTableBlock(int index, _Block block) {
    final cells = block.cells!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cells.asMap().entries.map((rowEntry) {
                  final r = rowEntry.key;
                  final row = rowEntry.value;
                  return Row(
                    children: row.asMap().entries.map((colEntry) {
                      final c = colEntry.key;
                      final isFirstRow = r == 0;
                      return Container(
                        width: 110,
                        decoration: BoxDecoration(
                          color: isFirstRow
                              ? AppColors.primary.withValues(alpha: 0.06)
                              : Colors.white,
                          border: Border(
                            right: c < row.length - 1
                                ? BorderSide(color: Colors.grey.shade300)
                                : BorderSide.none,
                            bottom: r < cells.length - 1
                                ? BorderSide(color: Colors.grey.shade300)
                                : BorderSide.none,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: TextField(
                          controller: colEntry.value,
                          readOnly: widget.readOnly,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isFirstRow
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: widget.readOnly ? null : (_) => _hasChanges = true,
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeBlock(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMathBlock(int index, _Block block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.readOnly ? null : () async {
              final newLatex = await showDialog<String>(
                context: context,
                builder: (_) => _MathInputDialog(initialLatex: block.latex),
              );
              if (newLatex != null && mounted) {
                setState(() {
                  block.latex = newLatex;
                  _hasChanges = true;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Math.tex(
                  block.latex ?? '',
                  textStyle:
                      const TextStyle(fontSize: 18, color: Colors.black87),
                  onErrorFallback: (err) => Text(
                    block.latex ?? '',
                    style: const TextStyle(
                        fontFamily: 'monospace', color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeBlock(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Image block with cursor-following resize handle ───────────────────────────

class _ImageBlockWidget extends StatefulWidget {
  const _ImageBlockWidget({
    required this.block,
    required this.isSelected,
    required this.onSelect,
    required this.onRemove,
    required this.onMarkChanged,
  });

  final _Block block;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onRemove;
  final VoidCallback? onMarkChanged;

  @override
  State<_ImageBlockWidget> createState() => _ImageBlockWidgetState();
}

class _ImageBlockWidgetState extends State<_ImageBlockWidget> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final imgW =
            (maxW * widget.block.widthFraction).clamp(maxW * 0.25, maxW);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onSelect,
              child: SizedBox(
                width: imgW,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.block.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    if (widget.onRemove != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: widget.onRemove,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            SizedBox(
              width: imgW,
              child: TextField(
                controller: widget.block.captionController,
                readOnly: widget.onMarkChanged == null,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: widget.onMarkChanged == null ? null : 'Add caption…',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // Resize slider — visible when selected
            if (widget.isSelected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.photo_size_select_large_outlined,
                      size: 16, color: Colors.black38),
                  Expanded(
                    child: Slider(
                      value: widget.block.widthFraction,
                      min: 0.25,
                      max: 1.0,
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.black12,
                      onChanged: (v) {
                        setState(() => widget.block.widthFraction = v);
                        widget.onMarkChanged?.call();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(widget.block.widthFraction * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Toolbar button ────────────────────────────────────────────────────────────

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    this.icon,
    this.child,
    this.onTap,
    this.active = false,
    this.disabled = false,
    this.tooltip,
  });

  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final bool active;
  final bool disabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? Colors.black26
        : active
            ? AppColors.primary
            : Colors.black54;

    Widget inner = child ?? Icon(icon, size: 24, color: color);

    Widget content = active
        ? Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: inner),
          )
        : SizedBox(width: 44, height: 44, child: Center(child: inner));

    if (tooltip != null) {
      content = Tooltip(message: tooltip!, child: content);
    }

    if (disabled || onTap == null) return content;

    return GestureDetector(onTap: onTap, child: content);
  }
}

// ── TT icon — mimics the typography toggle in the reference ──────────────────

class _TtIcon extends StatelessWidget {
  const _TtIcon({required this.active, required this.enabled});

  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = enabled ? Colors.black54 : Colors.black26;

    // Big "T" on the left, small "T" on the right, baseline-aligned
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'T',
          style: TextStyle(
            fontSize: active ? 22 : 18,
            fontWeight: FontWeight.w700,
            color: active ? activeColor : inactiveColor,
            height: 1,
          ),
        ),
        Text(
          'T',
          style: TextStyle(
            fontSize: active ? 13 : 11,
            fontWeight: FontWeight.w500,
            color: active ? activeColor : inactiveColor,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── Table size dialog ─────────────────────────────────────────────────────────

class _TableSizeDialog extends StatefulWidget {
  const _TableSizeDialog();

  @override
  State<_TableSizeDialog> createState() => _TableSizeDialogState();
}

class _TableSizeDialogState extends State<_TableSizeDialog> {
  int _rows = 3;
  int _cols = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Insert Table'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _counter('Rows', _rows, (v) => setState(() => _rows = v), 2, 8),
          const SizedBox(height: 16),
          _counter('Columns', _cols, (v) => setState(() => _cols = v), 2, 6),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (rows: _rows, cols: _cols)),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Insert'),
        ),
      ],
    );
  }

  Widget _counter(String label, int value, ValueChanged<int> onChanged,
      int min, int max) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label)),
        IconButton(
          onPressed:
              value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed:
              value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

// ── Math input dialog ─────────────────────────────────────────────────────────

class _MathInputDialog extends StatefulWidget {
  const _MathInputDialog({this.initialLatex});

  final String? initialLatex;

  @override
  State<_MathInputDialog> createState() => _MathInputDialogState();
}

class _MathInputDialogState extends State<_MathInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLatex ?? '');
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latex = _controller.text;
    return AlertDialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Insert Formula'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: r'E = mc^2',
              labelText: 'LaTeX',
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
          if (latex.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Preview',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Math.tex(
                  latex,
                  textStyle: const TextStyle(fontSize: 18),
                  onErrorFallback: (err) => Text(
                    'Invalid formula',
                    style: TextStyle(
                        color: AppColors.error, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: latex.isNotEmpty
              ? () => Navigator.pop(context, latex)
              : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Insert'),
        ),
      ],
    );
  }
}

// ── _Block model ──────────────────────────────────────────────────────────────

enum _BlockType { header, body, image, table, math }

class _Block {
  _BlockType type;

  // text / header
  TextEditingController? textController;
  FocusNode? focusNode;

  // image
  String? imageUrl;
  TextEditingController? captionController;
  double widthFraction = 1.0; // 0.25 – 1.0

  // table
  List<List<TextEditingController>>? cells;

  // math
  String? latex;

  _Block({required this.type});

  factory _Block.header(String text) {
    final b = _Block(type: _BlockType.header);
    b.textController = TextEditingController(text: text);
    b.focusNode = FocusNode();
    return b;
  }

  factory _Block.body(String text) {
    final b = _Block(type: _BlockType.body);
    b.textController = TextEditingController(text: text);
    b.focusNode = FocusNode();
    return b;
  }

  factory _Block.image({required String url, String caption = ''}) {
    final b = _Block(type: _BlockType.image);
    b.imageUrl = url;
    b.captionController = TextEditingController(text: caption);
    return b;
  }

  factory _Block.table({required int rows, required int cols}) {
    final b = _Block(type: _BlockType.table);
    b.cells = List.generate(
      rows,
      (_) => List.generate(cols, (_) => TextEditingController()),
    );
    return b;
  }

  factory _Block.math(String latexStr) {
    final b = _Block(type: _BlockType.math);
    b.latex = latexStr;
    return b;
  }

  void dispose() {
    textController?.dispose();
    focusNode?.dispose();
    captionController?.dispose();
    cells?.forEach((row) => row.forEach((c) => c.dispose()));
  }

  Map<String, dynamic> toJson() {
    switch (type) {
      case _BlockType.header:
        return {'type': 'header', 'text': textController?.text ?? ''};
      case _BlockType.body:
        return {'type': 'body', 'text': textController?.text ?? ''};
      case _BlockType.image:
        return {
          'type': 'image',
          'url': imageUrl ?? '',
          'caption': captionController?.text ?? '',
          'widthFraction': widthFraction,
        };
      case _BlockType.table:
        return {
          'type': 'table',
          'rows': cells
                  ?.map((row) => row.map((c) => c.text).toList())
                  .toList() ??
              [],
        };
      case _BlockType.math:
        return {'type': 'math', 'latex': latex ?? ''};
    }
  }

  static _Block fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String?) {
      case 'header':
        return _Block.header((json['text'] as String?) ?? '');
      case 'image':
        final b = _Block.image(
          url: (json['url'] as String?) ?? '',
          caption: (json['caption'] as String?) ?? '',
        );
        b.widthFraction = (json['widthFraction'] as num?)?.toDouble() ?? 1.0;
        return b;
      case 'table':
        final rowsData = json['rows'] as List?;
        if (rowsData == null || rowsData.isEmpty) {
          return _Block.table(rows: 2, cols: 2);
        }
        final rows = rowsData.length;
        final cols = (rowsData.first as List?)?.length ?? 2;
        final b = _Block.table(rows: rows, cols: cols);
        for (int r = 0; r < rows; r++) {
          final rowData = rowsData[r] as List?;
          for (int c = 0; c < cols; c++) {
            b.cells![r][c].text = (rowData?[c] as String?) ?? '';
          }
        }
        return b;
      case 'math':
        return _Block.math((json['latex'] as String?) ?? '');
      default: // 'body' or unknown
        return _Block.body((json['text'] as String?) ?? '');
    }
  }
}

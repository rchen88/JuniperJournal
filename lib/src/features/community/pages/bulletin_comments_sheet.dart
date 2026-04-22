import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/db/models/bulletin_comment.dart';
import 'package:juniper_journal/src/backend/db/repositories/communities_repo.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/widgets/top_snack_bar.dart';

class BulletinCommentsSheet extends StatefulWidget {
  final String postId;
  final String postTitle;
  final int initialCommentCount;
  final void Function(int newCount)? onCountChanged;

  const BulletinCommentsSheet({
    super.key,
    required this.postId,
    required this.postTitle,
    this.initialCommentCount = 0,
    this.onCountChanged,
  });

  @override
  State<BulletinCommentsSheet> createState() => _BulletinCommentsSheetState();
}

class _BulletinCommentsSheetState extends State<BulletinCommentsSheet> {
  final _repo = CommunitiesRepo();
  final _bodyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<BulletinComment> _comments = [];
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final comments = await _repo.getBulletinComments(widget.postId);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _posting = true);
    final comment = await _repo.addBulletinComment(
      postId: widget.postId,
      body: body,
    );
    if (!mounted) return;
    setState(() => _posting = false);
    if (comment == null) {
      showTopSnackBar(context, 'Failed to post comment');
      return;
    }
    _bodyCtrl.clear();
    setState(() => _comments.add(comment));
    widget.onCountChanged?.call(_comments.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Comments list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: _loading
                ? const Center(
                    heightFactor: 3,
                    child: CircularProgressIndicator(),
                  )
                : _comments.isEmpty
                    ? const Center(
                        heightFactor: 3,
                        child: Text(
                          'No comments yet. Be the first!',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollCtrl,
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (_, i) =>
                            _CommentTile(comment: _comments[i]),
                      ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Input row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _bodyCtrl,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      hintStyle: const TextStyle(
                          color: AppColors.hintText, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppColors.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _posting ? null : _submit,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _posting
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _CommentTile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final BulletinComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          backgroundImage: (comment.authorAvatarUrl?.trim().isNotEmpty == true)
              ? NetworkImage(comment.authorAvatarUrl!)
              : null,
          child: (comment.authorAvatarUrl?.trim().isNotEmpty != true)
              ? const Icon(Icons.person_outline,
                  size: 14, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.authorLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comment.body,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/community.dart';
import 'package:juniper_journal/src/backend/db/models/community_member.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/communities_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/users_repo.dart';
import 'package:juniper_journal/src/services/media_service.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/widgets/widgets.dart';

// Preset banner colors
const _bannerColors = [
  ('Forest', '#1E4620'),
  ('Navy', '#1A237E'),
  ('Maroon', '#880E4F'),
  ('Teal', '#00695C'),
  ('Slate', '#37474F'),
  ('Indigo', '#283593'),
  ('Burgundy', '#7B1FA2'),
  ('Rust', '#BF360C'),
];

// Domain → Focus options (same as project screens)
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

class CommunitySettingsScreen extends StatefulWidget {
  final Community community;

  const CommunitySettingsScreen({super.key, required this.community});

  @override
  State<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  final _communitiesRepo = CommunitiesRepo();
  final _usersRepo = UsersRepo();
  final _mediaService = MediaService();
  final _nameController = TextEditingController();

  late String? _imageUrl;
  late String? _selectedVisibility;
  late String? _selectedColorHex;
  String? _activeDomain;
  String? _activeFocus;

  List<CommunityMember> _members = [];
  bool _isLoadingMembers = true;
  bool _isSaving = false;
  final Map<String, bool> _loadingByMemberId = {};

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.community.name;
    _imageUrl = widget.community.imageUrl;
    _selectedVisibility = widget.community.visibility;
    _selectedColorHex = widget.community.bannerColorHex;
    // Parse stored "Domain: Focus" string back into selectors
    final existing = widget.community.subjectFocus;
    if (existing != null && existing.contains(': ')) {
      final idx = existing.indexOf(': ');
      _activeDomain = existing.substring(0, idx);
      _activeFocus = existing.substring(idx + 2);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMembers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    final members =
        await _communitiesRepo.getCommunityMembers(widget.community.id);
    if (!mounted) return;
    setState(() {
      _members = members;
      _isLoadingMembers = false;
    });
  }

  Future<void> _pickImage() async {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Community Image'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              final url = await _mediaService.pickAndUploadImage(
                ImageSource.camera,
                folder: 'community-images',
              );
              if (mounted && url != null) setState(() => _imageUrl = url);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(ctx);
              final url = await _mediaService.pickAndUploadImage(
                ImageSource.gallery,
                folder: 'community-images',
              );
              if (mounted && url != null) setState(() => _imageUrl = url);
            },
            child: const Text('Choose from Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showTopSnackBar(context, 'Community name cannot be empty');
      return;
    }
    setState(() => _isSaving = true);
    final subjectFocus = (_activeDomain != null && _activeFocus != null)
        ? '$_activeDomain: $_activeFocus'
        : (_activeDomain != null ? _activeDomain : null);

    final ok = await _communitiesRepo.updateCommunity(
      id: widget.community.id,
      name: name,
      imageUrl: _imageUrl,
      visibility: _selectedVisibility,
      subjectFocus: subjectFocus,
      bannerColorHex: _selectedColorHex,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      showTopSnackBar(context, 'Failed to save settings', isError: true);
      return;
    }
    // Return updated community to caller
    final updated = widget.community.copyWith(
      name: name,
      imageUrl: _imageUrl,
      visibility: _selectedVisibility,
      subjectFocus: subjectFocus,
      bannerColorHex: _selectedColorHex,
    );
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Community?'),
        content: Text(
          'This will permanently delete "${widget.community.name}", '
          'remove all members, and delete the group chat and all its messages. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    final ok = await _communitiesRepo.deleteCommunity(widget.community);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!ok) {
      showTopSnackBar(context, 'Failed to delete community', isError: true);
      return;
    }

    // Pop settings, then pop community home — back to the home feed
    Navigator.of(context).pop('deleted');
  }

  Future<void> _removeMember(CommunityMember member) async {
    final currentUserId = AuthService.instance.currentUser?.id;
    if (member.userId == currentUserId) return; // can't remove yourself

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(member.status == 'pending'
            ? 'Cancel invite?'
            : 'Remove member?'),
        content: Text(member.status == 'pending'
            ? 'Cancel the invite for ${member.resolvedName}?'
            : 'Remove ${member.resolvedName} from this community?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loadingByMemberId[member.memberId] = true);
    final ok = await _communitiesRepo.removeMember(member.memberId);
    if (!mounted) return;
    setState(() => _loadingByMemberId.remove(member.memberId));
    if (ok) _loadMembers();
  }

  Future<void> _openAddMemberDialog() async {
    final result = await showDialog<UserProfile>(
      context: context,
      builder: (_) => _UserSearchDialog(
        excludeIds: _members.map((m) => m.userId).toSet(),
      ),
    );
    if (result == null || !mounted) return;

    final ok = await _communitiesRepo.inviteMember(
      communityId: widget.community.id,
      userId: result.id,
    );
    if (!mounted) return;
    if (ok) {
      _loadMembers();
    } else {
      showTopSnackBar(context, 'Failed to send invite', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.instance.currentUser?.id;
    final accepted =
        _members.where((m) => m.status == 'accepted').toList();
    final pending =
        _members.where((m) => m.status == 'pending').toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Community Settings',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: _selectedColorHex != null
                          ? widget.community
                              .copyWith(bannerColorHex: _selectedColorHex)
                              .bannerColor
                          : widget.community.bannerColor,
                      backgroundImage:
                          (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? NetworkImage(_imageUrl!)
                              : null,
                      child: (_imageUrl == null || _imageUrl!.isEmpty)
                          ? const Icon(Icons.group,
                              size: 32, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Tap to update image',
                  style: TextStyle(
                      color: Colors.black45, fontSize: 12)),
            ),
            const SizedBox(height: 24),

            // ── Banner Color ────────────────────────────────────────────────
            _sectionLabel('Banner Color'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _bannerColors.map((entry) {
                final (label, hex) = entry;
                final color =
                    Color(int.parse('FF${hex.replaceFirst('#', '')}',
                        radix: 16));
                final isSelected = (_selectedColorHex ?? '#1E4620')
                        .toUpperCase() ==
                    hex.toUpperCase();
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedColorHex = hex),
                  child: Tooltip(
                    message: label,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Name ────────────────────────────────────────────────────────
            _sectionLabel('Community Name'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Visibility ──────────────────────────────────────────────────
            _sectionLabel('Visibility'),
            const SizedBox(height: 10),
            PillSelector(
              value: _selectedVisibility,
              placeholder: 'Select',
              items: const ['Public', 'Private'],
              onChanged: (v) =>
                  setState(() => _selectedVisibility = v),
            ),
            const SizedBox(height: 24),

            // ── Subject Focus — Domain + Focus stacked picker ───────────────
            _sectionLabel('Subject Domain & Focus'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18)),
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
                    onChanged: (v) => setState(() => _activeFocus = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Save ────────────────────────────────────────────────────────
            SubmitButton(
              label: 'Save Settings',
              isLoading: _isSaving,
              backgroundColor: AppColors.primary,
              onPressed: _saveSettings,
            ),
            const SizedBox(height: 36),

            // ── Members ─────────────────────────────────────────────────────
            Row(
              children: [
                _sectionLabel('Members'),
                const Spacer(),
                GestureDetector(
                  onTap: _openAddMemberDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        const Text('Invite',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingMembers)
              const Center(
                  child:
                      Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else ...[
              // Accepted members
              ...accepted.map((m) => _MemberRow(
                    member: m,
                    isCurrentUser: m.userId == currentUserId,
                    isLoading: _loadingByMemberId[m.memberId] == true,
                    onRemove: () => _removeMember(m),
                  )),

              // Pending invites section
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Pending Invites',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ...pending.map((m) => _MemberRow(
                      member: m,
                      isCurrentUser: false,
                      isLoading:
                          _loadingByMemberId[m.memberId] == true,
                      onRemove: () => _removeMember(m),
                      isPending: true,
                    )),
              ],
            ],

            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _handleDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Delete Community',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87),
      );
}

// ── _MemberRow ────────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isCurrentUser,
    required this.isLoading,
    required this.onRemove,
    this.isPending = false,
  });

  final CommunityMember member;
  final bool isCurrentUser;
  final bool isLoading;
  final VoidCallback onRemove;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: (member.avatarUrl != null &&
                    member.avatarUrl!.isNotEmpty)
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                ? const Icon(Icons.person_outline,
                    size: 20, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.resolvedName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  isPending
                      ? 'Invite pending'
                      : member.role == 'owner'
                          ? 'Owner'
                          : 'Member',
                  style: TextStyle(
                    fontSize: 12,
                    color: member.role == 'owner'
                        ? AppColors.primary
                        : Colors.grey.shade500,
                    fontWeight: member.role == 'owner'
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else if (!isCurrentUser && member.role != 'owner')
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPending ? Icons.cancel_outlined : Icons.person_remove_outlined,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── _UserSearchDialog ─────────────────────────────────────────────────────────

class _UserSearchDialog extends StatefulWidget {
  const _UserSearchDialog({required this.excludeIds});
  final Set<String> excludeIds;

  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final _controller = TextEditingController();
  final _usersRepo = UsersRepo();
  Timer? _debounce;
  List<UserProfile> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _controller.text.trim();
      if (q.isEmpty) {
        if (mounted) setState(() => _results = []);
        return;
      }
      if (mounted) setState(() => _isSearching = true);
      final all = await _usersRepo.searchPublicUsers(query: q) ?? [];
      final excluded = {
        ...widget.excludeIds,
        if (AuthService.instance.currentUser != null)
          AuthService.instance.currentUser!.id,
      };
      if (mounted) {
        setState(() {
          _results = all.where((u) => !excluded.contains(u.id)).toList();
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: AppColors.primary, size: 22),
                ),
                const Expanded(
                  child: Text('Invite Member',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 22),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search users',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 8),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: _results
                      .map((u) => ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary
                                  .withValues(alpha: 0.12),
                              backgroundImage: (u.avatarUrl != null &&
                                      u.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(u.avatarUrl!)
                                  : null,
                              child: (u.avatarUrl == null ||
                                      u.avatarUrl!.isEmpty)
                                  ? const Icon(Icons.person_outline,
                                      size: 16,
                                      color: AppColors.primary)
                                  : null,
                            ),
                            title: Text(u.resolvedDisplayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: u.username != null
                                ? Text('@${u.username!}',
                                    style: const TextStyle(
                                        fontSize: 12))
                                : null,
                            onTap: () =>
                                Navigator.pop(context, u),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

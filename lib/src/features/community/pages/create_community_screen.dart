import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/auth/auth_service.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/communities_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/users_repo.dart';
import 'package:juniper_journal/src/features/community/pages/community_home_screen.dart';
import 'package:juniper_journal/src/services/media_service.dart';
import 'package:juniper_journal/src/shared/styling/app_colors.dart';
import 'package:juniper_journal/src/shared/widgets/widgets.dart';
import 'package:image_picker/image_picker.dart';

// Domain → Focus options (same data as project screens)
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

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _nameController = TextEditingController();
  final _communitiesRepo = CommunitiesRepo();
  final _mediaService = MediaService();

  String? _imageUrl;
  String? _selectedVisibility;
  String? _activeDomain;
  String? _activeFocus;
  List<UserProfile> _pendingMembers = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  Future<void> _openAddMemberDialog() async {
    final result = await showDialog<List<UserProfile>>(
      context: context,
      builder: (_) =>
          _AddMemberDialog(existingMembers: List.from(_pendingMembers)),
    );
    if (result != null) setState(() => _pendingMembers = result);
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showTopSnackBar(context, 'Enter a community name');
      return;
    }
    setState(() => _isCreating = true);

    final subjectFocus = (_activeDomain != null && _activeFocus != null)
        ? '$_activeDomain: $_activeFocus'
        : (_activeDomain != null ? _activeDomain : null);

    final community = await _communitiesRepo.createCommunity(
      name: name,
      imageUrl: _imageUrl,
      visibility: _selectedVisibility ?? 'public',
      subjectFocus: subjectFocus,
      memberIds: _pendingMembers.map((m) => m.id).toList(),
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (community == null) {
      showTopSnackBar(context, 'Failed to create community', isError: true);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CommunityHomeScreen(community: community),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Create Community',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary,
                  backgroundImage:
                      (_imageUrl != null && _imageUrl!.isNotEmpty)
                          ? NetworkImage(_imageUrl!)
                          : null,
                  child: (_imageUrl == null || _imageUrl!.isEmpty)
                      ? const Icon(Icons.camera_alt,
                          size: 28, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Tap Image to Update',
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Community Name
            _label('Community Name'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Visibility
            _label('Visibility'),
            const SizedBox(height: 10),
            PillSelector(
              value: _selectedVisibility,
              placeholder: 'Public',
              items: const ['Public', 'Private'],
              onChanged: (v) => setState(() => _selectedVisibility = v),
            ),
            const SizedBox(height: 24),

            // Subject Focus — Domain + Focus stacked picker
            _label('Subject Domain & Focus'),
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
            const SizedBox(height: 24),

            // Add Member
            Row(
              children: [
                _label('Add Member'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _openAddMemberDialog,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Icon(Icons.add,
                        size: 16, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
            if (_pendingMembers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pendingMembers
                    .map((m) => _MemberChip(profile: m))
                    .toList(),
              ),
            ],
            const SizedBox(height: 48),

            // Create button
            SubmitButton(
              label: 'Create',
              isLoading: _isCreating,
              backgroundColor: AppColors.primary,
              onPressed: _handleCreate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      );
}

// ── _MemberChip ───────────────────────────────────────────────────────────────

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: (profile.avatarUrl != null &&
                    profile.avatarUrl!.isNotEmpty)
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                ? const Icon(Icons.person_outline,
                    size: 12, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            profile.resolvedDisplayName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── _AddMemberDialog ──────────────────────────────────────────────────────────

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog({required this.existingMembers});
  final List<UserProfile> existingMembers;

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _searchController = TextEditingController();
  final _usersRepo = UsersRepo();
  Timer? _debounce;
  UserProfile? _ownerProfile;
  List<UserProfile> _members = [];
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.existingMembers);
    _loadOwner();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOwner() async {
    final profile = await _usersRepo.getCurrentUserProfile();
    if (mounted) setState(() => _ownerProfile = profile);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _searchController.text.trim();
      if (q.isEmpty) {
        if (mounted) setState(() => _searchResults = []);
        return;
      }
      if (mounted) setState(() => _isSearching = true);
      final results = await _usersRepo.searchPublicUsers(query: q) ?? [];
      final excluded = {
        ..._members.map((m) => m.id),
        if (_ownerProfile != null) _ownerProfile!.id,
        if (AuthService.instance.currentUser != null)
          AuthService.instance.currentUser!.id,
      };
      if (mounted) {
        setState(() {
          _searchResults =
              results.where((u) => !excluded.contains(u.id)).toList();
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: AppColors.primary, size: 22),
                  ),
                  const Expanded(
                    child: Text(
                      'Add Member',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search users',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else if (_searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 8,
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: _searchResults
                        .map((u) => ListTile(
                              dense: true,
                              title: Text(u.resolvedDisplayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              subtitle: u.username != null
                                  ? Text(u.username!,
                                      style: const TextStyle(fontSize: 12))
                                  : null,
                              onTap: () => setState(() {
                                _members.add(u);
                                _searchResults.clear();
                                _searchController.clear();
                              }),
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: _members
                      .map((m) => ListTile(
                            dense: true,
                            title: Text(m.resolvedDisplayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            trailing: GestureDetector(
                              onTap: () =>
                                  setState(() => _members.remove(m)),
                              child: Icon(Icons.close,
                                  size: 16,
                                  color: Colors.grey.shade400),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _members),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

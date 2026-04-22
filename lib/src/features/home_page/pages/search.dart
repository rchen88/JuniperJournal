import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juniper_journal/src/backend/db/models/project.dart';
import 'package:juniper_journal/src/backend/db/models/user_profile.dart';
import 'package:juniper_journal/src/backend/db/repositories/friends_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/projects_repo.dart';
import 'package:juniper_journal/src/backend/db/repositories/users_repo.dart';
import 'package:juniper_journal/src/features/project/project.dart';
import 'package:juniper_journal/src/shared/styling/theme.dart';
import 'package:juniper_journal/src/shared/widgets/top_snack_bar.dart';

enum SearchScope { projects, friends }

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final _projectsRepo = ProjectsRepo();
  final _usersRepo = UsersRepo();
  final _friendsRepo = FriendsRepo();
  final _queryController = TextEditingController();
  Timer? _friendsSearchDebounce;

  SearchScope _scope = SearchScope.projects;
  bool _isLoading = true;
  List<Project> _projects = const [];
  bool _isFriendsLoading = false;
  final Map<String, bool> _actionLoadingByUserId = {};
  String? _friendsErrorMessage;
  List<UserProfile> _friends = const [];
  Map<String, String> _friendStatuses = const {};

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProjects();
    });
  }

  @override
  void dispose() {
    _friendsSearchDebounce?.cancel();
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (!mounted) return;
    setState(() {});
    if (_scope == SearchScope.friends) {
      _friendsSearchDebounce?.cancel();
      _friendsSearchDebounce = Timer(
        const Duration(milliseconds: 250),
        _searchFriends,
      );
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final rows = await _projectsRepo.getCurrentUserProjects();
    if (!mounted) return;

    setState(() {
      _projects = rows ?? const <Project>[];
      _isLoading = false;
    });
  }

  Future<void> _searchFriends() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _friends = const [];
        _isFriendsLoading = false;
        _friendsErrorMessage = null;
      });
      return;
    }

    setState(() {
      _isFriendsLoading = true;
      _friendsErrorMessage = null;
    });

    final users = await _usersRepo.searchPublicUsers(query: query);
    if (!mounted) return;

    if (users == null) {
      setState(() {
        _friends = const [];
        _friendStatuses = const {};
        _isFriendsLoading = false;
        _friendsErrorMessage = 'Search unavailable. Please try again.';
      });
      return;
    }

    final ids = users.map((u) => u.id).where((id) => id.isNotEmpty).toList();
    final statuses = await _friendsRepo.getRelationshipStatuses(ids);
    if (!mounted) return;

    setState(() {
      _friends = users;
      _friendStatuses = statuses;
      _isFriendsLoading = false;
    });
  }

  List<Project> _filteredProjects() {
    final query = _queryController.text.trim().toLowerCase();
    if (query.isEmpty) return _projects;

    return _projects.where((project) {
      final name = project.projectName.toLowerCase();
      final tags = project.tags.map((e) => e.toLowerCase()).join(' ');
      return name.contains(query) || tags.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final projects = _filteredProjects();

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
        title: const Text(
          'Search',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  hintText: _scope == SearchScope.projects
                      ? 'Search projects by name or tag'
                      : 'Search friends',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSlidingSegmentedControl<SearchScope>(
                groupValue: _scope,
                children: const {
                  SearchScope.projects: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Projects'),
                  ),
                  SearchScope.friends: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Friends'),
                  ),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() => _scope = value);
                  if (value == SearchScope.friends) {
                    _searchFriends();
                  }
                },
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _scope == SearchScope.projects
                  ? (_isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : (projects.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No matching projects',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),
                                  itemBuilder: (context, index) {
                                    final project = projects[index];
                                    final projectName = project.projectName.isNotEmpty
                                        ? project.projectName
                                        : 'Untitled Project';
                                    final projectId = project.id;
                                    final tags = project.tags;

                                    return ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      tileColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFFE6F2E9,
                                        ),
                                        child: const Icon(
                                          Icons.folder_outlined,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      title: Text(
                                        projectName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: tags.isEmpty
                                          ? const Text('No tags')
                                          : Text(tags.join(' • ')),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProjectDashboard(
                                              projectId: projectId,
                                              projectName: projectName,
                                              tags: tags,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemCount: projects.length,
                                )))
                  : _buildFriendsResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsResults() {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Search for friends by name or username.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    if (_isFriendsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendsErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _friendsErrorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    if (_friends.isEmpty) {
      return Center(
        child: Text(
          'No friends found for "$query".',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemBuilder: (context, index) {
        final user = _friends[index];
        final displayName =
            user.displayName ?? user.username ?? 'Unknown User';
        final username = user.username;
        final avatarUrl = user.avatarUrl;
        final status = _friendStatuses[user.id] ?? 'none';

        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryTint,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person_outline, color: AppColors.primary)
                : null,
          ),
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: (username != null && username.isNotEmpty)
              ? Text('@$username')
              : const Text('Public profile'),
          trailing: _buildFriendActionButton(
            userId: user.id,
            status: status,
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: _friends.length,
    );
  }

  Widget _buildFriendActionButton({
    required String userId,
    required String status,
  }) {
    if (_actionLoadingByUserId[userId] == true) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (status == 'friends') {
      return const Chip(
        label: Text('Friends'),
        visualDensity: VisualDensity.compact,
      );
    }

    if (status == 'pending_outgoing') {
      return const OutlinedButton(onPressed: null, child: Text('Pending'));
    }

    if (status == 'pending_incoming') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () => _declineRequest(userId),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Decline'),
          ),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: () => _acceptRequest(userId),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Accept'),
          ),
        ],
      );
    }

    return FilledButton(
      onPressed: () => _sendRequest(userId),
      child: const Text('Add'),
    );
  }

  Future<void> _sendRequest(String userId) async {
    if (userId.isEmpty) return;
    setState(() => _actionLoadingByUserId[userId] = true);
    final ok = await _friendsRepo.sendFriendRequest(addresseeId: userId);
    if (!mounted) return;

    setState(() => _actionLoadingByUserId.remove(userId));
    if (!ok) {
      showTopSnackBar(context, 'Failed to send friend request', isError: true);
      return;
    }
    _searchFriends();
  }

  Future<void> _acceptRequest(String requesterId) async {
    if (requesterId.isEmpty) return;
    setState(() => _actionLoadingByUserId[requesterId] = true);
    final ok = await _friendsRepo.acceptFriendRequest(requesterId: requesterId);
    if (!mounted) return;

    setState(() => _actionLoadingByUserId.remove(requesterId));
    if (!ok) {
      showTopSnackBar(context, 'Failed to accept request', isError: true);
      return;
    }
    _searchFriends();
  }

  Future<void> _declineRequest(String requesterId) async {
    if (requesterId.isEmpty) return;
    setState(() => _actionLoadingByUserId[requesterId] = true);
    final ok =
        await _friendsRepo.declineFriendRequest(requesterId: requesterId);
    if (!mounted) return;

    setState(() => _actionLoadingByUserId.remove(requesterId));
    if (!ok) {
      showTopSnackBar(context, 'Failed to decline request', isError: true);
      return;
    }
    _searchFriends();
  }
}

# Code Review Memory — JuniperJournal

## Project Stack
- Flutter (Dart), Supabase backend, fleather rich-text editor
- Package prefix: `juniper_journal`
- Styling: `AppColors` in `lib/src/shared/styling/app_colors.dart`
- Auth: singleton `AuthService.instance`, wraps `SupabaseDatabase.instance.client`
- Repos: instantiated inline per-widget (`final _repo = SomeRepo()`), not injected

## Confirmed Conventions
- Repos use `static const table = 'table_name'` for table identifiers
- All repo methods catch exceptions, log via `debugPrint`, and return null/false on error
- `mounted` guard always checked after every `await` before calling `setState`
- `const` used consistently on leaf widgets; `IndexedStack` used for tab bodies
- `FriendsRepo.getRelationshipStatuses` makes 4 sequential DB queries (known pattern, candidate for RPC)
- `_client` getter is untyped (`get _client`) in both repos — returns dynamic

## Recurring Issues Found (2026-03-02 review)
- Hardcoded color literals scattered across UI files instead of using `AppColors` constants
- `_mapAuthApiError` defined but never called in `signup.dart` (dead code pattern)
- `_handleGoogleLogin/Signup` methods exist but are commented out at the UI level — dead business logic
- `logCurrentUser()` debug method left on `AuthService` — deployment concern
- `FocusNode` for `_usernameFocus` in `login.dart` never disposed — resource leak
- OAuth redirect hardcodes `io.supabase.flutterquickstart://login-callback/` — leftover quickstart template value
- `_buildMetaPillsRow` in `project_dashboard.dart` uses all hardcoded placeholder strings with a TODO comment
- `_ProjectCard` instantiates `ProjectsRepo()` per card instance — should be passed in or inherited
- `_isLiking` flag in `_ProjectCardState` is not reset inside `setState` — async-safety gap
- `updateCurrentUserProfile` builds a map that always includes `id` key, then calls upsert — silently touches row even when no fields changed
- Comment icon in `_ProjectCard` (`GestureDetector onTap: () {}`) is a no-op stub
- `textSecondary` in `AppColors` has same hex value as `textPrimary` — likely a copy-paste bug

## Architecture Notes
- `HomeShellScreen` owns `FriendsRepo`, `ChatRepo`, `ProjectsRepo` — heavy direct coupling
- `JournalLogScreen` supports both embedded and standalone mode via `embedded` flag
- `_loadFeedProjects` populates side-effect maps (`_ownerLabelByUserId`, `_ownerAvatarByUserId`) instead of returning a structured result — makes testing harder
- Legacy journal migration runs inline during `_loadEntries` with no migration guard (could re-run)
- See `patterns.md` for detailed notes

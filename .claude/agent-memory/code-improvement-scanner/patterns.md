# Patterns & Detailed Notes

## Repo Instantiation Pattern
Repos are always instantiated directly in widget state: `final _repo = SomeRepo()`.
There is no DI framework. This is a consistent team convention, but creates a new
instance per widget/card. For high-frequency list items (e.g., _ProjectCard), this
creates many identical repo objects.

## Error Handling Pattern
All repo methods return null or false on exception, never rethrow. The UI checks
null/false and shows a SnackBar. This pattern is consistent and intentional.

## Auth Navigation Pattern
Sign-out/delete always does `pushAndRemoveUntil` to `JuniperAuthScreen` to clear stack.
This pattern is duplicated in both `home.dart` and `settings.dart` — good candidate
for a shared navigation helper.

## FriendsRepo DB Query Pattern
`getRelationshipStatuses` fires 4 sequential Supabase queries. These could be combined
into a single query using `.or()` across all conditions, or moved to a Postgres RPC.
This is the most expensive query pattern in the codebase.

## Mixed Import Styles
`login.dart` and `signup.dart` use relative imports for auth_service
(`'../../../backend/auth/auth_service.dart'`) while all other files use
package imports. This inconsistency should be normalized to package imports.

## Hardcoded Colors Still Present
Despite `AppColors` existing, several files still use raw `Color(0xFFXXXXXX)` literals,
particularly for avatar backgrounds (`0xFFE6F2E9`, `0xFFE8F4EC`), icon colors (`0xFF5B7B63`),
and the like-button green (`0xFF2A7A38`). These should be centralized.

## Dead Google OAuth Code
Both login.dart and signup.dart have `_handleGoogleLogin` / `_handleGoogleSignup` methods
that are fully implemented but never called (only referenced in commented-out UI code).
The OAuth redirect URL `io.supabase.flutterquickstart://login-callback/` is also a
leftover quickstart template value that must be replaced before enabling OAuth.

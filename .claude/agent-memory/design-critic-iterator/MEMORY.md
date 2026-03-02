# Design Critic Agent Memory

## Project: JuniperJournal (Flutter mobile app)

### Brand / Design System
- Primary green: `AppColors.primary` = `Color(0xFF5DB075)`
- Background: white `Color(0xFFFFFFFF)`
- Blue accent: `AppColors.blue` = `Color(0xFF2C70BF)`
- Text primary: `Color(0xFF212121)` (dark grey)
- Light grey text: `Color(0xFF868686)`
- Border light: `Color(0xFFE0E0E0)`
- Rounded corner convention in existing widgets: 12–18px radius

### Key Files Reviewed
- Profile page: `lib/src/features/home_page/pages/user_profile.dart`
- Social connections page: `lib/src/features/home_page/pages/social_connections.dart`
- App colors: `lib/src/shared/styling/app_colors.dart`

### Known Implementation State (as of first review)
- Profile page uses `Column` + `SingleChildScrollView` — no rounded white card over green header
- Tab bar uses `BoxDecoration` indicator (colored pill) — target design wants vertical-line separators only
- Friends list uses `ListTile` inside `ListView.separated` with thin `Divider` — not individual rounded cards
- Friend subtitle shows `@username` — target wants "XXX Points" style
- Friends tab has no header row (count + action icon buttons)
- Activity tab is a placeholder "coming soon" — target has styled activity cards with green arrow icons
- Avatar overlap: `Positioned(bottom: -56)` with avatar height 112px; white content starts with `SizedBox(height: 68)` — visually functional but not a rounded card

### User Preferences / Feedback Style
- Wants concise numbered lists ordered by visual impact
- Wants specific Flutter widget/property suggestions per item
- Feedback depth: implementation-specific (code-level detail expected)

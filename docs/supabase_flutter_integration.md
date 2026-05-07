# Supabase Flutter Integration Notes

This app now has a repository layer that can read from Supabase when configured
and falls back to the local prototype data when Supabase is unavailable.

## Runtime Configuration

Run the Flutter app with public Supabase values only:

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://gwuzlcmuxcokfpnaofjc.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your_publishable_or_anon_key
```

Do not put these values in Flutter:

- service role key
- database password
- secret key
- Stripe/webhook secrets
- Backblaze/S3 secrets

Those belong in Supabase Edge Functions or server-side environments.

## Added Flutter Data Layer

- `lib/data/supabase/`
  - Supabase initialization from `--dart-define`.
- `lib/data/repositories/`
  - Auth repository.
  - Project repository.
  - Feed repository.
  - Profile repository.
  - Saved content repository.
- `lib/data/mappers/`
  - Enum and row mappers between Arabic Flutter labels and Supabase enum values.
- `lib/data/local/`
  - Local seed data used as offline/prototype fallback.

## Added Supabase Migration

Run this migration in Supabase SQL editor or Supabase CLI:

```text
supabase/migrations/20260506100000_flutter_integration_bridge.sql
```

It adds:

- `project_details`
- `project_applications`
- `saved_items`
- `connection_requests`
- `post_reports`
- `get_projects_for_app`
- `create_project_for_app`
- `apply_to_project_for_app`
- `save_item_for_app`
- `request_connection_for_app`
- `get_network_profiles_for_app`

The migration also grants the app-facing RPCs to the correct Supabase roles and
adds RLS policies for owner-only saved content, project applications, connection
requests, and reports.

## Connected App Flows

- Signup creates the Supabase Auth user, upserts `profiles`, and writes the
  matching detail table for engineers, companies, craftspeople, or equipment.
- Phone OTP calls `send-otp` and verifies with `verify_otp_token`; the local
  fallback code remains `123456` for prototype runs without Supabase.
- The home feed reads from `get_home_feed` when available, then `posts`, then
  local seed data.
- The projects page reads from `get_projects_for_app`, then `projects`, then
  local seed data.
- Project publishing calls `create_project_for_app` and stores the detailed
  multi-step form data in `project_details`.
- Project applications call `apply_to_project_for_app` and are mirrored in the
  user's saved/applied content.
- Saved posts, reels, projects, companies, and stories use `save_item_for_app`
  when the migration is installed and otherwise remain local.
- My Network reads real profile cards from `get_network_profiles_for_app`.
  Engineers see engineers/craftspeople/workers/equipment users in the people
  tab and companies in the companies tab. Companies see engineers only. Other
  account types receive an empty access state.

## Important Mapping Decisions

Flutter account types map to Supabase like this:

| Flutter | Supabase |
|---|---|
| engineer | engineer |
| company | contractor |
| craftsman | craftsman |
| worker | worker |
| equipment | machinery |

## First Production Checklist

1. Apply the migration.
2. Confirm RLS policies on base tables: `profiles`, `projects`, `posts`,
   `messages`, `reels`, `stories`.
3. Confirm `send-otp` Edge Function accepts `{ "phone": "+964..." }`.
4. Confirm `verify_otp_token` accepts:
   - `p_phone_local10`
   - `p_verification_code`
5. Run Flutter with `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
6. Test signup with a real Supabase auth user.
7. Test project fetching and application submission.

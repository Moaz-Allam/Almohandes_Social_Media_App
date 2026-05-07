# Comprehensive Testing Strategy

This document defines the testing scope for `المهندس`, an RTL Flutter app
connected to Supabase for project collaboration, feeds, reels, profiles,
messages, premium courses, and saved content.

## Testing Goals

- Verify every critical user flow from onboarding to project application.
- Catch UI regressions in Arabic RTL layouts, light/dark themes, and small
  mobile viewports.
- Protect Supabase integration points: auth, OTP, profiles, posts, projects,
  applications, saved content, RLS policies, RPC functions, and Edge Functions.
- Keep the app fast by testing caching, request de-duplication, loading states,
  and refresh behavior.
- Make failures easy to debug by testing features in layers.

## Test Pyramid

### 1. Static Analysis

Run:

```powershell
flutter analyze
```

Coverage:

- Dart type safety.
- Lint rules.
- Unused imports and dead code.
- Async context misuse.
- Theme and constructor mistakes.

Acceptance:

- Zero analyzer errors.
- Info-level lint warnings should be fixed unless intentionally documented.

### 2. Unit Tests

Run:

```powershell
flutter test test/data
flutter test test/state
```

Targets:

- `SignupController`
  - Iraqi phone number validation.
  - Confirm password matching.
  - Account type switching resets specialization.
  - Governorate and specialization mapping.
- `AccountType`
  - Engineers and companies can post projects.
  - Craftspeople, workers, and equipment accounts cannot post projects.
  - Supabase role mapping stays stable.
- `TimedMemoryCache`
  - Fresh reads reuse cached values.
  - Concurrent reads share a single in-flight request.
  - Forced refresh bypasses cache.
  - Expired values refetch.
- Mappers
  - Supabase enum values map to Arabic UI values.
  - Arabic form selections map to Supabase enum values.
  - Feed/project rows tolerate missing optional fields.
- Project draft parsing
  - Budget range parsing.
  - Required skill splitting by comma, Arabic comma, and new line.
  - Default location/currency fallbacks.

### 3. Repository Tests

Targets:

- Auth repository
  - Local fallback signs in without Supabase.
  - Email login uses email auth.
  - Phone login normalizes Iraqi phone numbers.
  - Signup writes `profiles` and correct detail table.
  - OTP fallback works only for local prototype mode.
- Feed repository
  - Uses `get_home_feed` first.
  - Falls back to `posts` query.
  - Falls back to local seed data.
  - Does not repeat DB requests within cache TTL.
- Project repository
  - Uses `get_projects_for_app` first.
  - Project creation uses `create_project_for_app`.
  - Project application uses `apply_to_project_for_app`.
  - Forced refresh bypasses cache.
- Saved content repository
  - Uses `save_item_for_app`.
  - Falls back to `saved_items`.
  - Save/remove update local cache.

### 4. Widget Tests

Run:

```powershell
flutter test test/widget_test.dart
flutter test test/ui
```

Core user flows:

- Onboarding
  - Three onboarding screens display Arabic content.
  - Apple/social signup options are absent.
  - Join now opens signup.
- Signup
  - Account type selection.
  - Required Iraqi phone number.
  - Confirm password.
  - OTP screen after account basics.
  - Engineer/company/craftsman/worker/equipment specialization pages.
  - Governorate selection.
- Sign in
  - Email/password and phone/password.
  - Invalid credentials show feedback.
  - Successful session opens shell.
- Home feed
  - Top bar search/messages/menu.
  - Stories strip with create story tile.
  - Skeleton cards while posts load.
  - Posts render after load.
  - Like toggles icon color and count immediately.
  - Comments sheet opens.
  - Save/report menu opens from three dots.
  - Repost asks for confirmation.
  - Send opens contact picker then chat.
- Reels
  - Skeleton while reel player prepares.
  - Vertical swipe changes reel.
  - Progress bar advances and auto-advances.
  - Like animation appears.
  - Comments sheet opens.
  - Send opens contact picker.
- Network
  - Invitation arrow is correct in RTL.
  - Invitations list has check and X icons.
  - Engineers see all account types.
  - Companies see engineers only.
  - Other users see no recommendations.
- Profiles
  - My profile uses posts/about/saved structure.
  - Other profile uses posts/about/projects.
  - Non-owner profile shows `تواصل` and `متابعة`.
  - `تواصل` becomes pending.
  - Post grid opens full post detail.
- Projects
  - Top bar remains visible.
  - Filters work.
  - Skeleton cards while projects load.
  - Application form validates subject/message.
  - Success page appears.
  - Applied project appears in saved content.
- Premium
  - Premium success message appears.
  - Dashboard opens.
  - Course progress cards render.
  - Course detail playlists render.
  - Advanced video controls render.
- Settings
  - Dark mode toggles immediately.
  - Cairo font remains applied.

### 5. Integration Tests

Recommended directory:

```text
integration_test/
```

Run on Chrome/device:

```powershell
flutter test integration_test
```

Scenarios:

- Complete signup with mocked or staging OTP.
- Sign out/sign in.
- Create project as engineer.
- Attempt project creation as craftsman and confirm it is blocked.
- Apply to a project.
- Save a post, reel, and project.
- Open comments and send content to chat.
- Toggle dark mode and restart app.
- Open premium dashboard and video screen.

### 6. Supabase Database Tests

Run from Supabase SQL editor or CI against staging.

Tables:

- `profiles`
- `engineer_details`
- `contractor_details`
- `craftsman_details`
- `machinery_details`
- `posts`
- `post_likes`
- `post_comments`
- `reels`
- `reel_likes`
- `reel_comments`
- `stories`
- `projects`
- `project_details`
- `project_applications`
- `saved_items`
- `connection_requests`
- `notifications`
- `messages`

RPC functions:

- `get_projects_for_app`
- `create_project_for_app`
- `apply_to_project_for_app`
- `save_item_for_app`
- `request_connection_for_app`
- `get_home_feed`
- `verify_otp_token`
- `has_active_subscription`
- `get_user_conversations`
- `mark_messages_read`

Database assertions:

- An engineer can create a project.
- A company/contractor can create a project.
- Craftsman/worker/equipment users cannot create projects.
- An applicant can create only a pending application.
- Applicants cannot accept their own applications.
- Project owners can read/update application status.
- Users can read and modify only their own saved items.
- Connection participants can read connection requests.
- Only receivers can answer connection requests.
- Post/reel like counters update through triggers.
- Comment counters update through triggers.
- `updated_at` triggers fire.

### 7. Edge Function Tests

Functions to test:

- `send-otp`
- `activate-subscription`
- `admin-assign-subscription`
- `push-notifications`
- `engineer-chat`
- `b2-upload`
- `voice-to-text`
- `elevenlabs-tts`

Assertions:

- Valid request returns expected JSON shape.
- Missing auth is rejected where required.
- Service role secrets are never returned.
- Rate limiting blocks repeated OTP attempts.
- Error responses use stable codes that Flutter can map to Arabic messages.

### 8. Security Tests

Checklist:

- No service role key in Flutter, web assets, docs, or committed files.
- Only publishable/anon key is passed to the client.
- RLS enabled on app tables.
- Authenticated users cannot select another user's saved content.
- Authenticated users cannot mutate another user's profile details.
- Anonymous users can read only public content intended for discovery.
- File upload buckets have path-level ownership checks.
- Admin tables are hidden from normal users.
- Secrets are rotated after accidental exposure.

### 9. Performance Tests

Targets:

- Cold app bootstrap under 2 seconds on a mid-range Android device.
- Feed first skeleton under 300 ms.
- Feed content render under 1.5 seconds on warm cache.
- Project tab warm-cache render under 500 ms.
- No repeated feed/project DB request when switching tabs within cache TTL.
- Pull-to-refresh performs exactly one forced request.
- Reel page keeps 60 fps during vertical swipe.

Tools:

- Flutter DevTools performance view.
- Network tab in browser/devtools.
- Supabase query logs.
- `flutter run --profile`.

### 10. Accessibility and RTL Tests

Checklist:

- Every tappable icon has tooltip or semantic label.
- Text does not overflow in Arabic at 320 px width.
- Buttons remain reachable with large font settings.
- Arrows point correctly for RTL navigation.
- Progress bars fill in the intended RTL/LTR direction based on feature.
- Color contrast passes for light and dark mode.
- Focus order follows visual RTL order.

### 11. Visual Regression Tests

Screens to snapshot:

- Onboarding screens.
- Signup each step.
- OTP screen.
- Home feed loading and loaded.
- Comments sheet.
- Reels loading and loaded.
- Network tabs.
- Invitations.
- My profile.
- Other profile.
- Projects loading and loaded.
- Project application success.
- Premium dashboard.
- Premium video.
- Settings light/dark.

Recommended next step:

- Add golden tests once final design stabilizes.
- Keep separate golden baselines for light and dark mode.

## Release Gate

A release is ready only when:

- `flutter analyze` passes.
- `flutter test` passes.
- Integration tests pass against staging.
- Supabase migration is applied to staging.
- RLS test script passes.
- No secret scanning findings.
- Manual smoke test passes on Android, iOS, and web.

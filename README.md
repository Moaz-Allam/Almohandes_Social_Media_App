# المهندس (Almohandes)

A mobile-first professional social network for engineers in Iraq — a LinkedIn‑style
platform with a feed, reels, stories, messaging, job/project listings, a premium
learning section, and an in‑app AI assistant. The UI is **Arabic‑first and fully
RTL**.

- **Flutter** app (Dart), package name `tradeflow`, store identity
  **`com.almohandes.app`**, display name **المهندس**.
- **Supabase** backend (Postgres + Auth + Storage + Edge Functions), project ref
  `gwuzlcmuxcokfpnaofjc`.
- Current version: **`2.0.0+5`** (see [Versioning](#versioning)).

> This README is the developer entry point. For **building, signing and
> publishing** to the stores, read [`PUBLISHING_GUIDE.md`](PUBLISHING_GUIDE.md)
> (and [`IOS_RELEASE.md`](IOS_RELEASE.md) for iOS). For a higher‑level system
> tour, see [`PLATFORM_OVERVIEW.md`](PLATFORM_OVERVIEW.md).

---

## Table of contents

1. [Features](#features)
2. [Tech stack](#tech-stack)
3. [Architecture](#architecture)
4. [Project layout](#project-layout)
5. [Backend (Supabase)](#backend-supabase)
6. [Getting started](#getting-started)
7. [Configuration & environment](#configuration--environment)
8. [Running & testing](#running--testing)
9. [Building releases](#building-releases)
10. [Versioning](#versioning)
11. [Secrets & security](#secrets--security)
12. [Further documentation](#further-documentation)

---

## Features

| Area | Description |
| --- | --- |
| **Auth** | Phone‑first sign up/login, Iraq‑only (`+964`). OTP delivered server‑side via Twilio Verify (SMS / WhatsApp) through Supabase native phone auth. Account types (engineer, company, etc.) with profile onboarding. |
| **Feed** | Home feed of posts (text + images), likes, comments with replies, share. Powered by the `get_home_feed` RPC with governorate filtering. |
| **Reels** | Vertical short‑video feed with likes/comments. |
| **Stories** | Ephemeral story strip + full‑screen viewer/creator. |
| **Messaging** | 1:1 chat, contact sharing. |
| **Network** | Connections/invitations, people discovery, search. |
| **Jobs & Projects** | Companies post jobs/projects; engineers apply ("تقديماتي" / My Applications); owners review applicants and match. |
| **Listings** | Manage created items + applicants. |
| **Premium** | Paid learning section (courses, lectures, video player) gated behind a subscription. Payments via the Switch/OPPWA hosted widget. |
| **AI assistant ("إنجي")** | In‑app chat assistant backed by an Edge Function calling OpenRouter. |
| **Notifications** | In‑app + push (FCM on Android) with deep‑link routing. |
| **Settings & Profile** | Profile editing, privacy controls, saved items, post management. |

---

## Tech stack

- **Flutter** (stable) / **Dart** — last built with Flutter 3.41.5 / Dart 3.11.3.
- **Supabase** for Postgres, Auth, Storage, Realtime, and Edge Functions (Deno).
- **Firebase Cloud Messaging** for Android push.
- State management is a lightweight hand‑rolled `ChangeNotifier` pattern
  (`AppController` + `AppScope`), not a third‑party state library.

---

## Architecture

The app follows a feature‑first layout with a thin data/repository layer over
Supabase.

- **UI layer** — `lib/features/<feature>/…` screens and widgets, plus shared
  widgets in `lib/shared/widgets`.
- **State** — `lib/state/app_controller.dart` holds app‑wide state and exposes
  notifiers (e.g. `notifyFeedChanged()` bumps a feed version that screens watch
  to trigger silent refreshes). `AppScope` is the `InheritedWidget` that exposes
  the controller; use `AppScope.watch(context)` / `AppScope.read(context)`.
- **Data layer** — `lib/data`:
  - `repositories/` — one repository per domain (`feed_repository.dart`,
    `comment_repository.dart`, `project_repository.dart`, `job_repository.dart`,
    `message_repository.dart`, `notification_repository.dart`, `auth_repository.dart`,
    `engineer_ai_repository.dart`, …). Repositories call Supabase and return
    typed models; failures are normalized through `repository_failure.dart`.
  - `mappers/` — convert raw Supabase rows ↔ app models (e.g.
    `feed_mapper.dart`).
  - `cache/timed_memory_cache.dart` — short‑TTL in‑memory cache (feed lists use a
    1‑minute TTL; `forceRefresh: true` bypasses it).
  - `supabase/` — Supabase client config (`supabase_config.dart`), `realtime/`,
    `notifications/` (FCM token + local notifications dispatch), `session/`,
    `storage/`.
- **Models** — `lib/models`.
- **Core** — `lib/core`: theme (`app_theme.dart`), colors (`app_colors.dart`),
  layout breakpoints, country data.
- **Entry point** — `lib/main.dart` → `lib/app/linked_arabic_app.dart`.

### Data flow (example: adding a comment)

1. The comments sheet calls `CommentRepository.addComment(...)`, inserting into
   the `app_comments` table.
2. A DB trigger (`on_app_comment_notify` → `app_notify_on_comment()`) increments
   `posts.comments_count` for top‑level comments and notifies the post owner.
3. The client optimistically updates the local count, then calls
   `AppController.notifyFeedChanged()` so the feed silently re‑fetches and
   reconciles with the authoritative DB value.

---

## Project layout

```
lib/
  main.dart                 # entry point
  app/                      # root app widget (RTL/Arabic, routing, theme)
  core/                     # theme, colors, constants, country data
  state/                    # AppController, AppScope, signup controller
  models/                   # domain models
  data/
    repositories/           # Supabase-backed repositories (one per domain)
    mappers/                # row <-> model mappers
    cache/                  # TimedMemoryCache
    supabase/               # Supabase client + config
    realtime/ notifications/ session/ storage/
  features/                 # feature-first UI
    auth/ feed/ reels/ stories/ messages/ network/ search/
    jobs/ projects/ applications/ listings/ premium/
    profile/ settings/ notifications/ composer/ saved/ home/ menu/
  shared/                   # shared widgets, errors, async helpers, privacy
  firebase_options.dart     # FlutterFire client config

supabase/                   # migrations, edge functions, config.toml, auth/push docs
android/  ios/  web/         # platform projects
docs/                       # integration + testing + setup docs
play_store_release/          # store listing copy, graphics, signing (gitignored)
```

---

## Backend (Supabase)

The app talks to an already‑live Supabase project (ref `gwuzlcmuxcokfpnaofjc`).
The same project backs a separate **web admin dashboard**.

- **Migrations** live in `supabase/migrations/`. Apply with `supabase db push`.
- **Edge Functions** (`supabase/functions/`):
  - `send-otp`, `verify-otp`, `sync-auth-phone` — phone auth helpers.
  - `send-push` — FCM v1 push delivery (uses an `FCM_SERVICE_ACCOUNT` secret).
  - `switch-payment` — Switch/OPPWA hosted payment widget (server‑side
    credentials; falls back to the `admin_settings` table).
  - `engee-chat`, `engineer-chat` — the "إنجي" AI assistant via OpenRouter.
- **Auth** is phone‑first; OTP delivery is configured in
  `supabase/config.toml` under `[auth.sms.twilio_verify]` and is entirely
  server‑side (no SMS keys ship in the app).

> The app build itself only needs the Supabase **URL + anon/publishable key**
> (compiled in as defaults). All real secrets live in the backend, never in the
> binary. See [Secrets & security](#secrets--security).

---

## Getting started

### Prerequisites

- **Flutter SDK** (stable) + `flutter doctor` green. Last built with Flutter
  3.41.5 / Dart 3.11.3.
- **Android:** Android Studio / SDK, **JDK 17** (Gradle targets Java 17). A
  release keystore is required only for signed release builds.
- **iOS (macOS only):** Xcode + CocoaPods. Min iOS **15.0**.
- **Backend (optional):** Supabase CLI (`npx supabase …`) if you need to deploy
  migrations or functions.

### First run

```bash
flutter pub get
flutter run            # on a connected device/emulator
```

The app works out of the box against the production Supabase project because the
URL and anon key are baked in as compiled defaults.

---

## Configuration & environment

Client configuration lives in `lib/data/supabase/supabase_config.dart` and reads
from `--dart-define` with production defaults:

| Define | Default | Notes |
| --- | --- | --- |
| `SUPABASE_URL` | `https://gwuzlcmuxcokfpnaofjc.supabase.co` | Override to point at another project. |
| `SUPABASE_PUBLISHABLE_KEY` | (anon JWT) | Public client key — safe to ship. |

Override at build/run time when pointing at a different environment:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<anon-key>
```

Firebase client config ships in `android/app/google-services.json` and
`lib/firebase_options.dart` (Firebase project `almohandes-engineer-2026`).

---

## Running & testing

```bash
flutter pub get
flutter analyze        # expect only known deprecation infos, 0 errors
flutter test           # widget + unit tests
flutter run            # device/emulator
```

---

## Building releases

> Full, step‑by‑step instructions (signing, store upload, reviewer notes) are in
> [`PUBLISHING_GUIDE.md`](PUBLISHING_GUIDE.md) and [`IOS_RELEASE.md`](IOS_RELEASE.md).

**Android** (requires `android/key.properties` + `android/app/upload-keystore.jks`,
both gitignored — the build fails fast without them):

```bash
flutter build appbundle --release   # AAB for Google Play
flutter build apk --release          # universal APK for sideload testing
```

**iOS** (macOS only):

```bash
cd ios && pod install && cd ..
flutter build ipa --release
```

---

## Versioning

`pubspec.yaml` is the single source of truth:

```yaml
version: 2.0.0+5
#         ^^^^^ ^
#         name  build number
```

- **name** (`2.0.0`) → Android `versionName`, iOS `CFBundleShortVersionString`.
- **build** (`5`) → Android `versionCode`, iOS `CFBundleVersion` — must strictly
  increase on **every** upload to either store.

Version 1 is already live on both stores. Always confirm the build number is
higher than the highest published one before uploading.

---

## Secrets & security

**Never commit these** (they are gitignored or backend‑only):

- `android/key.properties`, `android/app/upload-keystore.jks`,
  `play_store_release/signing/` (keystore + passwords + fingerprints).
- Supabase **service_role** key.
- Twilio Auth Token, payment gateway token (`SWITCH_API_TOKEN`) + entity id,
  `OPENROUTER_API_KEY`, FCM service‑account JSON, App Store Connect `.p8`,
  Google Play service‑account JSON.
- The seed migrations
  `supabase/migrations/20260527060000_seed_test_accounts.sql` and
  `…20260530120000_seed_full_test_data.sql` (test data — do **not** apply to
  production).

The Supabase **anon/publishable** key and Firebase **client** config are public
by design and intentionally ship in the app.

---

## Further documentation

| Topic | Doc |
| --- | --- |
| Build & publish (both platforms) | [`PUBLISHING_GUIDE.md`](PUBLISHING_GUIDE.md) |
| iOS release, step by step | [`IOS_RELEASE.md`](IOS_RELEASE.md) |
| System/architecture overview | [`PLATFORM_OVERVIEW.md`](PLATFORM_OVERVIEW.md) |
| Phone OTP auth (Twilio / WhatsApp) | [`supabase/AUTH_SETUP.md`](supabase/AUTH_SETUP.md), [`supabase/WHATSAPP_AUTH_SETUP.md`](supabase/WHATSAPP_AUTH_SETUP.md) |
| Push notifications (FCM) | [`supabase/PUSH_SETUP.md`](supabase/PUSH_SETUP.md) |
| Supabase ↔ Flutter integration | [`docs/supabase_flutter_integration.md`](docs/supabase_flutter_integration.md) |
| Android device setup | [`docs/android_phone_setup.md`](docs/android_phone_setup.md) |
| Testing strategy | [`docs/comprehensive_testing_strategy.md`](docs/comprehensive_testing_strategy.md) |
| Store listing copy + graphics | [`play_store_release/`](play_store_release/) |

# المهندس (Almohandes) — Build & Publishing Handoff Guide

A complete runbook for a developer who needs to **build, sign, configure, and
publish** this app to **Google Play** and the **Apple App Store**. It lists every
secret/credential required, where it lives, how to build each platform, and how
to deploy the Supabase backend the app depends on.

> This is **version 2** of the app. Version 1 is already live on both stores.
> The version in `pubspec.yaml` is now **`2.0.0+5`** — read [§8 Versioning](#8-versioning--release-numbers)
> **before** you upload, and confirm the build number is higher than what is
> already published.

This guide links to the deeper, topic-specific docs already in the repo instead
of duplicating them:

| Topic | Doc |
| --- | --- |
| iOS build + App Store, step by step | [`IOS_RELEASE.md`](IOS_RELEASE.md) |
| Phone OTP auth (Twilio Verify / WhatsApp) | [`supabase/AUTH_SETUP.md`](supabase/AUTH_SETUP.md), [`supabase/WHATSAPP_AUTH_SETUP.md`](supabase/WHATSAPP_AUTH_SETUP.md) |
| Push notifications (FCM) | [`supabase/PUSH_SETUP.md`](supabase/PUSH_SETUP.md) |
| Android phone/device setup | [`docs/android_phone_setup.md`](docs/android_phone_setup.md) |
| Google Play listing copy + graphics + AAB | [`play_store_release/`](play_store_release/) |
| Architecture overview | [`PLATFORM_OVERVIEW.md`](PLATFORM_OVERVIEW.md) |

---

## 1. What this app is (so you know what you're shipping)

- **Flutter** mobile app (Dart), Arabic-first / RTL UI. Package name `tradeflow`,
  store/product identity **`com.almohandes.app`**, display name **المهندس**.
- **Backend = Supabase** (project ref `gwuzlcmuxcokfpnaofjc`): Postgres + Auth +
  Storage + Edge Functions. The same project also backs a separate web admin
  dashboard.
- **Auth is phone-first**, Iraq-only (`+964`). OTP is delivered by **Twilio
  Verify** (SMS / WhatsApp) through Supabase's native phone auth — **fully
  server-side; no SMS keys ship in the app binary.**
- **Push** = Firebase Cloud Messaging (Android). iOS push is **not** wired in
  this build.
- **Payments** = the **Switch / OPPWA** hosted payment widget, driven by the
  `switch-payment` Edge Function (server-side credentials).
- **In-app AI assistant ("إنجي")** = the `engee-chat` / `engineer-chat` Edge
  Functions calling **OpenRouter** (server-side key).

The important consequence: **almost every real secret lives in the backend
(Supabase / Twilio / Firebase / payment gateway), not in the app build.** The
app build itself only needs the **Supabase URL + anon (publishable) key** (which
already ship as compiled defaults) and the **Android signing keystore**.

---

## 2. App identity (already configured in this repo)

| Item | Value |
| --- | --- |
| Flutter package name | `tradeflow` (`pubspec.yaml`) |
| Android `applicationId` | `com.almohandes.app` (`android/app/build.gradle.kts`) |
| iOS Bundle Identifier | `com.almohandes.app` (`ios/Runner.xcodeproj`) |
| Display name | المهندس (Android `app_name` string, iOS `CFBundleDisplayName`) |
| Deep-link scheme | `com.almohandes.app://reset-password` (Android intent filter + iOS URL scheme) |
| Current version | **`2.0.0+5`** (`pubspec.yaml` → Android versionName/versionCode, iOS short/bundle version) |
| Min Android | from Flutter defaults (`flutter.minSdkVersion`) |
| Min iOS | `15.0` (`ios/Podfile`) |
| Firebase project | `almohandes-engineer-2026` (sender id `851572571996`) |

---

## 3. Toolchain / prerequisites

This repo was last built with:

```
Flutter 3.41.5 (stable)  •  Dart 3.11.3
```

Install the matching (or newer compatible) toolchain.

**For Android (Windows / macOS / Linux):**
- Flutter SDK + `flutter doctor` green for Android.
- Android Studio / Android SDK, **JDK 17** (the Gradle config targets Java 17).
- The Android **release keystore** (see §4) to sign the AAB.

**For iOS (macOS only):**
- A **Mac with Xcode** (iOS cannot be built on Windows). If you don't have one,
  use Codemagic / GitHub Actions `macos` runners / a cloud Mac — see
  [`IOS_RELEASE.md` §0](IOS_RELEASE.md).
- CocoaPods (`sudo gem install cocoapods`).

**For the backend (any OS):**
- **Supabase CLI** (`supabase`) — already linked to the project per the repo.
- **Deno** is bundled by the Supabase CLI for Edge Functions; no separate
  install needed for deploys.

---

## 4. Secrets & credentials inventory

> **Legend** — *In repo*: already committed, no action needed. *Gitignored /
> private*: exists locally but is **not** in git; obtain securely from the
> project owner. *Backend console*: set in the Supabase / Twilio / Firebase /
> payment dashboards, never in the app.

### 4.1 Android app signing — **REQUIRED to publish**

| Secret | Location | Status | Notes |
| --- | --- | --- | --- |
| Upload keystore | `android/app/upload-keystore.jks` (also copied to `play_store_release/signing/upload-keystore.jks`) | **Gitignored / private** | The release upload key. Losing it means you can't update the existing Play listing without a Google key reset. |
| Keystore credentials | `android/key.properties` (`storePassword`, `keyPassword`, `keyAlias=almohandes_upload`, `storeFile`) | **Gitignored / private** | The build **fails fast** if this file is missing (see `build.gradle.kts`). |
| Key fingerprints | `play_store_release/signing/upload_key_fingerprints.txt` | Private | SHA-1/256 — must match what Play Console expects. |

> Get `upload-keystore.jks` + `key.properties` from the project owner and place
> them at the paths above before building a release. **Never commit them.**

### 4.2 Supabase — app connection

| Secret | Location | Status | Notes |
| --- | --- | --- | --- |
| Supabase URL | `SUPABASE_URL` (default `https://gwuzlcmuxcokfpnaofjc.supabase.co`) | **In repo** (compiled default in `lib/data/supabase/supabase_config.dart`) | Overridable at build time via `--dart-define=SUPABASE_URL=...`. |
| Supabase anon / publishable key | `SUPABASE_PUBLISHABLE_KEY` | **In repo** (compiled default) | Public client key — safe to ship. Override via `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`. |
| Supabase **service_role** key | — | **Backend console only** | **NEVER** put this in the app. Used only by Edge Functions (auto-injected as `SUPABASE_SERVICE_ROLE_KEY`). |

The app works with **no dart-defines** because the production URL/anon key are
baked in as defaults. Override only if you point a build at a different project.

### 4.3 Firebase / Push (FCM)

| Secret | Location | Status | Notes |
| --- | --- | --- | --- |
| Android Firebase config | `android/app/google-services.json` | In repo | Ties the app to project `almohandes-engineer-2026`. |
| Firebase options (Dart) | `lib/firebase_options.dart` | In repo | Client API keys/app IDs — these are client identifiers, not server secrets. |
| iOS Firebase config | `ios/Runner/GoogleService-Info.plist` | **Missing** | Only needed if/when iOS push is added. Generate via FlutterFire for the iOS app. |
| FCM service account (server) | Supabase Edge Function secret `FCM_SERVICE_ACCOUNT` | **Backend console** | JSON service-account key the `send-push` function uses to call FCM v1. See [`supabase/PUSH_SETUP.md`](supabase/PUSH_SETUP.md). |

### 4.4 Twilio Verify — OTP delivery (server-side)

Set on the linked Supabase project (`supabase secrets set ...`), referenced by
`supabase/config.toml [auth.sms.twilio_verify]`:

| Secret | Where to get it |
| --- | --- |
| `SUPABASE_AUTH_SMS_TWILIO_VERIFY_ACCOUNT_SID` | Twilio Console → Account SID (`AC…`) |
| `SUPABASE_AUTH_SMS_TWILIO_VERIFY_AUTH_TOKEN` | Twilio Console → Auth Token |
| `SUPABASE_AUTH_SMS_TWILIO_VERIFY_MESSAGE_SERVICE_SID` | Twilio → Verify → Services → Service SID (`VA…`) |

Full steps: [`supabase/AUTH_SETUP.md`](supabase/AUTH_SETUP.md) (SMS) and
[`supabase/WHATSAPP_AUTH_SETUP.md`](supabase/WHATSAPP_AUTH_SETUP.md) (WhatsApp).

### 4.5 Payment gateway (Switch / OPPWA) — server-side

Edge Function secrets read by `supabase/functions/switch-payment/index.ts`
(with a fallback to the `admin_settings` table):

| Secret | Purpose |
| --- | --- |
| `SWITCH_API_TOKEN` | Bearer token for the payment gateway API |
| `SWITCH_ENTITY_ID` | Merchant entity id |
| `SWITCH_API_URL` | Gateway base (`https://test.oppwa.com/v1` for test, live URL for prod) |
| `SWITCH_PAYMENT_BRANDS` | e.g. `VISA MASTER` |
| `SWITCH_PAYMENT_RETURN_URL` | Optional override for the result redirect |

### 4.6 AI assistant — server-side

| Secret | Used by | Notes |
| --- | --- | --- |
| `OPENROUTER_API_KEY` | `engee-chat`, `engineer-chat` | Powers the in-app "إنجي" assistant via OpenRouter. Without it, the assistant returns a friendly "not configured" message. |
| `ENGINEER_AI_MODEL` | same | Optional model override (defaults to a free OpenRouter model). |
| `OPENAI_API_KEY` | `supabase/config.toml` (Studio AI) | Optional / local tooling only. |

### 4.7 Store / publisher accounts

| Account | Needed for |
| --- | --- |
| **Google Play Console** (paid, one-time $25) | Publishing the AAB, store listing. |
| **Apple Developer Program** ($99/yr) + **App Store Connect** | Building, signing, and submitting iOS. |
| App Store Connect **API key** (`.p8` + Key ID + Issuer ID) | Optional, for CLI/CI uploads (`altool`/fastlane). |
| Google Play **service account JSON** | Optional, for CI uploads (fastlane `supply`). |

---

## 5. Build & run locally (sanity check first)

```bash
flutter pub get
flutter analyze          # expect only pre-existing deprecation infos, 0 errors
flutter test             # widget/unit tests
flutter run              # on a connected device/emulator
```

---

## 6. Android release build (Google Play)

Prerequisite: `android/key.properties` + `android/app/upload-keystore.jks` in
place (see §4.1).

```bash
flutter clean
flutter pub get

# App Bundle for Play (preferred):
flutter build appbundle --release
#   -> build/app/outputs/bundle/release/app-release.aab

# (Optional) a universal APK for sideload testing:
flutter build apk --release
```

Then in **Play Console** → your app → **Production** (or Internal testing first):

1. Create a new release, upload the `.aab`.
2. Confirm the **version code is higher** than the live release (see §8).
3. Fill **release notes** (copy from
   [`play_store_release/metadata/release_notes.md`](play_store_release/metadata/release_notes.md)).
4. Roll out (start with **Internal testing**, then promote to Production).

Store listing assets (icon, feature graphic, screenshots, description) are ready
in [`play_store_release/`](play_store_release/) —
[`metadata/google_play_listing.md`](play_store_release/metadata/google_play_listing.md)
has the copy. The bundled AAB there is the older `+4` build; **build a fresh AAB
at `+5`** with the command above rather than uploading the old artifact.

---

## 7. iOS release build (App Store)

iOS **must** be built on macOS. Follow [`IOS_RELEASE.md`](IOS_RELEASE.md) end to
end — it covers Apple account setup, signing, `flutter build ipa --release`,
uploading via Transporter/altool/Xcode, TestFlight, and the **reviewer demo
account** note (the app needs a phone+password demo login or a Supabase test
phone number, because OTP can't reach a reviewer).

Quick version:

```bash
flutter clean && flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
# upload build/ios/ipa/*.ipa via Transporter, then submit in App Store Connect
```

---

## 8. Versioning & release numbers

`pubspec.yaml` holds a single source of truth:

```yaml
version: 2.0.0+5
#         ^^^^^ ^
#         name  build number
```

- **name** (`2.0.0`) → Android `versionName`, iOS `CFBundleShortVersionString`
  (the marketing version users see).
- **build** (`5`) → Android `versionCode`, iOS `CFBundleVersion` (must strictly
  increase on **every** upload to either store).

This release was bumped from `2.0.0+4` → **`2.0.0+5`** for the v2 store update.

> **Verify before you upload (because v1 is already live):**
> - **Google Play:** `versionCode` (`5`) **must be strictly greater** than the
>   highest version code already on the listing (any track). Open Play Console →
>   App bundle explorer / release history and check. If v1 used a higher code,
>   raise the `+build` number in `pubspec.yaml` accordingly (e.g. `2.0.0+6`).
> - **App Store:** the **marketing version** (`2.0.0`) must be higher than the
>   currently released App Store version, and `CFBundleVersion` (`5`) must be
>   higher than any build already uploaded for this version string. Bump the
>   `+build` number for each re-upload.
>
> For every subsequent release, **only ever increase** these numbers.

---

## 9. Backend deployment (only if the backend changed)

The app talks to an already-live Supabase project. You normally **don't** need
to touch the backend to ship a new app build. If you do need to deploy backend
changes:

```bash
# DB schema:
supabase db push                     # applies supabase/migrations/*

# Edge functions:
supabase functions deploy send-push switch-payment engee-chat engineer-chat \
  send-otp verify-otp sync-auth-phone

# Server secrets (examples — set the real values from §4):
supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)"
supabase secrets set OPENROUTER_API_KEY=...
supabase secrets set SWITCH_API_TOKEN=... SWITCH_ENTITY_ID=... SWITCH_API_URL=...
# Twilio Verify secrets: see supabase/AUTH_SETUP.md
```

> Do **not** apply the seed migrations
> `supabase/migrations/20260527060000_seed_test_accounts.sql` and
> `…20260530120000_seed_full_test_data.sql` to production — they insert test data.

---

## 10. Pre-submission checklist

- [ ] `flutter analyze` clean (only known deprecation infos), `flutter test` green.
- [ ] `pubspec.yaml` version bumped and **verified higher** than live (§8).
- [ ] Android: `key.properties` + keystore present; `flutter build appbundle --release` succeeds.
- [ ] iOS: build number raised; `flutter build ipa --release` succeeds on a Mac.
- [ ] Backend secrets set (Twilio Verify, FCM, payment, OpenRouter) and OTP
      delivery tested on a real device.
- [ ] **Reviewer access**: demo phone+password account *or* a Supabase test phone
      number+OTP provided in both store review notes (login needs an OTP).
- [ ] Store listings filled: screenshots, description (AR + EN), **privacy policy
      URL**, data-collection/App Privacy questionnaire (declare phone number).
- [ ] Permission usage strings present on iOS (camera/photos/microphone) before
      submitting.

---

## 11. Security — do NOT commit these

These are gitignored or backend-only and must never be checked into git or
pasted into the store listing / this doc:

- `android/key.properties`, `android/app/upload-keystore.jks`,
  `play_store_release/signing/` (keystore + passwords + fingerprints).
- Supabase **service_role** key.
- **Twilio** Auth Token.
- Payment gateway token (`SWITCH_API_TOKEN`) and entity id.
- `OPENROUTER_API_KEY`, FCM service-account JSON, App Store Connect `.p8`,
  Google Play service-account JSON.

The Supabase **anon/publishable** key and Firebase **client** config are public
by design and intentionally ship in the app.

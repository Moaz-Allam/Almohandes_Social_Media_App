# Android Phone Setup and Supabase Connection Guide

This guide explains the exact steps to run `المهندس` on a real Android phone
and connect it to the Supabase project.

## 1. Prerequisites

Install these on the development machine:

- Flutter SDK
- Android Studio
- Android SDK Platform Tools
- Git
- A physical Android phone
- A USB cable that supports data transfer

Check Flutter:

```powershell
flutter doctor
```

Expected:

- Flutter installed.
- Android toolchain installed.
- Android Studio installed.
- Connected device appears after USB setup.

Fix all blocking `flutter doctor` issues before continuing.

## 2. Prepare Supabase

Before running the app on Android, apply the database migration:

```text
supabase/migrations/20260506100000_flutter_integration_bridge.sql
```

In Supabase Dashboard:

1. Open the project.
2. Go to `SQL Editor`.
3. Create a new query.
4. Paste the full migration file.
5. Click `Run`.

This migration creates/updates the app bridge:

- Project details
- Project applications
- Saved items
- Connection requests
- Post reports
- Network profile discovery
- App-facing RPC functions
- RLS policies
- Function grants

If you previously saw this error:

```text
function public.create_project_for_app(...) does not exist
```

Use the latest migration file. The grant block now discovers function
signatures dynamically, so it will not fail when function arguments change.

## 3. Confirm Required Supabase Values

From Supabase Dashboard:

1. Open `Project Settings`.
2. Open `Data API` or `API`.
3. Copy:
   - Project URL
   - Publishable key or anon public key

Use only public client keys inside Flutter.

Never put these in Flutter:

- Service role key
- Secret key
- Database password
- Payment secrets
- Storage provider secrets

## 4. Prepare Edge Functions

The Flutter app expects these functions/RPCs to exist:

- `send-otp`
- `verify_otp_token`
- `get_home_feed`
- `get_projects_for_app`
- `create_project_for_app`
- `apply_to_project_for_app`
- `save_item_for_app`
- `get_network_profiles_for_app`

Minimum signup requirement:

- `send-otp` should accept:

```json
{
  "phone": "+9647XXXXXXXXX"
}
```

- `verify_otp_token` should accept:

```sql
p_phone_local10
p_verification_code
```

## 5. Enable Developer Options on Android

On the phone:

1. Open `Settings`.
2. Open `About phone`.
3. Tap `Build number` 7 times.
4. Enter the phone password if asked.
5. Go back to `Settings`.
6. Open `Developer options`.
7. Enable `USB debugging`.

Then connect the phone by USB.

When Android asks to allow USB debugging:

1. Check `Always allow from this computer`.
2. Tap `Allow`.

## 6. Verify the Phone Is Visible

Run:

```powershell
flutter devices
```

You should see something like:

```text
SM-A... (mobile) • RF... • android-arm64 • Android ...
```

If no device appears:

- Reconnect USB.
- Change USB mode to `File Transfer`.
- Reopen Android Studio.
- Run `flutter doctor`.
- Revoke and re-enable USB debugging.

## 7. Run the App on the Phone

Run with Supabase public values:

```powershell
flutter run `
  -d <ANDROID_DEVICE_ID> `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
```

Example:

```powershell
flutter run `
  -d RFXXXXXXXXX `
  --dart-define=SUPABASE_URL=https://gwuzlcmuxcokfpnaofjc.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
```

Do not paste service role keys into this command.

## 8. Run in Release-Like Profile Mode

For performance testing:

```powershell
flutter run `
  --profile `
  -d <ANDROID_DEVICE_ID> `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
```

Use profile mode to test:

- Feed load speed.
- Reels smoothness.
- Skeleton loading timing.
- Network request volume.
- Project apply flow.
- Dark mode.

## 9. Build an APK

Debug APK:

```powershell
flutter build apk `
  --debug `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
```

Release APK:

```powershell
flutter build apk `
  --release `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLIC_KEY
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Install manually:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

## 10. Android Internet Permission

Flutter Android apps normally include internet access for debug usage, but
confirm this file:

```text
android/app/src/main/AndroidManifest.xml
```

It should contain:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

If missing, add it above the `<application>` tag.

## 11. Phone Test Checklist

Run this checklist on the physical phone:

- App opens without a white screen.
- Cairo font displays correctly.
- RTL direction is correct.
- Dark mode toggles.
- Signup opens.
- Phone field accepts Iraqi numbers starting with `07`.
- OTP screen appears after the first signup step.
- Sign in works.
- Home feed loads from Supabase.
- Feed skeleton appears while loading.
- Stories strip appears.
- Like count updates immediately.
- Comments sheet opens.
- Repost confirmation appears.
- Send opens contacts and chat.
- Reels load with skeleton first.
- Reels swipe vertically.
- Reel progress advances.
- Projects page loads from Supabase.
- Project filters work.
- Engineer/company users can publish projects.
- Craftsman/worker/equipment users cannot publish projects.
- Project application form submits.
- Success page appears.
- Applied project appears in saved content.
- Network page loads real Supabase profiles.
- Engineer users see non-admin, non-company accounts in `مهندسون`.
- Engineer users see companies in `شركات`.
- Company users see engineers only.
- Other account types see no network profiles.
- Profile pages open.
- Premium dashboard opens.
- Course video controls work.

## 12. Debugging Supabase on Android

If data does not load:

1. Confirm the app was launched with `--dart-define`.
2. Confirm the public key is valid.
3. Confirm the migration ran successfully.
4. Confirm RLS policies allow the current user.
5. Open Supabase logs.
6. Check Flutter logs:

```powershell
flutter logs -d <ANDROID_DEVICE_ID>
```

Common causes:

- Using service role key in the wrong place.
- Missing migration.
- User profile row not created after signup.
- RLS policy blocking profile/project reads.
- Edge Function not deployed.
- Phone has no internet.

## 13. Production Notes

Before publishing:

- Rotate any secrets that were shared during development.
- Use only public client keys in Flutter.
- Move privileged actions to Edge Functions.
- Test on at least one low-end Android device.
- Test Android 10, 11, 12, 13, 14, and 15 if possible.
- Build a signed release APK or AAB.
- Add crash reporting before production launch.

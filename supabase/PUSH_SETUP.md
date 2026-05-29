# المهندس — Push Notifications (status)

Firebase project **`almohandes-engineer-2026`** is created and wired. Three
channels:

| Channel | Fires when | Status |
| --- | --- | --- |
| **Local / in-app** | App open / foreground | ✅ Working now (`LocalNotificationService`, driven by Realtime + FCM foreground). Arabic + app icon. |
| **FCM (Android/iOS)** | App backgrounded / killed | ✅ Code + server done. Needs the FCM service-account secret (1 console step). |
| **Web Push** | Browser closed | ✅ Code + server done. Needs the FCM secret **and** the Web VAPID key. |

## ✅ Already done (automated via CLI)

- Firebase project `almohandes-engineer-2026` created; Android, iOS, Web apps
  registered. `lib/firebase_options.dart`, `android/app/google-services.json`
  generated.
- `firebase_core` + `firebase_messaging` added; `Firebase.initializeApp` +
  background handler wired in `lib/main.dart`.
- `PushTokenService` registers the device token into `device_tokens` on
  sign-in and removes it on sign-out; foreground FCM messages route through
  `LocalNotificationService`.
- `web/firebase-messaging-sw.js` service worker added with the web config.
- Edge function `send-push` deployed (FCM HTTP v1 → Android/iOS/Web).
- Migrations applied: `device_tokens` unique-token + RLS, and an
  `after insert on notifications` trigger (`pg_net`) that calls `send-push`.

## ⚙️ Two values that need the Firebase console (can't be generated headless)

**1. FCM service-account key → Supabase secret** (enables background push):

Firebase console → Project settings → **Service accounts** → *Generate new
private key* → download the JSON, then:

```bash
npx supabase secrets set FCM_SERVICE_ACCOUNT="$(cat ~/Downloads/almohandes-engineer-2026-*.json)"
```

That's it for Android/iOS background push — the trigger already calls the
function on every new notification.

**2. Web Push VAPID key** (only needed for web *background* push):

Firebase console → Project settings → **Cloud Messaging** → *Web Push
certificates* → Generate key pair → copy the public key, then build web with:

```bash
flutter run -d chrome --dart-define=FCM_VAPID_KEY=<public-vapid-key>
# or: flutter build web --dart-define=FCM_VAPID_KEY=<public-vapid-key>
```

Without the VAPID key, web still shows **foreground** notifications; only web
background push is skipped.

## How it connects

```
new row in notifications
   ├─ Realtime ───────────────▶ open app → LocalNotificationService (foreground)
   └─ AFTER INSERT trigger ─▶ send-push ─▶ FCM v1 ─▶ Android / iOS / Web (background)
```

## Notes

- iOS: `flutterfire configure` registered the iOS app but the
  `GoogleService-Info.plist` wasn't written to `ios/Runner`. Re-run
  `flutterfire configure --platforms=ios` (or download it from the console) if
  you ship iOS. APNs key upload in the Firebase console is also required for
  real iOS delivery.
- Android: ensure `minSdkVersion >= 21` (Flutter default already satisfies).

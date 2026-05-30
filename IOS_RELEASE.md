# المهندس — iOS Build & App Store Release

Commands and steps to build the iOS app and publish it to the App Store.

> **You must build on macOS.** iOS apps can only be compiled, signed, and
> uploaded from a Mac with Xcode. You are currently on Windows — see
> [§0 Building without a Mac](#0-building-without-a-mac) for cloud options.

---

## App identifiers (already set in this repo)

| Thing | Value |
| --- | --- |
| Flutter package name | `tradeflow` |
| Display name | المهندس |
| Bundle Identifier | `com.almohandes.app` |
| Version (marketing + build) | `2.0.0+4` (from `pubspec.yaml`) |
| Minimum iOS | `15.0` (from `ios/Podfile`) |

The version string is `MARKETING_VERSION+BUILD_NUMBER`. Apple requires the
**build number to increase on every upload** to App Store Connect, even for the
same marketing version.

---

## 0. Building without a Mac

Since you're on Windows, pick one:

- **Codemagic** (easiest for Flutter): connect the repo, it provides macOS
  build machines and can sign + ship to TestFlight/App Store automatically.
- **GitHub Actions** with a `macos-latest` runner (free minutes, then paid).
- **Rented Mac in the cloud:** MacStadium, MacinCloud, or AWS EC2 Mac — then
  follow this doc over VNC/SSH exactly as on a local Mac.
- **A borrowed/physical Mac** with Xcode.

Everything below assumes you are on that Mac.

---

## 1. One-time prerequisites

### Accounts
- **Apple Developer Program** membership (USD $99/year) — enroll at
  developer.apple.com. Required to distribute on the App Store.
- Access to **App Store Connect** (appstoreconnect.apple.com).

### Tools on the Mac
```bash
# Xcode from the Mac App Store, then:
xcode-select --install                 # command line tools
sudo gem install cocoapods             # or: brew install cocoapods
flutter --version                      # install Flutter for macOS if missing
flutter doctor                         # must be green for the iOS toolchain
```

---

## 2. One-time project setup in Apple's portals

1. **Register the App ID / Bundle ID** `com.almohandes.app`
   (developer.apple.com → Certificates, IDs & Profiles → Identifiers).
   Enable any capabilities the app uses (e.g. **Push Notifications** if/when you
   wire iOS push, **Sign in with Apple** if added later).
2. **Create the app record** in App Store Connect → Apps → **+** → New App:
   - Platform: iOS
   - Name: `المهندس` (must be unique on the store)
   - Primary language, Bundle ID `com.almohandes.app`, SKU (any string).
3. **Signing** — open the project in Xcode and let it manage certificates:
   ```bash
   open ios/Runner.xcworkspace
   ```
   In Xcode → **Runner** target → **Signing & Capabilities**:
   - Check **Automatically manage signing**.
   - Select your **Team**.
   - Confirm Bundle Identifier is `com.almohandes.app`.
   Xcode will create the Distribution certificate + provisioning profile.

---

## 3. Bump the version before each release

Edit `pubspec.yaml`:
```yaml
version: 2.0.1+5     # raise marketing version and/or the +build number
```
The build number (after `+`) **must be higher** than anything already uploaded.

---

## 4. Build the release IPA (command line)

From the project root on the Mac:
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Builds a signed, App Store–ready archive + .ipa:
flutter build ipa --release
```
Output:
- Archive: `build/ios/archive/Runner.xcarchive`
- IPA:     `build/ios/ipa/*.ipa`

If automatic signing in Xcode isn't enough for your setup, supply an export
options plist:
```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```
(`method` = `app-store-connect`, plus your team ID — Xcode generates a sample
when you Archive → Distribute once.)

---

## 5. Upload to App Store Connect

Pick one method.

### A) Apple Transporter app (simplest)
Install **Transporter** from the Mac App Store, sign in, drag in
`build/ios/ipa/*.ipa`, click **Deliver**.

### B) Command line with an App Store Connect API key
Create an API key in App Store Connect → Users and Access → **Integrations /
Keys** (note the **Key ID** and **Issuer ID**, download the `.p8`):
```bash
xcrun altool --upload-app \
  -f build/ios/ipa/*.ipa \
  -t ios \
  --apiKey <KEY_ID> \
  --apiIssuer <ISSUER_ID>
```

### C) Xcode Organizer
`open ios/Runner.xcworkspace` → Product → **Archive** → **Distribute App** →
App Store Connect → Upload.

### D) Fastlane (best for repeatable / CI releases)
```bash
sudo gem install fastlane
# in ios/: fastlane pilot upload   (TestFlight)
#          fastlane deliver        (App Store metadata + binary)
```

---

## 6. TestFlight, metadata, and submit for review

In **App Store Connect** for the المهندس app:
1. The uploaded build appears under **TestFlight** after processing (a few
   minutes). Test it on a device first.
2. Fill the **App Store** tab: screenshots (6.7" + 5.5" required sizes),
   description (Arabic + English), keywords, support URL, **privacy policy
   URL**, category, and the **App Privacy** questionnaire (declare phone number
   collection, etc.).
3. Attach the build to a version, then **Add for Review → Submit**.

### App Review access (important for this app)
Login requires a **WhatsApp OTP**, which a reviewer can't receive. To avoid
rejection, do **one** of:
- Provide a working **demo account** (phone + password) in *App Review
  Information → Sign-in required → Demo account*, and explain the OTP-based
  signup in the notes; **or**
- Register a reviewer phone number under Supabase → Authentication → Providers →
  Phone → **Test Phone Numbers and OTPs** (e.g. `+1XXXXXXXXXX=123456`) so a
  fixed code works without sending a real message, and share that number + code
  in the review notes.

---

## 7. Release

After approval, release manually or automatically (App Store Connect →
your version → **Release**). Phased release is optional.

---

## Notes specific to this project

- **Auth is fully server-side** (Supabase + Twilio Verify, WhatsApp channel).
  No iOS-side keys are needed for OTP — nothing to configure in the iOS build
  for auth. Just make sure the production Supabase URL / anon key the app ships
  with point at the live project.
- **Push notifications:** iOS push is *not* wired in this build (web push uses
  VAPID). If you add iOS push later, you'll need an **APNs Auth Key** in App
  Store Connect, the **Push Notifications** capability on the App ID, and the
  matching entitlement in Xcode — then rebuild.
- **Permissions strings:** any iOS permission the app uses (camera, photos,
  microphone for voice messages) must have a usage description in
  `ios/Runner/Info.plist` (`NSCameraUsageDescription`,
  `NSPhotoLibraryUsageDescription`, `NSMicrophoneUsageDescription`) or App
  Review will reject. Verify these exist before submitting.

---

## Quick reference (per release, on a Mac)

```bash
# 1. bump version in pubspec.yaml (raise the +build number)
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
# 2. upload build/ios/ipa/*.ipa via Transporter / altool / Xcode / fastlane
# 3. App Store Connect → attach build → submit for review
```

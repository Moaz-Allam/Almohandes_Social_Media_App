# Fast Google Play Review Checklist

Use this before pressing "Send for review" in Play Console.

## Upload

- Upload `build/almohandes-release-v2.0.0-4.aab`.
- Confirm package name: `com.almohandes.app`.
- Confirm version name/code: `2.0.0 / 4`.
- Enable Google Play App Signing.
- Keep the upload keystore and passwords private.

## Store Listing

- App name: `المهندس`.
- Use the Arabic short and long descriptions from `google_play_listing.md`.
- Upload `graphics/app_icon_512x512.png` as the high-res icon.
- Upload `graphics/feature_graphic_1024x500_google_play.png` as the Google Play feature graphic.
- Upload all PNGs from `screenshots/` as phone screenshots.

## Declarations

- Add a working Privacy Policy URL.
- Complete Data Safety based on actual data collected: account data, contact info, messages, user content, media uploads, and app activity if enabled.
- Complete Content Rating.
- Complete Target Audience and Content.
- Complete Ads declaration.
- If reviewers need login, add a test account under App access.

## Policy Risk To Check

- If Premium unlocks digital content or services inside the app, configure Google Play Billing for production or remove external payment for that flow before release. Google Play commonly rejects non-Play Billing payment flows for digital goods.
- Make sure account deletion is reachable from inside the app and documented if personal accounts are created.
- Avoid placeholder content in production screenshots and production app data.

## Signing Fingerprints

- The local upload-key fingerprints are in `signing/upload_key_fingerprints.txt`.
- Google's app-signing certificate fingerprint is created/shown in Play Console after enabling Play App Signing. Copy that Play Console fingerprint into any services that require the final Google-signed app certificate.

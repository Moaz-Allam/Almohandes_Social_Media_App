# Store Review Fast Checklist

Use this before uploading builds to Google Play and App Store review. It is tailored for this app because it includes accounts, messaging, user-generated posts, media uploads, notifications, projects, payments, and profile data.

## Reviewer Access

- Provide a working reviewer account for each major role: engineer, company, craftsman, worker, equipment owner, and admin if admin screens are submitted.
- Include the shared test password, OTP/SMS test instructions, and any feature flags in App Store Connect and Play Console review notes.
- Make sure reviewers can reach the main flows without real payments, real project approvals, or private external approvals.
- Keep demo content clean and production-safe. No mock posts that look broken, private, copied, or offensive.

## Privacy And Data

- Keep the in-app privacy policy reachable from onboarding, sign in, sign up, and settings.
- Match store privacy disclosures to the app exactly: profile details, phone, email, avatar/cover images, posts, comments, stories, reels, messages, attachments, notifications, project applications, saved content, and analytics/diagnostics if enabled.
- Google Play requires a Data safety form for published apps, and even apps that do not collect data must provide a privacy policy.
- Apple requires App Privacy details in App Store Connect for data collected by the app and third-party SDKs.
- The app already has in-app account deletion; verify it deletes the Supabase auth user and related profile data before submission.
- Also provide the external web account-deletion URL required by Google Play if the app lets users create accounts.

References:

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Google Play Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Google Play account deletion: https://support.google.com/googleplay/android-developer/answer/13327111

## User-Generated Content

- Posts, comments, reels, stories, profiles, chat files, and projects are user-generated content.
- Keep report and block actions obvious anywhere public UGC can be viewed.
- Keep chat blocking/removal available from the chat menu.
- Make moderation actions timely and document the moderation policy in review notes.
- Do not ship a production build with unmoderated demo content.

References:

- Google Play UGC policy: https://support.google.com/googleplay/android-developer/answer/9876937
- Apple App Review Guidelines, Safety and UGC: https://developer.apple.com/app-store/review/guidelines/

## Permissions

- Request notification permission only after the user opens notifications or clearly asks for alerts.
- Request microphone permission only when recording a voice message.
- Request media/file permissions only when the user chooses to upload or send media.
- Explain denied permissions with normal UI feedback, not raw platform or Supabase errors.
- Remove unused permissions from Android manifests and iOS plist files.

## Payments And Premium

- If premium unlocks digital app features, prepare Apple/Google in-app purchase configuration before production.
- If payment is only for real-world services, document that clearly in review notes.
- Keep a non-payment path available for reviewers to see the app.

## Technical QA

- Run Flutter analyze and tests.
- Test sign up, OTP, sign in, sign out, account deletion, profile edit, follow/connect, messaging, voice recording, file send, posts, comments, reposts, reels, stories, projects, notifications, saved items, and network filtering.
- Test fresh install, cold launch, slow network, denied permissions, expired OTP, duplicate connect/follow/apply actions, and empty states.
- Upload Android builds to an internal/closed track and check Google Play Pre-launch report before production.
- For iOS, archive a release build and test with TestFlight on at least one real device before submitting.

Reference:

- Google Play Pre-launch report: https://play.google.com/console/about/pre-launchreports/

## Store Metadata

- Use screenshots that show real app screens, not placeholder loading states.
- Keep the app description aligned with actual features.
- Include a support URL, privacy policy URL, and WhatsApp/support contact.
- Do not mention platforms, features, or payment options that are not live in the submitted build.

# المهندس — WhatsApp OTP Auth Setup

This guide explains how to deliver login / signup / password‑reset OTPs over
**WhatsApp** instead of SMS, using the project's existing **Twilio Verify**
integration and Supabase native phone auth.

> Read `supabase/AUTH_SETUP.md` first for the base phone‑auth setup. This
> document only covers the delta needed to switch the delivery channel to
> WhatsApp.

---

## 0. What the app already does (code side — done)

The Flutter app sends OTPs over a single, centrally‑configured channel defined
in `lib/data/repositories/auth_repository.dart`:

```dart
const String _otpChannelName = String.fromEnvironment(
  'AUTH_OTP_CHANNEL',
  defaultValue: 'whatsapp',   // ← WhatsApp is the default now
);
const OtpChannel kOtpChannel =
    _otpChannelName == 'sms' ? OtpChannel.sms : OtpChannel.whatsapp;
```

All three `signInWithOtp(...)` calls (signup, resend fallback, password reset)
use `channel: kOtpChannel`. **The default is WhatsApp**, so no flag is needed
for normal builds. To go back to SMS *without editing code*, build with:

```bash
flutter run   --dart-define=AUTH_OTP_CHANNEL=sms
flutter build apk --dart-define=AUTH_OTP_CHANNEL=sms
```

Important detail: **verification does not change.** Supabase verifies every
phone OTP with token type `OtpType.sms` regardless of whether it was delivered
over SMS or WhatsApp, so `verifyOTP(type: OtpType.sms)` stays as‑is. You never
touch the verify code when switching channels.

After this point, everything is **Twilio + Supabase configuration** — no
further code changes.

---

## 1. Prerequisites

- A **Twilio account** with the **Verify** service already used by this
  project (`[auth.sms.twilio_verify]` in `supabase/config.toml`).
- A **WhatsApp Business** presence. With Twilio Verify you have two options:
  1. **Twilio's WhatsApp sender (fastest):** use Twilio's shared/managed
     WhatsApp Business sender. Twilio supplies pre‑approved OTP templates, so
     there is nothing to submit to Meta. Best for getting live quickly.
  2. **Your own WhatsApp Business sender:** connect your own number / WhatsApp
     Business Account (WABA) through Meta. Use this when you want OTP messages
     to come from *your* brand number.
- Access to the **Supabase project** (linked locally as `Engineer`) or its
  dashboard.

---

## 2. Twilio side

### 2.1 Enable the WhatsApp channel on the Verify Service

1. Twilio Console → **Verify → Services** → open the service whose SID is in
   `message_service_sid` (`VAxxxxxxxx…`). This is the *same* service used for
   SMS today.
2. Open the service's **Channels / Settings**.
3. Enable the **WhatsApp** channel (SMS can stay enabled as a fallback or be
   turned off — your choice).
4. Save.

> Because this project uses **Verify** (not Programmable Messaging), Twilio
> manages the WhatsApp OTP message **templates** for you — they are already
> approved by Meta. You normally do **not** need to author or submit a custom
> template. (If you *do* want a custom branded template, submit it for Meta
> approval under Messaging → Content Template Builder and attach it to the
> Verify service.)

### 2.2 Connect a WhatsApp sender

- **Using Twilio's managed sender:** nothing else to do — the Verify service
  can send WhatsApp immediately once the channel is enabled.
- **Using your own WhatsApp Business number:** Twilio Console → **Messaging →
  Senders → WhatsApp senders** → start the onboarding wizard. You will:
  1. Connect / create a **Meta Business Manager** account.
  2. Register your phone number as a **WhatsApp sender** (the number must not be
     active on the WhatsApp consumer or Business app already).
  3. Complete Meta's business verification.
  4. Once approved, the sender becomes available to the Verify service.

### 2.3 Geo permissions & limits

1. Verify → Service → **Geo permissions:** allow Iraq (+964) and any other
   country codes in `lib/core/data/countries.dart` (e.g. Egypt +20).
2. Confirm code length = **6 digits** (matches the 6‑box OTP UI) and a sane
   code lifetime (10 min).
3. **Trial accounts:** WhatsApp on a Twilio trial only delivers to numbers you
   have verified in the console and may force a Twilio sandbox sender. Upgrade
   to a paid account for production delivery to arbitrary numbers.

The same three secrets you already use stay valid (no new secret is required —
Verify routes the channel internally):

| Secret | Value |
| --- | --- |
| `SUPABASE_AUTH_SMS_TWILIO_VERIFY_ACCOUNT_SID` | Account SID (`ACxxxx…`) |
| `SUPABASE_AUTH_SMS_TWILIO_VERIFY_AUTH_TOKEN` | Account Auth Token |
| `SUPABASE_AUTH_SMS_TWILIO_VERIFY_MESSAGE_SERVICE_SID` | Verify **Service** SID (`VAxxxx…`) |

---

## 3. Supabase side

Good news: **no config change is required to switch to WhatsApp.** The channel
is decided by the app (`channel: whatsapp`) and executed by the Verify service.
The `[auth.sms.twilio_verify]` block in `supabase/config.toml` stays exactly as
it is.

Just confirm the provider is enabled and pushed:

1. Make sure the three secrets are set on the linked project:

   ```bash
   supabase secrets list
   # if any are missing:
   supabase secrets set \
     SUPABASE_AUTH_SMS_TWILIO_VERIFY_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxx \
     SUPABASE_AUTH_SMS_TWILIO_VERIFY_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxx \
     SUPABASE_AUTH_SMS_TWILIO_VERIFY_MESSAGE_SERVICE_SID=VAxxxxxxxxxxxxxxxxxxxx
   ```

2. Push the auth config (idempotent — no WhatsApp‑specific keys are needed):

   ```bash
   supabase config push
   ```

3. (Dashboard alternative) Authentication → **Providers → Phone** → ensure
   **Twilio Verify** is enabled with the same Account SID / Auth Token /
   Service SID.

4. Optional: review **Authentication → Rate Limits**. `sms_sent = 30/hour` in
   `config.toml` also governs WhatsApp OTP sends; `max_frequency = "5s"` is the
   minimum gap between resends.

> The Arabic body in `[auth.sms].template` only applies to the SMS channel.
> WhatsApp OTP wording comes from the Twilio/Meta‑approved WhatsApp template, so
> editing that template string has no effect on WhatsApp messages.

---

## 4. Build & verify

WhatsApp is the default, so a normal build is enough:

```bash
flutter run
```

Smoke test:

1. **Signup:** enter `+9647xxxxxxxxx` → tap "إرسال رمز التحقق" → the OTP arrives
   as a **WhatsApp message** → enter 6 digits → set password → finish profile →
   land on the signed‑in shell.
2. **Resend:** on the OTP screen tap resend → a new WhatsApp code arrives.
3. **Password reset:** "نسيت كلمة المرور" → enter a registered number → WhatsApp
   code arrives → set a new password.
4. **Force SMS (regression check):** rebuild with
   `--dart-define=AUTH_OTP_CHANNEL=sms` and confirm the code arrives by SMS.

---

## 5. Changing your WhatsApp Business number later

Swapping the **sender number** is a **provider‑side operation only — no code
change**:

1. In Twilio, register/verify the new number as a WhatsApp sender (re‑do the
   Meta onboarding for the new number; get templates approved if you use custom
   ones).
2. Attach the new sender to the Verify service (or replace the old one).
3. Done. The app never references the sender number — it only sends the user's
   phone + `channel: whatsapp`, and Twilio/Meta picks the sender.

Existing accounts and sessions are unaffected; users keep logging in with their
own phone numbers.

> Unrelated: the in‑app **support** link `wa.me/9647800000000` in
> `lib/features/settings/settings_screen.dart` is a separate hardcoded contact
> link, not the OTP sender. Changing *that* number is a code edit (or make it a
> `--dart-define`).

---

## 6. Troubleshooting

- **`AuthApiError: SMS provider not configured` / channel error** → the Verify
  service doesn't have the WhatsApp channel enabled, or the secrets aren't set.
  Re‑check §2.1 and `supabase secrets list`, then `supabase config push`.
- **Code never arrives on WhatsApp** → Twilio → Verify → **Logs**. On trial
  accounts the destination number must be verified, and the sender may need to
  be the Twilio sandbox. Check the sender approval status under Messaging →
  Senders.
- **`63016` / template errors** → the WhatsApp template isn't approved for a
  custom sender. Use Twilio's managed Verify templates, or finish Meta template
  approval.
- **`60200 Invalid parameter`** → phone not in E.164 (`+964…`). The app already
  normalizes via `_normalizePhone`, but verify Geo permissions include the
  country.
- **Resend delivers via SMS instead of WhatsApp** → `resend` has no channel
  parameter; if the Verify service falls back to SMS, the OTP is still valid.
  The app's resend fallback re‑issues via `signInWithOtp(channel: whatsapp)` so
  delivery still works.
- **Want to revert quickly** → build with `--dart-define=AUTH_OTP_CHANNEL=sms`;
  no code or Supabase change needed.

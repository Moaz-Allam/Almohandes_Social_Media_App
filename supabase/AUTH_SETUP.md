# المهندس — Phone Auth Setup Checklist

This project uses Supabase **native phone auth** with **Twilio Verify** as the
SMS provider. The mobile app calls `signInWithOtp(phone, channel: sms)` →
`verifyOTP` → `updateUser(password:)`, exactly like the alqafila reference
project. There are no custom edge functions in the signup hot path.

The CLI project is already linked and named **Engineer**. The steps below are
the one-time setup to make remote auth actually work.

---

## 1. Set Twilio Verify secrets on the linked project

The three secrets referenced by `supabase/config.toml` (`[auth.sms.twilio_verify]`)
must exist on the **remote** project. They are NEVER committed to git.

You need three values from your Twilio console:

| Variable | Where in Twilio |
| --- | --- |
| `SUPABASE_AUTH_SMS_TWILIO_VERIFY_ACCOUNT_SID` | Console → Account → API keys & tokens → Account SID |
| `SUPABASE_AUTH_SMS_TWILIO_VERIFY_AUTH_TOKEN` | Console → Account → API keys & tokens → Auth Token |
| `SUPABASE_AUTH_SMS_TWILIO_VERIFY_MESSAGE_SERVICE_SID` | Console → Verify → Services → (your service) → Service SID (`VAxxxxxx…`) |

Then set them on the linked project:

```bash
supabase secrets set \
  SUPABASE_AUTH_SMS_TWILIO_VERIFY_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxx \
  SUPABASE_AUTH_SMS_TWILIO_VERIFY_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxx \
  SUPABASE_AUTH_SMS_TWILIO_VERIFY_MESSAGE_SERVICE_SID=VAxxxxxxxxxxxxxxxxxxxx
```

> If you prefer the dashboard: Authentication → Providers → Phone → enable
> Twilio Verify and paste the same three values.

---

## 2. Configure Twilio Verify service

In the Twilio console (one-time, per Verify service):

1. **Channels:** enable SMS. WhatsApp is optional.
2. **Code length:** 6 digits (matches the 6-box OTP UI).
3. **Code lifetime:** 10 minutes is fine.
4. **Friendly name:** `Almohandes` (used in the SMS body).
5. **Geo permissions:** allow Iraq (+964) and Egypt (+20) at minimum; add other
   countries from `lib/core/data/countries.dart` as needed.

The Arabic SMS template is set in `supabase/config.toml` →
`[auth.sms].template = "رمز التحقق الخاص بك هو {{ .Code }}"`.
Twilio Verify will ignore that for trial accounts (it sends its own copy), but
on paid plans you can match it.

---

## 3. Push config + migrations to the linked project

```bash
# Push the auth config (auth.sms.twilio_verify, templates, signup flags)
supabase config push

# Push the new phone_exists RPC and any other unapplied migrations
supabase db push
```

If `config push` reports nothing to do, double-check the project link:

```bash
supabase projects list
supabase link --project-ref <ref-of-Engineer>
```

---

## 4. Verify it works

From the project root:

```bash
flutter run
```

Smoke test:

1. **Signup:** `+9647xxxxxxxxx` → tap "إرسال رمز التحقق" → SMS arrives →
   enter 6 digits → set password → fill name/type/specialization/governorate/bio
   → land on the signed-in shell.
2. **Login:** sign out, enter the same phone → password → land on shell.
3. **Existing phone:** start signup with a number that already has an account
   → screen shows the "تسجيل الدخول" CTA without sending an SMS (this is the
   `phone_exists` RPC short-circuit).

---

## Troubleshooting

- **`AuthApiError: SMS provider not configured`** → step 1 secrets are missing
  or the project wasn't relinked after setting them. Re-run `supabase secrets list`
  and confirm all three keys are present, then `supabase config push`.
- **OTP sent but never delivered** → check Twilio Verify → Logs. Trial
  accounts only deliver to verified caller IDs.
- **`phone_exists` returns false for a real account** → the auth user row is
  there but `auth.users.phone` is NULL (older synthetic-email accounts). Run
  the `sync-auth-phone` edge function or backfill manually.

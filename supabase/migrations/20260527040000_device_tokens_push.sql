-- ============================================================
-- المهندس — device_tokens for FCM / Web Push.
--
-- The client upserts its push token here (onConflict: token). Needs a
-- unique index on token + RLS so each user manages only their own
-- tokens. The send-push edge function reads tokens with the service
-- role (bypasses RLS).
-- ============================================================

create unique index if not exists device_tokens_token_key
  on public.device_tokens (token);

alter table public.device_tokens enable row level security;

drop policy if exists "device tokens owner manage" on public.device_tokens;
create policy "device tokens owner manage" on public.device_tokens
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

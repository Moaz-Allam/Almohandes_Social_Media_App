-- Keep public settings readable while preventing accidental exposure of
-- payment tokens, API keys, and other credentials through admin_settings.

drop policy if exists "Everyone can read admin_settings" on public.admin_settings;
drop policy if exists "admin_settings_read" on public.admin_settings;
drop policy if exists "admin_settings_select" on public.admin_settings;

create policy "admin_settings_safe_select"
on public.admin_settings
for select
using (
  public.check_is_admin(auth.uid())
  or (
    key not ilike '%token%'
    and key not ilike '%secret%'
    and key not ilike '%password%'
    and key not ilike '%api_key%'
    and key not ilike '%entity_id%'
    and key not ilike 'switch_%'
    and key not ilike 'payment_%'
  )
);

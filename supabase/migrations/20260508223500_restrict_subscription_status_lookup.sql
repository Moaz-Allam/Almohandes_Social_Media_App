-- Avoid exposing another user's Premium/subscription status through the
-- client-callable entitlement helper.

create or replace function public.has_active_subscription(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.subscriptions s
    join public.profiles p on p.id = s.profile_id
    where s.profile_id = p_profile_id
      and p.user_id = auth.uid()
      and s.status = 'active'
      and (s.expires_at is null or s.expires_at > now())
  )
$$;

revoke execute on function public.has_active_subscription(uuid)
  from public, anon;
grant execute on function public.has_active_subscription(uuid)
  to authenticated;

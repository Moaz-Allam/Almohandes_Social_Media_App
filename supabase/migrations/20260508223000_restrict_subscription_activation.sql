-- Premium entitlement must be granted by trusted payment/backend flows only.
-- Client applications should never be able to self-activate subscriptions.

do $$
begin
  if to_regprocedure('public.activate_subscription_p(uuid)') is not null then
    execute 'revoke execute on function public.activate_subscription_p(uuid) from public, anon, authenticated';
    execute 'grant execute on function public.activate_subscription_p(uuid) to service_role';
  end if;
end
$$;

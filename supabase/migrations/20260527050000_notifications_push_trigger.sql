-- ============================================================
-- المهندس — fire the send-push edge function on every new notification.
--
-- Uses pg_net (async HTTP from Postgres) so we don't need a dashboard
-- webhook. The function is deployed with --no-verify-jwt so this call
-- needs no auth header. Failures never block the notification insert.
-- ============================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.tg_notifications_send_push()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform net.http_post(
    url := 'https://gwuzlcmuxcokfpnaofjc.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body := jsonb_build_object('record', to_jsonb(new))
  );
  return new;
exception
  when others then
    -- Push is best-effort; never fail the insert.
    return new;
end;
$$;

drop trigger if exists trg_notifications_send_push on public.notifications;
create trigger trg_notifications_send_push
  after insert on public.notifications
  for each row
  execute function public.tg_notifications_send_push();

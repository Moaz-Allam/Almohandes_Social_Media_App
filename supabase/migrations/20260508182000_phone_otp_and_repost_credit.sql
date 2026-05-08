-- Production signup OTPs and repost attribution.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.signup_phone_otps (
  id uuid primary key default gen_random_uuid(),
  phone_local10 text not null,
  code_hash text not null,
  attempts integer not null default 0,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_signup_phone_otps_phone_created
  on public.signup_phone_otps (phone_local10, created_at desc);

alter table public.signup_phone_otps enable row level security;

create table if not exists public.signup_phone_verifications (
  phone_local10 text primary key,
  verified_at timestamptz not null default now(),
  expires_at timestamptz not null
);

alter table public.signup_phone_verifications enable row level security;

create or replace function public.normalize_iraqi_phone_local10(p_phone text)
returns text
language plpgsql
immutable
set search_path = public
as $$
declare
  v_phone text;
begin
  v_phone := regexp_replace(coalesce(p_phone, ''), '[^0-9+]', '', 'g');

  if v_phone ~ '^\+9647[3-9][0-9]{8}$' then
    return '0' || substring(v_phone from 5);
  end if;

  if v_phone ~ '^009647[3-9][0-9]{8}$' then
    return '0' || substring(v_phone from 6);
  end if;

  if v_phone ~ '^07[3-9][0-9]{8}$' then
    return v_phone;
  end if;

  return null;
end;
$$;

create or replace function public.create_signup_otp(p_phone text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_phone text;
  v_recent_count integer;
  v_bytes bytea;
  v_number bigint;
  v_code text;
  v_expires_at timestamptz;
begin
  v_phone := public.normalize_iraqi_phone_local10(p_phone);

  if v_phone is null then
    raise exception 'invalid_iraqi_phone';
  end if;

  select count(*)
  into v_recent_count
  from public.signup_phone_otps
  where phone_local10 = v_phone
    and created_at > now() - interval '10 minutes';

  if v_recent_count >= 5 then
    raise exception 'otp_rate_limited';
  end if;

  v_bytes := extensions.gen_random_bytes(4);
  v_number :=
    get_byte(v_bytes, 0)::bigint * 16777216 +
    get_byte(v_bytes, 1)::bigint * 65536 +
    get_byte(v_bytes, 2)::bigint * 256 +
    get_byte(v_bytes, 3)::bigint;
  v_code := lpad((v_number % 1000000)::text, 6, '0');
  v_expires_at := now() + interval '10 minutes';

  update public.signup_phone_otps
  set consumed_at = now()
  where phone_local10 = v_phone
    and consumed_at is null;

  insert into public.signup_phone_otps (
    phone_local10,
    code_hash,
    expires_at
  )
  values (
    v_phone,
    extensions.crypt(v_code, extensions.gen_salt('bf')),
    v_expires_at
  );

  return jsonb_build_object(
    'phone_local10', v_phone,
    'code', v_code,
    'expires_at', v_expires_at
  );
end;
$$;

revoke all on function public.create_signup_otp(text) from public;
grant execute on function public.create_signup_otp(text) to service_role;

drop function if exists public.verify_otp_token(text, uuid);

create or replace function public.verify_otp_token(
  p_phone_local10 text,
  p_verification_code text
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_phone text;
  v_otp public.signup_phone_otps%rowtype;
begin
  v_phone := public.normalize_iraqi_phone_local10(p_phone_local10);

  if v_phone is null or coalesce(p_verification_code, '') !~ '^[0-9]{6}$' then
    return false;
  end if;

  select *
  into v_otp
  from public.signup_phone_otps
  where phone_local10 = v_phone
    and consumed_at is null
    and expires_at > now()
  order by created_at desc
  limit 1
  for update;

  if not found then
    return false;
  end if;

  if v_otp.attempts >= 5 then
    return false;
  end if;

  update public.signup_phone_otps
  set attempts = attempts + 1
  where id = v_otp.id;

  if v_otp.code_hash = extensions.crypt(trim(p_verification_code), v_otp.code_hash) then
    update public.signup_phone_otps
    set consumed_at = now()
    where id = v_otp.id;

    insert into public.signup_phone_verifications (
      phone_local10,
      verified_at,
      expires_at
    )
    values (
      v_phone,
      now(),
      now() + interval '30 minutes'
    )
    on conflict (phone_local10)
    do update set
      verified_at = excluded.verified_at,
      expires_at = excluded.expires_at;

    return true;
  end if;

  return false;
end;
$$;

grant execute on function public.verify_otp_token(text, text) to anon, authenticated;

create or replace function public.has_verified_signup_phone(p_phone text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.signup_phone_verifications v
    where v.phone_local10 = public.normalize_iraqi_phone_local10(p_phone)
      and v.expires_at > now()
  );
$$;

grant execute on function public.has_verified_signup_phone(text) to anon, authenticated;

alter table if exists public.posts
  add column if not exists repost_of_post_id uuid references public.posts(id) on delete set null,
  add column if not exists repost_original_profile_id uuid references public.profiles(id) on delete set null,
  add column if not exists repost_original_name text;

drop function if exists public.get_home_feed(uuid, integer, integer);

create or replace function public.get_home_feed(
  p_profile_id uuid,
  p_limit integer default 20,
  p_offset integer default 0
)
returns table (
  post_id uuid,
  content text,
  image_url text,
  post_type text,
  likes_count integer,
  comments_count integer,
  created_at timestamptz,
  repost_of_post_id uuid,
  repost_original_profile_id uuid,
  repost_original_name text,
  profile_id uuid,
  full_name text,
  username text,
  avatar_url text,
  role public.user_role,
  is_verified boolean,
  is_liked boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  return query
  select
    p.id as post_id,
    p.content,
    p.image_url,
    p.post_type,
    p.likes_count,
    p.comments_count,
    p.created_at,
    p.repost_of_post_id,
    p.repost_original_profile_id,
    p.repost_original_name,
    pr.id as profile_id,
    pr.full_name,
    pr.username,
    pr.avatar_url,
    pr.role,
    pr.is_verified,
    exists(
      select 1
      from public.post_likes pl
      where pl.post_id = p.id
        and pl.profile_id = p_profile_id
    ) as is_liked
  from public.posts p
  join public.profiles pr on pr.id = p.profile_id
  left join public.blocked_users bu on
    (bu.blocker_id = p_profile_id and bu.blocked_id = p.profile_id)
    or (bu.blocker_id = p.profile_id and bu.blocked_id = p_profile_id)
  where p.is_active = true
    and (p.is_archived = false or p.is_archived is null)
    and bu.id is null
  order by p.created_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

grant all on function public.get_home_feed(uuid, integer, integer)
  to anon, authenticated, service_role;

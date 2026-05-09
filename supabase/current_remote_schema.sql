


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "auth";


ALTER SCHEMA "auth" OWNER TO "supabase_admin";


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE SCHEMA IF NOT EXISTS "storage";


ALTER SCHEMA "storage" OWNER TO "supabase_admin";


CREATE TYPE "auth"."aal_level" AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


ALTER TYPE "auth"."aal_level" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."code_challenge_method" AS ENUM (
    's256',
    'plain'
);


ALTER TYPE "auth"."code_challenge_method" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."factor_status" AS ENUM (
    'unverified',
    'verified'
);


ALTER TYPE "auth"."factor_status" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."factor_type" AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


ALTER TYPE "auth"."factor_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_authorization_status" AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


ALTER TYPE "auth"."oauth_authorization_status" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_client_type" AS ENUM (
    'public',
    'confidential'
);


ALTER TYPE "auth"."oauth_client_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_registration_type" AS ENUM (
    'dynamic',
    'manual'
);


ALTER TYPE "auth"."oauth_registration_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."oauth_response_type" AS ENUM (
    'code'
);


ALTER TYPE "auth"."oauth_response_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "auth"."one_time_token_type" AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


ALTER TYPE "auth"."one_time_token_type" OWNER TO "supabase_auth_admin";


CREATE TYPE "public"."admin_role" AS ENUM (
    'super_admin',
    'admin',
    'content_manager',
    'instructor',
    'support',
    'viewer'
);


ALTER TYPE "public"."admin_role" OWNER TO "postgres";


CREATE TYPE "public"."admin_status" AS ENUM (
    'active',
    'suspended',
    'pending'
);


ALTER TYPE "public"."admin_status" OWNER TO "postgres";


CREATE TYPE "public"."asset_type" AS ENUM (
    'video',
    'pdf',
    'image',
    'audio',
    'document',
    'presentation',
    'other'
);


ALTER TYPE "public"."asset_type" OWNER TO "postgres";


CREATE TYPE "public"."contractor_status" AS ENUM (
    'working',
    'available'
);


ALTER TYPE "public"."contractor_status" OWNER TO "postgres";


CREATE TYPE "public"."course_category" AS ENUM (
    'theoretical',
    'practical',
    'training'
);


ALTER TYPE "public"."course_category" OWNER TO "postgres";


CREATE TYPE "public"."craftsman_specialization" AS ENUM (
    'plastering',
    'carpentry',
    'blacksmith',
    'painter',
    'plumber',
    'electrician',
    'tiling',
    'other',
    'mechanic',
    'hvac',
    'aluminum',
    'solar',
    'cameras',
    'brick_mason',
    'concrete_worker'
);


ALTER TYPE "public"."craftsman_specialization" OWNER TO "postgres";


CREATE TYPE "public"."engineer_specialization" AS ENUM (
    'architectural',
    'civil',
    'electrical',
    'mechanical',
    'chemical',
    'environmental',
    'petroleum',
    'other',
    'computer',
    'surveying'
);


ALTER TYPE "public"."engineer_specialization" OWNER TO "postgres";


CREATE TYPE "public"."governorate" AS ENUM (
    'baghdad',
    'basra',
    'nineveh',
    'erbil',
    'sulaymaniyah',
    'duhok',
    'kirkuk',
    'diyala',
    'anbar',
    'babylon',
    'karbala',
    'najaf',
    'wasit',
    'saladin',
    'dhi_qar',
    'maysan',
    'muthanna',
    'qadisiyah'
);


ALTER TYPE "public"."governorate" OWNER TO "postgres";


CREATE TYPE "public"."lecture_status" AS ENUM (
    'draft',
    'pending_review',
    'published',
    'archived'
);


ALTER TYPE "public"."lecture_status" OWNER TO "postgres";


CREATE TYPE "public"."machinery_specialization" AS ENUM (
    'excavator',
    'crane',
    'loader',
    'bulldozer',
    'forklift',
    'concrete_mixer',
    'truck',
    'tanker',
    'generator',
    'compressor',
    'other',
    'tuk_tuk'
);


ALTER TYPE "public"."machinery_specialization" OWNER TO "postgres";


CREATE TYPE "public"."notification_target_type" AS ENUM (
    'all',
    'role',
    'department',
    'user'
);


ALTER TYPE "public"."notification_target_type" OWNER TO "postgres";


CREATE TYPE "public"."subscription_status" AS ENUM (
    'active',
    'expired',
    'cancelled',
    'trial'
);


ALTER TYPE "public"."subscription_status" OWNER TO "postgres";


CREATE TYPE "public"."user_role" AS ENUM (
    'engineer',
    'contractor',
    'craftsman',
    'client',
    'worker',
    'machinery',
    'admin',
    'moderator'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE TYPE "storage"."buckettype" AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


ALTER TYPE "storage"."buckettype" OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "auth"."email"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


ALTER FUNCTION "auth"."email"() OWNER TO "supabase_auth_admin";


COMMENT ON FUNCTION "auth"."email"() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';



CREATE OR REPLACE FUNCTION "auth"."jwt"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


ALTER FUNCTION "auth"."jwt"() OWNER TO "supabase_auth_admin";


CREATE OR REPLACE FUNCTION "auth"."role"() RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


ALTER FUNCTION "auth"."role"() OWNER TO "supabase_auth_admin";


COMMENT ON FUNCTION "auth"."role"() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';



CREATE OR REPLACE FUNCTION "auth"."uid"() RETURNS "uuid"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


ALTER FUNCTION "auth"."uid"() OWNER TO "supabase_auth_admin";


COMMENT ON FUNCTION "auth"."uid"() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';



CREATE OR REPLACE FUNCTION "public"."activate_subscription_p"("p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$ BEGIN INSERT INTO public.subscriptions (profile_id, status, plan_type, starts_at, expires_at, updated_at) VALUES (p_profile_id, 'active', 'yearly', NOW(), NOW() + INTERVAL '1 year', NOW()) ON CONFLICT (profile_id) DO UPDATE SET status = 'active', plan_type = 'yearly', starts_at = NOW(), expires_at = NOW() + INTERVAL '1 year', updated_at = NOW(); END; $$;


ALTER FUNCTION "public"."activate_subscription_p"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_has_permission"("p_permission_key" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_user_roles aur
    JOIN public.admin_role_permissions arp ON aur.role_id = arp.role_id
    JOIN public.admin_permissions ap ON arp.permission_id = ap.id
    WHERE aur.user_id = public.get_admin_user_id()
    AND ap.key = p_permission_key
  )
$$;


ALTER FUNCTION "public"."admin_has_permission"("p_permission_key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_has_role"("p_role" "public"."admin_role") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_user_roles aur
    JOIN public.admin_roles ar ON aur.role_id = ar.id
    WHERE aur.user_id = public.get_admin_user_id()
    AND ar.name = p_role
  )
$$;


ALTER FUNCTION "public"."admin_has_role"("p_role" "public"."admin_role") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_can_post_projects"("p_profile_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.profiles p
    where p.id = p_profile_id
      and p.role in ('engineer'::user_role, 'contractor'::user_role)
  )
$$;


ALTER FUNCTION "public"."app_can_post_projects"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_current_profile_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select p.id
  from public.profiles p
  where p.user_id = auth.uid()
  limit 1
$$;


ALTER FUNCTION "public"."app_current_profile_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_normalize_conversation_participants"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_first uuid;
begin
  if new.participant_one is not null
    and new.participant_two is not null
    and new.participant_one::text > new.participant_two::text then
    v_first := new.participant_one;
    new.participant_one := new.participant_two;
    new.participant_two := v_first;
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."app_normalize_conversation_participants"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_notify_on_comment"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_owner uuid;
begin
  if new.target_type = 'reel' then
    select r.profile_id into v_owner
    from public.reels r
    where r.id::text = new.target_id;
  elsif new.target_type = 'project' then
    select p.profile_id into v_owner
    from public.projects p
    where p.id::text = new.target_id;
  else
    select p.profile_id into v_owner
    from public.posts p
    where p.id::text = new.target_id;
  end if;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'New comment',
      'Someone commented on your content.',
      'comment',
      'app://' || new.target_type || '/' || new.target_id
    );
  end if;

  if new.target_type = 'post' then
    update public.posts
    set comments_count = coalesce(comments_count, 0) + 1
    where id::text = new.target_id;
  elsif new.target_type = 'reel' then
    update public.reels
    set comments_count = coalesce(comments_count, 0) + 1
    where id::text = new.target_id;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."app_notify_on_comment"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_notify_on_connection_request"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if tg_op = 'INSERT' and new.status = 'pending' then
    perform public.app_notify_once(
      new.receiver_profile_id,
      'New connection request',
      'You received a connection request.',
      'connection',
      'app://profile/' || new.requester_profile_id::text
    );
  elsif tg_op = 'UPDATE'
    and new.status = 'accepted'
    and old.status is distinct from 'accepted' then
    perform public.app_notify_once(
      new.requester_profile_id,
      'Connection accepted',
      'You can now message this connection.',
      'connection',
      'app://chat/' || new.receiver_profile_id::text
    );
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."app_notify_on_connection_request"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_notify_on_message"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_recipient uuid;
begin
  select case
      when c.participant_one = new.sender_id then c.participant_two
      else c.participant_one
    end
  into v_recipient
  from public.conversations c
  where c.id = new.conversation_id;

  if v_recipient is not null and v_recipient <> new.sender_id then
    perform public.app_notify_once(
      v_recipient,
      'New message',
      case new.message_type
        when 'voice' then 'You received a voice message.'
        when 'image' then 'You received an image.'
        when 'video' then 'You received a video.'
        when 'file' then 'You received a file.'
        else left(coalesce(new.content, 'New message'), 160)
      end,
      'message',
      'app://chat/' || new.conversation_id::text
    );
  end if;

  update public.messages
  set is_read = false
  where id = new.id
    and is_read is distinct from false;

  return new;
end;
$$;


ALTER FUNCTION "public"."app_notify_on_message"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_notify_on_post_like"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_owner uuid;
begin
  select p.profile_id
  into v_owner
  from public.posts p
  where p.id = new.post_id;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'New like',
      'Someone liked your post.',
      'like',
      'app://post/' || new.post_id::text
    );
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."app_notify_on_post_like"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_notify_on_project_application"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_owner uuid;
begin
  select p.profile_id
  into v_owner
  from public.projects p
  where p.id = new.project_id;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'New project proposal',
      'A user submitted a proposal to your project.',
      'project',
      'app://project/' || new.project_id::text
    );
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."app_notify_on_project_application"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_notify_on_reel_like"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_owner uuid;
begin
  select r.profile_id
  into v_owner
  from public.reels r
  where r.id = new.reel_id;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'New like',
      'Someone liked your reel.',
      'like',
      'app://reel/' || new.reel_id::text
    );
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."app_notify_on_reel_like"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_notify_once"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text", "p_action_url" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if p_profile_id is null then
    return;
  end if;

  if exists (
    select 1
    from public.notifications n
    where n.profile_id = p_profile_id
      and n.type = coalesce(nullif(trim(p_type), ''), 'general')
      and n.action_url is not distinct from p_action_url
      and n.created_at > now() - interval '30 seconds'
  ) then
    return;
  end if;

  insert into public.notifications (
    profile_id,
    title,
    message,
    type,
    action_url
  )
  values (
    p_profile_id,
    coalesce(nullif(trim(p_title), ''), 'New notification'),
    coalesce(p_message, ''),
    coalesce(nullif(trim(p_type), ''), 'general'),
    p_action_url
  );
end;
$$;


ALTER FUNCTION "public"."app_notify_once"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text", "p_action_url" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_safe_governorate"("p_governorate" "text") RETURNS "public"."governorate"
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO 'public'
    AS $$
  select case lower(coalesce(nullif(trim(p_governorate), ''), 'baghdad'))
    when 'baghdad' then 'baghdad'::public.governorate
    when 'basra' then 'basra'::public.governorate
    when 'nineveh' then 'nineveh'::public.governorate
    when 'erbil' then 'erbil'::public.governorate
    when 'sulaymaniyah' then 'sulaymaniyah'::public.governorate
    when 'duhok' then 'duhok'::public.governorate
    when 'kirkuk' then 'kirkuk'::public.governorate
    when 'diyala' then 'diyala'::public.governorate
    when 'anbar' then 'anbar'::public.governorate
    when 'babylon' then 'babylon'::public.governorate
    when 'karbala' then 'karbala'::public.governorate
    when 'najaf' then 'najaf'::public.governorate
    when 'wasit' then 'wasit'::public.governorate
    when 'saladin' then 'saladin'::public.governorate
    when 'dhi_qar' then 'dhi_qar'::public.governorate
    when 'maysan' then 'maysan'::public.governorate
    when 'muthanna' then 'muthanna'::public.governorate
    when 'qadisiyah' then 'qadisiyah'::public.governorate
    else 'baghdad'::public.governorate
  end
$$;


ALTER FUNCTION "public"."app_safe_governorate"("p_governorate" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_safe_user_role"("p_role" "text") RETURNS "public"."user_role"
    LANGUAGE "sql" IMMUTABLE
    SET "search_path" TO 'public'
    AS $$
  select case lower(coalesce(nullif(trim(p_role), ''), 'engineer'))
    when 'engineer' then 'engineer'::public.user_role
    when 'contractor' then 'contractor'::public.user_role
    when 'company' then 'contractor'::public.user_role
    when 'client' then 'client'::public.user_role
    when 'craftsman' then 'craftsman'::public.user_role
    when 'worker' then 'worker'::public.user_role
    when 'machinery' then 'machinery'::public.user_role
    when 'equipment' then 'machinery'::public.user_role
    when 'admin' then 'admin'::public.user_role
    else 'engineer'::public.user_role
  end
$$;


ALTER FUNCTION "public"."app_safe_user_role"("p_role" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_sync_profile_cover_columns"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if new.cover_url is null and new.cover_photo_url is not null then
    new.cover_url := new.cover_photo_url;
  elsif new.cover_photo_url is null and new.cover_url is not null then
    new.cover_photo_url := new.cover_url;
  elsif tg_op = 'UPDATE'
    and new.cover_url is distinct from old.cover_url
    and new.cover_url is not null then
    new.cover_photo_url := new.cover_url;
  elsif tg_op = 'UPDATE'
    and new.cover_photo_url is distinct from old.cover_photo_url
    and new.cover_photo_url is not null then
    new.cover_url := new.cover_photo_url;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."app_sync_profile_cover_columns"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_touch_conversation"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  update public.conversations
  set last_message = case
      when new.message_type = 'voice' then 'رسالة صوتية'
      when new.message_type = 'image' then 'صورة مرفقة'
      when new.message_type = 'video' then 'فيديو مرفق'
      when new.message_type = 'file' then 'ملف مرفق'
      else left(new.content, 180)
    end,
    last_message_at = new.created_at
  where id = new.conversation_id;
  return new;
end;
$$;


ALTER FUNCTION "public"."app_touch_conversation"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."app_update_connection_counts"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_one uuid;
  v_two uuid;
begin
  if new.status = 'accepted' and old.status is distinct from 'accepted' then
    update public.profiles
    set following_count = coalesce(following_count, 0) + 1
    where id in (new.requester_profile_id, new.receiver_profile_id);

    v_one := least(new.requester_profile_id, new.receiver_profile_id);
    v_two := greatest(new.requester_profile_id, new.receiver_profile_id);

    insert into public.conversations (
      participant_one,
      participant_two,
      last_message,
      last_message_at
    )
    values (v_one, v_two, '', now())
    on conflict (participant_one, participant_two)
    do nothing;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."app_update_connection_counts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."apply_to_project_for_app"("p_project_id" "uuid", "p_subject" "text", "p_message" "text", "p_files" "jsonb" DEFAULT '[]'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_profile_id uuid;
  v_owner_id uuid;
  v_application_id uuid;
begin
  v_profile_id := public.app_current_profile_id();

  if v_profile_id is null then
    raise exception 'profile_not_found';
  end if;

  select profile_id into v_owner_id
  from public.projects
  where id = p_project_id;

  if v_owner_id = v_profile_id then
    raise exception 'cannot_apply_to_own_project';
  end if;

  select id into v_application_id
  from public.project_applications
  where project_id = p_project_id
    and profile_id = v_profile_id;

  if v_application_id is not null then
    raise exception 'already_applied';
  end if;

  insert into public.project_applications (
    project_id,
    profile_id,
    subject,
    message,
    attachments_count,
    files
  )
  values (
    p_project_id,
    v_profile_id,
    p_subject,
    p_message,
    jsonb_array_length(coalesce(p_files, '[]'::jsonb)),
    coalesce(p_files, '[]'::jsonb)
  )
  returning id into v_application_id;

  return v_application_id;
end;
$$;


ALTER FUNCTION "public"."apply_to_project_for_app"("p_project_id" "uuid", "p_subject" "text", "p_message" "text", "p_files" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_is_admin"("user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.admin_users au
    WHERE au.id = check_is_admin.user_id
    AND au.status = 'active'
  );
END;
$$;


ALTER FUNCTION "public"."check_is_admin"("user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_permission"("p_user_id" "uuid", "p_permission" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM user_roles ur
    JOIN role_permissions rp ON ur.role_id = rp.role_id
    JOIN permissions p ON rp.permission_id = p.id
    WHERE ur.user_id = p_user_id
    AND p.name = p_permission
  );
END;
$$;


ALTER FUNCTION "public"."check_permission"("p_user_id" "uuid", "p_permission" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_rate_limit"("p_key" "text", "p_window_minutes" integer DEFAULT 60, "p_max_requests" integer DEFAULT 5) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_count integer;
  v_window_start timestamp with time zone;
BEGIN
  v_window_start := now() - (p_window_minutes || ' minutes')::interval;
  
  -- Count requests in window
  SELECT COALESCE(SUM(request_count), 0) INTO v_count
  FROM public.rate_limits
  WHERE key = p_key AND window_start > v_window_start;
  
  -- If over limit, return false
  IF v_count >= p_max_requests THEN
    RETURN false;
  END IF;
  
  -- Record this request
  INSERT INTO public.rate_limits (key, window_start, request_count)
  VALUES (p_key, now(), 1);
  
  -- Periodically cleanup (1% chance per request)
  IF random() < 0.01 THEN
    PERFORM public.cleanup_old_rate_limits();
  END IF;
  
  RETURN true;
END;
$$;


ALTER FUNCTION "public"."check_rate_limit"("p_key" "text", "p_window_minutes" integer, "p_max_requests" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_subscription_expiry_notifications"("p_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_subscription RECORD;
  v_days_remaining INTEGER;
  v_notification_exists BOOLEAN;
BEGIN
  -- Get active subscription for the profile
  SELECT * INTO v_subscription
  FROM public.subscriptions
  WHERE profile_id = p_profile_id
    AND status = 'active'
    AND expires_at IS NOT NULL;
  
  -- If no active subscription with expiry, exit
  IF v_subscription IS NULL THEN
    RETURN;
  END IF;
  
  -- Calculate days remaining
  v_days_remaining := EXTRACT(DAY FROM (v_subscription.expires_at - NOW()));
  
  -- Check for 30-day reminder (between 29 and 31 days)
  IF v_days_remaining BETWEEN 29 AND 31 THEN
    -- Check if notification already exists for this period
    SELECT EXISTS(
      SELECT 1 FROM public.notifications
      WHERE profile_id = p_profile_id
        AND type = 'subscription_expiry_30'
        AND created_at > NOW() - INTERVAL '7 days'
    ) INTO v_notification_exists;
    
    IF NOT v_notification_exists THEN
      INSERT INTO public.notifications (profile_id, title, message, type, action_url)
      VALUES (
        p_profile_id,
        'تذكير بتجديد الاشتراك',
        'اشتراكك سينتهي خلال 30 يوماً. جدد الآن للاستمرار في الاستفادة من جميع المميزات.',
        'subscription_expiry_30',
        '/subscription'
      );
    END IF;
  END IF;
  
  -- Check for 7-day reminder (between 6 and 8 days)
  IF v_days_remaining BETWEEN 6 AND 8 THEN
    -- Check if notification already exists for this period
    SELECT EXISTS(
      SELECT 1 FROM public.notifications
      WHERE profile_id = p_profile_id
        AND type = 'subscription_expiry_7'
        AND created_at > NOW() - INTERVAL '3 days'
    ) INTO v_notification_exists;
    
    IF NOT v_notification_exists THEN
      INSERT INTO public.notifications (profile_id, title, message, type, action_url)
      VALUES (
        p_profile_id,
        'اشتراكك على وشك الانتهاء!',
        'تبقى 7 أيام فقط على انتهاء اشتراكك. جدد الآن لتجنب انقطاع الخدمة.',
        'subscription_expiry_7',
        '/subscription'
      );
    END IF;
  END IF;
  
  -- Check for 1-day reminder (last day)
  IF v_days_remaining BETWEEN 0 AND 1 THEN
    -- Check if notification already exists for this period
    SELECT EXISTS(
      SELECT 1 FROM public.notifications
      WHERE profile_id = p_profile_id
        AND type = 'subscription_expiry_1'
        AND created_at > NOW() - INTERVAL '1 day'
    ) INTO v_notification_exists;
    
    IF NOT v_notification_exists THEN
      INSERT INTO public.notifications (profile_id, title, message, type, action_url)
      VALUES (
        p_profile_id,
        'اشتراكك ينتهي اليوم!',
        'اشتراكك ينتهي اليوم. جدد الآن للحفاظ على وصولك لجميع المميزات.',
        'subscription_expiry_1',
        '/subscription'
      );
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION "public"."check_subscription_expiry_notifications"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_expired_otps"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  DELETE FROM public.otp_verifications WHERE expires_at < now();
END;
$$;


ALTER FUNCTION "public"."cleanup_expired_otps"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_old_rate_limits"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  DELETE FROM public.rate_limits WHERE window_start < now() - interval '24 hours';
END;
$$;


ALTER FUNCTION "public"."cleanup_old_rate_limits"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."complete_signup_profile_for_app"("p_full_name" "text", "p_email" "text", "p_phone" "text", "p_role" "text", "p_governorate" "text", "p_bio" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_user_id uuid;
  v_profile_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = v_user_id
  order by p.created_at desc nulls last, p.id
  limit 1;

  if v_profile_id is null then
    insert into public.profiles (
      user_id,
      full_name,
      email,
      phone,
      role,
      governorate,
      bio
    )
    values (
      v_user_id,
      coalesce(nullif(trim(p_full_name), ''), split_part(coalesce(p_email, ''), '@', 1), 'User'),
      nullif(trim(p_email), ''),
      nullif(trim(p_phone), ''),
      public.app_safe_user_role(p_role),
      public.app_safe_governorate(p_governorate),
      nullif(trim(p_bio), '')
    )
    returning id into v_profile_id;
  else
    update public.profiles
    set
      full_name = coalesce(nullif(trim(p_full_name), ''), full_name),
      email = coalesce(nullif(trim(p_email), ''), email),
      phone = nullif(trim(p_phone), ''),
      role = public.app_safe_user_role(p_role),
      governorate = public.app_safe_governorate(p_governorate),
      bio = nullif(trim(p_bio), ''),
      updated_at = now()
    where id = v_profile_id;
  end if;

  return v_profile_id;
end;
$$;


ALTER FUNCTION "public"."complete_signup_profile_for_app"("p_full_name" "text", "p_email" "text", "p_phone" "text", "p_role" "text", "p_governorate" "text", "p_bio" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_notification"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text" DEFAULT 'general'::"text", "p_action_url" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  new_id uuid;
  valid_types text[] := ARRAY['general', 'rating', 'follow', 'message', 'system', 'project', 'review'];
BEGIN
  -- Validate title length
  IF p_title IS NULL OR length(p_title) = 0 THEN
    RAISE EXCEPTION 'Title cannot be empty';
  END IF;
  
  IF length(p_title) > 200 THEN
    RAISE EXCEPTION 'Title must be less than 200 characters';
  END IF;
  
  -- Validate message length
  IF p_message IS NULL OR length(p_message) = 0 THEN
    RAISE EXCEPTION 'Message cannot be empty';
  END IF;
  
  IF length(p_message) > 1000 THEN
    RAISE EXCEPTION 'Message must be less than 1000 characters';
  END IF;
  
  -- Validate notification type
  IF p_type IS NOT NULL AND NOT (p_type = ANY(valid_types)) THEN
    RAISE EXCEPTION 'Invalid notification type: %', p_type;
  END IF;
  
  -- Validate action URL format if provided
  IF p_action_url IS NOT NULL AND p_action_url !~ '^https?://' AND p_action_url !~ '^/' THEN
    RAISE EXCEPTION 'Invalid action URL format';
  END IF;
  
  -- Sanitize inputs by trimming whitespace
  INSERT INTO public.notifications (profile_id, title, message, type, action_url)
  VALUES (p_profile_id, trim(p_title), trim(p_message), COALESCE(p_type, 'general'), p_action_url)
  RETURNING id INTO new_id;
  
  RETURN new_id;
END;
$$;


ALTER FUNCTION "public"."create_notification"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text", "p_action_url" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_project_for_app"("p_title" "text", "p_description" "text", "p_governorate" "text", "p_tagline" "text" DEFAULT NULL::"text", "p_category" "text" DEFAULT 'civil'::"text", "p_project_type" "text" DEFAULT 'project_collaboration'::"text", "p_work_mode" "text" DEFAULT 'onsite'::"text", "p_stage" "text" DEFAULT 'planning'::"text", "p_problem" "text" DEFAULT NULL::"text", "p_goals" "text" DEFAULT NULL::"text", "p_target_users" "text" DEFAULT NULL::"text", "p_existing_assets" "text"[] DEFAULT '{}'::"text"[], "p_required_skills" "text"[] DEFAULT '{}'::"text"[], "p_preferred_skills" "text"[] DEFAULT '{}'::"text"[], "p_tools_equipment" "text"[] DEFAULT '{}'::"text"[], "p_seniority_level" "text" DEFAULT NULL::"text", "p_years_experience" integer DEFAULT NULL::integer, "p_certifications" "text"[] DEFAULT '{}'::"text"[], "p_engineers_needed" integer DEFAULT 1, "p_roles_needed" "text"[] DEFAULT '{}'::"text"[], "p_responsibilities" "jsonb" DEFAULT '{}'::"jsonb", "p_current_team_size" "text" DEFAULT NULL::"text", "p_collaboration_tools" "text"[] DEFAULT '{}'::"text"[], "p_estimated_duration" "text" DEFAULT NULL::"text", "p_weekly_commitment" "text" DEFAULT NULL::"text", "p_milestones" "jsonb" DEFAULT '[]'::"jsonb", "p_deadline_urgency" "text" DEFAULT NULL::"text", "p_payment_status" "text" DEFAULT 'paid'::"text", "p_payment_model" "text" DEFAULT NULL::"text", "p_currency" "text" DEFAULT 'IQD'::"text", "p_bonus_incentives" "text" DEFAULT NULL::"text", "p_budget_min" numeric DEFAULT NULL::numeric, "p_budget_max" numeric DEFAULT NULL::numeric) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_profile_id uuid;
  v_project_id uuid;
begin
  v_profile_id := public.app_current_profile_id();

  if v_profile_id is null then
    raise exception 'profile_not_found';
  end if;

  if not public.app_can_post_projects(v_profile_id) then
    raise exception 'project_posting_not_allowed';
  end if;

  insert into public.projects (
    profile_id,
    title,
    description,
    governorate,
    budget_min,
    budget_max,
    status
  )
  values (
    v_profile_id,
    p_title,
    p_description,
    p_governorate::governorate,
    p_budget_min,
    p_budget_max,
    'planning'
  )
  returning id into v_project_id;

  insert into public.project_details (
    project_id,
    tagline,
    category,
    project_type,
    work_mode,
    stage,
    problem,
    goals,
    target_users,
    existing_assets,
    required_skills,
    preferred_skills,
    tools_equipment,
    seniority_level,
    years_experience,
    certifications,
    engineers_needed,
    roles_needed,
    responsibilities,
    current_team_size,
    collaboration_tools,
    estimated_duration,
    weekly_commitment,
    milestones,
    deadline_urgency,
    payment_status,
    payment_model,
    currency,
    bonus_incentives
  )
  values (
    v_project_id,
    p_tagline,
    p_category,
    p_project_type,
    p_work_mode,
    p_stage,
    p_problem,
    p_goals,
    p_target_users,
    coalesce(p_existing_assets, '{}'),
    coalesce(p_required_skills, '{}'),
    coalesce(p_preferred_skills, '{}'),
    coalesce(p_tools_equipment, '{}'),
    p_seniority_level,
    p_years_experience,
    coalesce(p_certifications, '{}'),
    greatest(coalesce(p_engineers_needed, 1), 1),
    coalesce(p_roles_needed, '{}'),
    coalesce(p_responsibilities, '{}'::jsonb),
    p_current_team_size,
    coalesce(p_collaboration_tools, '{}'),
    p_estimated_duration,
    p_weekly_commitment,
    coalesce(p_milestones, '[]'::jsonb),
    p_deadline_urgency,
    p_payment_status,
    p_payment_model,
    coalesce(nullif(p_currency, ''), 'IQD'),
    p_bonus_incentives
  );

  update public.profiles
  set projects_count = coalesce(projects_count, 0) + 1,
      updated_at = now()
  where id = v_profile_id;

  return v_project_id;
end;
$$;


ALTER FUNCTION "public"."create_project_for_app"("p_title" "text", "p_description" "text", "p_governorate" "text", "p_tagline" "text", "p_category" "text", "p_project_type" "text", "p_work_mode" "text", "p_stage" "text", "p_problem" "text", "p_goals" "text", "p_target_users" "text", "p_existing_assets" "text"[], "p_required_skills" "text"[], "p_preferred_skills" "text"[], "p_tools_equipment" "text"[], "p_seniority_level" "text", "p_years_experience" integer, "p_certifications" "text"[], "p_engineers_needed" integer, "p_roles_needed" "text"[], "p_responsibilities" "jsonb", "p_current_team_size" "text", "p_collaboration_tools" "text"[], "p_estimated_duration" "text", "p_weekly_commitment" "text", "p_milestones" "jsonb", "p_deadline_urgency" "text", "p_payment_status" "text", "p_payment_model" "text", "p_currency" "text", "p_bonus_incentives" "text", "p_budget_min" numeric, "p_budget_max" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_current_user_for_app"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $_$
declare
  v_user_id uuid;
  v_profile_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = v_user_id
  limit 1;

  if v_profile_id is not null then
    if to_regclass('public.messages') is not null then
      execute 'delete from public.messages where sender_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.conversations') is not null then
      execute 'delete from public.conversations where participant_one = $1 or participant_two = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.notifications') is not null then
      execute 'delete from public.notifications where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.saved_items') is not null then
      execute 'delete from public.saved_items where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.project_applications') is not null then
      if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'project_applications'
          and column_name = 'reviewed_by'
      ) then
        execute 'delete from public.project_applications where profile_id = $1 or reviewed_by = $1'
          using v_profile_id;
      else
        execute 'delete from public.project_applications where profile_id = $1'
          using v_profile_id;
      end if;
    end if;

    if to_regclass('public.app_comments') is not null then
      execute 'delete from public.app_comments where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.app_reposts') is not null then
      execute 'delete from public.app_reposts where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.followers') is not null then
      execute 'delete from public.followers where follower_id = $1 or following_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.connection_requests') is not null then
      execute 'delete from public.connection_requests where requester_profile_id = $1 or receiver_profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.blocked_profiles') is not null then
      execute 'delete from public.blocked_profiles where blocker_profile_id = $1 or blocked_profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.stories') is not null then
      execute 'delete from public.stories where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.reels') is not null then
      execute 'delete from public.reels where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.posts') is not null then
      execute 'delete from public.posts where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.project_details') is not null
      and to_regclass('public.projects') is not null then
      execute 'delete from public.project_details where project_id in (select id from public.projects where profile_id = $1)'
        using v_profile_id;
    end if;

    if to_regclass('public.projects') is not null then
      execute 'delete from public.projects where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.engineer_details') is not null then
      execute 'delete from public.engineer_details where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.contractor_details') is not null then
      execute 'delete from public.contractor_details where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.craftsman_details') is not null then
      execute 'delete from public.craftsman_details where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.machinery_details') is not null then
      execute 'delete from public.machinery_details where profile_id = $1'
        using v_profile_id;
    end if;

    if to_regclass('public.subscriptions') is not null then
      execute 'delete from public.subscriptions where profile_id = $1'
        using v_profile_id;
    end if;

    delete from public.profiles
    where id = v_profile_id;
  end if;

  delete from public.profiles
  where user_id = v_user_id;

  delete from auth.users
  where id = v_user_id;
end;
$_$;


ALTER FUNCTION "public"."delete_current_user_for_app"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_admin_chat_monitor"("p_limit" integer DEFAULT 20) RETURNS TABLE("id" "uuid", "updated_at" timestamp with time zone, "participant_one_name" "text", "participant_one_avatar" "text", "participant_two_name" "text", "participant_two_avatar" "text", "last_message_content" "text", "last_message_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.updated_at,
        p1.full_name as participant_one_name,
        p1.avatar_url as participant_one_avatar,
        p2.full_name as participant_two_name,
        p2.avatar_url as participant_two_avatar,
        m.content as last_message_content,
        m.created_at as last_message_at
    FROM conversations c
    LEFT JOIN profiles p1 ON c.participant_one = p1.id
    LEFT JOIN profiles p2 ON c.participant_two = p2.id
    LEFT JOIN LATERAL (
        SELECT content, created_at 
        FROM messages 
        WHERE conversation_id = c.id 
        ORDER BY created_at DESC 
        LIMIT 1
    ) m ON true
    ORDER BY c.updated_at DESC
    LIMIT p_limit;
END;
$$;


ALTER FUNCTION "public"."get_admin_chat_monitor"("p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_admin_system_stats"() RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    result json;
    db_size_bytes bigint;
    table_count int;
    monthly_registrations json;
    monthly_revenue json;
BEGIN
    -- 1. Get DB Size
    SELECT pg_database_size(current_database()) INTO db_size_bytes;
    
    -- 2. Get Table Count
    SELECT count(*)::int INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public';
    
    -- 3. Get Monthly Registrations (Last 6 Months, Zero-padded)
    SELECT json_agg(t) INTO monthly_registrations
    FROM (
        SELECT 
            to_char(m, 'Mon') as month,
            COALESCE(count(p.id), 0)::int as count,
            m as month_date
        FROM generate_series(
            date_trunc('month', now()) - interval '5 months',
            date_trunc('month', now()),
            interval '1 month'
        ) m
        LEFT JOIN profiles p ON date_trunc('month', p.created_at) = m
        GROUP BY m
        ORDER BY m ASC
    ) t;

    -- 4. Get Monthly Revenue (Last 6 Months, Zero-padded)
    SELECT json_agg(r) INTO monthly_revenue
    FROM (
        SELECT 
            to_char(m, 'Mon') as month,
            COALESCE(SUM(
                CASE 
                    WHEN s.plan_type = 'basic' THEN 29
                    WHEN s.plan_type = 'professional' THEN 99
                    WHEN s.plan_type = 'diamond' THEN 299
                    ELSE 0 
                END
            ), 0)::int as revenue,
            m as month_date
        FROM generate_series(
            date_trunc('month', now()) - interval '5 months',
            date_trunc('month', now()),
            interval '1 month'
        ) m
        LEFT JOIN subscriptions s ON date_trunc('month', s.created_at) = m
        GROUP BY m
        ORDER BY m ASC
    ) r;

    result := json_build_object(
        'db_size_bytes', db_size_bytes,
        'table_count', table_count,
        'registrations', COALESCE(monthly_registrations, '[]'::json),
        'revenue', COALESCE(monthly_revenue, '[]'::json)
    );
    
    RETURN result;
END;
$$;


ALTER FUNCTION "public"."get_admin_system_stats"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_admin_user_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT id FROM public.admin_users 
  WHERE email = (SELECT email FROM auth.users WHERE id = auth.uid())
  AND status = 'active'
  LIMIT 1
$$;


ALTER FUNCTION "public"."get_admin_user_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_conversation_participant_phone"("p_conversation_id" "uuid", "p_participant_id" "uuid") RETURNS "text"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_phone text;
  v_current_user_id uuid;
BEGIN
  -- Get the current user's profile id
  SELECT id INTO v_current_user_id 
  FROM profiles 
  WHERE user_id = auth.uid();
  
  -- Check if current user is a participant in this conversation
  IF NOT EXISTS (
    SELECT 1 FROM conversations 
    WHERE id = p_conversation_id 
    AND (participant_one = v_current_user_id OR participant_two = v_current_user_id)
  ) THEN
    RETURN NULL; -- Not authorized
  END IF;
  
  -- Check if requested participant is in the same conversation
  IF NOT EXISTS (
    SELECT 1 FROM conversations 
    WHERE id = p_conversation_id 
    AND (participant_one = p_participant_id OR participant_two = p_participant_id)
  ) THEN
    RETURN NULL; -- Not authorized
  END IF;
  
  -- Get the phone number
  SELECT phone INTO v_phone
  FROM profiles
  WHERE id = p_participant_id;
  
  RETURN v_phone;
END;
$$;


ALTER FUNCTION "public"."get_conversation_participant_phone"("p_conversation_id" "uuid", "p_participant_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_home_feed"("p_profile_id" "uuid", "p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0) RETURNS TABLE("post_id" "uuid", "content" "text", "image_url" "text", "post_type" "text", "likes_count" integer, "comments_count" integer, "created_at" timestamp with time zone, "profile_id" "uuid", "full_name" "text", "username" "text", "avatar_url" "text", "role" "public"."user_role", "is_verified" boolean, "is_liked" boolean)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as post_id,
    p.content,
    p.image_url,
    p.post_type,
    p.likes_count,
    p.comments_count,
    p.created_at,
    pr.id as profile_id,
    pr.full_name,
    pr.username,
    pr.avatar_url,
    pr.role,
    pr.is_verified,
    EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = p.id AND pl.profile_id = p_profile_id) as is_liked
  FROM posts p
  JOIN profiles pr ON pr.id = p.profile_id
  LEFT JOIN blocked_users bu ON (bu.blocker_id = p_profile_id AND bu.blocked_id = p.profile_id)
    OR (bu.blocker_id = p.profile_id AND bu.blocked_id = p_profile_id)
  WHERE p.is_active = true 
    AND (p.is_archived = false OR p.is_archived IS NULL)
    AND bu.id IS NULL
  ORDER BY p.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


ALTER FUNCTION "public"."get_home_feed"("p_profile_id" "uuid", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_network_profiles_for_app"("p_audience" "text" DEFAULT 'people'::"text", "p_limit" integer DEFAULT 40) RETURNS TABLE("id" "uuid", "full_name" "text", "username" "text", "role" "text", "governorate" "text", "bio" "text", "experience_years" integer, "projects_count" integer, "followers_count" integer, "avatar_url" "text", "is_verified" boolean)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_profile_id uuid;
  v_viewer_role public.user_role;
begin
  v_profile_id := public.app_current_profile_id();

  select p.role
  into v_viewer_role
  from public.profiles p
  where p.id = v_profile_id
  limit 1;

  if v_profile_id is null or v_viewer_role is null then
    return;
  end if;

  if v_viewer_role not in ('engineer'::public.user_role, 'contractor'::public.user_role, 'client'::public.user_role, 'admin'::public.user_role) then
    return;
  end if;

  return query
  select
    p.id,
    p.full_name,
    p.username,
    p.role::text,
    p.governorate::text,
    p.bio,
    p.experience_years,
    p.projects_count,
    p.followers_count,
    p.avatar_url,
    p.is_verified
  from public.profiles p
  where p.id <> v_profile_id
    and not exists (
      select 1
      from public.connection_requests cr
      where cr.status = 'accepted'
        and (
          (cr.requester_profile_id = v_profile_id and cr.receiver_profile_id = p.id)
          or (cr.requester_profile_id = p.id and cr.receiver_profile_id = v_profile_id)
        )
    )
    and (
      v_viewer_role = 'admin'::public.user_role
      or (
        p_audience = 'companies'
        and v_viewer_role in ('engineer'::public.user_role, 'contractor'::public.user_role, 'client'::public.user_role)
        and p.role in ('contractor'::public.user_role, 'client'::public.user_role)
      )
      or (
        p_audience <> 'companies'
        and v_viewer_role = 'engineer'::public.user_role
        and p.role in (
          'engineer'::public.user_role,
          'craftsman'::public.user_role,
          'worker'::public.user_role,
          'machinery'::public.user_role
        )
      )
      or (
        p_audience <> 'companies'
        and v_viewer_role in ('contractor'::public.user_role, 'client'::public.user_role)
        and p.role = 'engineer'::public.user_role
      )
    )
  order by p.is_verified desc, p.projects_count desc, p.created_at desc
  limit least(greatest(coalesce(p_limit, 40), 1), 100);
end;
$$;


ALTER FUNCTION "public"."get_network_profiles_for_app"("p_audience" "text", "p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_profile_for_user"("p_profile_id" "uuid") RETURNS TABLE("id" "uuid", "user_id" "uuid", "full_name" "text", "username" "text", "avatar_url" "text", "bio" "text", "role" "public"."user_role", "governorate" "public"."governorate", "experience_years" integer, "rating" numeric, "total_reviews" integer, "is_verified" boolean, "followers_count" integer, "following_count" integer, "posts_count" integer, "projects_count" integer, "facebook_url" "text", "instagram_url" "text", "cover_photo_url" "text", "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "phone" "text")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.user_id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.bio,
    p.role,
    p.governorate,
    p.experience_years,
    p.rating,
    p.total_reviews,
    p.is_verified,
    p.followers_count,
    p.following_count,
    p.posts_count,
    p.projects_count,
    p.facebook_url,
    p.instagram_url,
    p.cover_photo_url,
    p.created_at,
    p.updated_at,
    CASE 
      WHEN p.user_id = auth.uid() THEN p.phone
      ELSE NULL::text
    END as phone
  FROM profiles p
  WHERE p.id = p_profile_id;
END;
$$;


ALTER FUNCTION "public"."get_profile_for_user"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_projects_for_app"("p_limit" integer DEFAULT 50) RETURNS TABLE("id" "uuid", "title" "text", "description" "text", "governorate" "text", "budget_min" numeric, "budget_max" numeric, "status" "text", "start_date" timestamp with time zone, "end_date" timestamp with time zone, "image_url" "text", "profile_id" "uuid", "created_at" timestamp with time zone, "project_details" "jsonb", "profiles" "jsonb")
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    p.id,
    p.title,
    p.description,
    p.governorate::text,
    p.budget_min,
    p.budget_max,
    p.status,
    p.start_date,
    p.end_date,
    p.image_url,
    p.profile_id,
    p.created_at,
    to_jsonb(pd.*) as project_details,
    jsonb_build_object(
      'id', pr.id,
      'full_name', pr.full_name,
      'username', pr.username,
      'role', pr.role,
      'avatar_url', pr.avatar_url,
      'is_verified', pr.is_verified
    ) as profiles
  from public.projects p
  left join public.project_details pd on pd.project_id = p.id
  left join public.profiles pr on pr.id = p.profile_id
  order by p.created_at desc
  limit least(greatest(p_limit, 1), 100)
$$;


ALTER FUNCTION "public"."get_projects_for_app"("p_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_public_engineer_details"("p_profile_id" "uuid") RETURNS TABLE("profile_id" "uuid", "specialization" "text", "company_name" "text")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ed.profile_id,
    ed.specialization::text,
    ed.company_name
  FROM public.engineer_details ed
  WHERE ed.profile_id = p_profile_id;
END;
$$;


ALTER FUNCTION "public"."get_public_engineer_details"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_public_profile"("p_profile_id" "uuid") RETURNS TABLE("id" "uuid", "full_name" "text", "username" "text", "avatar_url" "text", "bio" "text", "role" "public"."user_role", "governorate" "public"."governorate", "experience_years" integer, "rating" numeric, "total_reviews" integer, "is_verified" boolean, "followers_count" integer, "following_count" integer, "posts_count" integer, "projects_count" integer, "facebook_url" "text", "instagram_url" "text", "cover_photo_url" "text", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.bio,
    p.role,
    p.governorate,
    p.experience_years,
    p.rating,
    p.total_reviews,
    p.is_verified,
    p.followers_count,
    p.following_count,
    p.posts_count,
    p.projects_count,
    p.facebook_url,
    p.instagram_url,
    p.cover_photo_url,
    p.created_at
  FROM profiles p
  WHERE p.id = p_profile_id;
END;
$$;


ALTER FUNCTION "public"."get_public_profile"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_public_profile_with_details"("p_profile_id" "uuid") RETURNS TABLE("id" "uuid", "user_id" "uuid", "full_name" "text", "username" "text", "avatar_url" "text", "bio" "text", "role" "public"."user_role", "governorate" "public"."governorate", "experience_years" integer, "rating" numeric, "total_reviews" integer, "is_verified" boolean, "followers_count" integer, "following_count" integer, "posts_count" integer, "projects_count" integer, "facebook_url" "text", "instagram_url" "text", "cover_photo_url" "text", "created_at" timestamp with time zone, "specialization" "text", "company_name" "text")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.user_id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.bio,
    p.role,
    p.governorate,
    p.experience_years,
    p.rating,
    p.total_reviews,
    p.is_verified,
    p.followers_count,
    p.following_count,
    p.posts_count,
    p.projects_count,
    p.facebook_url,
    p.instagram_url,
    p.cover_photo_url,
    p.created_at,
    CASE 
      WHEN p.role = 'engineer' THEN (SELECT ed.specialization::text FROM engineer_details ed WHERE ed.profile_id = p.id)
      WHEN p.role = 'craftsman' THEN (SELECT cd.specialization::text FROM craftsman_details cd WHERE cd.profile_id = p.id)
      WHEN p.role = 'machinery' THEN (SELECT md.specialization::text FROM machinery_details md WHERE md.profile_id = p.id)
      ELSE NULL
    END as specialization,
    CASE 
      WHEN p.role = 'engineer' THEN (SELECT ed.company_name FROM engineer_details ed WHERE ed.profile_id = p.id)
      WHEN p.role = 'contractor' THEN (SELECT cd.company_name FROM contractor_details cd WHERE cd.profile_id = p.id)
      ELSE NULL
    END as company_name
  FROM profiles p
  WHERE p.id = p_profile_id;
END;
$$;


ALTER FUNCTION "public"."get_public_profile_with_details"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_public_profiles"("p_profile_ids" "uuid"[]) RETURNS TABLE("id" "uuid", "full_name" "text", "username" "text", "avatar_url" "text", "role" "public"."user_role", "is_verified" boolean)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.role,
    p.is_verified
  FROM profiles p
  WHERE p.id = ANY(p_profile_ids);
END;
$$;


ALTER FUNCTION "public"."get_public_profiles"("p_profile_ids" "uuid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_safe_profile"("p_profile_id" "uuid") RETURNS TABLE("id" "uuid", "user_id" "uuid", "full_name" "text", "username" "text", "avatar_url" "text", "bio" "text", "role" "public"."user_role", "governorate" "public"."governorate", "experience_years" integer, "rating" numeric, "total_reviews" integer, "is_verified" boolean, "followers_count" integer, "following_count" integer, "posts_count" integer, "projects_count" integer, "facebook_url" "text", "instagram_url" "text", "cover_photo_url" "text", "created_at" timestamp with time zone, "updated_at" timestamp with time zone, "phone" "text")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.user_id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.bio,
    p.role,
    p.governorate,
    p.experience_years,
    p.rating,
    p.total_reviews,
    p.is_verified,
    p.followers_count,
    p.following_count,
    p.posts_count,
    p.projects_count,
    p.facebook_url,
    p.instagram_url,
    p.cover_photo_url,
    p.created_at,
    p.updated_at,
    CASE 
      WHEN p.user_id = auth.uid() THEN p.phone
      ELSE NULL
    END as phone
  FROM profiles p
  WHERE p.id = p_profile_id;
END;
$$;


ALTER FUNCTION "public"."get_safe_profile"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_storage_overview"() RETURNS TABLE("bucket_name" "text", "total_files" bigint, "total_size" bigint, "formatted_size" "text", "unique_users" bigint)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- Only allow admins
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT 
    su.bucket_name,
    COUNT(*)::bigint as total_files,
    COALESCE(SUM(su.file_size), 0)::bigint as total_size,
    CASE 
      WHEN COALESCE(SUM(su.file_size), 0) >= 1073741824 THEN 
        ROUND(COALESCE(SUM(su.file_size), 0)::numeric / 1073741824, 2)::text || ' GB'
      WHEN COALESCE(SUM(su.file_size), 0) >= 1048576 THEN 
        ROUND(COALESCE(SUM(su.file_size), 0)::numeric / 1048576, 2)::text || ' MB'
      ELSE 
        ROUND(COALESCE(SUM(su.file_size), 0)::numeric / 1024, 2)::text || ' KB'
    END as formatted_size,
    COUNT(DISTINCT su.profile_id)::bigint as unique_users
  FROM storage_usage su
  GROUP BY su.bucket_name
  ORDER BY total_size DESC;
END;
$$;


ALTER FUNCTION "public"."get_storage_overview"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_suspicious_users"("min_attempts" integer DEFAULT 5, "time_window" interval DEFAULT '24:00:00'::interval) RETURNS TABLE("profile_id" "uuid", "full_name" "text", "attempt_count" bigint, "last_attempt" timestamp with time zone, "attempt_types" "text"[])
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT 
    ca.profile_id,
    p.full_name,
    COUNT(*) as attempt_count,
    MAX(ca.created_at) as last_attempt,
    ARRAY_AGG(DISTINCT ca.attempt_type) as attempt_types
  FROM capture_attempts ca
  JOIN profiles p ON p.id = ca.profile_id
  WHERE ca.created_at > NOW() - time_window
  GROUP BY ca.profile_id, p.full_name
  HAVING COUNT(*) >= min_attempts
  ORDER BY attempt_count DESC
$$;


ALTER FUNCTION "public"."get_suspicious_users"("min_attempts" integer, "time_window" interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_unread_messages_count"("p_profile_id" "uuid") RETURNS bigint
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT COALESCE(SUM(sub.cnt), 0)::bigint
  FROM (
    SELECT COUNT(*) as cnt
    FROM messages m
    JOIN conversations c ON c.id = m.conversation_id
    WHERE m.is_read = false
      AND m.sender_id != p_profile_id
      AND (c.participant_one = p_profile_id OR c.participant_two = p_profile_id)
  ) sub;
$$;


ALTER FUNCTION "public"."get_unread_messages_count"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_conversations"("p_profile_id" "uuid") RETURNS TABLE("conversation_id" "uuid", "recipient_profile_id" "uuid", "recipient_name" "text", "recipient_avatar_url" "text", "last_message" "text", "last_message_at" timestamp with time zone, "unread_count" bigint)
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    c.id as conversation_id,
    other_profile.id as recipient_profile_id,
    other_profile.full_name as recipient_name,
    other_profile.avatar_url as recipient_avatar_url,
    coalesce(c.last_message, '') as last_message,
    c.last_message_at,
    count(m.id) filter (
      where m.sender_id <> p_profile_id
        and coalesce(m.read_at is null, true)
        and coalesce(m.is_read, false) = false
    ) as unread_count
  from public.conversations c
  join public.profiles other_profile
    on other_profile.id = case
      when c.participant_one = p_profile_id then c.participant_two
      else c.participant_one
    end
  left join public.messages m
    on m.conversation_id = c.id
  where p_profile_id in (c.participant_one, c.participant_two)
  group by c.id, other_profile.id, other_profile.full_name, other_profile.avatar_url, c.last_message, c.last_message_at
  order by c.last_message_at desc nulls last, c.created_at desc
  limit 50
$$;


ALTER FUNCTION "public"."get_user_conversations"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_storage_stats"("p_profile_id" "uuid") RETURNS TABLE("bucket_name" "text", "file_count" bigint, "total_size" bigint, "formatted_size" "text")
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    su.bucket_name,
    COUNT(*)::bigint as file_count,
    COALESCE(SUM(su.file_size), 0)::bigint as total_size,
    CASE 
      WHEN COALESCE(SUM(su.file_size), 0) >= 1073741824 THEN 
        ROUND(COALESCE(SUM(su.file_size), 0)::numeric / 1073741824, 2)::text || ' GB'
      WHEN COALESCE(SUM(su.file_size), 0) >= 1048576 THEN 
        ROUND(COALESCE(SUM(su.file_size), 0)::numeric / 1048576, 2)::text || ' MB'
      WHEN COALESCE(SUM(su.file_size), 0) >= 1024 THEN 
        ROUND(COALESCE(SUM(su.file_size), 0)::numeric / 1024, 2)::text || ' KB'
      ELSE 
        COALESCE(SUM(su.file_size), 0)::text || ' B'
    END as formatted_size
  FROM storage_usage su
  WHERE su.profile_id = p_profile_id
  GROUP BY su.bucket_name
  ORDER BY total_size DESC;
END;
$$;


ALTER FUNCTION "public"."get_user_storage_stats"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_auth_user_for_app"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_profile_id uuid;
begin
  select p.id
  into v_profile_id
  from public.profiles p
  where p.user_id = new.id
  order by p.created_at desc nulls last, p.id
  limit 1;

  if v_profile_id is null then
    insert into public.profiles (
      user_id,
      full_name,
      email,
      phone,
      role,
      governorate,
      bio
    )
    values (
      new.id,
      coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        split_part(coalesce(new.email, ''), '@', 1),
        'User'
      ),
      nullif(trim(coalesce(new.email, new.raw_user_meta_data->>'email', '')), ''),
      nullif(trim(coalesce(new.raw_user_meta_data->>'phone', '')), ''),
      public.app_safe_user_role(new.raw_user_meta_data->>'role'),
      public.app_safe_governorate(new.raw_user_meta_data->>'governorate'),
      nullif(trim(coalesce(new.raw_user_meta_data->>'bio', '')), '')
    );
  else
    update public.profiles
    set
      full_name = coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        split_part(coalesce(new.email, ''), '@', 1),
        full_name
      ),
      email = coalesce(nullif(trim(coalesce(new.email, new.raw_user_meta_data->>'email', '')), ''), email),
      phone = coalesce(nullif(trim(coalesce(new.raw_user_meta_data->>'phone', '')), ''), phone),
      role = public.app_safe_user_role(coalesce(new.raw_user_meta_data->>'role', role::text)),
      governorate = public.app_safe_governorate(coalesce(new.raw_user_meta_data->>'governorate', governorate::text)),
      bio = coalesce(nullif(trim(coalesce(new.raw_user_meta_data->>'bio', '')), ''), bio),
      updated_at = now()
    where id = v_profile_id;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_auth_user_for_app"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into public.profiles (
    user_id,
    email,
    full_name,
    role,
    governorate
  )
  values (
    new.id,
    nullif(trim(coalesce(new.email, new.raw_user_meta_data->>'email', '')), ''),
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
      split_part(coalesce(new.email, ''), '@', 1),
      'User'
    ),
    public.app_safe_user_role(new.raw_user_meta_data->>'role'),
    public.app_safe_governorate(new.raw_user_meta_data->>'governorate')
  )
  on conflict (user_id)
  do update set
    email = coalesce(excluded.email, public.profiles.email),
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    role = coalesce(public.profiles.role, excluded.role),
    governorate = coalesce(public.profiles.governorate, excluded.governorate),
    updated_at = now();

  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_active_subscription"("p_profile_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.subscriptions
    WHERE profile_id = p_profile_id
      AND status = 'active'
      AND (expires_at IS NULL OR expires_at > now())
  )
$$;


ALTER FUNCTION "public"."has_active_subscription"("p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  UPDATE reels SET views_count = views_count + 1 WHERE id = p_reel_id;
END;
$$;


ALTER FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid", "p_viewer_profile_id" "uuid" DEFAULT NULL::"uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- If viewer_profile_id is provided, track unique view
  IF p_viewer_profile_id IS NOT NULL THEN
    -- Insert view if not exists (unique per user)
    INSERT INTO reel_views (reel_id, viewer_profile_id)
    VALUES (p_reel_id, p_viewer_profile_id)
    ON CONFLICT (reel_id, viewer_profile_id) DO NOTHING;
    
    -- Only increment if this was a new view
    IF FOUND THEN
      UPDATE reels SET views_count = views_count + 1 WHERE id = p_reel_id;
    END IF;
  ELSE
    -- For anonymous users, just increment (backwards compatibility)
    UPDATE reels SET views_count = views_count + 1 WHERE id = p_reel_id;
  END IF;
END;
$$;


ALTER FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid", "p_viewer_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_story_view"("p_story_id" "uuid", "p_viewer_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- Insert view if not exists
  INSERT INTO story_views (story_id, viewer_profile_id)
  VALUES (p_story_id, p_viewer_profile_id)
  ON CONFLICT (story_id, viewer_profile_id) DO NOTHING;
  
  -- Update view count
  UPDATE stories SET views_count = views_count + 1 WHERE id = p_story_id;
END;
$$;


ALTER FUNCTION "public"."increment_story_view"("p_story_id" "uuid", "p_viewer_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT public.get_admin_user_id() IS NOT NULL
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_blocked"("checker_id" "uuid", "target_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM blocked_users
    WHERE (blocker_id = checker_id AND blocked_id = target_id)
       OR (blocker_id = target_id AND blocked_id = checker_id)
  )
$$;


ALTER FUNCTION "public"."is_blocked"("checker_id" "uuid", "target_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_own_profile"("profile_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT auth.uid() IS NOT NULL AND auth.uid() = profile_user_id
$$;


ALTER FUNCTION "public"."is_own_profile"("profile_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_profile_owner"("profile_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  SELECT auth.uid() = profile_user_id
$$;


ALTER FUNCTION "public"."is_profile_owner"("profile_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_super_admin"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE id = auth.uid() AND role = 'super_admin'
  );
END;
$$;


ALTER FUNCTION "public"."is_super_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text" DEFAULT 'system'::"text", "p_entity_id" "text" DEFAULT NULL::"text", "p_old" "jsonb" DEFAULT NULL::"jsonb", "p_new" "jsonb" DEFAULT NULL::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.admin_audit_log (
    admin_id,
    action,
    entity,
    entity_id,
    old_data,
    new_data,
    created_at
  ) VALUES (
    auth.uid(),
    p_action,
    p_entity,
    p_entity_id,
    p_old,
    p_new,
    now()
  );
EXCEPTION WHEN OTHERS THEN
  -- Silently ignore if log table doesn't exist or any insert error
  -- Never block the main operation due to audit failures
  RAISE WARNING 'log_admin_action failed: %', SQLERRM;
END;
$$;


ALTER FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text", "p_entity_id" "text", "p_old" "jsonb", "p_new" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text", "p_entity_id" "uuid" DEFAULT NULL::"uuid", "p_old_values" "jsonb" DEFAULT NULL::"jsonb", "p_new_values" "jsonb" DEFAULT NULL::"jsonb", "p_metadata" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_admin_user_id uuid;
  v_admin_email text;
  v_log_id uuid;
BEGIN
  v_admin_user_id := public.get_admin_user_id();
  
  SELECT email INTO v_admin_email 
  FROM public.admin_users 
  WHERE id = v_admin_user_id;
  
  INSERT INTO public.admin_audit_logs (
    actor_user_id,
    actor_email,
    action,
    entity,
    entity_id,
    old_values,
    new_values,
    metadata
  ) VALUES (
    v_admin_user_id,
    v_admin_email,
    p_action,
    p_entity,
    p_entity_id,
    p_old_values,
    p_new_values,
    p_metadata
  )
  RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$;


ALTER FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text", "p_entity_id" "uuid", "p_old_values" "jsonb", "p_new_values" "jsonb", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_messages_read"("p_conversation_id" "uuid", "p_reader_profile_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  UPDATE messages 
  SET is_read = true 
  WHERE conversation_id = p_conversation_id 
    AND sender_id != p_reader_profile_id 
    AND is_read = false;
END;
$$;


ALTER FUNCTION "public"."mark_messages_read"("p_conversation_id" "uuid", "p_reader_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_admins_on_report"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  admin_user RECORD;
  reporter_name text;
BEGIN
  -- Get reporter name
  SELECT full_name INTO reporter_name
  FROM profiles
  WHERE id = NEW.reporter_id;
  
  -- Insert notification for all active admins
  FOR admin_user IN 
    SELECT au.id, au.email 
    FROM admin_users au
    WHERE au.status = 'active'
  LOOP
    INSERT INTO admin_notifications (
      title,
      title_ar,
      body,
      body_ar,
      target_type,
      target_value,
      created_by
    ) VALUES (
      'New User Report',
      'بلاغ جديد',
      'A new report has been submitted by ' || COALESCE(reporter_name, 'Unknown') || '. Reason: ' || COALESCE(NEW.reason, 'Not specified'),
      'تم تقديم بلاغ جديد من ' || COALESCE(reporter_name, 'مستخدم') || '. السبب: ' || COALESCE(NEW.reason, 'غير محدد'),
      'role',
      'super_admin',
      NULL
    );
  END LOOP;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_admins_on_report"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_craftsman_on_contact"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  sender_profile RECORD;
  recipient_profile RECORD;
  recipient_id uuid;
  notification_title text;
  notification_message text;
BEGIN
  -- Get sender profile
  SELECT * INTO sender_profile FROM profiles WHERE id = NEW.sender_id;
  
  -- Determine recipient (the other participant in the conversation)
  SELECT 
    CASE 
      WHEN c.participant_one = NEW.sender_id THEN c.participant_two
      ELSE c.participant_one
    END INTO recipient_id
  FROM conversations c
  WHERE c.id = NEW.conversation_id;
  
  -- Get recipient profile
  SELECT * INTO recipient_profile FROM profiles WHERE id = recipient_id;
  
  -- Check if sender is engineer or contractor and recipient is craftsman or machinery
  IF sender_profile.role IN ('engineer', 'contractor') 
     AND recipient_profile.role IN ('craftsman', 'machinery', 'worker') THEN
    
    -- Set notification title and message based on sender role
    IF sender_profile.role = 'engineer' THEN
      notification_title := 'تواصل جديد من مهندس';
      notification_message := 'قام المهندس ' || sender_profile.full_name || ' بإرسال رسالة لك';
    ELSE
      notification_title := 'تواصل جديد من شركة';
      notification_message := 'قامت الشركة ' || sender_profile.full_name || ' بإرسال رسالة لك';
    END IF;
    
    -- Create notification for the craftsman/machinery
    INSERT INTO notifications (profile_id, title, message, type, action_url)
    VALUES (
      recipient_id,
      notification_title,
      notification_message,
      'message',
      '/messages'
    );
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_craftsman_on_contact"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_on_follow"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  follower_name text;
BEGIN
  -- Get the follower's name
  SELECT full_name INTO follower_name
  FROM profiles
  WHERE id = NEW.follower_id;
  
  -- Create notification for the followed user
  INSERT INTO notifications (profile_id, title, message, type, action_url)
  VALUES (
    NEW.following_id,
    'متابع جديد',
    follower_name || ' بدأ بمتابعتك',
    'follow',
    '/followers'
  );
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_on_follow"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."request_connection_for_app"("p_receiver_profile_id" "uuid", "p_message" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_profile_id uuid;
  v_request_id uuid;
  v_status text;
begin
  v_profile_id := public.app_current_profile_id();

  if v_profile_id is null then
    raise exception 'profile_not_found';
  end if;

  if p_receiver_profile_id is null or p_receiver_profile_id = v_profile_id then
    raise exception 'invalid_receiver';
  end if;

  select id, status
  into v_request_id, v_status
  from public.connection_requests
  where (
      requester_profile_id = v_profile_id
      and receiver_profile_id = p_receiver_profile_id
    )
    or (
      requester_profile_id = p_receiver_profile_id
      and receiver_profile_id = v_profile_id
    )
  order by
    case status when 'accepted' then 0 when 'pending' then 1 else 2 end,
    updated_at desc nulls last,
    created_at desc nulls last
  limit 1;

  if v_status in ('pending', 'accepted') then
    return v_request_id;
  end if;

  if v_request_id is not null then
    update public.connection_requests
    set requester_profile_id = v_profile_id,
        receiver_profile_id = p_receiver_profile_id,
        status = 'pending',
        message = p_message,
        responded_at = null,
        updated_at = now()
    where id = v_request_id
    returning id into v_request_id;
  else
    insert into public.connection_requests (
      requester_profile_id,
      receiver_profile_id,
      message
    )
    values (v_profile_id, p_receiver_profile_id, p_message)
    returning id into v_request_id;
  end if;

  return v_request_id;
end;
$$;


ALTER FUNCTION "public"."request_connection_for_app"("p_receiver_profile_id" "uuid", "p_message" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."save_item_for_app"("p_item_type" "text", "p_item_id" "text", "p_title" "text", "p_subtitle" "text" DEFAULT NULL::"text", "p_detail" "text" DEFAULT NULL::"text", "p_metadata" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_profile_id uuid;
  v_saved_id uuid;
begin
  v_profile_id := public.app_current_profile_id();

  if v_profile_id is null then
    raise exception 'profile_not_found';
  end if;

  insert into public.saved_items (
    profile_id,
    item_type,
    item_id,
    title,
    subtitle,
    detail,
    metadata
  )
  values (
    v_profile_id,
    p_item_type,
    p_item_id,
    p_title,
    p_subtitle,
    p_detail,
    coalesce(p_metadata, '{}'::jsonb)
  )
  on conflict (profile_id, item_type, item_id)
  do update set
    title = excluded.title,
    subtitle = excluded.subtitle,
    detail = excluded.detail,
    metadata = excluded.metadata,
    created_at = now()
  returning id into v_saved_id;

  return v_saved_id;
end;
$$;


ALTER FUNCTION "public"."save_item_for_app"("p_item_type" "text", "p_item_id" "text", "p_title" "text", "p_subtitle" "text", "p_detail" "text", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."search_profiles_safe"("p_search_term" "text" DEFAULT NULL::"text", "p_role" "public"."user_role" DEFAULT NULL::"public"."user_role", "p_governorate" "public"."governorate" DEFAULT NULL::"public"."governorate", "p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0) RETURNS TABLE("id" "uuid", "full_name" "text", "username" "text", "avatar_url" "text", "bio" "text", "role" "public"."user_role", "governorate" "public"."governorate", "experience_years" integer, "rating" numeric, "total_reviews" integer, "is_verified" boolean, "followers_count" integer, "following_count" integer)
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  search_pattern text;
BEGIN
  -- Escape special LIKE characters to prevent injection
  IF p_search_term IS NOT NULL AND length(trim(p_search_term)) > 0 THEN
    -- Escape backslash first, then %, then _
    search_pattern := '%' || replace(replace(replace(trim(p_search_term), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  END IF;
  
  -- Limit search term length to prevent DoS
  IF p_search_term IS NOT NULL AND length(p_search_term) > 100 THEN
    RAISE EXCEPTION 'Search term too long';
  END IF;
  
  -- Limit maximum results to prevent excessive data retrieval
  IF p_limit > 100 THEN
    p_limit := 100;
  END IF;
  
  RETURN QUERY
  SELECT 
    p.id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.bio,
    p.role,
    p.governorate,
    p.experience_years,
    p.rating,
    p.total_reviews,
    p.is_verified,
    p.followers_count,
    p.following_count
  FROM profiles p
  WHERE 
    (search_pattern IS NULL OR p.full_name ILIKE search_pattern OR p.username ILIKE search_pattern)
    AND (p_role IS NULL OR p.role = p_role)
    AND (p_governorate IS NULL OR p.governorate = p_governorate)
  ORDER BY p.rating DESC NULLS LAST, p.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


ALTER FUNCTION "public"."search_profiles_safe"("p_search_term" "text", "p_role" "public"."user_role", "p_governorate" "public"."governorate", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_profile_email"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE profiles
  SET email = NEW.email
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_profile_email"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_user_email"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE profiles
  SET email = NEW.email
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."sync_user_email"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."toggle_story_like"("p_story_id" "uuid", "p_profile_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_liked boolean;
BEGIN
  -- Check if already liked
  IF EXISTS (SELECT 1 FROM story_likes WHERE story_id = p_story_id AND profile_id = p_profile_id) THEN
    -- Unlike
    DELETE FROM story_likes WHERE story_id = p_story_id AND profile_id = p_profile_id;
    UPDATE stories SET likes_count = likes_count - 1 WHERE id = p_story_id;
    v_liked := false;
  ELSE
    -- Like
    INSERT INTO story_likes (story_id, profile_id) VALUES (p_story_id, p_profile_id);
    UPDATE stories SET likes_count = likes_count + 1 WHERE id = p_story_id;
    v_liked := true;
  END IF;
  
  RETURN v_liked;
END;
$$;


ALTER FUNCTION "public"."toggle_story_like"("p_story_id" "uuid", "p_profile_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_follower_counts"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  -- Validate that the operation is triggered by a valid follower action
  IF TG_OP = 'INSERT' THEN
    -- Only update if follower_id exists in profiles
    IF EXISTS (SELECT 1 FROM profiles WHERE id = NEW.follower_id) AND 
       EXISTS (SELECT 1 FROM profiles WHERE id = NEW.following_id) THEN
      UPDATE profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
      UPDATE profiles SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF EXISTS (SELECT 1 FROM profiles WHERE id = OLD.follower_id) AND 
       EXISTS (SELECT 1 FROM profiles WHERE id = OLD.following_id) THEN
      UPDATE profiles SET following_count = GREATEST(0, following_count - 1) WHERE id = OLD.follower_id;
      UPDATE profiles SET followers_count = GREATEST(0, followers_count - 1) WHERE id = OLD.following_id;
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_follower_counts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_post_comments_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET comments_count = GREATEST(0, comments_count - 1) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_post_comments_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_post_likes_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_post_likes_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_reel_comments_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE reels SET comments_count = comments_count + 1 WHERE id = NEW.reel_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE reels SET comments_count = comments_count - 1 WHERE id = OLD.reel_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_reel_comments_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_reel_likes_count"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE reels SET likes_count = likes_count + 1 WHERE id = NEW.reel_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE reels SET likes_count = likes_count - 1 WHERE id = OLD.reel_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_reel_likes_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."verify_otp_token"("p_phone_local10" "text", "p_verification_token" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_token_valid boolean := false;
BEGIN
  -- Check if verification token matches (in a real implementation, 
  -- this would check a token store with expiration)
  -- For now, we just validate the format and return true
  -- The actual token validation happens in the edge function
  IF p_verification_token IS NOT NULL AND p_phone_local10 IS NOT NULL THEN
    v_token_valid := true;
  END IF;
  
  RETURN v_token_valid;
END;
$$;


ALTER FUNCTION "public"."verify_otp_token"("p_phone_local10" "text", "p_verification_token" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "storage"."allow_any_operation"("expected_operations" "text"[]) RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT CASE
      WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
      ELSE raw_operation
    END AS current_operation
    FROM current_operation
  )
  SELECT EXISTS (
    SELECT 1
    FROM normalized n
    CROSS JOIN LATERAL unnest(expected_operations) AS expected_operation
    WHERE expected_operation IS NOT NULL
      AND expected_operation <> ''
      AND n.current_operation = CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END
  );
$$;


ALTER FUNCTION "storage"."allow_any_operation"("expected_operations" "text"[]) OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."allow_only_operation"("expected_operation" "text") RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT
      CASE
        WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
        ELSE raw_operation
      END AS current_operation,
      CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END AS requested_operation
    FROM current_operation
  )
  SELECT CASE
    WHEN requested_operation IS NULL OR requested_operation = '' THEN FALSE
    ELSE COALESCE(current_operation = requested_operation, FALSE)
  END
  FROM normalized;
$$;


ALTER FUNCTION "storage"."allow_only_operation"("expected_operation" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."can_insert_object"("bucketid" "text", "name" "text", "owner" "uuid", "metadata" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


ALTER FUNCTION "storage"."can_insert_object"("bucketid" "text", "name" "text", "owner" "uuid", "metadata" "jsonb") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."enforce_bucket_name_length"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


ALTER FUNCTION "storage"."enforce_bucket_name_length"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."extension"("name" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Get the last path segment (the actual filename)
    SELECT _parts[array_length(_parts, 1)] INTO _filename;
    -- Extract extension: reverse, split on '.', then reverse again
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


ALTER FUNCTION "storage"."extension"("name" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."filename"("name" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


ALTER FUNCTION "storage"."filename"("name" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."foldername"("name" "text") RETURNS "text"[]
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


ALTER FUNCTION "storage"."foldername"("name" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."get_common_prefix"("p_key" "text", "p_prefix" "text", "p_delimiter" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


ALTER FUNCTION "storage"."get_common_prefix"("p_key" "text", "p_prefix" "text", "p_delimiter" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."get_size_by_bucket"() RETURNS TABLE("size" bigint, "bucket_id" "text")
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::bigint)::bigint as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


ALTER FUNCTION "storage"."get_size_by_bucket"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."list_multipart_uploads_with_delimiter"("bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer DEFAULT 100, "next_key_token" "text" DEFAULT ''::"text", "next_upload_token" "text" DEFAULT ''::"text") RETURNS TABLE("key" "text", "id" "text", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


ALTER FUNCTION "storage"."list_multipart_uploads_with_delimiter"("bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer, "next_key_token" "text", "next_upload_token" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."list_objects_with_delimiter"("_bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer DEFAULT 100, "start_after" "text" DEFAULT ''::"text", "next_token" "text" DEFAULT ''::"text", "sort_order" "text" DEFAULT 'asc'::"text") RETURNS TABLE("name" "text", "id" "uuid", "metadata" "jsonb", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION "storage"."list_objects_with_delimiter"("_bucket_id" "text", "prefix_param" "text", "delimiter_param" "text", "max_keys" integer, "start_after" "text", "next_token" "text", "sort_order" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."operation"() RETURNS "text"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


ALTER FUNCTION "storage"."operation"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."protect_delete"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION "storage"."protect_delete"() OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."search"("prefix" "text", "bucketname" "text", "limits" integer DEFAULT 100, "levels" integer DEFAULT 1, "offsets" integer DEFAULT 0, "search" "text" DEFAULT ''::"text", "sortcolumn" "text" DEFAULT 'name'::"text", "sortorder" "text" DEFAULT 'asc'::"text") RETURNS TABLE("name" "text", "id" "uuid", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


ALTER FUNCTION "storage"."search"("prefix" "text", "bucketname" "text", "limits" integer, "levels" integer, "offsets" integer, "search" "text", "sortcolumn" "text", "sortorder" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."search_by_timestamp"("p_prefix" "text", "p_bucket_id" "text", "p_limit" integer, "p_level" integer, "p_start_after" "text", "p_sort_order" "text", "p_sort_column" "text", "p_sort_column_after" "text") RETURNS TABLE("key" "text", "name" "text", "id" "uuid", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


ALTER FUNCTION "storage"."search_by_timestamp"("p_prefix" "text", "p_bucket_id" "text", "p_limit" integer, "p_level" integer, "p_start_after" "text", "p_sort_order" "text", "p_sort_column" "text", "p_sort_column_after" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."search_v2"("prefix" "text", "bucket_name" "text", "limits" integer DEFAULT 100, "levels" integer DEFAULT 1, "start_after" "text" DEFAULT ''::"text", "sort_order" "text" DEFAULT 'asc'::"text", "sort_column" "text" DEFAULT 'name'::"text", "sort_column_after" "text" DEFAULT ''::"text") RETURNS TABLE("key" "text", "name" "text", "id" "uuid", "updated_at" timestamp with time zone, "created_at" timestamp with time zone, "last_accessed_at" timestamp with time zone, "metadata" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


ALTER FUNCTION "storage"."search_v2"("prefix" "text", "bucket_name" "text", "limits" integer, "levels" integer, "start_after" "text", "sort_order" "text", "sort_column" "text", "sort_column_after" "text") OWNER TO "supabase_storage_admin";


CREATE OR REPLACE FUNCTION "storage"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


ALTER FUNCTION "storage"."update_updated_at_column"() OWNER TO "supabase_storage_admin";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "auth"."audit_log_entries" (
    "instance_id" "uuid",
    "id" "uuid" NOT NULL,
    "payload" json,
    "created_at" timestamp with time zone,
    "ip_address" character varying(64) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE "auth"."audit_log_entries" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."audit_log_entries" IS 'Auth: Audit trail for user actions.';



CREATE TABLE IF NOT EXISTS "auth"."custom_oauth_providers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "provider_type" "text" NOT NULL,
    "identifier" "text" NOT NULL,
    "name" "text" NOT NULL,
    "client_id" "text" NOT NULL,
    "client_secret" "text" NOT NULL,
    "acceptable_client_ids" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "scopes" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "pkce_enabled" boolean DEFAULT true NOT NULL,
    "attribute_mapping" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "authorization_params" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "enabled" boolean DEFAULT true NOT NULL,
    "email_optional" boolean DEFAULT false NOT NULL,
    "issuer" "text",
    "discovery_url" "text",
    "skip_nonce_check" boolean DEFAULT false NOT NULL,
    "cached_discovery" "jsonb",
    "discovery_cached_at" timestamp with time zone,
    "authorization_url" "text",
    "token_url" "text",
    "userinfo_url" "text",
    "jwks_uri" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "custom_oauth_providers_authorization_url_https" CHECK ((("authorization_url" IS NULL) OR ("authorization_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_authorization_url_length" CHECK ((("authorization_url" IS NULL) OR ("char_length"("authorization_url") <= 2048))),
    CONSTRAINT "custom_oauth_providers_client_id_length" CHECK ((("char_length"("client_id") >= 1) AND ("char_length"("client_id") <= 512))),
    CONSTRAINT "custom_oauth_providers_discovery_url_length" CHECK ((("discovery_url" IS NULL) OR ("char_length"("discovery_url") <= 2048))),
    CONSTRAINT "custom_oauth_providers_identifier_format" CHECK (("identifier" ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::"text")),
    CONSTRAINT "custom_oauth_providers_issuer_length" CHECK ((("issuer" IS NULL) OR (("char_length"("issuer") >= 1) AND ("char_length"("issuer") <= 2048)))),
    CONSTRAINT "custom_oauth_providers_jwks_uri_https" CHECK ((("jwks_uri" IS NULL) OR ("jwks_uri" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_jwks_uri_length" CHECK ((("jwks_uri" IS NULL) OR ("char_length"("jwks_uri") <= 2048))),
    CONSTRAINT "custom_oauth_providers_name_length" CHECK ((("char_length"("name") >= 1) AND ("char_length"("name") <= 100))),
    CONSTRAINT "custom_oauth_providers_oauth2_requires_endpoints" CHECK ((("provider_type" <> 'oauth2'::"text") OR (("authorization_url" IS NOT NULL) AND ("token_url" IS NOT NULL) AND ("userinfo_url" IS NOT NULL)))),
    CONSTRAINT "custom_oauth_providers_oidc_discovery_url_https" CHECK ((("provider_type" <> 'oidc'::"text") OR ("discovery_url" IS NULL) OR ("discovery_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_oidc_issuer_https" CHECK ((("provider_type" <> 'oidc'::"text") OR ("issuer" IS NULL) OR ("issuer" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_oidc_requires_issuer" CHECK ((("provider_type" <> 'oidc'::"text") OR ("issuer" IS NOT NULL))),
    CONSTRAINT "custom_oauth_providers_provider_type_check" CHECK (("provider_type" = ANY (ARRAY['oauth2'::"text", 'oidc'::"text"]))),
    CONSTRAINT "custom_oauth_providers_token_url_https" CHECK ((("token_url" IS NULL) OR ("token_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_token_url_length" CHECK ((("token_url" IS NULL) OR ("char_length"("token_url") <= 2048))),
    CONSTRAINT "custom_oauth_providers_userinfo_url_https" CHECK ((("userinfo_url" IS NULL) OR ("userinfo_url" ~~ 'https://%'::"text"))),
    CONSTRAINT "custom_oauth_providers_userinfo_url_length" CHECK ((("userinfo_url" IS NULL) OR ("char_length"("userinfo_url") <= 2048)))
);


ALTER TABLE "auth"."custom_oauth_providers" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."flow_state" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid",
    "auth_code" "text",
    "code_challenge_method" "auth"."code_challenge_method",
    "code_challenge" "text",
    "provider_type" "text" NOT NULL,
    "provider_access_token" "text",
    "provider_refresh_token" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "authentication_method" "text" NOT NULL,
    "auth_code_issued_at" timestamp with time zone,
    "invite_token" "text",
    "referrer" "text",
    "oauth_client_state_id" "uuid",
    "linking_target_id" "uuid",
    "email_optional" boolean DEFAULT false NOT NULL
);


ALTER TABLE "auth"."flow_state" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."flow_state" IS 'Stores metadata for all OAuth/SSO login flows';



CREATE TABLE IF NOT EXISTS "auth"."identities" (
    "provider_id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "identity_data" "jsonb" NOT NULL,
    "provider" "text" NOT NULL,
    "last_sign_in_at" timestamp with time zone,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "email" "text" GENERATED ALWAYS AS ("lower"(("identity_data" ->> 'email'::"text"))) STORED,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL
);


ALTER TABLE "auth"."identities" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."identities" IS 'Auth: Stores identities associated to a user.';



COMMENT ON COLUMN "auth"."identities"."email" IS 'Auth: Email is a generated column that references the optional email property in the identity_data';



CREATE TABLE IF NOT EXISTS "auth"."instances" (
    "id" "uuid" NOT NULL,
    "uuid" "uuid",
    "raw_base_config" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);


ALTER TABLE "auth"."instances" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."instances" IS 'Auth: Manages users across multiple sites.';



CREATE TABLE IF NOT EXISTS "auth"."mfa_amr_claims" (
    "session_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "authentication_method" "text" NOT NULL,
    "id" "uuid" NOT NULL
);


ALTER TABLE "auth"."mfa_amr_claims" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."mfa_amr_claims" IS 'auth: stores authenticator method reference claims for multi factor authentication';



CREATE TABLE IF NOT EXISTS "auth"."mfa_challenges" (
    "id" "uuid" NOT NULL,
    "factor_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "verified_at" timestamp with time zone,
    "ip_address" "inet" NOT NULL,
    "otp_code" "text",
    "web_authn_session_data" "jsonb"
);


ALTER TABLE "auth"."mfa_challenges" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."mfa_challenges" IS 'auth: stores metadata about challenge requests made';



CREATE TABLE IF NOT EXISTS "auth"."mfa_factors" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "friendly_name" "text",
    "factor_type" "auth"."factor_type" NOT NULL,
    "status" "auth"."factor_status" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "secret" "text",
    "phone" "text",
    "last_challenged_at" timestamp with time zone,
    "web_authn_credential" "jsonb",
    "web_authn_aaguid" "uuid",
    "last_webauthn_challenge_data" "jsonb"
);


ALTER TABLE "auth"."mfa_factors" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."mfa_factors" IS 'auth: stores metadata about factors';



COMMENT ON COLUMN "auth"."mfa_factors"."last_webauthn_challenge_data" IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';



CREATE TABLE IF NOT EXISTS "auth"."oauth_authorizations" (
    "id" "uuid" NOT NULL,
    "authorization_id" "text" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "redirect_uri" "text" NOT NULL,
    "scope" "text" NOT NULL,
    "state" "text",
    "resource" "text",
    "code_challenge" "text",
    "code_challenge_method" "auth"."code_challenge_method",
    "response_type" "auth"."oauth_response_type" DEFAULT 'code'::"auth"."oauth_response_type" NOT NULL,
    "status" "auth"."oauth_authorization_status" DEFAULT 'pending'::"auth"."oauth_authorization_status" NOT NULL,
    "authorization_code" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '00:03:00'::interval) NOT NULL,
    "approved_at" timestamp with time zone,
    "nonce" "text",
    CONSTRAINT "oauth_authorizations_authorization_code_length" CHECK (("char_length"("authorization_code") <= 255)),
    CONSTRAINT "oauth_authorizations_code_challenge_length" CHECK (("char_length"("code_challenge") <= 128)),
    CONSTRAINT "oauth_authorizations_expires_at_future" CHECK (("expires_at" > "created_at")),
    CONSTRAINT "oauth_authorizations_nonce_length" CHECK (("char_length"("nonce") <= 255)),
    CONSTRAINT "oauth_authorizations_redirect_uri_length" CHECK (("char_length"("redirect_uri") <= 2048)),
    CONSTRAINT "oauth_authorizations_resource_length" CHECK (("char_length"("resource") <= 2048)),
    CONSTRAINT "oauth_authorizations_scope_length" CHECK (("char_length"("scope") <= 4096)),
    CONSTRAINT "oauth_authorizations_state_length" CHECK (("char_length"("state") <= 4096))
);


ALTER TABLE "auth"."oauth_authorizations" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."oauth_client_states" (
    "id" "uuid" NOT NULL,
    "provider_type" "text" NOT NULL,
    "code_verifier" "text",
    "created_at" timestamp with time zone NOT NULL
);


ALTER TABLE "auth"."oauth_client_states" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."oauth_client_states" IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';



CREATE TABLE IF NOT EXISTS "auth"."oauth_clients" (
    "id" "uuid" NOT NULL,
    "client_secret_hash" "text",
    "registration_type" "auth"."oauth_registration_type" NOT NULL,
    "redirect_uris" "text" NOT NULL,
    "grant_types" "text" NOT NULL,
    "client_name" "text",
    "client_uri" "text",
    "logo_uri" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "client_type" "auth"."oauth_client_type" DEFAULT 'confidential'::"auth"."oauth_client_type" NOT NULL,
    "token_endpoint_auth_method" "text" NOT NULL,
    CONSTRAINT "oauth_clients_client_name_length" CHECK (("char_length"("client_name") <= 1024)),
    CONSTRAINT "oauth_clients_client_uri_length" CHECK (("char_length"("client_uri") <= 2048)),
    CONSTRAINT "oauth_clients_logo_uri_length" CHECK (("char_length"("logo_uri") <= 2048)),
    CONSTRAINT "oauth_clients_token_endpoint_auth_method_check" CHECK (("token_endpoint_auth_method" = ANY (ARRAY['client_secret_basic'::"text", 'client_secret_post'::"text", 'none'::"text"])))
);


ALTER TABLE "auth"."oauth_clients" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."oauth_consents" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "client_id" "uuid" NOT NULL,
    "scopes" "text" NOT NULL,
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "revoked_at" timestamp with time zone,
    CONSTRAINT "oauth_consents_revoked_after_granted" CHECK ((("revoked_at" IS NULL) OR ("revoked_at" >= "granted_at"))),
    CONSTRAINT "oauth_consents_scopes_length" CHECK (("char_length"("scopes") <= 2048)),
    CONSTRAINT "oauth_consents_scopes_not_empty" CHECK (("char_length"(TRIM(BOTH FROM "scopes")) > 0))
);


ALTER TABLE "auth"."oauth_consents" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."one_time_tokens" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token_type" "auth"."one_time_token_type" NOT NULL,
    "token_hash" "text" NOT NULL,
    "relates_to" "text" NOT NULL,
    "created_at" timestamp without time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp without time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "one_time_tokens_token_hash_check" CHECK (("char_length"("token_hash") > 0))
);


ALTER TABLE "auth"."one_time_tokens" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."refresh_tokens" (
    "instance_id" "uuid",
    "id" bigint NOT NULL,
    "token" character varying(255),
    "user_id" character varying(255),
    "revoked" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "parent" character varying(255),
    "session_id" "uuid"
);


ALTER TABLE "auth"."refresh_tokens" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."refresh_tokens" IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';



CREATE SEQUENCE IF NOT EXISTS "auth"."refresh_tokens_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "auth"."refresh_tokens_id_seq" OWNER TO "supabase_auth_admin";


ALTER SEQUENCE "auth"."refresh_tokens_id_seq" OWNED BY "auth"."refresh_tokens"."id";



CREATE TABLE IF NOT EXISTS "auth"."saml_providers" (
    "id" "uuid" NOT NULL,
    "sso_provider_id" "uuid" NOT NULL,
    "entity_id" "text" NOT NULL,
    "metadata_xml" "text" NOT NULL,
    "metadata_url" "text",
    "attribute_mapping" "jsonb",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "name_id_format" "text",
    CONSTRAINT "entity_id not empty" CHECK (("char_length"("entity_id") > 0)),
    CONSTRAINT "metadata_url not empty" CHECK ((("metadata_url" = NULL::"text") OR ("char_length"("metadata_url") > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK (("char_length"("metadata_xml") > 0))
);


ALTER TABLE "auth"."saml_providers" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."saml_providers" IS 'Auth: Manages SAML Identity Provider connections.';



CREATE TABLE IF NOT EXISTS "auth"."saml_relay_states" (
    "id" "uuid" NOT NULL,
    "sso_provider_id" "uuid" NOT NULL,
    "request_id" "text" NOT NULL,
    "for_email" "text",
    "redirect_to" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "flow_state_id" "uuid",
    CONSTRAINT "request_id not empty" CHECK (("char_length"("request_id") > 0))
);


ALTER TABLE "auth"."saml_relay_states" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."saml_relay_states" IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';



CREATE TABLE IF NOT EXISTS "auth"."schema_migrations" (
    "version" character varying(255) NOT NULL
);


ALTER TABLE "auth"."schema_migrations" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."schema_migrations" IS 'Auth: Manages updates to the auth system.';



CREATE TABLE IF NOT EXISTS "auth"."sessions" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "factor_id" "uuid",
    "aal" "auth"."aal_level",
    "not_after" timestamp with time zone,
    "refreshed_at" timestamp without time zone,
    "user_agent" "text",
    "ip" "inet",
    "tag" "text",
    "oauth_client_id" "uuid",
    "refresh_token_hmac_key" "text",
    "refresh_token_counter" bigint,
    "scopes" "text",
    CONSTRAINT "sessions_scopes_length" CHECK (("char_length"("scopes") <= 4096))
);


ALTER TABLE "auth"."sessions" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."sessions" IS 'Auth: Stores session data associated to a user.';



COMMENT ON COLUMN "auth"."sessions"."not_after" IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';



COMMENT ON COLUMN "auth"."sessions"."refresh_token_hmac_key" IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';



COMMENT ON COLUMN "auth"."sessions"."refresh_token_counter" IS 'Holds the ID (counter) of the last issued refresh token.';



CREATE TABLE IF NOT EXISTS "auth"."sso_domains" (
    "id" "uuid" NOT NULL,
    "sso_provider_id" "uuid" NOT NULL,
    "domain" "text" NOT NULL,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK (("char_length"("domain") > 0))
);


ALTER TABLE "auth"."sso_domains" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."sso_domains" IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';



CREATE TABLE IF NOT EXISTS "auth"."sso_providers" (
    "id" "uuid" NOT NULL,
    "resource_id" "text",
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "disabled" boolean,
    CONSTRAINT "resource_id not empty" CHECK ((("resource_id" = NULL::"text") OR ("char_length"("resource_id") > 0)))
);


ALTER TABLE "auth"."sso_providers" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."sso_providers" IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';



COMMENT ON COLUMN "auth"."sso_providers"."resource_id" IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';



CREATE TABLE IF NOT EXISTS "auth"."users" (
    "instance_id" "uuid",
    "id" "uuid" NOT NULL,
    "aud" character varying(255),
    "role" character varying(255),
    "email" character varying(255),
    "encrypted_password" character varying(255),
    "email_confirmed_at" timestamp with time zone,
    "invited_at" timestamp with time zone,
    "confirmation_token" character varying(255),
    "confirmation_sent_at" timestamp with time zone,
    "recovery_token" character varying(255),
    "recovery_sent_at" timestamp with time zone,
    "email_change_token_new" character varying(255),
    "email_change" character varying(255),
    "email_change_sent_at" timestamp with time zone,
    "last_sign_in_at" timestamp with time zone,
    "raw_app_meta_data" "jsonb",
    "raw_user_meta_data" "jsonb",
    "is_super_admin" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "phone" "text" DEFAULT NULL::character varying,
    "phone_confirmed_at" timestamp with time zone,
    "phone_change" "text" DEFAULT ''::character varying,
    "phone_change_token" character varying(255) DEFAULT ''::character varying,
    "phone_change_sent_at" timestamp with time zone,
    "confirmed_at" timestamp with time zone GENERATED ALWAYS AS (LEAST("email_confirmed_at", "phone_confirmed_at")) STORED,
    "email_change_token_current" character varying(255) DEFAULT ''::character varying,
    "email_change_confirm_status" smallint DEFAULT 0,
    "banned_until" timestamp with time zone,
    "reauthentication_token" character varying(255) DEFAULT ''::character varying,
    "reauthentication_sent_at" timestamp with time zone,
    "is_sso_user" boolean DEFAULT false NOT NULL,
    "deleted_at" timestamp with time zone,
    "is_anonymous" boolean DEFAULT false NOT NULL,
    CONSTRAINT "users_email_change_confirm_status_check" CHECK ((("email_change_confirm_status" >= 0) AND ("email_change_confirm_status" <= 2)))
);


ALTER TABLE "auth"."users" OWNER TO "supabase_auth_admin";


COMMENT ON TABLE "auth"."users" IS 'Auth: Stores user login data within a secure schema.';



COMMENT ON COLUMN "auth"."users"."is_sso_user" IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';



CREATE TABLE IF NOT EXISTS "auth"."webauthn_challenges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "challenge_type" "text" NOT NULL,
    "session_data" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    CONSTRAINT "webauthn_challenges_challenge_type_check" CHECK (("challenge_type" = ANY (ARRAY['signup'::"text", 'registration'::"text", 'authentication'::"text"])))
);


ALTER TABLE "auth"."webauthn_challenges" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "auth"."webauthn_credentials" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "credential_id" "bytea" NOT NULL,
    "public_key" "bytea" NOT NULL,
    "attestation_type" "text" DEFAULT ''::"text" NOT NULL,
    "aaguid" "uuid",
    "sign_count" bigint DEFAULT 0 NOT NULL,
    "transports" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "backup_eligible" boolean DEFAULT false NOT NULL,
    "backed_up" boolean DEFAULT false NOT NULL,
    "friendly_name" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_used_at" timestamp with time zone
);


ALTER TABLE "auth"."webauthn_credentials" OWNER TO "supabase_auth_admin";


CREATE TABLE IF NOT EXISTS "public"."admin_audit_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "admin_id" "uuid",
    "action" "text" NOT NULL,
    "entity" "text" DEFAULT 'system'::"text" NOT NULL,
    "entity_id" "text",
    "old_data" "jsonb",
    "new_data" "jsonb",
    "ip_address" "text",
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."admin_audit_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_audit_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "actor_user_id" "uuid",
    "actor_email" "text",
    "action" "text" NOT NULL,
    "entity" "text" NOT NULL,
    "entity_id" "uuid",
    "old_values" "jsonb",
    "new_values" "jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "ip_address" "text",
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_checklist" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "label_ar" "text" NOT NULL,
    "label_en" "text" NOT NULL,
    "category" "text" NOT NULL,
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."admin_checklist" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_courses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "department_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "name_ar" "text",
    "slug" "text" NOT NULL,
    "description" "text",
    "description_ar" "text",
    "thumbnail_url" "text",
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_courses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_departments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "name_ar" "text",
    "slug" "text" NOT NULL,
    "description" "text",
    "description_ar" "text",
    "icon" "text",
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "bg_color" "text" DEFAULT 'bg-slate-700'::"text",
    "tile_type" "text" DEFAULT 'learning'::"text",
    "icon_type" "text" DEFAULT 'emoji'::"text",
    "lucide_icon" "text"
);


ALTER TABLE "public"."admin_departments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_faq" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "question_ar" "text" NOT NULL,
    "question_en" "text" NOT NULL,
    "answer_ar" "text" NOT NULL,
    "answer_en" "text" NOT NULL,
    "category" "text" NOT NULL,
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."admin_faq" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_lecture_assets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "lecture_id" "uuid" NOT NULL,
    "type" "public"."asset_type" DEFAULT 'other'::"public"."asset_type" NOT NULL,
    "file_name" "text" NOT NULL,
    "storage_path" "text" NOT NULL,
    "file_size" bigint,
    "mime_type" "text",
    "is_primary" boolean DEFAULT false,
    "sort_order" integer DEFAULT 0,
    "version" integer DEFAULT 1,
    "uploaded_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_lecture_assets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_lectures" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "course_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "title_ar" "text",
    "description" "text",
    "description_ar" "text",
    "status" "public"."lecture_status" DEFAULT 'draft'::"public"."lecture_status" NOT NULL,
    "sort_order" integer DEFAULT 0,
    "duration_minutes" integer,
    "instructor_id" "uuid",
    "published_at" timestamp with time zone,
    "scheduled_publish_at" timestamp with time zone,
    "version" integer DEFAULT 1,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_lectures" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_legal_sections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "title_ar" "text" NOT NULL,
    "title_en" "text" NOT NULL,
    "content_ar" "text",
    "content_en" "text",
    "icon" "text",
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."admin_legal_sections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_notification_reads" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "notification_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "read_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_notification_reads" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "title_ar" "text",
    "body" "text" NOT NULL,
    "body_ar" "text",
    "target_type" "public"."notification_target_type" DEFAULT 'all'::"public"."notification_target_type" NOT NULL,
    "target_value" "text",
    "is_active" boolean DEFAULT true,
    "scheduled_at" timestamp with time zone,
    "sent_at" timestamp with time zone,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_permissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "display_name_ar" "text",
    "description" "text",
    "description_ar" "text",
    "category" "text" DEFAULT 'general'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_role_permissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role_id" "uuid" NOT NULL,
    "permission_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_role_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "public"."admin_role" NOT NULL,
    "display_name" "text" NOT NULL,
    "display_name_ar" "text",
    "description" "text",
    "description_ar" "text",
    "is_system" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" "text" NOT NULL,
    "value_json" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "category" "text" DEFAULT 'general'::"text" NOT NULL,
    "is_sensitive" boolean DEFAULT false,
    "description" "text",
    "description_ar" "text",
    "updated_by" "uuid",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_support_tickets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "subject" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'open'::"text",
    "priority" "text" DEFAULT 'normal'::"text",
    "category" "text",
    "assigned_to" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "admin_support_tickets_priority_check" CHECK (("priority" = ANY (ARRAY['low'::"text", 'normal'::"text", 'high'::"text", 'urgent'::"text"]))),
    CONSTRAINT "admin_support_tickets_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'in_progress'::"text", 'resolved'::"text", 'closed'::"text"])))
);


ALTER TABLE "public"."admin_support_tickets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_user_roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role_id" "uuid" NOT NULL,
    "assigned_by" "uuid",
    "assigned_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_user_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."admin_users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "full_name" "text" NOT NULL,
    "full_name_ar" "text",
    "avatar_url" "text",
    "phone" "text",
    "status" "public"."admin_status" DEFAULT 'pending'::"public"."admin_status" NOT NULL,
    "mfa_enabled" boolean DEFAULT false,
    "last_login_at" timestamp with time zone,
    "login_count" integer DEFAULT 0,
    "failed_login_attempts" integer DEFAULT 0,
    "locked_until" timestamp with time zone,
    "session_expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "role" "text" DEFAULT 'admin_users'::"text"
);


ALTER TABLE "public"."admin_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ai_conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "title" "text" DEFAULT 'محادثة جديدة'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."ai_conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ai_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "conversation_id" "uuid",
    CONSTRAINT "ai_messages_content_length_check" CHECK ((("length"("content") >= 1) AND ("length"("content") <= 50000))),
    CONSTRAINT "ai_messages_role_check" CHECK (("role" = ANY (ARRAY['user'::"text", 'assistant'::"text", 'system'::"text"])))
);


ALTER TABLE "public"."ai_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "text" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "app_comments_target_type_check" CHECK (("target_type" = ANY (ARRAY['post'::"text", 'reel'::"text", 'project'::"text"])))
);


ALTER TABLE "public"."app_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_config" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" "text" NOT NULL,
    "value" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."app_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_reposts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "text" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "app_reposts_target_type_check" CHECK (("target_type" = ANY (ARRAY['post'::"text", 'reel'::"text"])))
);


ALTER TABLE "public"."app_reposts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."automation_rules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text",
    "condition" "jsonb",
    "action" "jsonb",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."automation_rules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."badge_requests" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "reason" "text",
    CONSTRAINT "badge_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."badge_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."blocked_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "blocker_profile_id" "uuid" NOT NULL,
    "blocked_profile_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "blocked_profiles_check" CHECK (("blocker_profile_id" <> "blocked_profile_id"))
);


ALTER TABLE "public"."blocked_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."blocked_users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "blocker_id" "uuid" NOT NULL,
    "blocked_id" "uuid" NOT NULL,
    "blocked_at" timestamp with time zone DEFAULT "now"(),
    "reason" "text"
);


ALTER TABLE "public"."blocked_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."capture_attempts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "attempt_type" "text" NOT NULL,
    "attempt_reason" "text",
    "device_info" "jsonb" DEFAULT '{}'::"jsonb",
    "ip_address" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."capture_attempts" OWNER TO "postgres";


COMMENT ON TABLE "public"."capture_attempts" IS 'Logs suspicious capture attempts (screenshots, screen recording, etc.) for security monitoring';



CREATE TABLE IF NOT EXISTS "public"."comment_likes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "comment_type" "text" NOT NULL,
    "comment_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "comment_likes_comment_type_check" CHECK (("comment_type" = ANY (ARRAY['post'::"text", 'reel'::"text", 'story'::"text"])))
);


ALTER TABLE "public"."comment_likes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."connection_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "requester_profile_id" "uuid" NOT NULL,
    "receiver_profile_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "message" "text",
    "responded_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "connection_requests_check" CHECK (("requester_profile_id" <> "receiver_profile_id")),
    CONSTRAINT "connection_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'rejected'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."connection_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."contractor_details" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "status" "public"."contractor_status" DEFAULT 'available'::"public"."contractor_status",
    "company_name" "text",
    "employees_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."contractor_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "participant_one" "uuid" NOT NULL,
    "participant_two" "uuid" NOT NULL,
    "last_message" "text" DEFAULT ''::"text",
    "last_message_at" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."course_progress" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "course_id" "uuid" NOT NULL,
    "is_completed" boolean DEFAULT false NOT NULL,
    "progress_percentage" integer DEFAULT 0 NOT NULL,
    "last_watched_at" timestamp with time zone DEFAULT "now"(),
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."course_progress" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."courses" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title_en" "text" NOT NULL,
    "title_ar" "text" NOT NULL,
    "description_en" "text",
    "description_ar" "text",
    "category" "public"."course_category" NOT NULL,
    "video_url" "text" NOT NULL,
    "thumbnail_url" "text",
    "duration_minutes" integer DEFAULT 0 NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."courses" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."craftsman_details" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "specialization" "public"."craftsman_specialization" NOT NULL,
    "hourly_rate" numeric(10,2),
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."craftsman_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."device_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token" "text" NOT NULL,
    "platform" "text" DEFAULT 'web'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."device_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."engineer_details" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "specialization" "public"."engineer_specialization" NOT NULL,
    "license_number" "text",
    "company_name" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."engineer_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."engineer_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."engineer_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."followers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "follower_id" "uuid" NOT NULL,
    "following_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "followers_check" CHECK (("follower_id" <> "following_id"))
);


ALTER TABLE "public"."followers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."job_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "governorate" "public"."governorate" NOT NULL,
    "budget_min" numeric(12,2),
    "budget_max" numeric(12,2),
    "required_role" "public"."user_role",
    "required_specialization" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "expires_at" timestamp with time zone
);


ALTER TABLE "public"."job_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."machinery_details" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "specialization" "public"."machinery_specialization" NOT NULL,
    "machinery_name" "text",
    "machinery_model" "text",
    "hourly_rate" numeric,
    "daily_rate" numeric,
    "is_available" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."machinery_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "message_type" "text" DEFAULT 'text'::"text" NOT NULL,
    "image_url" "text",
    "is_read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "audio_url" "text",
    "audio_duration" integer,
    "read_at" timestamp with time zone,
    CONSTRAINT "messages_message_type_check" CHECK (("message_type" = ANY (ARRAY['text'::"text", 'voice'::"text", 'file'::"text", 'image'::"text", 'video'::"text"])))
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."muted_conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "muted_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."muted_conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "type" "text" DEFAULT 'general'::"text" NOT NULL,
    "is_read" boolean DEFAULT false NOT NULL,
    "action_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."otp_verifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "phone_local10" character varying(10) NOT NULL,
    "code" character varying(6) NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "attempts" integer DEFAULT 0 NOT NULL,
    "verified" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE ONLY "public"."otp_verifications" FORCE ROW LEVEL SECURITY;


ALTER TABLE "public"."otp_verifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payment_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "subscription_id" "uuid",
    "amount" numeric DEFAULT 120000 NOT NULL,
    "currency" "text" DEFAULT 'IQD'::"text" NOT NULL,
    "payment_method" "text" DEFAULT 'simulation'::"text" NOT NULL,
    "status" "text" DEFAULT 'completed'::"text" NOT NULL,
    "transaction_id" "text",
    "paid_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "period_start" timestamp with time zone DEFAULT "now"() NOT NULL,
    "period_end" timestamp with time zone DEFAULT ("now"() + '1 year'::interval) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."payment_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."permissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "likes_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "post_comments_content_length_check" CHECK ((("length"("content") >= 1) AND ("length"("content") <= 5000)))
);


ALTER TABLE "public"."post_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_likes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."post_likes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."post_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "post_id" "uuid" NOT NULL,
    "reporter_id" "uuid" NOT NULL,
    "reason" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "admin_notes" "text",
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "post_reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewed'::"text", 'resolved'::"text", 'dismissed'::"text"])))
);


ALTER TABLE "public"."post_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."posts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "image_url" "text",
    "post_type" "text" DEFAULT 'general'::"text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "is_archived" boolean DEFAULT false,
    "archived_at" timestamp with time zone,
    "likes_count" integer DEFAULT 0 NOT NULL,
    "comments_count" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."posts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."processed_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "transaction_id" "text" NOT NULL,
    "user_id" "uuid",
    "status" "text",
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."processed_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "full_name" "text",
    "phone" "text",
    "avatar_url" "text",
    "role" "public"."user_role",
    "governorate" "public"."governorate",
    "facebook_url" "text",
    "instagram_url" "text",
    "bio" "text",
    "experience_years" integer DEFAULT 0,
    "rating" numeric(3,2) DEFAULT 0,
    "total_reviews" integer DEFAULT 0,
    "is_verified" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "followers_count" integer DEFAULT 0,
    "following_count" integer DEFAULT 0,
    "posts_count" integer DEFAULT 0,
    "projects_count" integer DEFAULT 0,
    "cover_photo_url" "text",
    "username" "text",
    "verification_status" "text" DEFAULT 'unverified'::"text",
    "id_document_url" "text",
    "subscription_status" "text" DEFAULT 'inactive'::"text",
    "subscription_expires_at" timestamp without time zone,
    "email" "text",
    "date_of_birth" "date",
    "verification_rejection_reason" "text",
    "has_pro_badge" boolean DEFAULT false,
    "cover_url" "text",
    CONSTRAINT "profiles_verification_status_check" CHECK (("verification_status" = ANY (ARRAY['unverified'::"text", 'pending'::"text", 'verified'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_applications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "subject" "text" NOT NULL,
    "message" "text" NOT NULL,
    "attachments_count" integer DEFAULT 0 NOT NULL,
    "files" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "project_applications_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'rejected'::"text", 'withdrawn'::"text"])))
);


ALTER TABLE "public"."project_applications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_attachments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "file_name" "text" NOT NULL,
    "file_url" "text" NOT NULL,
    "file_type" "text" NOT NULL,
    "file_size" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."project_attachments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."project_details" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "tagline" "text",
    "category" "text" DEFAULT 'مدني'::"text" NOT NULL,
    "project_type" "text" DEFAULT 'تعاون مشروع'::"text" NOT NULL,
    "work_mode" "text" DEFAULT 'موقعي'::"text" NOT NULL,
    "stage" "text" DEFAULT 'تخطيط'::"text" NOT NULL,
    "problem" "text",
    "goals" "text",
    "target_users" "text",
    "existing_assets" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "required_skills" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "preferred_skills" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "tools_equipment" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "seniority_level" "text",
    "years_experience" integer,
    "certifications" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "engineers_needed" integer DEFAULT 1 NOT NULL,
    "roles_needed" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "responsibilities" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "current_team_size" "text",
    "collaboration_tools" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "estimated_duration" "text",
    "weekly_commitment" "text",
    "milestones" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "deadline_urgency" "text",
    "payment_status" "text" DEFAULT 'مدفوع'::"text" NOT NULL,
    "payment_model" "text",
    "currency" "text" DEFAULT 'IQD'::"text" NOT NULL,
    "bonus_incentives" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "project_details_engineers_needed_check" CHECK (("engineers_needed" > 0))
);


ALTER TABLE "public"."project_details" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "governorate" "text" NOT NULL,
    "budget_min" numeric,
    "budget_max" numeric,
    "status" "text" DEFAULT 'planning'::"text" NOT NULL,
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "image_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."rate_limits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" "text" NOT NULL,
    "window_start" timestamp with time zone DEFAULT "now"() NOT NULL,
    "request_count" integer DEFAULT 1 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."rate_limits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reel_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reel_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "likes_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "parent_id" "uuid",
    CONSTRAINT "reel_comments_content_length_check" CHECK ((("length"("content") >= 1) AND ("length"("content") <= 5000)))
);


ALTER TABLE "public"."reel_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reel_likes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reel_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."reel_likes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reel_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reel_id" "uuid" NOT NULL,
    "reporter_id" "uuid" NOT NULL,
    "reason" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "admin_notes" "text",
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."reel_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reel_views" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reel_id" "uuid" NOT NULL,
    "viewer_profile_id" "uuid" NOT NULL,
    "viewed_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."reel_views" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reels" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "video_url" "text" NOT NULL,
    "thumbnail_url" "text",
    "caption" "text",
    "duration_seconds" integer DEFAULT 0,
    "views_count" integer DEFAULT 0,
    "likes_count" integer DEFAULT 0,
    "comments_count" integer DEFAULT 0,
    "shares_count" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "reels_caption_length_check" CHECK ((("caption" IS NULL) OR ("length"("caption") <= 2200))),
    CONSTRAINT "reels_duration_check" CHECK ((("duration_seconds" IS NULL) OR (("duration_seconds" >= 0) AND ("duration_seconds" <= 600))))
);


ALTER TABLE "public"."reels" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reviews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reviewer_id" "uuid" NOT NULL,
    "reviewed_id" "uuid" NOT NULL,
    "rating" integer NOT NULL,
    "comment" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "reviews_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."reviews" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_permissions" (
    "role_id" "uuid" NOT NULL,
    "permission_id" "uuid" NOT NULL
);


ALTER TABLE "public"."role_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."saved_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "item_type" "text" NOT NULL,
    "item_id" "text" NOT NULL,
    "title" "text" NOT NULL,
    "subtitle" "text",
    "detail" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "saved_items_item_type_check" CHECK (("item_type" = ANY (ARRAY['post'::"text", 'reel'::"text", 'project'::"text", 'company'::"text", 'story'::"text"])))
);


ALTER TABLE "public"."saved_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."saved_reels" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reel_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."saved_reels" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."storage_usage" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "bucket_name" "text" NOT NULL,
    "file_path" "text" NOT NULL,
    "file_size" bigint DEFAULT 0 NOT NULL,
    "mime_type" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."storage_usage" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."stories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "content" "text",
    "media_url" "text" NOT NULL,
    "media_type" "text" DEFAULT 'image'::"text" NOT NULL,
    "views_count" integer DEFAULT 0,
    "likes_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '24:00:00'::interval) NOT NULL,
    "is_archived" boolean DEFAULT false,
    "archived_at" timestamp with time zone,
    CONSTRAINT "stories_content_length_check" CHECK ((("content" IS NULL) OR ("length"("content") <= 500)))
);


ALTER TABLE "public"."stories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."story_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "story_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."story_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."story_likes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "story_id" "uuid" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."story_likes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."story_views" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "story_id" "uuid" NOT NULL,
    "viewer_profile_id" "uuid" NOT NULL,
    "viewed_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."story_views" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "status" "public"."subscription_status" DEFAULT 'trial'::"public"."subscription_status" NOT NULL,
    "plan_type" "text" DEFAULT 'free'::"text" NOT NULL,
    "starts_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."support_tickets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "subject" "text" NOT NULL,
    "description" "text" NOT NULL,
    "category" "text" DEFAULT 'general'::"text" NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "admin_notes" "text",
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."support_tickets" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."system_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "type" "text",
    "message" "text",
    "metadata" "jsonb",
    "created_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."system_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."system_status" (
    "id" integer NOT NULL,
    "service" "text",
    "status" "text",
    "updated_at" timestamp without time zone
);


ALTER TABLE "public"."system_status" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reporter_id" "uuid" NOT NULL,
    "reported_id" "uuid" NOT NULL,
    "conversation_id" "uuid",
    "reason" "text",
    "status" "text" DEFAULT 'pending'::"text",
    "admin_notes" "text",
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewed'::"text", 'resolved'::"text", 'dismissed'::"text"])))
);


ALTER TABLE "public"."user_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "storage"."buckets" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "owner" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "public" boolean DEFAULT false,
    "avif_autodetection" boolean DEFAULT false,
    "file_size_limit" bigint,
    "allowed_mime_types" "text"[],
    "owner_id" "text",
    "type" "storage"."buckettype" DEFAULT 'STANDARD'::"storage"."buckettype" NOT NULL
);


ALTER TABLE "storage"."buckets" OWNER TO "supabase_storage_admin";


COMMENT ON COLUMN "storage"."buckets"."owner" IS 'Field is deprecated, use owner_id instead';



CREATE TABLE IF NOT EXISTS "storage"."buckets_analytics" (
    "name" "text" NOT NULL,
    "type" "storage"."buckettype" DEFAULT 'ANALYTICS'::"storage"."buckettype" NOT NULL,
    "format" "text" DEFAULT 'ICEBERG'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "deleted_at" timestamp with time zone
);


ALTER TABLE "storage"."buckets_analytics" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."buckets_vectors" (
    "id" "text" NOT NULL,
    "type" "storage"."buckettype" DEFAULT 'VECTOR'::"storage"."buckettype" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "storage"."buckets_vectors" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."migrations" (
    "id" integer NOT NULL,
    "name" character varying(100) NOT NULL,
    "hash" character varying(40) NOT NULL,
    "executed_at" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE "storage"."migrations" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."objects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bucket_id" "text",
    "name" "text",
    "owner" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "last_accessed_at" timestamp with time zone DEFAULT "now"(),
    "metadata" "jsonb",
    "path_tokens" "text"[] GENERATED ALWAYS AS ("string_to_array"("name", '/'::"text")) STORED,
    "version" "text",
    "owner_id" "text",
    "user_metadata" "jsonb"
);


ALTER TABLE "storage"."objects" OWNER TO "supabase_storage_admin";


COMMENT ON COLUMN "storage"."objects"."owner" IS 'Field is deprecated, use owner_id instead';



CREATE TABLE IF NOT EXISTS "storage"."s3_multipart_uploads" (
    "id" "text" NOT NULL,
    "in_progress_size" bigint DEFAULT 0 NOT NULL,
    "upload_signature" "text" NOT NULL,
    "bucket_id" "text" NOT NULL,
    "key" "text" NOT NULL COLLATE "pg_catalog"."C",
    "version" "text" NOT NULL,
    "owner_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_metadata" "jsonb",
    "metadata" "jsonb"
);


ALTER TABLE "storage"."s3_multipart_uploads" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."s3_multipart_uploads_parts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "upload_id" "text" NOT NULL,
    "size" bigint DEFAULT 0 NOT NULL,
    "part_number" integer NOT NULL,
    "bucket_id" "text" NOT NULL,
    "key" "text" NOT NULL COLLATE "pg_catalog"."C",
    "etag" "text" NOT NULL,
    "owner_id" "text",
    "version" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "storage"."s3_multipart_uploads_parts" OWNER TO "supabase_storage_admin";


CREATE TABLE IF NOT EXISTS "storage"."vector_indexes" (
    "id" "text" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL COLLATE "pg_catalog"."C",
    "bucket_id" "text" NOT NULL,
    "data_type" "text" NOT NULL,
    "dimension" integer NOT NULL,
    "distance_metric" "text" NOT NULL,
    "metadata_configuration" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "storage"."vector_indexes" OWNER TO "supabase_storage_admin";


ALTER TABLE ONLY "auth"."refresh_tokens" ALTER COLUMN "id" SET DEFAULT "nextval"('"auth"."refresh_tokens_id_seq"'::"regclass");



ALTER TABLE ONLY "auth"."mfa_amr_claims"
    ADD CONSTRAINT "amr_id_pk" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."audit_log_entries"
    ADD CONSTRAINT "audit_log_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."custom_oauth_providers"
    ADD CONSTRAINT "custom_oauth_providers_identifier_key" UNIQUE ("identifier");



ALTER TABLE ONLY "auth"."custom_oauth_providers"
    ADD CONSTRAINT "custom_oauth_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."flow_state"
    ADD CONSTRAINT "flow_state_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."identities"
    ADD CONSTRAINT "identities_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."identities"
    ADD CONSTRAINT "identities_provider_id_provider_unique" UNIQUE ("provider_id", "provider");



ALTER TABLE ONLY "auth"."instances"
    ADD CONSTRAINT "instances_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."mfa_amr_claims"
    ADD CONSTRAINT "mfa_amr_claims_session_id_authentication_method_pkey" UNIQUE ("session_id", "authentication_method");



ALTER TABLE ONLY "auth"."mfa_challenges"
    ADD CONSTRAINT "mfa_challenges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."mfa_factors"
    ADD CONSTRAINT "mfa_factors_last_challenged_at_key" UNIQUE ("last_challenged_at");



ALTER TABLE ONLY "auth"."mfa_factors"
    ADD CONSTRAINT "mfa_factors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_authorization_code_key" UNIQUE ("authorization_code");



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_authorization_id_key" UNIQUE ("authorization_id");



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_client_states"
    ADD CONSTRAINT "oauth_client_states_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_clients"
    ADD CONSTRAINT "oauth_clients_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_user_client_unique" UNIQUE ("user_id", "client_id");



ALTER TABLE ONLY "auth"."one_time_tokens"
    ADD CONSTRAINT "one_time_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_token_unique" UNIQUE ("token");



ALTER TABLE ONLY "auth"."saml_providers"
    ADD CONSTRAINT "saml_providers_entity_id_key" UNIQUE ("entity_id");



ALTER TABLE ONLY "auth"."saml_providers"
    ADD CONSTRAINT "saml_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."saml_relay_states"
    ADD CONSTRAINT "saml_relay_states_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."schema_migrations"
    ADD CONSTRAINT "schema_migrations_pkey" PRIMARY KEY ("version");



ALTER TABLE ONLY "auth"."sessions"
    ADD CONSTRAINT "sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."sso_domains"
    ADD CONSTRAINT "sso_domains_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."sso_providers"
    ADD CONSTRAINT "sso_providers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."users"
    ADD CONSTRAINT "users_phone_key" UNIQUE ("phone");



ALTER TABLE ONLY "auth"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."webauthn_challenges"
    ADD CONSTRAINT "webauthn_challenges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "auth"."webauthn_credentials"
    ADD CONSTRAINT "webauthn_credentials_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_audit_log"
    ADD CONSTRAINT "admin_audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_audit_logs"
    ADD CONSTRAINT "admin_audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_checklist"
    ADD CONSTRAINT "admin_checklist_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_courses"
    ADD CONSTRAINT "admin_courses_department_id_slug_key" UNIQUE ("department_id", "slug");



ALTER TABLE ONLY "public"."admin_courses"
    ADD CONSTRAINT "admin_courses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_departments"
    ADD CONSTRAINT "admin_departments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_departments"
    ADD CONSTRAINT "admin_departments_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."admin_faq"
    ADD CONSTRAINT "admin_faq_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_lecture_assets"
    ADD CONSTRAINT "admin_lecture_assets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_lectures"
    ADD CONSTRAINT "admin_lectures_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_legal_sections"
    ADD CONSTRAINT "admin_legal_sections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_legal_sections"
    ADD CONSTRAINT "admin_legal_sections_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."admin_notification_reads"
    ADD CONSTRAINT "admin_notification_reads_notification_id_user_id_key" UNIQUE ("notification_id", "user_id");



ALTER TABLE ONLY "public"."admin_notification_reads"
    ADD CONSTRAINT "admin_notification_reads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_notifications"
    ADD CONSTRAINT "admin_notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_permissions"
    ADD CONSTRAINT "admin_permissions_key_key" UNIQUE ("key");



ALTER TABLE ONLY "public"."admin_permissions"
    ADD CONSTRAINT "admin_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_role_permissions"
    ADD CONSTRAINT "admin_role_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_role_permissions"
    ADD CONSTRAINT "admin_role_permissions_role_id_permission_id_key" UNIQUE ("role_id", "permission_id");



ALTER TABLE ONLY "public"."admin_roles"
    ADD CONSTRAINT "admin_roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."admin_roles"
    ADD CONSTRAINT "admin_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_settings"
    ADD CONSTRAINT "admin_settings_key_key" UNIQUE ("key");



ALTER TABLE ONLY "public"."admin_settings"
    ADD CONSTRAINT "admin_settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_support_tickets"
    ADD CONSTRAINT "admin_support_tickets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_user_roles"
    ADD CONSTRAINT "admin_user_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."admin_user_roles"
    ADD CONSTRAINT "admin_user_roles_user_id_role_id_key" UNIQUE ("user_id", "role_id");



ALTER TABLE ONLY "public"."admin_users"
    ADD CONSTRAINT "admin_users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."admin_users"
    ADD CONSTRAINT "admin_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ai_conversations"
    ADD CONSTRAINT "ai_conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ai_messages"
    ADD CONSTRAINT "ai_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_comments"
    ADD CONSTRAINT "app_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_config"
    ADD CONSTRAINT "app_config_key_key" UNIQUE ("key");



ALTER TABLE ONLY "public"."app_config"
    ADD CONSTRAINT "app_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_reposts"
    ADD CONSTRAINT "app_reposts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_reposts"
    ADD CONSTRAINT "app_reposts_target_type_target_id_profile_id_key" UNIQUE ("target_type", "target_id", "profile_id");



ALTER TABLE ONLY "public"."automation_rules"
    ADD CONSTRAINT "automation_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."badge_requests"
    ADD CONSTRAINT "badge_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."blocked_profiles"
    ADD CONSTRAINT "blocked_profiles_blocker_profile_id_blocked_profile_id_key" UNIQUE ("blocker_profile_id", "blocked_profile_id");



ALTER TABLE ONLY "public"."blocked_profiles"
    ADD CONSTRAINT "blocked_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_blocker_id_blocked_id_key" UNIQUE ("blocker_id", "blocked_id");



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."capture_attempts"
    ADD CONSTRAINT "capture_attempts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."comment_likes"
    ADD CONSTRAINT "comment_likes_comment_type_comment_id_profile_id_key" UNIQUE ("comment_type", "comment_id", "profile_id");



ALTER TABLE ONLY "public"."comment_likes"
    ADD CONSTRAINT "comment_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."connection_requests"
    ADD CONSTRAINT "connection_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."connection_requests"
    ADD CONSTRAINT "connection_requests_requester_profile_id_receiver_profile_i_key" UNIQUE ("requester_profile_id", "receiver_profile_id");



ALTER TABLE ONLY "public"."contractor_details"
    ADD CONSTRAINT "contractor_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contractor_details"
    ADD CONSTRAINT "contractor_details_profile_id_key" UNIQUE ("profile_id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_participant_pair_key" UNIQUE ("participant_one", "participant_two");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."course_progress"
    ADD CONSTRAINT "course_progress_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."course_progress"
    ADD CONSTRAINT "course_progress_profile_id_course_id_key" UNIQUE ("profile_id", "course_id");



ALTER TABLE ONLY "public"."courses"
    ADD CONSTRAINT "courses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."craftsman_details"
    ADD CONSTRAINT "craftsman_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."craftsman_details"
    ADD CONSTRAINT "craftsman_details_profile_id_key" UNIQUE ("profile_id");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_user_id_token_key" UNIQUE ("user_id", "token");



ALTER TABLE ONLY "public"."engineer_details"
    ADD CONSTRAINT "engineer_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."engineer_details"
    ADD CONSTRAINT "engineer_details_profile_id_key" UNIQUE ("profile_id");



ALTER TABLE ONLY "public"."engineer_notes"
    ADD CONSTRAINT "engineer_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."followers"
    ADD CONSTRAINT "followers_follower_id_following_id_key" UNIQUE ("follower_id", "following_id");



ALTER TABLE ONLY "public"."followers"
    ADD CONSTRAINT "followers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."job_requests"
    ADD CONSTRAINT "job_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."machinery_details"
    ADD CONSTRAINT "machinery_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."machinery_details"
    ADD CONSTRAINT "machinery_details_profile_id_key" UNIQUE ("profile_id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."muted_conversations"
    ADD CONSTRAINT "muted_conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."muted_conversations"
    ADD CONSTRAINT "muted_conversations_profile_id_conversation_id_key" UNIQUE ("profile_id", "conversation_id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."otp_verifications"
    ADD CONSTRAINT "otp_verifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payment_history"
    ADD CONSTRAINT "payment_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_comments"
    ADD CONSTRAINT "post_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_post_id_profile_id_key" UNIQUE ("post_id", "profile_id");



ALTER TABLE ONLY "public"."post_reports"
    ADD CONSTRAINT "post_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."post_reports"
    ADD CONSTRAINT "post_reports_post_id_reporter_id_key" UNIQUE ("post_id", "reporter_id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."processed_transactions"
    ADD CONSTRAINT "processed_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."processed_transactions"
    ADD CONSTRAINT "processed_transactions_transaction_id_key" UNIQUE ("transaction_id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."project_applications"
    ADD CONSTRAINT "project_applications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_applications"
    ADD CONSTRAINT "project_applications_project_id_profile_id_key" UNIQUE ("project_id", "profile_id");



ALTER TABLE ONLY "public"."project_attachments"
    ADD CONSTRAINT "project_attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_details"
    ADD CONSTRAINT "project_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."project_details"
    ADD CONSTRAINT "project_details_project_id_key" UNIQUE ("project_id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."rate_limits"
    ADD CONSTRAINT "rate_limits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reel_comments"
    ADD CONSTRAINT "reel_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reel_likes"
    ADD CONSTRAINT "reel_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reel_likes"
    ADD CONSTRAINT "reel_likes_reel_id_profile_id_key" UNIQUE ("reel_id", "profile_id");



ALTER TABLE ONLY "public"."reel_reports"
    ADD CONSTRAINT "reel_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reel_reports"
    ADD CONSTRAINT "reel_reports_reel_id_reporter_id_key" UNIQUE ("reel_id", "reporter_id");



ALTER TABLE ONLY "public"."reel_views"
    ADD CONSTRAINT "reel_views_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reel_views"
    ADD CONSTRAINT "reel_views_reel_id_viewer_profile_id_key" UNIQUE ("reel_id", "viewer_profile_id");



ALTER TABLE ONLY "public"."reels"
    ADD CONSTRAINT "reels_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_reviewer_id_reviewed_id_key" UNIQUE ("reviewer_id", "reviewed_id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("role_id", "permission_id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saved_items"
    ADD CONSTRAINT "saved_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saved_items"
    ADD CONSTRAINT "saved_items_profile_id_item_type_item_id_key" UNIQUE ("profile_id", "item_type", "item_id");



ALTER TABLE ONLY "public"."saved_reels"
    ADD CONSTRAINT "saved_reels_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saved_reels"
    ADD CONSTRAINT "saved_reels_reel_id_profile_id_key" UNIQUE ("reel_id", "profile_id");



ALTER TABLE ONLY "public"."storage_usage"
    ADD CONSTRAINT "storage_usage_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."storage_usage"
    ADD CONSTRAINT "storage_usage_profile_id_bucket_name_file_path_key" UNIQUE ("profile_id", "bucket_name", "file_path");



ALTER TABLE ONLY "public"."stories"
    ADD CONSTRAINT "stories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story_comments"
    ADD CONSTRAINT "story_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story_likes"
    ADD CONSTRAINT "story_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story_likes"
    ADD CONSTRAINT "story_likes_story_id_profile_id_key" UNIQUE ("story_id", "profile_id");



ALTER TABLE ONLY "public"."story_views"
    ADD CONSTRAINT "story_views_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."story_views"
    ADD CONSTRAINT "story_views_story_id_viewer_profile_id_key" UNIQUE ("story_id", "viewer_profile_id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_profile_id_key" UNIQUE ("profile_id");



ALTER TABLE ONLY "public"."support_tickets"
    ADD CONSTRAINT "support_tickets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_logs"
    ADD CONSTRAINT "system_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_status"
    ADD CONSTRAINT "system_status_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."otp_verifications"
    ADD CONSTRAINT "unique_phone_otp" UNIQUE ("phone_local10");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "unique_user_profile" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."buckets_analytics"
    ADD CONSTRAINT "buckets_analytics_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."buckets"
    ADD CONSTRAINT "buckets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."buckets_vectors"
    ADD CONSTRAINT "buckets_vectors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."migrations"
    ADD CONSTRAINT "migrations_name_key" UNIQUE ("name");



ALTER TABLE ONLY "storage"."migrations"
    ADD CONSTRAINT "migrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."objects"
    ADD CONSTRAINT "objects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
    ADD CONSTRAINT "s3_multipart_uploads_parts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads"
    ADD CONSTRAINT "s3_multipart_uploads_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "storage"."vector_indexes"
    ADD CONSTRAINT "vector_indexes_pkey" PRIMARY KEY ("id");



CREATE INDEX "audit_logs_instance_id_idx" ON "auth"."audit_log_entries" USING "btree" ("instance_id");



CREATE UNIQUE INDEX "confirmation_token_idx" ON "auth"."users" USING "btree" ("confirmation_token") WHERE (("confirmation_token")::"text" !~ '^[0-9 ]*$'::"text");



CREATE INDEX "custom_oauth_providers_created_at_idx" ON "auth"."custom_oauth_providers" USING "btree" ("created_at");



CREATE INDEX "custom_oauth_providers_enabled_idx" ON "auth"."custom_oauth_providers" USING "btree" ("enabled");



CREATE INDEX "custom_oauth_providers_identifier_idx" ON "auth"."custom_oauth_providers" USING "btree" ("identifier");



CREATE INDEX "custom_oauth_providers_provider_type_idx" ON "auth"."custom_oauth_providers" USING "btree" ("provider_type");



CREATE UNIQUE INDEX "email_change_token_current_idx" ON "auth"."users" USING "btree" ("email_change_token_current") WHERE (("email_change_token_current")::"text" !~ '^[0-9 ]*$'::"text");



CREATE UNIQUE INDEX "email_change_token_new_idx" ON "auth"."users" USING "btree" ("email_change_token_new") WHERE (("email_change_token_new")::"text" !~ '^[0-9 ]*$'::"text");



CREATE INDEX "factor_id_created_at_idx" ON "auth"."mfa_factors" USING "btree" ("user_id", "created_at");



CREATE INDEX "flow_state_created_at_idx" ON "auth"."flow_state" USING "btree" ("created_at" DESC);



CREATE INDEX "identities_email_idx" ON "auth"."identities" USING "btree" ("email" "text_pattern_ops");



COMMENT ON INDEX "auth"."identities_email_idx" IS 'Auth: Ensures indexed queries on the email column';



CREATE INDEX "identities_user_id_idx" ON "auth"."identities" USING "btree" ("user_id");



CREATE INDEX "idx_auth_code" ON "auth"."flow_state" USING "btree" ("auth_code");



CREATE INDEX "idx_oauth_client_states_created_at" ON "auth"."oauth_client_states" USING "btree" ("created_at");



CREATE INDEX "idx_user_id_auth_method" ON "auth"."flow_state" USING "btree" ("user_id", "authentication_method");



CREATE INDEX "mfa_challenge_created_at_idx" ON "auth"."mfa_challenges" USING "btree" ("created_at" DESC);



CREATE UNIQUE INDEX "mfa_factors_user_friendly_name_unique" ON "auth"."mfa_factors" USING "btree" ("friendly_name", "user_id") WHERE (TRIM(BOTH FROM "friendly_name") <> ''::"text");



CREATE INDEX "mfa_factors_user_id_idx" ON "auth"."mfa_factors" USING "btree" ("user_id");



CREATE INDEX "oauth_auth_pending_exp_idx" ON "auth"."oauth_authorizations" USING "btree" ("expires_at") WHERE ("status" = 'pending'::"auth"."oauth_authorization_status");



CREATE INDEX "oauth_clients_deleted_at_idx" ON "auth"."oauth_clients" USING "btree" ("deleted_at");



CREATE INDEX "oauth_consents_active_client_idx" ON "auth"."oauth_consents" USING "btree" ("client_id") WHERE ("revoked_at" IS NULL);



CREATE INDEX "oauth_consents_active_user_client_idx" ON "auth"."oauth_consents" USING "btree" ("user_id", "client_id") WHERE ("revoked_at" IS NULL);



CREATE INDEX "oauth_consents_user_order_idx" ON "auth"."oauth_consents" USING "btree" ("user_id", "granted_at" DESC);



CREATE INDEX "one_time_tokens_relates_to_hash_idx" ON "auth"."one_time_tokens" USING "hash" ("relates_to");



CREATE INDEX "one_time_tokens_token_hash_hash_idx" ON "auth"."one_time_tokens" USING "hash" ("token_hash");



CREATE UNIQUE INDEX "one_time_tokens_user_id_token_type_key" ON "auth"."one_time_tokens" USING "btree" ("user_id", "token_type");



CREATE UNIQUE INDEX "reauthentication_token_idx" ON "auth"."users" USING "btree" ("reauthentication_token") WHERE (("reauthentication_token")::"text" !~ '^[0-9 ]*$'::"text");



CREATE UNIQUE INDEX "recovery_token_idx" ON "auth"."users" USING "btree" ("recovery_token") WHERE (("recovery_token")::"text" !~ '^[0-9 ]*$'::"text");



CREATE INDEX "refresh_tokens_instance_id_idx" ON "auth"."refresh_tokens" USING "btree" ("instance_id");



CREATE INDEX "refresh_tokens_instance_id_user_id_idx" ON "auth"."refresh_tokens" USING "btree" ("instance_id", "user_id");



CREATE INDEX "refresh_tokens_parent_idx" ON "auth"."refresh_tokens" USING "btree" ("parent");



CREATE INDEX "refresh_tokens_session_id_revoked_idx" ON "auth"."refresh_tokens" USING "btree" ("session_id", "revoked");



CREATE INDEX "refresh_tokens_updated_at_idx" ON "auth"."refresh_tokens" USING "btree" ("updated_at" DESC);



CREATE INDEX "saml_providers_sso_provider_id_idx" ON "auth"."saml_providers" USING "btree" ("sso_provider_id");



CREATE INDEX "saml_relay_states_created_at_idx" ON "auth"."saml_relay_states" USING "btree" ("created_at" DESC);



CREATE INDEX "saml_relay_states_for_email_idx" ON "auth"."saml_relay_states" USING "btree" ("for_email");



CREATE INDEX "saml_relay_states_sso_provider_id_idx" ON "auth"."saml_relay_states" USING "btree" ("sso_provider_id");



CREATE INDEX "sessions_not_after_idx" ON "auth"."sessions" USING "btree" ("not_after" DESC);



CREATE INDEX "sessions_oauth_client_id_idx" ON "auth"."sessions" USING "btree" ("oauth_client_id");



CREATE INDEX "sessions_user_id_idx" ON "auth"."sessions" USING "btree" ("user_id");



CREATE UNIQUE INDEX "sso_domains_domain_idx" ON "auth"."sso_domains" USING "btree" ("lower"("domain"));



CREATE INDEX "sso_domains_sso_provider_id_idx" ON "auth"."sso_domains" USING "btree" ("sso_provider_id");



CREATE UNIQUE INDEX "sso_providers_resource_id_idx" ON "auth"."sso_providers" USING "btree" ("lower"("resource_id"));



CREATE INDEX "sso_providers_resource_id_pattern_idx" ON "auth"."sso_providers" USING "btree" ("resource_id" "text_pattern_ops");



CREATE UNIQUE INDEX "unique_phone_factor_per_user" ON "auth"."mfa_factors" USING "btree" ("user_id", "phone");



CREATE INDEX "user_id_created_at_idx" ON "auth"."sessions" USING "btree" ("user_id", "created_at");



CREATE UNIQUE INDEX "users_email_partial_key" ON "auth"."users" USING "btree" ("email") WHERE ("is_sso_user" = false);



COMMENT ON INDEX "auth"."users_email_partial_key" IS 'Auth: A partial unique index that applies only when is_sso_user is false';



CREATE INDEX "users_instance_id_email_idx" ON "auth"."users" USING "btree" ("instance_id", "lower"(("email")::"text"));



CREATE INDEX "users_instance_id_idx" ON "auth"."users" USING "btree" ("instance_id");



CREATE INDEX "users_is_anonymous_idx" ON "auth"."users" USING "btree" ("is_anonymous");



CREATE INDEX "webauthn_challenges_expires_at_idx" ON "auth"."webauthn_challenges" USING "btree" ("expires_at");



CREATE INDEX "webauthn_challenges_user_id_idx" ON "auth"."webauthn_challenges" USING "btree" ("user_id");



CREATE UNIQUE INDEX "webauthn_credentials_credential_id_key" ON "auth"."webauthn_credentials" USING "btree" ("credential_id");



CREATE INDEX "webauthn_credentials_user_id_idx" ON "auth"."webauthn_credentials" USING "btree" ("user_id");



CREATE UNIQUE INDEX "connection_requests_active_pair_unique_idx" ON "public"."connection_requests" USING "btree" (LEAST("requester_profile_id", "receiver_profile_id"), GREATEST("requester_profile_id", "receiver_profile_id")) WHERE ("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text"]));



CREATE INDEX "idx_admin_audit_log_action" ON "public"."admin_audit_log" USING "btree" ("action");



CREATE INDEX "idx_admin_audit_log_admin" ON "public"."admin_audit_log" USING "btree" ("admin_id");



CREATE INDEX "idx_admin_audit_log_created" ON "public"."admin_audit_log" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_admin_audit_logs_actor" ON "public"."admin_audit_logs" USING "btree" ("actor_user_id");



CREATE INDEX "idx_admin_audit_logs_created_at" ON "public"."admin_audit_logs" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_admin_audit_logs_entity" ON "public"."admin_audit_logs" USING "btree" ("entity", "entity_id");



CREATE INDEX "idx_admin_lecture_assets_lecture_id" ON "public"."admin_lecture_assets" USING "btree" ("lecture_id");



CREATE INDEX "idx_admin_lectures_course_id" ON "public"."admin_lectures" USING "btree" ("course_id");



CREATE INDEX "idx_admin_lectures_status" ON "public"."admin_lectures" USING "btree" ("status");



CREATE INDEX "idx_admin_role_permissions_role_id" ON "public"."admin_role_permissions" USING "btree" ("role_id");



CREATE INDEX "idx_admin_user_roles_role_id" ON "public"."admin_user_roles" USING "btree" ("role_id");



CREATE INDEX "idx_admin_user_roles_user_id" ON "public"."admin_user_roles" USING "btree" ("user_id");



CREATE INDEX "idx_admin_users_email" ON "public"."admin_users" USING "btree" ("email");



CREATE INDEX "idx_admin_users_status" ON "public"."admin_users" USING "btree" ("status");



CREATE INDEX "idx_ai_conversations_profile" ON "public"."ai_conversations" USING "btree" ("profile_id", "updated_at" DESC);



CREATE INDEX "idx_ai_conversations_profile_id" ON "public"."ai_conversations" USING "btree" ("profile_id");



CREATE INDEX "idx_ai_messages_conversation" ON "public"."ai_messages" USING "btree" ("conversation_id", "created_at");



CREATE INDEX "idx_ai_messages_conversation_id" ON "public"."ai_messages" USING "btree" ("conversation_id");



CREATE INDEX "idx_app_comments_target_created_at" ON "public"."app_comments" USING "btree" ("target_type", "target_id", "created_at" DESC);



CREATE INDEX "idx_blocked_users_pair" ON "public"."blocked_users" USING "btree" ("blocker_id", "blocked_id");



CREATE INDEX "idx_blocked_users_reverse" ON "public"."blocked_users" USING "btree" ("blocked_id", "blocker_id");



CREATE INDEX "idx_capture_attempts_created_at" ON "public"."capture_attempts" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_capture_attempts_profile_id" ON "public"."capture_attempts" USING "btree" ("profile_id");



CREATE INDEX "idx_capture_attempts_type" ON "public"."capture_attempts" USING "btree" ("attempt_type");



CREATE INDEX "idx_connection_requests_receiver_status" ON "public"."connection_requests" USING "btree" ("receiver_profile_id", "status");



CREATE INDEX "idx_conversations_last_message_at" ON "public"."conversations" USING "btree" ("last_message_at" DESC NULLS LAST);



CREATE INDEX "idx_conversations_participant_one_last" ON "public"."conversations" USING "btree" ("participant_one", "last_message_at" DESC);



CREATE INDEX "idx_conversations_participant_two_last" ON "public"."conversations" USING "btree" ("participant_two", "last_message_at" DESC);



CREATE INDEX "idx_conversations_participants" ON "public"."conversations" USING "btree" ("participant_one", "participant_two", "last_message_at" DESC);



CREATE INDEX "idx_followers_follower" ON "public"."followers" USING "btree" ("follower_id", "created_at" DESC);



CREATE INDEX "idx_followers_follower_id" ON "public"."followers" USING "btree" ("follower_id");



CREATE INDEX "idx_followers_following" ON "public"."followers" USING "btree" ("following_id", "created_at" DESC);



CREATE INDEX "idx_followers_following_id" ON "public"."followers" USING "btree" ("following_id");



CREATE INDEX "idx_followers_pair" ON "public"."followers" USING "btree" ("follower_id", "following_id");



CREATE INDEX "idx_messages_conv_unread" ON "public"."messages" USING "btree" ("conversation_id", "is_read") WHERE ("is_read" = false);



CREATE INDEX "idx_messages_conversation_created" ON "public"."messages" USING "btree" ("conversation_id", "created_at" DESC);



CREATE INDEX "idx_messages_conversation_created_at" ON "public"."messages" USING "btree" ("conversation_id", "created_at");



CREATE INDEX "idx_messages_conversation_id" ON "public"."messages" USING "btree" ("conversation_id");



CREATE INDEX "idx_messages_unread" ON "public"."messages" USING "btree" ("conversation_id", "sender_id", "is_read") WHERE ("is_read" = false);



CREATE INDEX "idx_messages_unread_by_conversation" ON "public"."messages" USING "btree" ("conversation_id", "sender_id") WHERE ("read_at" IS NULL);



CREATE INDEX "idx_muted_conversations_pair" ON "public"."muted_conversations" USING "btree" ("profile_id", "conversation_id");



CREATE INDEX "idx_notifications_created_at" ON "public"."notifications" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_notifications_profile_created" ON "public"."notifications" USING "btree" ("profile_id", "created_at" DESC);



CREATE INDEX "idx_notifications_profile_created_at" ON "public"."notifications" USING "btree" ("profile_id", "created_at" DESC);



CREATE INDEX "idx_notifications_profile_id" ON "public"."notifications" USING "btree" ("profile_id");



CREATE INDEX "idx_notifications_profile_unread" ON "public"."notifications" USING "btree" ("profile_id", "is_read") WHERE ("is_read" = false);



CREATE INDEX "idx_notifications_unread" ON "public"."notifications" USING "btree" ("profile_id", "is_read") WHERE ("is_read" = false);



CREATE INDEX "idx_otp_phone" ON "public"."otp_verifications" USING "btree" ("phone_local10");



CREATE INDEX "idx_post_comments_post" ON "public"."post_comments" USING "btree" ("post_id");



CREATE INDEX "idx_post_comments_post_id" ON "public"."post_comments" USING "btree" ("post_id");



CREATE INDEX "idx_post_likes_composite" ON "public"."post_likes" USING "btree" ("post_id", "profile_id");



CREATE INDEX "idx_post_likes_post" ON "public"."post_likes" USING "btree" ("post_id");



CREATE INDEX "idx_post_likes_post_id" ON "public"."post_likes" USING "btree" ("post_id");



CREATE INDEX "idx_post_reports_status" ON "public"."post_reports" USING "btree" ("status");



CREATE INDEX "idx_posts_active_created" ON "public"."posts" USING "btree" ("is_active", "created_at" DESC) WHERE ("is_active" = true);



CREATE INDEX "idx_posts_archived" ON "public"."posts" USING "btree" ("profile_id", "is_archived") WHERE ("is_archived" = true);



CREATE INDEX "idx_posts_created_at" ON "public"."posts" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_posts_profile_active" ON "public"."posts" USING "btree" ("profile_id", "is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_posts_profile_id" ON "public"."posts" USING "btree" ("profile_id");



CREATE INDEX "idx_profiles_created_at" ON "public"."profiles" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_profiles_email_trgm" ON "public"."profiles" USING "gin" ("email" "public"."gin_trgm_ops");



CREATE INDEX "idx_profiles_full_name_trgm" ON "public"."profiles" USING "gin" ("full_name" "public"."gin_trgm_ops");



CREATE INDEX "idx_profiles_governorate" ON "public"."profiles" USING "btree" ("governorate");



CREATE INDEX "idx_profiles_role" ON "public"."profiles" USING "btree" ("role");



CREATE INDEX "idx_profiles_role_governorate" ON "public"."profiles" USING "btree" ("role", "governorate");



CREATE INDEX "idx_profiles_role_rating" ON "public"."profiles" USING "btree" ("role", "rating" DESC NULLS LAST);



CREATE INDEX "idx_profiles_search_name" ON "public"."profiles" USING "gin" ("to_tsvector"('"simple"'::"regconfig", COALESCE("full_name", ''::"text")));



CREATE INDEX "idx_profiles_user_id" ON "public"."profiles" USING "btree" ("user_id");



CREATE INDEX "idx_profiles_username" ON "public"."profiles" USING "btree" ("username");



CREATE UNIQUE INDEX "idx_profiles_username_unique" ON "public"."profiles" USING "btree" ("lower"("username")) WHERE ("username" IS NOT NULL);



CREATE INDEX "idx_project_applications_profile_id" ON "public"."project_applications" USING "btree" ("profile_id");



CREATE INDEX "idx_project_applications_project_id" ON "public"."project_applications" USING "btree" ("project_id");



CREATE UNIQUE INDEX "idx_project_applications_project_profile" ON "public"."project_applications" USING "btree" ("project_id", "profile_id");



CREATE INDEX "idx_project_details_project_id" ON "public"."project_details" USING "btree" ("project_id");



CREATE INDEX "idx_projects_profile" ON "public"."projects" USING "btree" ("profile_id", "created_at" DESC);



CREATE INDEX "idx_rate_limits_key_window" ON "public"."rate_limits" USING "btree" ("key", "window_start");



CREATE INDEX "idx_reel_comments_parent_id" ON "public"."reel_comments" USING "btree" ("parent_id");



CREATE INDEX "idx_reel_comments_reel" ON "public"."reel_comments" USING "btree" ("reel_id");



CREATE INDEX "idx_reel_likes_reel" ON "public"."reel_likes" USING "btree" ("reel_id");



CREATE INDEX "idx_reel_reports_reel_id" ON "public"."reel_reports" USING "btree" ("reel_id");



CREATE INDEX "idx_reel_reports_reporter_id" ON "public"."reel_reports" USING "btree" ("reporter_id");



CREATE INDEX "idx_reel_reports_status" ON "public"."reel_reports" USING "btree" ("status");



CREATE INDEX "idx_reel_views_reel_id" ON "public"."reel_views" USING "btree" ("reel_id");



CREATE INDEX "idx_reel_views_viewer_id" ON "public"."reel_views" USING "btree" ("viewer_profile_id");



CREATE INDEX "idx_reels_active_feed" ON "public"."reels" USING "btree" ("created_at" DESC) WHERE ("is_active" = true);



CREATE INDEX "idx_reels_created_at" ON "public"."reels" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_reels_profile" ON "public"."reels" USING "btree" ("profile_id", "created_at" DESC);



CREATE INDEX "idx_reels_profile_id" ON "public"."reels" USING "btree" ("profile_id");



CREATE INDEX "idx_reviews_reviewed" ON "public"."reviews" USING "btree" ("reviewed_id", "created_at" DESC);



CREATE INDEX "idx_saved_items_profile_id_created_at" ON "public"."saved_items" USING "btree" ("profile_id", "created_at" DESC);



CREATE INDEX "idx_saved_reels_profile" ON "public"."saved_reels" USING "btree" ("profile_id", "created_at" DESC);



CREATE INDEX "idx_saved_reels_profile_id" ON "public"."saved_reels" USING "btree" ("profile_id");



CREATE INDEX "idx_saved_reels_reel_id" ON "public"."saved_reels" USING "btree" ("reel_id");



CREATE INDEX "idx_storage_usage_bucket" ON "public"."storage_usage" USING "btree" ("bucket_name");



CREATE INDEX "idx_storage_usage_created" ON "public"."storage_usage" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_storage_usage_profile" ON "public"."storage_usage" USING "btree" ("profile_id");



CREATE INDEX "idx_stories_active_feed" ON "public"."stories" USING "btree" ("profile_id", "expires_at" DESC) WHERE ("is_archived" = false);



CREATE INDEX "idx_stories_archived" ON "public"."stories" USING "btree" ("profile_id", "is_archived") WHERE ("is_archived" = true);



CREATE INDEX "idx_stories_expires" ON "public"."stories" USING "btree" ("expires_at") WHERE ("is_archived" = false);



CREATE INDEX "idx_stories_expires_at" ON "public"."stories" USING "btree" ("expires_at");



CREATE INDEX "idx_stories_profile_expires" ON "public"."stories" USING "btree" ("profile_id", "expires_at" DESC);



CREATE INDEX "idx_stories_profile_id" ON "public"."stories" USING "btree" ("profile_id");



CREATE INDEX "idx_story_comments_story_id" ON "public"."story_comments" USING "btree" ("story_id");



CREATE INDEX "idx_story_likes_story" ON "public"."story_likes" USING "btree" ("story_id", "profile_id");



CREATE INDEX "idx_story_likes_story_id" ON "public"."story_likes" USING "btree" ("story_id");



CREATE INDEX "idx_story_views_story" ON "public"."story_views" USING "btree" ("story_id", "viewer_profile_id");



CREATE INDEX "idx_story_views_story_id" ON "public"."story_views" USING "btree" ("story_id");



CREATE INDEX "idx_subscriptions_active" ON "public"."subscriptions" USING "btree" ("profile_id", "status") WHERE ("status" = 'active'::"public"."subscription_status");



CREATE UNIQUE INDEX "bname" ON "storage"."buckets" USING "btree" ("name");



CREATE UNIQUE INDEX "bucketid_objname" ON "storage"."objects" USING "btree" ("bucket_id", "name");



CREATE UNIQUE INDEX "buckets_analytics_unique_name_idx" ON "storage"."buckets_analytics" USING "btree" ("name") WHERE ("deleted_at" IS NULL);



CREATE INDEX "idx_multipart_uploads_list" ON "storage"."s3_multipart_uploads" USING "btree" ("bucket_id", "key", "created_at");



CREATE INDEX "idx_objects_bucket_id_name" ON "storage"."objects" USING "btree" ("bucket_id", "name" COLLATE "C");



CREATE INDEX "idx_objects_bucket_id_name_lower" ON "storage"."objects" USING "btree" ("bucket_id", "lower"("name") COLLATE "C");



CREATE INDEX "name_prefix_search" ON "storage"."objects" USING "btree" ("name" "text_pattern_ops");



CREATE UNIQUE INDEX "vector_indexes_name_bucket_id_idx" ON "storage"."vector_indexes" USING "btree" ("name", "bucket_id");



CREATE OR REPLACE TRIGGER "on_auth_user_created" AFTER INSERT ON "auth"."users" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_user"();



CREATE OR REPLACE TRIGGER "on_auth_user_created_create_app_profile" AFTER INSERT ON "auth"."users" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_auth_user_for_app"();



CREATE OR REPLACE TRIGGER "on_auth_user_email_updated" AFTER UPDATE OF "email" ON "auth"."users" FOR EACH ROW EXECUTE FUNCTION "public"."sync_profile_email"();



CREATE OR REPLACE TRIGGER "on_auth_user_updated" AFTER UPDATE OF "email" ON "auth"."users" FOR EACH ROW EXECUTE FUNCTION "public"."sync_user_email"();



CREATE OR REPLACE TRIGGER "notify_craftsman_on_new_message" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."notify_craftsman_on_contact"();



CREATE OR REPLACE TRIGGER "on_app_comment_notify" AFTER INSERT ON "public"."app_comments" FOR EACH ROW EXECUTE FUNCTION "public"."app_notify_on_comment"();



CREATE OR REPLACE TRIGGER "on_app_connection_request_notify" AFTER INSERT OR UPDATE ON "public"."connection_requests" FOR EACH ROW EXECUTE FUNCTION "public"."app_notify_on_connection_request"();



CREATE OR REPLACE TRIGGER "on_app_message_notify" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."app_notify_on_message"();



CREATE OR REPLACE TRIGGER "on_app_message_touch_conversation" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."app_touch_conversation"();



CREATE OR REPLACE TRIGGER "on_app_normalize_conversation_participants" BEFORE INSERT OR UPDATE ON "public"."conversations" FOR EACH ROW EXECUTE FUNCTION "public"."app_normalize_conversation_participants"();



CREATE OR REPLACE TRIGGER "on_app_post_like_notify" AFTER INSERT ON "public"."post_likes" FOR EACH ROW EXECUTE FUNCTION "public"."app_notify_on_post_like"();



CREATE OR REPLACE TRIGGER "on_app_project_application_notify" AFTER INSERT ON "public"."project_applications" FOR EACH ROW EXECUTE FUNCTION "public"."app_notify_on_project_application"();



CREATE OR REPLACE TRIGGER "on_app_reel_like_notify" AFTER INSERT ON "public"."reel_likes" FOR EACH ROW EXECUTE FUNCTION "public"."app_notify_on_reel_like"();



CREATE OR REPLACE TRIGGER "on_app_sync_profile_cover_columns" BEFORE INSERT OR UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."app_sync_profile_cover_columns"();



CREATE OR REPLACE TRIGGER "on_connection_request_counts" AFTER UPDATE ON "public"."connection_requests" FOR EACH ROW EXECUTE FUNCTION "public"."app_update_connection_counts"();



CREATE OR REPLACE TRIGGER "on_new_follower" AFTER INSERT ON "public"."followers" FOR EACH ROW EXECUTE FUNCTION "public"."notify_on_follow"();



CREATE OR REPLACE TRIGGER "on_new_user_report" AFTER INSERT ON "public"."user_reports" FOR EACH ROW EXECUTE FUNCTION "public"."notify_admins_on_report"();



CREATE OR REPLACE TRIGGER "on_reel_comment_change" AFTER INSERT OR DELETE ON "public"."reel_comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_reel_comments_count"();



CREATE OR REPLACE TRIGGER "on_reel_like_change" AFTER INSERT OR DELETE ON "public"."reel_likes" FOR EACH ROW EXECUTE FUNCTION "public"."update_reel_likes_count"();



CREATE OR REPLACE TRIGGER "trg_update_post_comments_count" AFTER INSERT OR DELETE ON "public"."post_comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_post_comments_count"();



CREATE OR REPLACE TRIGGER "trg_update_post_likes_count" AFTER INSERT OR DELETE ON "public"."post_likes" FOR EACH ROW EXECUTE FUNCTION "public"."update_post_likes_count"();



CREATE OR REPLACE TRIGGER "update_admin_courses_updated_at" BEFORE UPDATE ON "public"."admin_courses" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_admin_departments_updated_at" BEFORE UPDATE ON "public"."admin_departments" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_admin_lectures_updated_at" BEFORE UPDATE ON "public"."admin_lectures" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_admin_users_updated_at" BEFORE UPDATE ON "public"."admin_users" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_ai_conversations_updated_at" BEFORE UPDATE ON "public"."ai_conversations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_badge_requests_updated_at" BEFORE UPDATE ON "public"."badge_requests" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_connection_requests_updated_at" BEFORE UPDATE ON "public"."connection_requests" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_conversations_updated_at" BEFORE UPDATE ON "public"."conversations" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_courses_updated_at" BEFORE UPDATE ON "public"."courses" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_engineer_notes_updated_at" BEFORE UPDATE ON "public"."engineer_notes" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_follower_counts_trigger" AFTER INSERT OR DELETE ON "public"."followers" FOR EACH ROW EXECUTE FUNCTION "public"."update_follower_counts"();



CREATE OR REPLACE TRIGGER "update_post_reports_updated_at" BEFORE UPDATE ON "public"."post_reports" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_posts_updated_at" BEFORE UPDATE ON "public"."posts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_profiles_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_project_applications_updated_at" BEFORE UPDATE ON "public"."project_applications" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_project_details_updated_at" BEFORE UPDATE ON "public"."project_details" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_projects_updated_at" BEFORE UPDATE ON "public"."projects" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_reel_reports_updated_at" BEFORE UPDATE ON "public"."reel_reports" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_reviews_updated_at" BEFORE UPDATE ON "public"."reviews" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_subscriptions_updated_at" BEFORE UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_support_tickets_updated_at" BEFORE UPDATE ON "public"."support_tickets" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "enforce_bucket_name_length_trigger" BEFORE INSERT OR UPDATE OF "name" ON "storage"."buckets" FOR EACH ROW EXECUTE FUNCTION "storage"."enforce_bucket_name_length"();



CREATE OR REPLACE TRIGGER "protect_buckets_delete" BEFORE DELETE ON "storage"."buckets" FOR EACH STATEMENT EXECUTE FUNCTION "storage"."protect_delete"();



CREATE OR REPLACE TRIGGER "protect_objects_delete" BEFORE DELETE ON "storage"."objects" FOR EACH STATEMENT EXECUTE FUNCTION "storage"."protect_delete"();



CREATE OR REPLACE TRIGGER "update_objects_updated_at" BEFORE UPDATE ON "storage"."objects" FOR EACH ROW EXECUTE FUNCTION "storage"."update_updated_at_column"();



ALTER TABLE ONLY "auth"."identities"
    ADD CONSTRAINT "identities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."mfa_amr_claims"
    ADD CONSTRAINT "mfa_amr_claims_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."mfa_challenges"
    ADD CONSTRAINT "mfa_challenges_auth_factor_id_fkey" FOREIGN KEY ("factor_id") REFERENCES "auth"."mfa_factors"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."mfa_factors"
    ADD CONSTRAINT "mfa_factors_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_authorizations"
    ADD CONSTRAINT "oauth_authorizations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "auth"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."oauth_consents"
    ADD CONSTRAINT "oauth_consents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."one_time_tokens"
    ADD CONSTRAINT "one_time_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."refresh_tokens"
    ADD CONSTRAINT "refresh_tokens_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "auth"."sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."saml_providers"
    ADD CONSTRAINT "saml_providers_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."saml_relay_states"
    ADD CONSTRAINT "saml_relay_states_flow_state_id_fkey" FOREIGN KEY ("flow_state_id") REFERENCES "auth"."flow_state"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."saml_relay_states"
    ADD CONSTRAINT "saml_relay_states_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."sessions"
    ADD CONSTRAINT "sessions_oauth_client_id_fkey" FOREIGN KEY ("oauth_client_id") REFERENCES "auth"."oauth_clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."sessions"
    ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."sso_domains"
    ADD CONSTRAINT "sso_domains_sso_provider_id_fkey" FOREIGN KEY ("sso_provider_id") REFERENCES "auth"."sso_providers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."webauthn_challenges"
    ADD CONSTRAINT "webauthn_challenges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "auth"."webauthn_credentials"
    ADD CONSTRAINT "webauthn_credentials_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_audit_log"
    ADD CONSTRAINT "admin_audit_log_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."admin_audit_logs"
    ADD CONSTRAINT "admin_audit_logs_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_courses"
    ADD CONSTRAINT "admin_courses_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_courses"
    ADD CONSTRAINT "admin_courses_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "public"."admin_departments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_departments"
    ADD CONSTRAINT "admin_departments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_lecture_assets"
    ADD CONSTRAINT "admin_lecture_assets_lecture_id_fkey" FOREIGN KEY ("lecture_id") REFERENCES "public"."admin_lectures"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_lecture_assets"
    ADD CONSTRAINT "admin_lecture_assets_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_lectures"
    ADD CONSTRAINT "admin_lectures_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "public"."admin_courses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_lectures"
    ADD CONSTRAINT "admin_lectures_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_lectures"
    ADD CONSTRAINT "admin_lectures_instructor_id_fkey" FOREIGN KEY ("instructor_id") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_notification_reads"
    ADD CONSTRAINT "admin_notification_reads_notification_id_fkey" FOREIGN KEY ("notification_id") REFERENCES "public"."admin_notifications"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_notifications"
    ADD CONSTRAINT "admin_notifications_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_role_permissions"
    ADD CONSTRAINT "admin_role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."admin_permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_role_permissions"
    ADD CONSTRAINT "admin_role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."admin_roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_settings"
    ADD CONSTRAINT "admin_settings_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_support_tickets"
    ADD CONSTRAINT "admin_support_tickets_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_support_tickets"
    ADD CONSTRAINT "admin_support_tickets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_user_roles"
    ADD CONSTRAINT "admin_user_roles_assigned_by_fkey" FOREIGN KEY ("assigned_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."admin_user_roles"
    ADD CONSTRAINT "admin_user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."admin_roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."admin_user_roles"
    ADD CONSTRAINT "admin_user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."admin_users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."ai_messages"
    ADD CONSTRAINT "ai_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."ai_conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."app_comments"
    ADD CONSTRAINT "app_comments_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."app_reposts"
    ADD CONSTRAINT "app_reposts_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."badge_requests"
    ADD CONSTRAINT "badge_requests_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."blocked_profiles"
    ADD CONSTRAINT "blocked_profiles_blocked_profile_id_fkey" FOREIGN KEY ("blocked_profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."blocked_profiles"
    ADD CONSTRAINT "blocked_profiles_blocker_profile_id_fkey" FOREIGN KEY ("blocker_profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_blocked_id_fkey" FOREIGN KEY ("blocked_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."blocked_users"
    ADD CONSTRAINT "blocked_users_blocker_id_fkey" FOREIGN KEY ("blocker_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."capture_attempts"
    ADD CONSTRAINT "capture_attempts_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."comment_likes"
    ADD CONSTRAINT "comment_likes_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."connection_requests"
    ADD CONSTRAINT "connection_requests_receiver_profile_id_fkey" FOREIGN KEY ("receiver_profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."connection_requests"
    ADD CONSTRAINT "connection_requests_requester_profile_id_fkey" FOREIGN KEY ("requester_profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contractor_details"
    ADD CONSTRAINT "contractor_details_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."course_progress"
    ADD CONSTRAINT "course_progress_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "public"."courses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."course_progress"
    ADD CONSTRAINT "course_progress_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."craftsman_details"
    ADD CONSTRAINT "craftsman_details_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."engineer_details"
    ADD CONSTRAINT "engineer_details_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."engineer_notes"
    ADD CONSTRAINT "engineer_notes_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."followers"
    ADD CONSTRAINT "followers_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."followers"
    ADD CONSTRAINT "followers_following_id_fkey" FOREIGN KEY ("following_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."job_requests"
    ADD CONSTRAINT "job_requests_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."machinery_details"
    ADD CONSTRAINT "machinery_details_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."muted_conversations"
    ADD CONSTRAINT "muted_conversations_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."muted_conversations"
    ADD CONSTRAINT "muted_conversations_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payment_history"
    ADD CONSTRAINT "payment_history_subscription_id_fkey" FOREIGN KEY ("subscription_id") REFERENCES "public"."subscriptions"("id");



ALTER TABLE ONLY "public"."post_comments"
    ADD CONSTRAINT "post_comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_comments"
    ADD CONSTRAINT "post_comments_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_likes"
    ADD CONSTRAINT "post_likes_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_reports"
    ADD CONSTRAINT "post_reports_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "public"."posts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_reports"
    ADD CONSTRAINT "post_reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."post_reports"
    ADD CONSTRAINT "post_reports_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."posts"
    ADD CONSTRAINT "posts_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_applications"
    ADD CONSTRAINT "project_applications_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_applications"
    ADD CONSTRAINT "project_applications_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_applications"
    ADD CONSTRAINT "project_applications_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."project_attachments"
    ADD CONSTRAINT "project_attachments_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."project_details"
    ADD CONSTRAINT "project_details_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reel_comments"
    ADD CONSTRAINT "reel_comments_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."reel_comments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reel_comments"
    ADD CONSTRAINT "reel_comments_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reel_comments"
    ADD CONSTRAINT "reel_comments_reel_id_fkey" FOREIGN KEY ("reel_id") REFERENCES "public"."reels"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reel_likes"
    ADD CONSTRAINT "reel_likes_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reel_likes"
    ADD CONSTRAINT "reel_likes_reel_id_fkey" FOREIGN KEY ("reel_id") REFERENCES "public"."reels"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reel_reports"
    ADD CONSTRAINT "reel_reports_reel_id_fkey" FOREIGN KEY ("reel_id") REFERENCES "public"."reels"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reel_reports"
    ADD CONSTRAINT "reel_reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reel_reports"
    ADD CONSTRAINT "reel_reports_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "public"."reel_views"
    ADD CONSTRAINT "reel_views_reel_id_fkey" FOREIGN KEY ("reel_id") REFERENCES "public"."reels"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reel_views"
    ADD CONSTRAINT "reel_views_viewer_profile_id_fkey" FOREIGN KEY ("viewer_profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reels"
    ADD CONSTRAINT "reels_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_reviewed_id_fkey" FOREIGN KEY ("reviewed_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_reviewer_id_fkey" FOREIGN KEY ("reviewer_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."saved_items"
    ADD CONSTRAINT "saved_items_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."saved_reels"
    ADD CONSTRAINT "saved_reels_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."saved_reels"
    ADD CONSTRAINT "saved_reels_reel_id_fkey" FOREIGN KEY ("reel_id") REFERENCES "public"."reels"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."storage_usage"
    ADD CONSTRAINT "storage_usage_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."stories"
    ADD CONSTRAINT "stories_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_comments"
    ADD CONSTRAINT "story_comments_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_comments"
    ADD CONSTRAINT "story_comments_story_id_fkey" FOREIGN KEY ("story_id") REFERENCES "public"."stories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_likes"
    ADD CONSTRAINT "story_likes_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_likes"
    ADD CONSTRAINT "story_likes_story_id_fkey" FOREIGN KEY ("story_id") REFERENCES "public"."stories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_views"
    ADD CONSTRAINT "story_views_story_id_fkey" FOREIGN KEY ("story_id") REFERENCES "public"."stories"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."story_views"
    ADD CONSTRAINT "story_views_viewer_profile_id_fkey" FOREIGN KEY ("viewer_profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reported_id_fkey" FOREIGN KEY ("reported_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "public"."admin_users"("id");



ALTER TABLE ONLY "storage"."objects"
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads"
    ADD CONSTRAINT "s3_multipart_uploads_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
    ADD CONSTRAINT "s3_multipart_uploads_parts_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets"("id");



ALTER TABLE ONLY "storage"."s3_multipart_uploads_parts"
    ADD CONSTRAINT "s3_multipart_uploads_parts_upload_id_fkey" FOREIGN KEY ("upload_id") REFERENCES "storage"."s3_multipart_uploads"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "storage"."vector_indexes"
    ADD CONSTRAINT "vector_indexes_bucket_id_fkey" FOREIGN KEY ("bucket_id") REFERENCES "storage"."buckets_vectors"("id");



ALTER TABLE "auth"."audit_log_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."flow_state" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."identities" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."instances" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."mfa_amr_claims" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."mfa_challenges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."mfa_factors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."one_time_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."refresh_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."saml_providers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."saml_relay_states" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."schema_migrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."sso_domains" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."sso_providers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "auth"."users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Active courses are viewable by authenticated users" ON "public"."courses" FOR SELECT TO "authenticated" USING (("is_active" = true));



CREATE POLICY "Active job requests viewable by everyone" ON "public"."job_requests" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Admin users check status" ON "public"."admin_users" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Admins can delete posts" ON "public"."posts" FOR DELETE USING ("public"."is_admin"());



CREATE POLICY "Admins can delete reels" ON "public"."reels" FOR DELETE USING ("public"."is_admin"());



CREATE POLICY "Admins can manage app_config" ON "public"."app_config" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE ("admin_users"."id" = "auth"."uid"())))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE ("admin_users"."id" = "auth"."uid"()))));



CREATE POLICY "Admins can update badge requests" ON "public"."badge_requests" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE ("admin_users"."id" = "auth"."uid"()))));



CREATE POLICY "Admins can update posts" ON "public"."posts" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "Admins can update profiles" ON "public"."profiles" FOR UPDATE USING ((("id" = "auth"."uid"()) OR (( SELECT "admin_users"."status"
   FROM "public"."admin_users"
  WHERE ("admin_users"."id" = "auth"."uid"())
 LIMIT 1) = 'active'::"public"."admin_status")));



CREATE POLICY "Admins can update reels" ON "public"."reels" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "Admins can update reports" ON "public"."user_reports" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "Admins can update tickets" ON "public"."support_tickets" FOR UPDATE USING ("public"."is_admin"());



CREATE POLICY "Admins can view admin users" ON "public"."admin_users" FOR SELECT TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "Admins can view all payment history" ON "public"."payment_history" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view all posts" ON "public"."posts" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view all reels" ON "public"."reels" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view all reports" ON "public"."user_reports" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view all subscriptions" ON "public"."subscriptions" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view all tickets" ON "public"."support_tickets" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view assets" ON "public"."admin_lecture_assets" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view audit log" ON "public"."admin_audit_log" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE (("admin_users"."id" = "auth"."uid"()) AND ("admin_users"."status" = 'active'::"public"."admin_status")))));



CREATE POLICY "Admins can view audit logs" ON "public"."admin_audit_logs" FOR SELECT USING (("public"."admin_has_permission"('audit:view'::"text") OR "public"."is_super_admin"()));



CREATE POLICY "Admins can view courses" ON "public"."admin_courses" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view departments" ON "public"."admin_departments" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view lectures" ON "public"."admin_lectures" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view notification reads" ON "public"."admin_notification_reads" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view notifications" ON "public"."admin_notifications" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view permissions" ON "public"."admin_permissions" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view role permissions" ON "public"."admin_role_permissions" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view roles" ON "public"."admin_roles" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can view user roles" ON "public"."admin_user_roles" FOR SELECT USING ("public"."is_admin"());



CREATE POLICY "Admins can write admin_settings" ON "public"."admin_settings" USING ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE (("admin_users"."id" = "auth"."uid"()) AND ("admin_users"."status" = 'active'::"public"."admin_status")))));



CREATE POLICY "Admins have full control over checklists" ON "public"."admin_checklist" USING ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE (("admin_users"."id" = "auth"."uid"()) AND ("admin_users"."status" = 'active'::"public"."admin_status")))));



CREATE POLICY "Admins have full control over faqs" ON "public"."admin_faq" USING ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE (("admin_users"."id" = "auth"."uid"()) AND ("admin_users"."status" = 'active'::"public"."admin_status")))));



CREATE POLICY "Admins have full control over legal sections" ON "public"."admin_legal_sections" USING ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE (("admin_users"."id" = "auth"."uid"()) AND ("admin_users"."status" = 'active'::"public"."admin_status")))));



CREATE POLICY "Admins have full control over tickets" ON "public"."admin_support_tickets" USING ((EXISTS ( SELECT 1
   FROM "public"."admin_users"
  WHERE (("admin_users"."id" = "auth"."uid"()) AND ("admin_users"."status" = 'active'::"public"."admin_status")))));



CREATE POLICY "Anyone can read app_config" ON "public"."app_config" FOR SELECT USING (true);



CREATE POLICY "Anyone can view active checklists" ON "public"."admin_checklist" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Anyone can view active faqs" ON "public"."admin_faq" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Anyone can view active legal sections" ON "public"."admin_legal_sections" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Anyone can view reel views" ON "public"."reel_views" FOR SELECT USING (true);



CREATE POLICY "Applicants can create pending applications" ON "public"."project_applications" FOR INSERT WITH CHECK ((("status" = 'pending'::"text") AND (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "project_applications"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Applicants can read their own applications" ON "public"."project_applications" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "project_applications"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Applicants can withdraw their applications" ON "public"."project_applications" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "project_applications"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((("status" = ANY (ARRAY['pending'::"text", 'withdrawn'::"text"])) AND (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "project_applications"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Attachments viewable by everyone" ON "public"."project_attachments" FOR SELECT USING (true);



CREATE POLICY "Authenticated users can insert their own views" ON "public"."reel_views" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reel_views"."viewer_profile_id"))));



CREATE POLICY "Authenticated users can mark notifications read" ON "public"."admin_notification_reads" FOR INSERT WITH CHECK ((("auth"."uid"() IS NOT NULL) AND ("user_id" = "auth"."uid"())));



CREATE POLICY "Authenticated users create notifications" ON "public"."notifications" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Block direct notification inserts" ON "public"."notifications" FOR INSERT TO "authenticated" WITH CHECK (false);



CREATE POLICY "Comment likes are viewable by everyone" ON "public"."comment_likes" FOR SELECT USING (true);



CREATE POLICY "Comments are readable" ON "public"."app_comments" FOR SELECT USING (true);



CREATE POLICY "Connection participants can see requests" ON "public"."connection_requests" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."user_id" = "auth"."uid"()) AND ("p"."id" = ANY (ARRAY["connection_requests"."requester_profile_id", "connection_requests"."receiver_profile_id"]))))));



CREATE POLICY "Content managers can manage courses" ON "public"."admin_courses" USING (("public"."admin_has_permission"('courses:manage'::"text") OR "public"."is_super_admin"()));



CREATE POLICY "Content managers can manage departments" ON "public"."admin_departments" USING (("public"."admin_has_permission"('departments:manage'::"text") OR "public"."is_super_admin"()));



CREATE POLICY "Conversation participants can read" ON "public"."conversations" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."user_id" = "auth"."uid"()) AND ("p"."id" = ANY (ARRAY["conversations"."participant_one", "conversations"."participant_two"]))))));



CREATE POLICY "Conversation participants can read messages" ON "public"."messages" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."conversations" "c"
     JOIN "public"."profiles" "p" ON ((("p"."id" = "c"."participant_one") OR ("p"."id" = "c"."participant_two"))))
  WHERE (("c"."id" = "messages"."conversation_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Conversation participants delete" ON "public"."conversations" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."user_id" = "auth"."uid"()) AND ("p"."id" = ANY (ARRAY["conversations"."participant_one", "conversations"."participant_two"]))))));



CREATE POLICY "Conversation participants delete messages" ON "public"."messages" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."conversations" "c"
     JOIN "public"."profiles" "p" ON ((("p"."id" = "c"."participant_one") OR ("p"."id" = "c"."participant_two"))))
  WHERE (("c"."id" = "messages"."conversation_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Conversation participants send messages" ON "public"."messages" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."conversations" "c"
     JOIN "public"."profiles" "p" ON (("p"."id" = "messages"."sender_id")))
  WHERE (("c"."id" = "messages"."conversation_id") AND ("p"."user_id" = "auth"."uid"()) AND (("messages"."sender_id" = "c"."participant_one") OR ("messages"."sender_id" = "c"."participant_two"))))));



CREATE POLICY "Conversation participants update messages" ON "public"."messages" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."conversations" "c"
     JOIN "public"."profiles" "p" ON ((("p"."id" = "c"."participant_one") OR ("p"."id" = "c"."participant_two"))))
  WHERE (("c"."id" = "messages"."conversation_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."conversations" "c"
     JOIN "public"."profiles" "p" ON ((("p"."id" = "c"."participant_one") OR ("p"."id" = "c"."participant_two"))))
  WHERE (("c"."id" = "messages"."conversation_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Deny anonymous access to admin_users" ON "public"."admin_users" TO "anon" USING (false) WITH CHECK (false);



CREATE POLICY "Deny anonymous access to subscriptions" ON "public"."subscriptions" FOR SELECT TO "anon" USING (false);



CREATE POLICY "Engineers can view own details" ON "public"."engineer_details" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Everyone can read admin_settings" ON "public"."admin_settings" FOR SELECT USING (true);



CREATE POLICY "Followers are viewable by authenticated users" ON "public"."followers" FOR SELECT TO "authenticated" USING (true);



COMMENT ON POLICY "Followers are viewable by authenticated users" ON "public"."followers" IS 'Restricts follower relationship visibility to authenticated users only, preventing anonymous scraping of user social connections.';



CREATE POLICY "No client access to otp_verifications" ON "public"."otp_verifications" TO "authenticated", "anon" USING (false) WITH CHECK (false);



CREATE POLICY "Non-admins cannot access admin_users" ON "public"."admin_users" FOR SELECT TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "Only admins can view audit logs" ON "public"."admin_audit_logs" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"public"."user_role")))));



CREATE POLICY "Post comments are viewable by everyone" ON "public"."post_comments" FOR SELECT USING (true);



CREATE POLICY "Post likes are viewable by everyone" ON "public"."post_likes" FOR SELECT USING (true);



CREATE POLICY "Posts are publicly readable" ON "public"."posts" FOR SELECT USING (true);



CREATE POLICY "Posts are viewable by everyone" ON "public"."posts" FOR SELECT USING (true);



CREATE POLICY "Posts viewable - active for all, all for owner" ON "public"."posts" FOR SELECT USING ((((("is_archived" = false) OR ("is_archived" IS NULL)) AND ("is_active" = true)) OR ("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))));



CREATE POLICY "Profiles are publicly readable" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "Project details are publicly readable" ON "public"."project_details" FOR SELECT USING (true);



CREATE POLICY "Project owners can manage attachments" ON "public"."project_attachments" USING (("project_id" IN ( SELECT "projects"."id"
   FROM "public"."projects"
  WHERE ("projects"."profile_id" IN ( SELECT "profiles"."id"
           FROM "public"."profiles"
          WHERE ("profiles"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Project owners can manage details" ON "public"."project_details" USING ((EXISTS ( SELECT 1
   FROM ("public"."projects" "p"
     JOIN "public"."profiles" "pr" ON (("pr"."id" = "p"."profile_id")))
  WHERE (("p"."id" = "project_details"."project_id") AND ("pr"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."projects" "p"
     JOIN "public"."profiles" "pr" ON (("pr"."id" = "p"."profile_id")))
  WHERE (("p"."id" = "project_details"."project_id") AND ("pr"."user_id" = "auth"."uid"())))));



CREATE POLICY "Project owners can read applications" ON "public"."project_applications" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."projects" "pr"
     JOIN "public"."profiles" "owner" ON (("owner"."id" = "pr"."profile_id")))
  WHERE (("pr"."id" = "project_applications"."project_id") AND ("owner"."user_id" = "auth"."uid"())))));



CREATE POLICY "Project owners can update application status" ON "public"."project_applications" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM ("public"."projects" "pr"
     JOIN "public"."profiles" "owner" ON (("owner"."id" = "pr"."profile_id")))
  WHERE (("pr"."id" = "project_applications"."project_id") AND ("owner"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."projects" "pr"
     JOIN "public"."profiles" "owner" ON (("owner"."id" = "pr"."profile_id")))
  WHERE (("pr"."id" = "project_applications"."project_id") AND ("owner"."user_id" = "auth"."uid"())))));



CREATE POLICY "Projects viewable by everyone" ON "public"."projects" FOR SELECT USING (true);



CREATE POLICY "Public can read subscriptions" ON "public"."subscriptions" FOR SELECT USING (true);



CREATE POLICY "Public read contractor_details" ON "public"."contractor_details" FOR SELECT USING (true);



CREATE POLICY "Public read craftsman_details" ON "public"."craftsman_details" FOR SELECT USING (true);



CREATE POLICY "Public read engineer_details" ON "public"."engineer_details" FOR SELECT USING (true);



CREATE POLICY "Public read machinery_details" ON "public"."machinery_details" FOR SELECT USING (true);



CREATE POLICY "Receivers can answer connection requests" ON "public"."connection_requests" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "connection_requests"."receiver_profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "connection_requests"."receiver_profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Reel comments are viewable by everyone" ON "public"."reel_comments" FOR SELECT USING (true);



CREATE POLICY "Reel likes are viewable by everyone" ON "public"."reel_likes" FOR SELECT USING (true);



CREATE POLICY "Reels are publicly readable" ON "public"."reels" FOR SELECT USING (true);



CREATE POLICY "Reels are viewable by everyone" ON "public"."reels" FOR SELECT USING (true);



CREATE POLICY "Reviews are viewable by everyone" ON "public"."reviews" FOR SELECT USING (true);



CREATE POLICY "Stories are publicly readable" ON "public"."stories" FOR SELECT USING (true);



CREATE POLICY "Stories are viewable by everyone" ON "public"."stories" FOR SELECT USING (true);



CREATE POLICY "Stories viewable - active for all, all for owner" ON "public"."stories" FOR SELECT USING ((((("is_archived" = false) OR ("is_archived" IS NULL)) AND ("expires_at" > "now"())) OR ("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))));



CREATE POLICY "Story comments are viewable by everyone" ON "public"."story_comments" FOR SELECT USING (true);



CREATE POLICY "Story likes are viewable by everyone" ON "public"."story_likes" FOR SELECT USING (true);



CREATE POLICY "Story views are viewable by story owner" ON "public"."story_views" FOR SELECT USING (("story_id" IN ( SELECT "stories"."id"
   FROM "public"."stories"
  WHERE ("stories"."profile_id" IN ( SELECT "profiles"."id"
           FROM "public"."profiles"
          WHERE ("profiles"."user_id" = "auth"."uid"()))))));



CREATE POLICY "Super admins can delete admin users" ON "public"."admin_users" FOR DELETE TO "authenticated" USING ("public"."is_super_admin"());



CREATE POLICY "Super admins can delete assets" ON "public"."admin_lecture_assets" FOR DELETE USING (("public"."is_super_admin"() OR ("uploaded_by" = "public"."get_admin_user_id"())));



CREATE POLICY "Super admins can do everything" ON "public"."admin_users" USING ("public"."is_super_admin"());



CREATE POLICY "Super admins can insert admin users" ON "public"."admin_users" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_super_admin"());



CREATE POLICY "Super admins can manage permissions" ON "public"."admin_permissions" USING ("public"."is_super_admin"());



CREATE POLICY "Super admins can manage role permissions" ON "public"."admin_role_permissions" USING ("public"."is_super_admin"());



CREATE POLICY "Super admins can manage roles" ON "public"."admin_roles" USING ("public"."is_super_admin"());



CREATE POLICY "Super admins can manage user roles" ON "public"."admin_user_roles" USING ("public"."is_super_admin"());



CREATE POLICY "Super admins can update admin users" ON "public"."admin_users" FOR UPDATE TO "authenticated" USING (("public"."is_super_admin"() OR ("id" = "public"."get_admin_user_id"()))) WITH CHECK (("public"."is_super_admin"() OR ("id" = "public"."get_admin_user_id"())));



CREATE POLICY "Super admins can update assets" ON "public"."admin_lecture_assets" FOR UPDATE USING (("public"."is_super_admin"() OR ("uploaded_by" = "public"."get_admin_user_id"())));



CREATE POLICY "System can insert audit logs" ON "public"."admin_audit_logs" FOR INSERT WITH CHECK (true);



CREATE POLICY "System can insert audit logs via function" ON "public"."admin_audit_logs" FOR INSERT WITH CHECK ("public"."is_admin"());



CREATE POLICY "Users can block others" ON "public"."blocked_users" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "blocked_users"."blocker_id"))));



CREATE POLICY "Users can comment on posts" ON "public"."post_comments" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "post_comments"."profile_id"))));



CREATE POLICY "Users can comment on reels" ON "public"."reel_comments" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reel_comments"."profile_id"))));



CREATE POLICY "Users can create AI messages" ON "public"."ai_messages" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create badge requests" ON "public"."badge_requests" FOR INSERT WITH CHECK (("auth"."uid"() = "profile_id"));



CREATE POLICY "Users can create comments" ON "public"."story_comments" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create conversations" ON "public"."conversations" FOR INSERT WITH CHECK ((("participant_one" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))) OR ("participant_two" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can create own projects" ON "public"."projects" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create reports" ON "public"."user_reports" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "user_reports"."reporter_id"))));



CREATE POLICY "Users can create reviews" ON "public"."reviews" FOR INSERT WITH CHECK (("reviewer_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create story views" ON "public"."story_views" FOR INSERT WITH CHECK (("viewer_profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create support tickets" ON "public"."support_tickets" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create their own conversations" ON "public"."ai_conversations" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create their own notes" ON "public"."engineer_notes" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create their own reels" ON "public"."reels" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reels"."profile_id"))));



CREATE POLICY "Users can create their own reports" ON "public"."reel_reports" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reel_reports"."reporter_id"))));



CREATE POLICY "Users can create their own stories" ON "public"."stories" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create their own subscription" ON "public"."subscriptions" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can create their own tickets" ON "public"."admin_support_tickets" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can delete AI messages" ON "public"."ai_messages" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete own notifications" ON "public"."notifications" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete own posts or admins" ON "public"."posts" FOR DELETE USING ((("auth"."uid"() = "profile_id") OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "Users can delete own projects" ON "public"."projects" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete own reels or admins" ON "public"."reels" FOR DELETE USING ((("auth"."uid"() = "profile_id") OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "Users can delete own reviews" ON "public"."reviews" FOR DELETE USING (("reviewer_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete own stories or admins" ON "public"."stories" FOR DELETE USING ((("auth"."uid"() = "profile_id") OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'admin'::"public"."user_role"))))));



CREATE POLICY "Users can delete their conversations" ON "public"."conversations" FOR DELETE USING ((("participant_one" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))) OR ("participant_two" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can delete their own comments" ON "public"."reel_comments" FOR DELETE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reel_comments"."profile_id"))));



CREATE POLICY "Users can delete their own comments" ON "public"."story_comments" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete their own conversations" ON "public"."ai_conversations" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete their own device tokens" ON "public"."device_tokens" FOR DELETE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete their own messages" ON "public"."messages" FOR DELETE USING (("sender_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete their own notes" ON "public"."engineer_notes" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can delete their own post comments" ON "public"."post_comments" FOR DELETE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "post_comments"."profile_id"))));



CREATE POLICY "Users can delete their own reels" ON "public"."reels" FOR DELETE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reels"."profile_id"))));



CREATE POLICY "Users can delete their own stories" ON "public"."stories" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can follow others" ON "public"."followers" FOR INSERT WITH CHECK (("follower_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can insert own posts" ON "public"."posts" FOR INSERT WITH CHECK (("auth"."uid"() = "profile_id"));



CREATE POLICY "Users can insert own reels" ON "public"."reels" FOR INSERT WITH CHECK (("auth"."uid"() = "profile_id"));



CREATE POLICY "Users can insert own stories" ON "public"."stories" FOR INSERT WITH CHECK (("auth"."uid"() = "profile_id"));



CREATE POLICY "Users can insert their own course progress" ON "public"."course_progress" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can insert their own device tokens" ON "public"."device_tokens" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can like comments" ON "public"."comment_likes" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "comment_likes"."profile_id"))));



CREATE POLICY "Users can like posts" ON "public"."post_likes" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "post_likes"."profile_id"))));



CREATE POLICY "Users can like reels" ON "public"."reel_likes" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reel_likes"."profile_id"))));



CREATE POLICY "Users can like stories" ON "public"."story_likes" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can log their own capture attempts" ON "public"."capture_attempts" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can manage own contractor details" ON "public"."contractor_details" TO "authenticated" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))) WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can manage own craftsman details" ON "public"."craftsman_details" TO "authenticated" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))) WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can manage own engineer details" ON "public"."engineer_details" TO "authenticated" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))) WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can manage own job requests" ON "public"."job_requests" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can manage own machinery details" ON "public"."machinery_details" TO "authenticated" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))) WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can manage own posts" ON "public"."posts" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can mute conversations" ON "public"."muted_conversations" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "muted_conversations"."profile_id"))));



CREATE POLICY "Users can save reels" ON "public"."saved_reels" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can send messages" ON "public"."messages" FOR INSERT WITH CHECK (("sender_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can unblock others" ON "public"."blocked_users" FOR DELETE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "blocked_users"."blocker_id"))));



CREATE POLICY "Users can unfollow" ON "public"."followers" FOR DELETE USING (("follower_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can unlike comments" ON "public"."comment_likes" FOR DELETE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "comment_likes"."profile_id"))));



CREATE POLICY "Users can unlike posts" ON "public"."post_likes" FOR DELETE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "post_likes"."profile_id"))));



CREATE POLICY "Users can unlike reels" ON "public"."reel_likes" FOR DELETE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reel_likes"."profile_id"))));



CREATE POLICY "Users can unlike stories" ON "public"."story_likes" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can unmute conversations" ON "public"."muted_conversations" FOR DELETE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "muted_conversations"."profile_id"))));



CREATE POLICY "Users can unsave reels" ON "public"."saved_reels" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update AI messages" ON "public"."ai_messages" FOR UPDATE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update own notifications" ON "public"."notifications" FOR UPDATE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update own projects" ON "public"."projects" FOR UPDATE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update own reviews" ON "public"."reviews" FOR UPDATE USING (("reviewer_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update their conversations" ON "public"."conversations" FOR UPDATE USING ((("participant_one" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))) OR ("participant_two" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users can update their messages" ON "public"."messages" FOR UPDATE USING (("sender_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update their own comments" ON "public"."reel_comments" FOR UPDATE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reel_comments"."profile_id"))));



CREATE POLICY "Users can update their own conversations" ON "public"."ai_conversations" FOR UPDATE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update their own course progress" ON "public"."course_progress" FOR UPDATE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update their own device tokens" ON "public"."device_tokens" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their own notes" ON "public"."engineer_notes" FOR UPDATE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update their own post comments" ON "public"."post_comments" FOR UPDATE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "post_comments"."profile_id"))));



CREATE POLICY "Users can update their own reels" ON "public"."reels" FOR UPDATE USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reels"."profile_id"))));



CREATE POLICY "Users can update their own stories" ON "public"."stories" FOR UPDATE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can update their own subscription" ON "public"."subscriptions" FOR UPDATE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view if allowed" ON "public"."profiles" FOR SELECT USING ("public"."check_permission"("auth"."uid"(), 'view_dashboard'::"text"));



CREATE POLICY "Users can view messages in their conversations" ON "public"."messages" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."conversations" "c"
  WHERE (("c"."id" = "messages"."conversation_id") AND (("c"."participant_one" IN ( SELECT "profiles"."id"
           FROM "public"."profiles"
          WHERE ("profiles"."user_id" = "auth"."uid"()))) OR ("c"."participant_two" IN ( SELECT "profiles"."id"
           FROM "public"."profiles"
          WHERE ("profiles"."user_id" = "auth"."uid"())))) AND (NOT (EXISTS ( SELECT 1
           FROM "public"."blocked_users" "bu"
          WHERE ((("bu"."blocker_id" = "c"."participant_one") AND ("bu"."blocked_id" = "c"."participant_two")) OR (("bu"."blocker_id" = "c"."participant_two") AND ("bu"."blocked_id" = "c"."participant_one"))))))))));



CREATE POLICY "Users can view own data" ON "public"."admin_users" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view own notifications" ON "public"."notifications" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view own tickets" ON "public"."support_tickets" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their AI messages" ON "public"."ai_messages" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their blocked list" ON "public"."blocked_users" FOR SELECT USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "blocked_users"."blocker_id"))));



CREATE POLICY "Users can view their conversations" ON "public"."conversations" FOR SELECT TO "authenticated" USING ((("auth"."uid"() IS NOT NULL) AND (("participant_one" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))) OR ("participant_two" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"())))) AND (NOT (EXISTS ( SELECT 1
   FROM "public"."blocked_users" "bu"
  WHERE ((("bu"."blocker_id" = "conversations"."participant_one") AND ("bu"."blocked_id" = "conversations"."participant_two")) OR (("bu"."blocker_id" = "conversations"."participant_two") AND ("bu"."blocked_id" = "conversations"."participant_one"))))))));



CREATE POLICY "Users can view their own badge requests" ON "public"."badge_requests" FOR SELECT USING (("auth"."uid"() = "profile_id"));



CREATE POLICY "Users can view their own capture attempts" ON "public"."capture_attempts" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own contractor details" ON "public"."contractor_details" FOR SELECT TO "authenticated" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own conversations" ON "public"."ai_conversations" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own course progress" ON "public"."course_progress" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own craftsman details" ON "public"."craftsman_details" FOR SELECT TO "authenticated" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own device tokens" ON "public"."device_tokens" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view their own engineer details" ON "public"."engineer_details" FOR SELECT TO "authenticated" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own machinery details" ON "public"."machinery_details" FOR SELECT TO "authenticated" USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own muted conversations" ON "public"."muted_conversations" FOR SELECT USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "muted_conversations"."profile_id"))));



CREATE POLICY "Users can view their own notes" ON "public"."engineer_notes" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own payment history" ON "public"."payment_history" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own reports" ON "public"."reel_reports" FOR SELECT USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reel_reports"."reporter_id"))));



CREATE POLICY "Users can view their own reports" ON "public"."user_reports" FOR SELECT USING (("auth"."uid"() = ( SELECT "profiles"."user_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "user_reports"."reporter_id"))));



CREATE POLICY "Users can view their own subscription" ON "public"."subscriptions" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users can view their own tickets" ON "public"."admin_support_tickets" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users can view their saved reels" ON "public"."saved_reels" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Users create outgoing connection requests" ON "public"."connection_requests" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "connection_requests"."requester_profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users create own comments" ON "public"."app_comments" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "app_comments"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users create own conversations" ON "public"."conversations" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."user_id" = "auth"."uid"()) AND ("p"."id" = ANY (ARRAY["conversations"."participant_one", "conversations"."participant_two"]))))));



CREATE POLICY "Users create their own post reports" ON "public"."post_reports" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "post_reports"."reporter_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users create their own profile" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users delete own notifications" ON "public"."notifications" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "notifications"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users delete their own profile" ON "public"."profiles" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "Users manage own blocks" ON "public"."blocked_profiles" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "blocked_profiles"."blocker_profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "blocked_profiles"."blocker_profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own contractor_details" ON "public"."contractor_details" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "contractor_details"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "contractor_details"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own craftsman_details" ON "public"."craftsman_details" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "craftsman_details"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "craftsman_details"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own engineer_details" ON "public"."engineer_details" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "engineer_details"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "engineer_details"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own machinery_details" ON "public"."machinery_details" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "machinery_details"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "machinery_details"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own notifications" ON "public"."notifications" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "notifications"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "notifications"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own reels" ON "public"."reels" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "reels"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "reels"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage own reposts" ON "public"."app_reposts" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "app_reposts"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "app_reposts"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage their own posts" ON "public"."posts" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "posts"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "posts"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage their own saved items" ON "public"."saved_items" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "saved_items"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "saved_items"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users manage their own stories" ON "public"."stories" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "stories"."profile_id") AND ("p"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "stories"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users read own notifications" ON "public"."notifications" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "notifications"."profile_id") AND ("p"."user_id" = "auth"."uid"())))));



CREATE POLICY "Users update their own profile" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "Users with lecture permissions can delete" ON "public"."admin_lectures" FOR DELETE USING (("public"."admin_has_permission"('lectures:delete'::"text") OR "public"."is_super_admin"()));



CREATE POLICY "Users with lecture permissions can manage" ON "public"."admin_lectures" FOR INSERT WITH CHECK (("public"."admin_has_permission"('lectures:create'::"text") OR "public"."is_super_admin"()));



CREATE POLICY "Users with lecture permissions can update" ON "public"."admin_lectures" FOR UPDATE USING (("public"."admin_has_permission"('lectures:update'::"text") OR "public"."is_super_admin"() OR ("instructor_id" = "public"."get_admin_user_id"())));



CREATE POLICY "Users with notification permission can manage" ON "public"."admin_notifications" USING (("public"."admin_has_permission"('notifications:send'::"text") OR "public"."is_super_admin"()));



CREATE POLICY "Users with upload permission can insert" ON "public"."admin_lecture_assets" FOR INSERT WITH CHECK (("public"."admin_has_permission"('lectures:upload'::"text") OR "public"."is_super_admin"()));



ALTER TABLE "public"."admin_audit_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_audit_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_audit_logs_select" ON "public"."admin_audit_logs" FOR SELECT USING ((("auth"."role"() = 'authenticated'::"text") AND "public"."check_is_admin"("auth"."uid"())));



CREATE POLICY "admin_audit_logs_write" ON "public"."admin_audit_logs" USING ("public"."check_is_admin"("auth"."uid"())) WITH CHECK ("public"."check_is_admin"("auth"."uid"()));



ALTER TABLE "public"."admin_checklist" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_courses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_departments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_faq" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_lecture_assets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_lectures" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_legal_sections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_notification_reads" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_role_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_roles_select" ON "public"."admin_roles" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "admin_roles_write" ON "public"."admin_roles" USING ("public"."check_is_admin"("auth"."uid"())) WITH CHECK ("public"."check_is_admin"("auth"."uid"()));



ALTER TABLE "public"."admin_settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_settings_read" ON "public"."admin_settings" FOR SELECT USING (true);



CREATE POLICY "admin_settings_select" ON "public"."admin_settings" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "admin_settings_write" ON "public"."admin_settings" USING ("public"."check_is_admin"("auth"."uid"())) WITH CHECK ("public"."check_is_admin"("auth"."uid"()));



ALTER TABLE "public"."admin_support_tickets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."admin_user_roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_user_roles_select" ON "public"."admin_user_roles" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "admin_user_roles_write" ON "public"."admin_user_roles" USING ("public"."check_is_admin"("auth"."uid"())) WITH CHECK ("public"."check_is_admin"("auth"."uid"()));



ALTER TABLE "public"."admin_users" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "admin_users_select" ON "public"."admin_users" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "admin_users_write" ON "public"."admin_users" USING ("public"."check_is_admin"("auth"."uid"())) WITH CHECK ("public"."check_is_admin"("auth"."uid"()));



ALTER TABLE "public"."ai_conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."ai_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_reposts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "authenticated_read_admin_users" ON "public"."admin_users" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."automation_rules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."badge_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."blocked_profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."blocked_users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."capture_attempts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."comment_likes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."connection_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contractor_details" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."course_progress" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."courses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."craftsman_details" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."device_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."engineer_details" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."engineer_notes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."followers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."job_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."machinery_details" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."muted_conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."otp_verifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."payment_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."post_comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."post_likes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."post_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."posts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."processed_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_select" ON "public"."profiles" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "profiles_select_own" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "profiles_write" ON "public"."profiles" USING ((("auth"."uid"() = "id") OR "public"."check_is_admin"("auth"."uid"()))) WITH CHECK ((("auth"."uid"() = "id") OR "public"."check_is_admin"("auth"."uid"())));



ALTER TABLE "public"."project_applications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."project_attachments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."project_details" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."projects" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."rate_limits" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reel_comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reel_likes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reel_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reel_views" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reels" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reviews" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."role_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."saved_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."saved_reels" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."storage_usage" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."stories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."story_comments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."story_likes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."story_views" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "subscriptions_select" ON "public"."subscriptions" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "subscriptions_write" ON "public"."subscriptions" USING ("public"."check_is_admin"("auth"."uid"())) WITH CHECK ("public"."check_is_admin"("auth"."uid"()));



ALTER TABLE "public"."support_tickets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."system_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "system_logs_select" ON "public"."system_logs" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "system_logs_write" ON "public"."system_logs" USING ("public"."check_is_admin"("auth"."uid"())) WITH CHECK ("public"."check_is_admin"("auth"."uid"()));



ALTER TABLE "public"."system_status" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_reports" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_delete_own_usage" ON "public"."storage_usage" FOR DELETE USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "users_insert_own_usage" ON "public"."storage_usage" FOR INSERT WITH CHECK (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "users_view_own_usage" ON "public"."storage_usage" FOR SELECT USING (("profile_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."user_id" = "auth"."uid"()))));



CREATE POLICY "Admins can delete lecture assets" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'lecture-assets'::"text") AND "public"."admin_has_permission"('lectures:delete'::"text")));



CREATE POLICY "Admins can update lecture assets" ON "storage"."objects" FOR UPDATE USING ((("bucket_id" = 'lecture-assets'::"text") AND "public"."admin_has_permission"('lectures:upload'::"text")));



CREATE POLICY "Admins can upload lecture assets" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'lecture-assets'::"text") AND "public"."admin_has_permission"('lectures:upload'::"text")));



CREATE POLICY "Admins can view lecture assets" ON "storage"."objects" FOR SELECT USING ((("bucket_id" = 'lecture-assets'::"text") AND "public"."is_admin"()));



CREATE POLICY "Anyone can view project attachments" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'project-attachments'::"text"));



CREATE POLICY "Anyone can view stories files" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'stories'::"text"));



CREATE POLICY "Authenticated users can upload project attachments" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'project-attachments'::"text") AND ("auth"."role"() = 'authenticated'::"text")));



CREATE POLICY "Avatar images are publicly accessible" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'avatars'::"text"));



CREATE POLICY "Chat images are publicly accessible" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'chat-images'::"text"));



CREATE POLICY "Story images are publicly accessible" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'stories'::"text"));



CREATE POLICY "Users can delete own chat images" ON "storage"."objects" FOR DELETE TO "authenticated" USING ((("bucket_id" = 'chat-images'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can delete own files in stories" ON "storage"."objects" FOR DELETE TO "authenticated" USING ((("bucket_id" = 'stories'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "Users can delete their own avatar" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'avatars'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can delete their own project attachments" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'project-attachments'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can delete their own story images" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'stories'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can delete their own voice messages" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'voice-messages'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can update own files in stories" ON "storage"."objects" FOR UPDATE TO "authenticated" USING ((("bucket_id" = 'stories'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "Users can update their own avatar" ON "storage"."objects" FOR UPDATE USING ((("bucket_id" = 'avatars'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can update their own project attachments" ON "storage"."objects" FOR UPDATE USING ((("bucket_id" = 'project-attachments'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can upload chat images" ON "storage"."objects" FOR INSERT TO "authenticated" WITH CHECK ((("bucket_id" = 'chat-images'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can upload their own avatar" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'avatars'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can upload their own story images" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'stories'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can upload their own voice messages" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'voice-messages'::"text") AND (("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1])));



CREATE POLICY "Users can upload to own folder in stories" ON "storage"."objects" FOR INSERT TO "authenticated" WITH CHECK ((("bucket_id" = 'stories'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "avatars_auth_insert" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'avatars'::"text") AND ("auth"."uid"() IS NOT NULL) AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "avatars_owner_delete" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'avatars'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "avatars_owner_update" ON "storage"."objects" FOR UPDATE USING ((("bucket_id" = 'avatars'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "avatars_public_read" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'avatars'::"text"));



ALTER TABLE "storage"."buckets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."buckets_analytics" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."buckets_vectors" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "chat_media_auth_insert" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'chat-media'::"text") AND ("auth"."uid"() IS NOT NULL)));



CREATE POLICY "chat_media_owner_delete" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'chat-media'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "chat_media_participant_read" ON "storage"."objects" FOR SELECT USING ((("bucket_id" = 'chat-media'::"text") AND ("auth"."uid"() IS NOT NULL) AND ((("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text") OR (EXISTS ( SELECT 1
   FROM (("public"."conversations" "c"
     JOIN "public"."profiles" "p" ON (("p"."user_id" = "auth"."uid"())))
     JOIN "public"."messages" "m" ON (("m"."conversation_id" = "c"."id")))
  WHERE ((("c"."participant_one" = "p"."id") OR ("c"."participant_two" = "p"."id")) AND (("m"."image_url" ~~ (('%'::"text" || "objects"."name") || '%'::"text")) OR ("m"."audio_url" ~~ (('%'::"text" || "objects"."name") || '%'::"text")))))))));



CREATE POLICY "covers_auth_insert" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'covers'::"text") AND ("auth"."uid"() IS NOT NULL) AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "covers_owner_delete" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'covers'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "covers_owner_update" ON "storage"."objects" FOR UPDATE USING ((("bucket_id" = 'covers'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "covers_public_read" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'covers'::"text"));



CREATE POLICY "documents_owner_all" ON "storage"."objects" USING ((("bucket_id" = 'documents'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



ALTER TABLE "storage"."migrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."objects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "posts_auth_insert" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'posts'::"text") AND ("auth"."uid"() IS NOT NULL) AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "posts_owner_delete" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'posts'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "posts_owner_update" ON "storage"."objects" FOR UPDATE USING ((("bucket_id" = 'posts'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "posts_public_read" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'posts'::"text"));



CREATE POLICY "reels_auth_insert" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'reels'::"text") AND ("auth"."uid"() IS NOT NULL) AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "reels_owner_delete" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'reels'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "reels_owner_update" ON "storage"."objects" FOR UPDATE USING ((("bucket_id" = 'reels'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "reels_public_read" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'reels'::"text"));



ALTER TABLE "storage"."s3_multipart_uploads" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "storage"."s3_multipart_uploads_parts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "stories_auth_insert" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'stories'::"text") AND ("auth"."uid"() IS NOT NULL) AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "stories_owner_delete" ON "storage"."objects" FOR DELETE USING ((("bucket_id" = 'stories'::"text") AND (("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text")));



CREATE POLICY "stories_public_read" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'stories'::"text"));



ALTER TABLE "storage"."vector_indexes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "voice_auth_insert" ON "storage"."objects" FOR INSERT WITH CHECK ((("bucket_id" = 'voice-messages'::"text") AND ("auth"."uid"() IS NOT NULL)));



CREATE POLICY "voice_messages_participant_read" ON "storage"."objects" FOR SELECT USING ((("bucket_id" = 'voice-messages'::"text") AND ("auth"."uid"() IS NOT NULL) AND ((("storage"."foldername"("name"))[1] = ("auth"."uid"())::"text") OR (EXISTS ( SELECT 1
   FROM (("public"."conversations" "c"
     JOIN "public"."profiles" "p" ON (("p"."user_id" = "auth"."uid"())))
     JOIN "public"."messages" "m" ON (("m"."conversation_id" = "c"."id")))
  WHERE ((("c"."participant_one" = "p"."id") OR ("c"."participant_two" = "p"."id")) AND ("m"."image_url" ~~ (('%'::"text" || "storage"."filename"("objects"."name")) || '%'::"text"))))))));



CREATE POLICY "voice_public_read" ON "storage"."objects" FOR SELECT USING (("bucket_id" = 'voice-messages'::"text"));



GRANT USAGE ON SCHEMA "auth" TO "anon";
GRANT USAGE ON SCHEMA "auth" TO "authenticated";
GRANT USAGE ON SCHEMA "auth" TO "service_role";
GRANT ALL ON SCHEMA "auth" TO "supabase_auth_admin";
GRANT ALL ON SCHEMA "auth" TO "dashboard_user";
GRANT USAGE ON SCHEMA "auth" TO "postgres";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT USAGE ON SCHEMA "storage" TO "postgres" WITH GRANT OPTION;
GRANT USAGE ON SCHEMA "storage" TO "anon";
GRANT USAGE ON SCHEMA "storage" TO "authenticated";
GRANT USAGE ON SCHEMA "storage" TO "service_role";
GRANT ALL ON SCHEMA "storage" TO "supabase_storage_admin" WITH GRANT OPTION;
GRANT ALL ON SCHEMA "storage" TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."email"() TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."jwt"() TO "postgres";
GRANT ALL ON FUNCTION "auth"."jwt"() TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."role"() TO "dashboard_user";



GRANT ALL ON FUNCTION "auth"."uid"() TO "dashboard_user";



GRANT ALL ON FUNCTION "public"."activate_subscription_p"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."activate_subscription_p"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."activate_subscription_p"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_has_permission"("p_permission_key" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_has_permission"("p_permission_key" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_has_permission"("p_permission_key" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_has_role"("p_role" "public"."admin_role") TO "anon";
GRANT ALL ON FUNCTION "public"."admin_has_role"("p_role" "public"."admin_role") TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_has_role"("p_role" "public"."admin_role") TO "service_role";



GRANT ALL ON FUNCTION "public"."app_can_post_projects"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."app_can_post_projects"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_can_post_projects"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."app_current_profile_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_current_profile_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_current_profile_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_normalize_conversation_participants"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_normalize_conversation_participants"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_normalize_conversation_participants"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_notify_on_comment"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_notify_on_comment"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_notify_on_comment"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_notify_on_connection_request"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_notify_on_connection_request"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_notify_on_connection_request"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_notify_on_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_notify_on_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_notify_on_message"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_notify_on_post_like"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_notify_on_post_like"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_notify_on_post_like"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_notify_on_project_application"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_notify_on_project_application"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_notify_on_project_application"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_notify_on_reel_like"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_notify_on_reel_like"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_notify_on_reel_like"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_notify_once"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text", "p_action_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."app_notify_once"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text", "p_action_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_notify_once"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text", "p_action_url" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."app_safe_governorate"("p_governorate" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."app_safe_governorate"("p_governorate" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_safe_governorate"("p_governorate" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."app_safe_user_role"("p_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."app_safe_user_role"("p_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_safe_user_role"("p_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."app_sync_profile_cover_columns"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_sync_profile_cover_columns"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_sync_profile_cover_columns"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_touch_conversation"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_touch_conversation"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_touch_conversation"() TO "service_role";



GRANT ALL ON FUNCTION "public"."app_update_connection_counts"() TO "anon";
GRANT ALL ON FUNCTION "public"."app_update_connection_counts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."app_update_connection_counts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."apply_to_project_for_app"("p_project_id" "uuid", "p_subject" "text", "p_message" "text", "p_files" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."apply_to_project_for_app"("p_project_id" "uuid", "p_subject" "text", "p_message" "text", "p_files" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_to_project_for_app"("p_project_id" "uuid", "p_subject" "text", "p_message" "text", "p_files" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."check_is_admin"("user_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."check_is_admin"("user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."check_is_admin"("user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_is_admin"("user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."check_permission"("p_user_id" "uuid", "p_permission" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."check_permission"("p_user_id" "uuid", "p_permission" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_permission"("p_user_id" "uuid", "p_permission" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."check_rate_limit"("p_key" "text", "p_window_minutes" integer, "p_max_requests" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."check_rate_limit"("p_key" "text", "p_window_minutes" integer, "p_max_requests" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_rate_limit"("p_key" "text", "p_window_minutes" integer, "p_max_requests" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."check_subscription_expiry_notifications"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."check_subscription_expiry_notifications"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_subscription_expiry_notifications"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_expired_otps"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_expired_otps"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_expired_otps"() TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_old_rate_limits"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_old_rate_limits"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_old_rate_limits"() TO "service_role";



GRANT ALL ON FUNCTION "public"."complete_signup_profile_for_app"("p_full_name" "text", "p_email" "text", "p_phone" "text", "p_role" "text", "p_governorate" "text", "p_bio" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."complete_signup_profile_for_app"("p_full_name" "text", "p_email" "text", "p_phone" "text", "p_role" "text", "p_governorate" "text", "p_bio" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."complete_signup_profile_for_app"("p_full_name" "text", "p_email" "text", "p_phone" "text", "p_role" "text", "p_governorate" "text", "p_bio" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_notification"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text", "p_action_url" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_notification"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text", "p_action_url" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_notification"("p_profile_id" "uuid", "p_title" "text", "p_message" "text", "p_type" "text", "p_action_url" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."create_project_for_app"("p_title" "text", "p_description" "text", "p_governorate" "text", "p_tagline" "text", "p_category" "text", "p_project_type" "text", "p_work_mode" "text", "p_stage" "text", "p_problem" "text", "p_goals" "text", "p_target_users" "text", "p_existing_assets" "text"[], "p_required_skills" "text"[], "p_preferred_skills" "text"[], "p_tools_equipment" "text"[], "p_seniority_level" "text", "p_years_experience" integer, "p_certifications" "text"[], "p_engineers_needed" integer, "p_roles_needed" "text"[], "p_responsibilities" "jsonb", "p_current_team_size" "text", "p_collaboration_tools" "text"[], "p_estimated_duration" "text", "p_weekly_commitment" "text", "p_milestones" "jsonb", "p_deadline_urgency" "text", "p_payment_status" "text", "p_payment_model" "text", "p_currency" "text", "p_bonus_incentives" "text", "p_budget_min" numeric, "p_budget_max" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."create_project_for_app"("p_title" "text", "p_description" "text", "p_governorate" "text", "p_tagline" "text", "p_category" "text", "p_project_type" "text", "p_work_mode" "text", "p_stage" "text", "p_problem" "text", "p_goals" "text", "p_target_users" "text", "p_existing_assets" "text"[], "p_required_skills" "text"[], "p_preferred_skills" "text"[], "p_tools_equipment" "text"[], "p_seniority_level" "text", "p_years_experience" integer, "p_certifications" "text"[], "p_engineers_needed" integer, "p_roles_needed" "text"[], "p_responsibilities" "jsonb", "p_current_team_size" "text", "p_collaboration_tools" "text"[], "p_estimated_duration" "text", "p_weekly_commitment" "text", "p_milestones" "jsonb", "p_deadline_urgency" "text", "p_payment_status" "text", "p_payment_model" "text", "p_currency" "text", "p_bonus_incentives" "text", "p_budget_min" numeric, "p_budget_max" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_project_for_app"("p_title" "text", "p_description" "text", "p_governorate" "text", "p_tagline" "text", "p_category" "text", "p_project_type" "text", "p_work_mode" "text", "p_stage" "text", "p_problem" "text", "p_goals" "text", "p_target_users" "text", "p_existing_assets" "text"[], "p_required_skills" "text"[], "p_preferred_skills" "text"[], "p_tools_equipment" "text"[], "p_seniority_level" "text", "p_years_experience" integer, "p_certifications" "text"[], "p_engineers_needed" integer, "p_roles_needed" "text"[], "p_responsibilities" "jsonb", "p_current_team_size" "text", "p_collaboration_tools" "text"[], "p_estimated_duration" "text", "p_weekly_commitment" "text", "p_milestones" "jsonb", "p_deadline_urgency" "text", "p_payment_status" "text", "p_payment_model" "text", "p_currency" "text", "p_bonus_incentives" "text", "p_budget_min" numeric, "p_budget_max" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_current_user_for_app"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_current_user_for_app"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_current_user_for_app"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_admin_chat_monitor"("p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_admin_chat_monitor"("p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_admin_chat_monitor"("p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_admin_system_stats"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_admin_system_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_admin_system_stats"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_admin_user_id"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_admin_user_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_admin_user_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_conversation_participant_phone"("p_conversation_id" "uuid", "p_participant_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_conversation_participant_phone"("p_conversation_id" "uuid", "p_participant_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_conversation_participant_phone"("p_conversation_id" "uuid", "p_participant_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_home_feed"("p_profile_id" "uuid", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_home_feed"("p_profile_id" "uuid", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_home_feed"("p_profile_id" "uuid", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_network_profiles_for_app"("p_audience" "text", "p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_network_profiles_for_app"("p_audience" "text", "p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_network_profiles_for_app"("p_audience" "text", "p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_profile_for_user"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_profile_for_user"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_profile_for_user"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_projects_for_app"("p_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_projects_for_app"("p_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_projects_for_app"("p_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_public_engineer_details"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_public_engineer_details"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_public_engineer_details"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_public_profile"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_public_profile"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_public_profile"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_public_profile_with_details"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_public_profile_with_details"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_public_profile_with_details"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_public_profiles"("p_profile_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."get_public_profiles"("p_profile_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_public_profiles"("p_profile_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_safe_profile"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_safe_profile"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_safe_profile"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_storage_overview"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_storage_overview"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_storage_overview"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_suspicious_users"("min_attempts" integer, "time_window" interval) TO "anon";
GRANT ALL ON FUNCTION "public"."get_suspicious_users"("min_attempts" integer, "time_window" interval) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_suspicious_users"("min_attempts" integer, "time_window" interval) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_unread_messages_count"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_unread_messages_count"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_unread_messages_count"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_conversations"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_conversations"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_conversations"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_storage_stats"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_storage_stats"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_storage_stats"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_auth_user_for_app"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user_for_app"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user_for_app"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."has_active_subscription"("p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."has_active_subscription"("p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_active_subscription"("p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid", "p_viewer_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid", "p_viewer_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_reel_view"("p_reel_id" "uuid", "p_viewer_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_story_view"("p_story_id" "uuid", "p_viewer_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."increment_story_view"("p_story_id" "uuid", "p_viewer_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_story_view"("p_story_id" "uuid", "p_viewer_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_blocked"("checker_id" "uuid", "target_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_blocked"("checker_id" "uuid", "target_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_blocked"("checker_id" "uuid", "target_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_own_profile"("profile_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_own_profile"("profile_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_own_profile"("profile_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_profile_owner"("profile_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_profile_owner"("profile_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_profile_owner"("profile_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_super_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_super_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_super_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text", "p_entity_id" "text", "p_old" "jsonb", "p_new" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text", "p_entity_id" "text", "p_old" "jsonb", "p_new" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text", "p_entity_id" "text", "p_old" "jsonb", "p_new" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text", "p_entity_id" "uuid", "p_old_values" "jsonb", "p_new_values" "jsonb", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text", "p_entity_id" "uuid", "p_old_values" "jsonb", "p_new_values" "jsonb", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_admin_action"("p_action" "text", "p_entity" "text", "p_entity_id" "uuid", "p_old_values" "jsonb", "p_new_values" "jsonb", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_messages_read"("p_conversation_id" "uuid", "p_reader_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_messages_read"("p_conversation_id" "uuid", "p_reader_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_messages_read"("p_conversation_id" "uuid", "p_reader_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_admins_on_report"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_admins_on_report"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_admins_on_report"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_craftsman_on_contact"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_craftsman_on_contact"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_craftsman_on_contact"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_on_follow"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_on_follow"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_on_follow"() TO "service_role";



GRANT ALL ON FUNCTION "public"."request_connection_for_app"("p_receiver_profile_id" "uuid", "p_message" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."request_connection_for_app"("p_receiver_profile_id" "uuid", "p_message" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_connection_for_app"("p_receiver_profile_id" "uuid", "p_message" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."save_item_for_app"("p_item_type" "text", "p_item_id" "text", "p_title" "text", "p_subtitle" "text", "p_detail" "text", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."save_item_for_app"("p_item_type" "text", "p_item_id" "text", "p_title" "text", "p_subtitle" "text", "p_detail" "text", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."save_item_for_app"("p_item_type" "text", "p_item_id" "text", "p_title" "text", "p_subtitle" "text", "p_detail" "text", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."search_profiles_safe"("p_search_term" "text", "p_role" "public"."user_role", "p_governorate" "public"."governorate", "p_limit" integer, "p_offset" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."search_profiles_safe"("p_search_term" "text", "p_role" "public"."user_role", "p_governorate" "public"."governorate", "p_limit" integer, "p_offset" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_profiles_safe"("p_search_term" "text", "p_role" "public"."user_role", "p_governorate" "public"."governorate", "p_limit" integer, "p_offset" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_profile_email"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_profile_email"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_profile_email"() TO "service_role";



GRANT ALL ON FUNCTION "public"."sync_user_email"() TO "anon";
GRANT ALL ON FUNCTION "public"."sync_user_email"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."sync_user_email"() TO "service_role";



GRANT ALL ON FUNCTION "public"."toggle_story_like"("p_story_id" "uuid", "p_profile_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."toggle_story_like"("p_story_id" "uuid", "p_profile_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."toggle_story_like"("p_story_id" "uuid", "p_profile_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_follower_counts"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_follower_counts"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_follower_counts"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_post_comments_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_post_comments_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_post_comments_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_post_likes_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_post_likes_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_post_likes_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_reel_comments_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_reel_comments_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_reel_comments_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_reel_likes_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_reel_likes_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_reel_likes_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."verify_otp_token"("p_phone_local10" "text", "p_verification_token" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."verify_otp_token"("p_phone_local10" "text", "p_verification_token" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."verify_otp_token"("p_phone_local10" "text", "p_verification_token" "uuid") TO "service_role";



GRANT ALL ON TABLE "auth"."audit_log_entries" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."audit_log_entries" TO "postgres";
GRANT SELECT ON TABLE "auth"."audit_log_entries" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "auth"."custom_oauth_providers" TO "postgres";
GRANT ALL ON TABLE "auth"."custom_oauth_providers" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."flow_state" TO "postgres";
GRANT SELECT ON TABLE "auth"."flow_state" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."flow_state" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."identities" TO "postgres";
GRANT SELECT ON TABLE "auth"."identities" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."identities" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."instances" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."instances" TO "postgres";
GRANT SELECT ON TABLE "auth"."instances" TO "postgres" WITH GRANT OPTION;



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."mfa_amr_claims" TO "postgres";
GRANT SELECT ON TABLE "auth"."mfa_amr_claims" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."mfa_amr_claims" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."mfa_challenges" TO "postgres";
GRANT SELECT ON TABLE "auth"."mfa_challenges" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."mfa_challenges" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."mfa_factors" TO "postgres";
GRANT SELECT ON TABLE "auth"."mfa_factors" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."mfa_factors" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_authorizations" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_authorizations" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_client_states" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_client_states" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_clients" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_clients" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."oauth_consents" TO "postgres";
GRANT ALL ON TABLE "auth"."oauth_consents" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."one_time_tokens" TO "postgres";
GRANT SELECT ON TABLE "auth"."one_time_tokens" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."one_time_tokens" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."refresh_tokens" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."refresh_tokens" TO "postgres";
GRANT SELECT ON TABLE "auth"."refresh_tokens" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON SEQUENCE "auth"."refresh_tokens_id_seq" TO "dashboard_user";
GRANT ALL ON SEQUENCE "auth"."refresh_tokens_id_seq" TO "postgres";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."saml_providers" TO "postgres";
GRANT SELECT ON TABLE "auth"."saml_providers" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."saml_providers" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."saml_relay_states" TO "postgres";
GRANT SELECT ON TABLE "auth"."saml_relay_states" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."saml_relay_states" TO "dashboard_user";



GRANT SELECT ON TABLE "auth"."schema_migrations" TO "postgres" WITH GRANT OPTION;



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."sessions" TO "postgres";
GRANT SELECT ON TABLE "auth"."sessions" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."sessions" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."sso_domains" TO "postgres";
GRANT SELECT ON TABLE "auth"."sso_domains" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."sso_domains" TO "dashboard_user";



GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."sso_providers" TO "postgres";
GRANT SELECT ON TABLE "auth"."sso_providers" TO "postgres" WITH GRANT OPTION;
GRANT ALL ON TABLE "auth"."sso_providers" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."users" TO "dashboard_user";
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "auth"."users" TO "postgres";
GRANT SELECT ON TABLE "auth"."users" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "auth"."webauthn_challenges" TO "postgres";
GRANT ALL ON TABLE "auth"."webauthn_challenges" TO "dashboard_user";



GRANT ALL ON TABLE "auth"."webauthn_credentials" TO "postgres";
GRANT ALL ON TABLE "auth"."webauthn_credentials" TO "dashboard_user";



GRANT ALL ON TABLE "public"."admin_audit_log" TO "anon";
GRANT ALL ON TABLE "public"."admin_audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_audit_log" TO "service_role";



GRANT ALL ON TABLE "public"."admin_audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."admin_audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."admin_checklist" TO "anon";
GRANT ALL ON TABLE "public"."admin_checklist" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_checklist" TO "service_role";



GRANT ALL ON TABLE "public"."admin_courses" TO "anon";
GRANT ALL ON TABLE "public"."admin_courses" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_courses" TO "service_role";



GRANT ALL ON TABLE "public"."admin_departments" TO "anon";
GRANT ALL ON TABLE "public"."admin_departments" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_departments" TO "service_role";



GRANT ALL ON TABLE "public"."admin_faq" TO "anon";
GRANT ALL ON TABLE "public"."admin_faq" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_faq" TO "service_role";



GRANT ALL ON TABLE "public"."admin_lecture_assets" TO "anon";
GRANT ALL ON TABLE "public"."admin_lecture_assets" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_lecture_assets" TO "service_role";



GRANT ALL ON TABLE "public"."admin_lectures" TO "anon";
GRANT ALL ON TABLE "public"."admin_lectures" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_lectures" TO "service_role";



GRANT ALL ON TABLE "public"."admin_legal_sections" TO "anon";
GRANT ALL ON TABLE "public"."admin_legal_sections" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_legal_sections" TO "service_role";



GRANT ALL ON TABLE "public"."admin_notification_reads" TO "anon";
GRANT ALL ON TABLE "public"."admin_notification_reads" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_notification_reads" TO "service_role";



GRANT ALL ON TABLE "public"."admin_notifications" TO "anon";
GRANT ALL ON TABLE "public"."admin_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_notifications" TO "service_role";



GRANT ALL ON TABLE "public"."admin_permissions" TO "anon";
GRANT ALL ON TABLE "public"."admin_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."admin_role_permissions" TO "anon";
GRANT ALL ON TABLE "public"."admin_role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_role_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."admin_roles" TO "anon";
GRANT ALL ON TABLE "public"."admin_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_roles" TO "service_role";



GRANT ALL ON TABLE "public"."admin_settings" TO "anon";
GRANT ALL ON TABLE "public"."admin_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_settings" TO "service_role";



GRANT ALL ON TABLE "public"."admin_support_tickets" TO "anon";
GRANT ALL ON TABLE "public"."admin_support_tickets" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_support_tickets" TO "service_role";



GRANT ALL ON TABLE "public"."admin_user_roles" TO "anon";
GRANT ALL ON TABLE "public"."admin_user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_user_roles" TO "service_role";



GRANT ALL ON TABLE "public"."admin_users" TO "anon";
GRANT ALL ON TABLE "public"."admin_users" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_users" TO "service_role";



GRANT ALL ON TABLE "public"."ai_conversations" TO "anon";
GRANT ALL ON TABLE "public"."ai_conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."ai_conversations" TO "service_role";



GRANT ALL ON TABLE "public"."ai_messages" TO "anon";
GRANT ALL ON TABLE "public"."ai_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."ai_messages" TO "service_role";



GRANT ALL ON TABLE "public"."app_comments" TO "anon";
GRANT ALL ON TABLE "public"."app_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."app_comments" TO "service_role";



GRANT ALL ON TABLE "public"."app_config" TO "anon";
GRANT ALL ON TABLE "public"."app_config" TO "authenticated";
GRANT ALL ON TABLE "public"."app_config" TO "service_role";



GRANT ALL ON TABLE "public"."app_reposts" TO "anon";
GRANT ALL ON TABLE "public"."app_reposts" TO "authenticated";
GRANT ALL ON TABLE "public"."app_reposts" TO "service_role";



GRANT ALL ON TABLE "public"."automation_rules" TO "anon";
GRANT ALL ON TABLE "public"."automation_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."automation_rules" TO "service_role";



GRANT ALL ON TABLE "public"."badge_requests" TO "anon";
GRANT ALL ON TABLE "public"."badge_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."badge_requests" TO "service_role";



GRANT ALL ON TABLE "public"."blocked_profiles" TO "anon";
GRANT ALL ON TABLE "public"."blocked_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."blocked_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."blocked_users" TO "anon";
GRANT ALL ON TABLE "public"."blocked_users" TO "authenticated";
GRANT ALL ON TABLE "public"."blocked_users" TO "service_role";



GRANT ALL ON TABLE "public"."capture_attempts" TO "anon";
GRANT ALL ON TABLE "public"."capture_attempts" TO "authenticated";
GRANT ALL ON TABLE "public"."capture_attempts" TO "service_role";



GRANT ALL ON TABLE "public"."comment_likes" TO "anon";
GRANT ALL ON TABLE "public"."comment_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."comment_likes" TO "service_role";



GRANT ALL ON TABLE "public"."connection_requests" TO "anon";
GRANT ALL ON TABLE "public"."connection_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."connection_requests" TO "service_role";



GRANT ALL ON TABLE "public"."contractor_details" TO "anon";
GRANT ALL ON TABLE "public"."contractor_details" TO "authenticated";
GRANT ALL ON TABLE "public"."contractor_details" TO "service_role";



GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";



GRANT ALL ON TABLE "public"."course_progress" TO "anon";
GRANT ALL ON TABLE "public"."course_progress" TO "authenticated";
GRANT ALL ON TABLE "public"."course_progress" TO "service_role";



GRANT ALL ON TABLE "public"."courses" TO "anon";
GRANT ALL ON TABLE "public"."courses" TO "authenticated";
GRANT ALL ON TABLE "public"."courses" TO "service_role";



GRANT ALL ON TABLE "public"."craftsman_details" TO "anon";
GRANT ALL ON TABLE "public"."craftsman_details" TO "authenticated";
GRANT ALL ON TABLE "public"."craftsman_details" TO "service_role";



GRANT ALL ON TABLE "public"."device_tokens" TO "anon";
GRANT ALL ON TABLE "public"."device_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."device_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."engineer_details" TO "anon";
GRANT ALL ON TABLE "public"."engineer_details" TO "authenticated";
GRANT ALL ON TABLE "public"."engineer_details" TO "service_role";



GRANT ALL ON TABLE "public"."engineer_notes" TO "anon";
GRANT ALL ON TABLE "public"."engineer_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."engineer_notes" TO "service_role";



GRANT ALL ON TABLE "public"."followers" TO "anon";
GRANT ALL ON TABLE "public"."followers" TO "authenticated";
GRANT ALL ON TABLE "public"."followers" TO "service_role";



GRANT ALL ON TABLE "public"."job_requests" TO "anon";
GRANT ALL ON TABLE "public"."job_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."job_requests" TO "service_role";



GRANT ALL ON TABLE "public"."machinery_details" TO "anon";
GRANT ALL ON TABLE "public"."machinery_details" TO "authenticated";
GRANT ALL ON TABLE "public"."machinery_details" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON TABLE "public"."muted_conversations" TO "anon";
GRANT ALL ON TABLE "public"."muted_conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."muted_conversations" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."otp_verifications" TO "anon";
GRANT ALL ON TABLE "public"."otp_verifications" TO "authenticated";
GRANT ALL ON TABLE "public"."otp_verifications" TO "service_role";



GRANT ALL ON TABLE "public"."payment_history" TO "anon";
GRANT ALL ON TABLE "public"."payment_history" TO "authenticated";
GRANT ALL ON TABLE "public"."payment_history" TO "service_role";



GRANT ALL ON TABLE "public"."permissions" TO "anon";
GRANT ALL ON TABLE "public"."permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."permissions" TO "service_role";



GRANT ALL ON TABLE "public"."post_comments" TO "anon";
GRANT ALL ON TABLE "public"."post_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."post_comments" TO "service_role";



GRANT ALL ON TABLE "public"."post_likes" TO "anon";
GRANT ALL ON TABLE "public"."post_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."post_likes" TO "service_role";



GRANT ALL ON TABLE "public"."post_reports" TO "anon";
GRANT ALL ON TABLE "public"."post_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."post_reports" TO "service_role";



GRANT ALL ON TABLE "public"."posts" TO "anon";
GRANT ALL ON TABLE "public"."posts" TO "authenticated";
GRANT ALL ON TABLE "public"."posts" TO "service_role";



GRANT ALL ON TABLE "public"."processed_transactions" TO "anon";
GRANT ALL ON TABLE "public"."processed_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."processed_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."project_applications" TO "anon";
GRANT ALL ON TABLE "public"."project_applications" TO "authenticated";
GRANT ALL ON TABLE "public"."project_applications" TO "service_role";



GRANT ALL ON TABLE "public"."project_attachments" TO "anon";
GRANT ALL ON TABLE "public"."project_attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."project_attachments" TO "service_role";



GRANT ALL ON TABLE "public"."project_details" TO "anon";
GRANT ALL ON TABLE "public"."project_details" TO "authenticated";
GRANT ALL ON TABLE "public"."project_details" TO "service_role";



GRANT ALL ON TABLE "public"."projects" TO "anon";
GRANT ALL ON TABLE "public"."projects" TO "authenticated";
GRANT ALL ON TABLE "public"."projects" TO "service_role";



GRANT ALL ON TABLE "public"."rate_limits" TO "anon";
GRANT ALL ON TABLE "public"."rate_limits" TO "authenticated";
GRANT ALL ON TABLE "public"."rate_limits" TO "service_role";



GRANT ALL ON TABLE "public"."reel_comments" TO "anon";
GRANT ALL ON TABLE "public"."reel_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."reel_comments" TO "service_role";



GRANT ALL ON TABLE "public"."reel_likes" TO "anon";
GRANT ALL ON TABLE "public"."reel_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."reel_likes" TO "service_role";



GRANT ALL ON TABLE "public"."reel_reports" TO "anon";
GRANT ALL ON TABLE "public"."reel_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."reel_reports" TO "service_role";



GRANT ALL ON TABLE "public"."reel_views" TO "anon";
GRANT ALL ON TABLE "public"."reel_views" TO "authenticated";
GRANT ALL ON TABLE "public"."reel_views" TO "service_role";



GRANT ALL ON TABLE "public"."reels" TO "anon";
GRANT ALL ON TABLE "public"."reels" TO "authenticated";
GRANT ALL ON TABLE "public"."reels" TO "service_role";



GRANT ALL ON TABLE "public"."reviews" TO "anon";
GRANT ALL ON TABLE "public"."reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."reviews" TO "service_role";



GRANT ALL ON TABLE "public"."role_permissions" TO "anon";
GRANT ALL ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON TABLE "public"."saved_items" TO "anon";
GRANT ALL ON TABLE "public"."saved_items" TO "authenticated";
GRANT ALL ON TABLE "public"."saved_items" TO "service_role";



GRANT ALL ON TABLE "public"."saved_reels" TO "anon";
GRANT ALL ON TABLE "public"."saved_reels" TO "authenticated";
GRANT ALL ON TABLE "public"."saved_reels" TO "service_role";



GRANT ALL ON TABLE "public"."storage_usage" TO "anon";
GRANT ALL ON TABLE "public"."storage_usage" TO "authenticated";
GRANT ALL ON TABLE "public"."storage_usage" TO "service_role";



GRANT ALL ON TABLE "public"."stories" TO "anon";
GRANT ALL ON TABLE "public"."stories" TO "authenticated";
GRANT ALL ON TABLE "public"."stories" TO "service_role";



GRANT ALL ON TABLE "public"."story_comments" TO "anon";
GRANT ALL ON TABLE "public"."story_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."story_comments" TO "service_role";



GRANT ALL ON TABLE "public"."story_likes" TO "anon";
GRANT ALL ON TABLE "public"."story_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."story_likes" TO "service_role";



GRANT ALL ON TABLE "public"."story_views" TO "anon";
GRANT ALL ON TABLE "public"."story_views" TO "authenticated";
GRANT ALL ON TABLE "public"."story_views" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."support_tickets" TO "anon";
GRANT ALL ON TABLE "public"."support_tickets" TO "authenticated";
GRANT ALL ON TABLE "public"."support_tickets" TO "service_role";



GRANT ALL ON TABLE "public"."system_logs" TO "anon";
GRANT ALL ON TABLE "public"."system_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."system_logs" TO "service_role";



GRANT ALL ON TABLE "public"."system_status" TO "anon";
GRANT ALL ON TABLE "public"."system_status" TO "authenticated";
GRANT ALL ON TABLE "public"."system_status" TO "service_role";



GRANT ALL ON TABLE "public"."user_reports" TO "anon";
GRANT ALL ON TABLE "public"."user_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."user_reports" TO "service_role";



REVOKE ALL ON TABLE "storage"."buckets" FROM "supabase_storage_admin";
GRANT ALL ON TABLE "storage"."buckets" TO "supabase_storage_admin" WITH GRANT OPTION;
GRANT ALL ON TABLE "storage"."buckets" TO "service_role";
GRANT ALL ON TABLE "storage"."buckets" TO "authenticated";
GRANT ALL ON TABLE "storage"."buckets" TO "anon";
GRANT ALL ON TABLE "storage"."buckets" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "storage"."buckets_analytics" TO "service_role";
GRANT ALL ON TABLE "storage"."buckets_analytics" TO "authenticated";
GRANT ALL ON TABLE "storage"."buckets_analytics" TO "anon";



GRANT SELECT ON TABLE "storage"."buckets_vectors" TO "service_role";
GRANT SELECT ON TABLE "storage"."buckets_vectors" TO "authenticated";
GRANT SELECT ON TABLE "storage"."buckets_vectors" TO "anon";



REVOKE ALL ON TABLE "storage"."objects" FROM "supabase_storage_admin";
GRANT ALL ON TABLE "storage"."objects" TO "supabase_storage_admin" WITH GRANT OPTION;
GRANT ALL ON TABLE "storage"."objects" TO "service_role";
GRANT ALL ON TABLE "storage"."objects" TO "authenticated";
GRANT ALL ON TABLE "storage"."objects" TO "anon";
GRANT ALL ON TABLE "storage"."objects" TO "postgres" WITH GRANT OPTION;



GRANT ALL ON TABLE "storage"."s3_multipart_uploads" TO "service_role";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads" TO "authenticated";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads" TO "anon";



GRANT ALL ON TABLE "storage"."s3_multipart_uploads_parts" TO "service_role";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads_parts" TO "authenticated";
GRANT SELECT ON TABLE "storage"."s3_multipart_uploads_parts" TO "anon";



GRANT SELECT ON TABLE "storage"."vector_indexes" TO "service_role";
GRANT SELECT ON TABLE "storage"."vector_indexes" TO "authenticated";
GRANT SELECT ON TABLE "storage"."vector_indexes" TO "anon";



ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON SEQUENCES TO "dashboard_user";



ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON FUNCTIONS TO "dashboard_user";



ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_auth_admin" IN SCHEMA "auth" GRANT ALL ON TABLES TO "dashboard_user";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON SEQUENCES TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON FUNCTIONS TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "storage" GRANT ALL ON TABLES TO "service_role";




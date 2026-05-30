-- Applications tracking + matching feature.
--
-- Adds the server-side pieces the app needs to:
--   * let owners "match" (accept) an applicant on a project or job;
--   * enforce match limits (project = engineers_needed, job = single);
--   * hide matched items from the feed (project.status='completed',
--     job.is_active=false + status='completed');
--   * notify applicants when matched and owners when applied to;
--   * power the "تقديماتي" (my applications), owner management, and
--     "الأعمال" (matched works) screens via dedicated RPCs.

-- 1. jobs.status -----------------------------------------------------------
-- Mirror projects.status so a matched job can be marked completed while
-- still being readable by its owner (the feed already filters is_active).
alter table public.jobs
  add column if not exists status text not null default 'open';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'jobs_status_check'
  ) then
    alter table public.jobs
      add constraint jobs_status_check
      check (status in ('open', 'completed', 'closed'));
  end if;
end $$;

-- 2. Feed: never surface completed (fully matched) projects ----------------
create or replace function public.get_projects_for_app(p_limit integer default 50)
returns table (
  id uuid,
  title text,
  description text,
  governorate text,
  budget_min numeric,
  budget_max numeric,
  status text,
  start_date timestamptz,
  end_date timestamptz,
  image_url text,
  profile_id uuid,
  created_at timestamptz,
  project_details jsonb,
  profiles jsonb
)
language sql
stable
security definer
set search_path = public
as $$
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
  where p.status is distinct from 'completed'
  order by p.created_at desc
  limit least(greatest(p_limit, 1), 100)
$$;

-- 3. Matching: project -----------------------------------------------------
-- Accepts an applicant. Idempotent, owner-only, enforces the engineers_needed
-- cap, notifies the applicant, and marks the project completed once filled.
create or replace function public.match_project_applicant(p_application_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := public.app_current_profile_id();
  v_project_id uuid;
  v_applicant uuid;
  v_status text;
  v_owner uuid;
  v_title text;
  v_needed integer;
  v_accepted integer;
begin
  if v_me is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select pa.project_id, pa.profile_id, pa.status
    into v_project_id, v_applicant, v_status
  from public.project_applications pa
  where pa.id = p_application_id;

  if v_project_id is null then
    raise exception 'APPLICATION_NOT_FOUND';
  end if;

  select pr.profile_id, pr.title
    into v_owner, v_title
  from public.projects pr
  where pr.id = v_project_id;

  if v_owner is null or v_owner <> v_me then
    raise exception 'NOT_PROJECT_OWNER';
  end if;

  -- Already matched: nothing to do.
  if v_status = 'accepted' then
    return;
  end if;

  select coalesce(pd.engineers_needed, 1)
    into v_needed
  from public.project_details pd
  where pd.project_id = v_project_id;
  v_needed := coalesce(v_needed, 1);

  select count(*)
    into v_accepted
  from public.project_applications
  where project_id = v_project_id
    and status = 'accepted';

  if v_accepted >= v_needed then
    raise exception 'MATCH_LIMIT_REACHED';
  end if;

  update public.project_applications
  set status = 'accepted',
      reviewed_by = v_me,
      reviewed_at = now(),
      updated_at = now()
  where id = p_application_id;

  perform public.app_notify_once(
    v_applicant,
    'تمت مطابقتك في مشروع',
    'تم اختيارك للمشاركة في مشروع: ' || coalesce(v_title, ''),
    'project',
    'app://project/' || v_project_id::text
  );

  -- When the last needed slot is filled, drop the project from the feed.
  if v_accepted + 1 >= v_needed then
    update public.projects
    set status = 'completed',
        updated_at = now()
    where id = v_project_id;
  end if;
end;
$$;

-- 4. Matching: job (single match) ------------------------------------------
create or replace function public.match_job_applicant(p_application_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me uuid := public.app_current_profile_id();
  v_job_id uuid;
  v_applicant uuid;
  v_status text;
  v_owner uuid;
  v_title text;
  v_accepted integer;
begin
  if v_me is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select ja.job_id, ja.profile_id, ja.status
    into v_job_id, v_applicant, v_status
  from public.job_applications ja
  where ja.id = p_application_id;

  if v_job_id is null then
    raise exception 'APPLICATION_NOT_FOUND';
  end if;

  select j.profile_id, j.title
    into v_owner, v_title
  from public.jobs j
  where j.id = v_job_id;

  if v_owner is null or v_owner <> v_me then
    raise exception 'NOT_JOB_OWNER';
  end if;

  if v_status = 'accepted' then
    return;
  end if;

  select count(*)
    into v_accepted
  from public.job_applications
  where job_id = v_job_id
    and status = 'accepted';

  -- A job can only ever match one person.
  if v_accepted >= 1 then
    raise exception 'MATCH_LIMIT_REACHED';
  end if;

  update public.job_applications
  set status = 'accepted',
      updated_at = now()
  where id = p_application_id;

  perform public.app_notify_once(
    v_applicant,
    'تمت مطابقتك في وظيفة',
    'تم اختيارك لوظيفة: ' || coalesce(v_title, ''),
    'job',
    'app://job/' || v_job_id::text
  );

  -- Matched: remove from the feed and mark completed.
  update public.jobs
  set is_active = false,
      status = 'completed',
      updated_at = now()
  where id = v_job_id;
end;
$$;

-- 5. Notify the job owner when someone applies -----------------------------
create or replace function public.app_notify_on_job_application() returns trigger
  language plpgsql
  security definer
  set search_path to 'public'
as $$
declare
  v_owner uuid;
begin
  select j.profile_id
    into v_owner
  from public.jobs j
  where j.id = new.job_id;

  if v_owner is not null and v_owner <> new.profile_id then
    perform public.app_notify_once(
      v_owner,
      'طلب جديد على وظيفتك',
      'تم إرسال طلب جديد للتقديم على وظيفتك',
      'job',
      'app://job/' || new.job_id::text
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_app_job_application_notify on public.job_applications;
create trigger on_app_job_application_notify
  after insert on public.job_applications
  for each row execute function public.app_notify_on_job_application();

-- 6. Owner views -----------------------------------------------------------
-- Projects created by the caller, with application + accepted counts.
create or replace function public.get_my_projects()
returns table (
  id uuid,
  title text,
  description text,
  governorate text,
  status text,
  image_url text,
  created_at timestamptz,
  engineers_needed integer,
  applications_count bigint,
  accepted_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.title,
    p.description,
    p.governorate::text,
    p.status,
    p.image_url,
    p.created_at,
    coalesce(pd.engineers_needed, 1),
    (select count(*) from public.project_applications pa where pa.project_id = p.id),
    (select count(*) from public.project_applications pa
       where pa.project_id = p.id and pa.status = 'accepted')
  from public.projects p
  left join public.project_details pd on pd.project_id = p.id
  where p.profile_id = public.app_current_profile_id()
  order by p.created_at desc
$$;

-- Jobs created by the caller, with application + accepted counts.
create or replace function public.get_my_jobs()
returns table (
  id uuid,
  title text,
  description text,
  company_name text,
  location text,
  job_type text,
  category text,
  salary_range text,
  status text,
  is_active boolean,
  created_at timestamptz,
  applications_count bigint,
  accepted_count bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    j.id,
    j.title,
    j.description,
    j.company_name,
    j.location,
    j.job_type,
    j.category,
    j.salary_range,
    j.status,
    j.is_active,
    j.created_at,
    (select count(*) from public.job_applications ja where ja.job_id = j.id),
    (select count(*) from public.job_applications ja
       where ja.job_id = j.id and ja.status = 'accepted')
  from public.jobs j
  where j.profile_id = public.app_current_profile_id()
  order by j.created_at desc
$$;

-- Applicants on a job the caller owns (mirrors project_applications reads).
create or replace function public.get_job_applications(p_job_id uuid)
returns table (
  application_id uuid,
  status text,
  cover_letter text,
  created_at timestamptz,
  applicant_id uuid,
  full_name text,
  role text,
  bio text,
  avatar_url text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ja.id,
    ja.status,
    ja.cover_letter,
    ja.created_at,
    pr.id,
    pr.full_name,
    pr.role::text,
    pr.bio,
    pr.avatar_url
  from public.job_applications ja
  join public.jobs j on j.id = ja.job_id
  left join public.profiles pr on pr.id = ja.profile_id
  where ja.job_id = p_job_id
    and j.profile_id = public.app_current_profile_id()
  order by ja.created_at desc
$$;

-- 7. Applicant views (تقديماتي) -------------------------------------------
create or replace function public.get_my_project_applications()
returns table (
  application_id uuid,
  status text,
  created_at timestamptz,
  project_id uuid,
  title text,
  governorate text,
  project_status text,
  owner_name text,
  owner_avatar text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    pa.id,
    pa.status,
    pa.created_at,
    p.id,
    p.title,
    p.governorate::text,
    p.status,
    pr.full_name,
    pr.avatar_url
  from public.project_applications pa
  join public.projects p on p.id = pa.project_id
  left join public.profiles pr on pr.id = p.profile_id
  where pa.profile_id = public.app_current_profile_id()
  order by pa.created_at desc
$$;

create or replace function public.get_my_job_applications()
returns table (
  application_id uuid,
  status text,
  created_at timestamptz,
  job_id uuid,
  title text,
  company_name text,
  location text,
  job_status text,
  owner_name text,
  owner_avatar text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ja.id,
    ja.status,
    ja.created_at,
    j.id,
    j.title,
    j.company_name,
    j.location,
    j.status,
    pr.full_name,
    pr.avatar_url
  from public.job_applications ja
  join public.jobs j on j.id = ja.job_id
  left join public.profiles pr on pr.id = j.profile_id
  where ja.profile_id = public.app_current_profile_id()
  order by ja.created_at desc
$$;

-- 8. Matched works for a profile's "الأعمال" tab --------------------------
-- Accepted applications (project + job) where the given profile is the
-- matched person. Security definer so it works for any public profile view.
create or replace function public.get_matched_works(p_profile_id uuid)
returns table (
  kind text,
  ref_id uuid,
  title text,
  subtitle text,
  owner_name text,
  owner_avatar text,
  matched_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    'project'::text,
    p.id,
    p.title,
    p.governorate::text,
    pr.full_name,
    pr.avatar_url,
    pa.reviewed_at
  from public.project_applications pa
  join public.projects p on p.id = pa.project_id
  left join public.profiles pr on pr.id = p.profile_id
  where pa.profile_id = p_profile_id
    and pa.status = 'accepted'
  union all
  select
    'job'::text,
    j.id,
    j.title,
    coalesce(j.company_name, j.location),
    pr.full_name,
    pr.avatar_url,
    ja.updated_at
  from public.job_applications ja
  join public.jobs j on j.id = ja.job_id
  left join public.profiles pr on pr.id = j.profile_id
  where ja.profile_id = p_profile_id
    and ja.status = 'accepted'
  order by 7 desc nulls last
$$;

-- 9. Grants ----------------------------------------------------------------
grant execute on function public.match_project_applicant(uuid) to authenticated;
grant execute on function public.match_job_applicant(uuid) to authenticated;
grant execute on function public.get_my_projects() to authenticated;
grant execute on function public.get_my_jobs() to authenticated;
grant execute on function public.get_job_applications(uuid) to authenticated;
grant execute on function public.get_my_project_applications() to authenticated;
grant execute on function public.get_my_job_applications() to authenticated;
grant execute on function public.get_matched_works(uuid) to authenticated;

revoke all on function public.match_project_applicant(uuid) from anon;
revoke all on function public.match_job_applicant(uuid) from anon;

-- Flutter integration bridge for the المهندس app.
-- This migration extends the existing Supabase schema without replacing the
-- current production tables. It adds the missing structures required by the
-- Flutter prototype: rich project details, project applications, generic saved
-- items, connection requests, post reports, and RPCs optimized for the app.

create extension if not exists pgcrypto;

create table if not exists public.project_details (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null unique references public.projects(id) on delete cascade,
  tagline text,
  category text not null default 'مدني',
  project_type text not null default 'تعاون مشروع',
  work_mode text not null default 'موقعي',
  stage text not null default 'تخطيط',
  problem text,
  goals text,
  target_users text,
  existing_assets text[] not null default '{}',
  required_skills text[] not null default '{}',
  preferred_skills text[] not null default '{}',
  tools_equipment text[] not null default '{}',
  seniority_level text,
  years_experience integer,
  certifications text[] not null default '{}',
  engineers_needed integer not null default 1 check (engineers_needed > 0),
  roles_needed text[] not null default '{}',
  responsibilities jsonb not null default '{}'::jsonb,
  current_team_size text,
  collaboration_tools text[] not null default '{}',
  estimated_duration text,
  weekly_commitment text,
  milestones jsonb not null default '[]'::jsonb,
  deadline_urgency text,
  payment_status text not null default 'مدفوع',
  payment_model text,
  currency text not null default 'IQD',
  bonus_incentives text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.project_applications (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  subject text not null,
  message text not null,
  attachments_count integer not null default 0,
  files jsonb not null default '[]'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'withdrawn')),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (project_id, profile_id)
);

create table if not exists public.saved_items (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  item_type text not null
    check (item_type in ('post', 'reel', 'project', 'company', 'story')),
  item_id text not null,
  title text not null,
  subtitle text,
  detail text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (profile_id, item_type, item_id)
);

create table if not exists public.connection_requests (
  id uuid primary key default gen_random_uuid(),
  requester_profile_id uuid not null references public.profiles(id) on delete cascade,
  receiver_profile_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  message text,
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (requester_profile_id <> receiver_profile_id),
  unique (requester_profile_id, receiver_profile_id)
);

create table if not exists public.post_reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  status text not null default 'pending'
    check (status in ('pending', 'reviewed', 'resolved', 'dismissed')),
  admin_notes text,
  reviewed_by uuid references public.admin_users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (post_id, reporter_id)
);

create index if not exists idx_project_details_project_id
  on public.project_details(project_id);

create index if not exists idx_project_applications_profile_id
  on public.project_applications(profile_id);

create index if not exists idx_project_applications_project_id
  on public.project_applications(project_id);

create index if not exists idx_saved_items_profile_id_created_at
  on public.saved_items(profile_id, created_at desc);

create index if not exists idx_connection_requests_receiver_status
  on public.connection_requests(receiver_profile_id, status);

create index if not exists idx_post_reports_status
  on public.post_reports(status);

create or replace function public.app_current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.profiles p
  where p.user_id = auth.uid()
  limit 1
$$;

create or replace function public.app_can_post_projects(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = p_profile_id
      and p.role in ('engineer'::user_role, 'contractor'::user_role)
  )
$$;

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
  order by p.created_at desc
  limit least(greatest(p_limit, 1), 100)
$$;

create or replace function public.create_project_for_app(
  p_title text,
  p_description text,
  p_governorate text,
  p_tagline text default null,
  p_category text default 'civil',
  p_project_type text default 'project_collaboration',
  p_work_mode text default 'onsite',
  p_stage text default 'planning',
  p_problem text default null,
  p_goals text default null,
  p_target_users text default null,
  p_existing_assets text[] default '{}',
  p_required_skills text[] default '{}',
  p_preferred_skills text[] default '{}',
  p_tools_equipment text[] default '{}',
  p_seniority_level text default null,
  p_years_experience integer default null,
  p_certifications text[] default '{}',
  p_engineers_needed integer default 1,
  p_roles_needed text[] default '{}',
  p_responsibilities jsonb default '{}'::jsonb,
  p_current_team_size text default null,
  p_collaboration_tools text[] default '{}',
  p_estimated_duration text default null,
  p_weekly_commitment text default null,
  p_milestones jsonb default '[]'::jsonb,
  p_deadline_urgency text default null,
  p_payment_status text default 'paid',
  p_payment_model text default null,
  p_currency text default 'IQD',
  p_bonus_incentives text default null,
  p_budget_min numeric default null,
  p_budget_max numeric default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
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

create or replace function public.apply_to_project_for_app(
  p_project_id uuid,
  p_subject text,
  p_message text,
  p_files jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_application_id uuid;
begin
  v_profile_id := public.app_current_profile_id();

  if v_profile_id is null then
    raise exception 'profile_not_found';
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
  on conflict (project_id, profile_id)
  do update set
    subject = excluded.subject,
    message = excluded.message,
    attachments_count = excluded.attachments_count,
    files = excluded.files,
    status = case
      when public.project_applications.status in ('accepted', 'rejected')
        then public.project_applications.status
      else 'pending'
    end,
    updated_at = now()
  returning id into v_application_id;

  return v_application_id;
end;
$$;

create or replace function public.save_item_for_app(
  p_item_type text,
  p_item_id text,
  p_title text,
  p_subtitle text default null,
  p_detail text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
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

create or replace function public.request_connection_for_app(
  p_receiver_profile_id uuid,
  p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_request_id uuid;
begin
  v_profile_id := public.app_current_profile_id();

  if v_profile_id is null then
    raise exception 'profile_not_found';
  end if;

  insert into public.connection_requests (
    requester_profile_id,
    receiver_profile_id,
    message
  )
  values (v_profile_id, p_receiver_profile_id, p_message)
  on conflict (requester_profile_id, receiver_profile_id)
  do update set
    status = 'pending',
    message = excluded.message,
    updated_at = now()
  returning id into v_request_id;

  return v_request_id;
end;
$$;

create or replace function public.get_network_profiles_for_app(
  p_audience text default 'people',
  p_limit integer default 40
)
returns table (
  id uuid,
  full_name text,
  username text,
  role text,
  governorate text,
  bio text,
  experience_years integer,
  projects_count integer,
  followers_count integer,
  avatar_url text,
  is_verified boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_viewer_role user_role;
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

  if p_audience = 'companies' then
    if v_viewer_role <> 'engineer'::user_role then
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
      and p.role in ('contractor'::user_role, 'client'::user_role)
    order by p.is_verified desc, p.projects_count desc, p.created_at desc
    limit least(greatest(p_limit, 1), 100);

    return;
  end if;

  if v_viewer_role = 'engineer'::user_role then
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
      and p.role in (
        'engineer'::user_role,
        'craftsman'::user_role,
        'worker'::user_role,
        'machinery'::user_role
      )
    order by p.is_verified desc, p.projects_count desc, p.created_at desc
    limit least(greatest(p_limit, 1), 100);

    return;
  end if;

  if v_viewer_role = 'contractor'::user_role
      or v_viewer_role = 'client'::user_role then
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
      and p.role = 'engineer'::user_role
    order by p.is_verified desc, p.projects_count desc, p.created_at desc
    limit least(greatest(p_limit, 1), 100);
  end if;
end;
$$;

do $$
declare
  v_function regprocedure;
begin
  for v_function in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'get_projects_for_app',
        'get_network_profiles_for_app'
      )
  loop
    execute format('grant execute on function %s to anon, authenticated', v_function);
  end loop;

  for v_function in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'app_current_profile_id',
        'app_can_post_projects',
        'create_project_for_app',
        'apply_to_project_for_app',
        'save_item_for_app',
        'request_connection_for_app'
      )
  loop
    execute format('grant execute on function %s to authenticated', v_function);
  end loop;
end
$$;

alter table public.project_details enable row level security;
alter table public.project_applications enable row level security;
alter table public.saved_items enable row level security;
alter table public.connection_requests enable row level security;
alter table public.post_reports enable row level security;

do $$
begin
  if exists (select 1 from pg_proc where proname = 'update_updated_at_column') then
    if not exists (
      select 1 from pg_trigger where tgname = 'update_project_details_updated_at'
    ) then
      create trigger update_project_details_updated_at
      before update on public.project_details
      for each row execute function public.update_updated_at_column();
    end if;

    if not exists (
      select 1 from pg_trigger where tgname = 'update_project_applications_updated_at'
    ) then
      create trigger update_project_applications_updated_at
      before update on public.project_applications
      for each row execute function public.update_updated_at_column();
    end if;

    if not exists (
      select 1 from pg_trigger where tgname = 'update_connection_requests_updated_at'
    ) then
      create trigger update_connection_requests_updated_at
      before update on public.connection_requests
      for each row execute function public.update_updated_at_column();
    end if;

    if not exists (
      select 1 from pg_trigger where tgname = 'update_post_reports_updated_at'
    ) then
      create trigger update_post_reports_updated_at
      before update on public.post_reports
      for each row execute function public.update_updated_at_column();
    end if;
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'project_details'
      and policyname = 'Project details are publicly readable'
  ) then
    create policy "Project details are publicly readable"
      on public.project_details
      for select
      using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'project_details'
      and policyname = 'Project owners can manage details'
  ) then
    create policy "Project owners can manage details"
      on public.project_details
      for all
      using (
        exists (
          select 1
          from public.projects p
          join public.profiles pr on pr.id = p.profile_id
          where p.id = project_details.project_id
            and pr.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1
          from public.projects p
          join public.profiles pr on pr.id = p.profile_id
          where p.id = project_details.project_id
            and pr.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'project_applications'
      and policyname = 'Applicants can read their own applications'
  ) then
    create policy "Applicants can read their own applications"
      on public.project_applications
      for select
      using (
        exists (
          select 1 from public.profiles p
          where p.id = project_applications.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'project_applications'
      and policyname = 'Applicants can create pending applications'
  ) then
    create policy "Applicants can create pending applications"
      on public.project_applications
      for insert
      with check (
        status = 'pending'
        and
        exists (
          select 1 from public.profiles p
          where p.id = project_applications.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'project_applications'
      and policyname = 'Applicants can withdraw their applications'
  ) then
    create policy "Applicants can withdraw their applications"
      on public.project_applications
      for update
      using (
        exists (
          select 1 from public.profiles p
          where p.id = project_applications.profile_id
            and p.user_id = auth.uid()
        )
      )
      with check (
        status in ('pending', 'withdrawn')
        and
        exists (
          select 1 from public.profiles p
          where p.id = project_applications.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'project_applications'
      and policyname = 'Project owners can read applications'
  ) then
    create policy "Project owners can read applications"
      on public.project_applications
      for select
      using (
        exists (
          select 1
          from public.projects p
          join public.profiles pr on pr.id = p.profile_id
          where p.id = project_applications.project_id
            and pr.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'project_applications'
      and policyname = 'Project owners can update application status'
  ) then
    create policy "Project owners can update application status"
      on public.project_applications
      for update
      using (
        exists (
          select 1
          from public.projects p
          join public.profiles pr on pr.id = p.profile_id
          where p.id = project_applications.project_id
            and pr.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1
          from public.projects p
          join public.profiles pr on pr.id = p.profile_id
          where p.id = project_applications.project_id
            and pr.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'saved_items'
      and policyname = 'Users manage their own saved items'
  ) then
    create policy "Users manage their own saved items"
      on public.saved_items
      for all
      using (
        exists (
          select 1 from public.profiles p
          where p.id = saved_items.profile_id
            and p.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.profiles p
          where p.id = saved_items.profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'connection_requests'
      and policyname = 'Connection participants can see requests'
  ) then
    create policy "Connection participants can see requests"
      on public.connection_requests
      for select
      using (
        exists (
          select 1 from public.profiles p
          where p.user_id = auth.uid()
            and p.id in (
              connection_requests.requester_profile_id,
              connection_requests.receiver_profile_id
            )
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'connection_requests'
      and policyname = 'Users create outgoing connection requests'
  ) then
    create policy "Users create outgoing connection requests"
      on public.connection_requests
      for insert
      with check (
        exists (
          select 1 from public.profiles p
          where p.id = connection_requests.requester_profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'connection_requests'
      and policyname = 'Receivers can answer connection requests'
  ) then
    create policy "Receivers can answer connection requests"
      on public.connection_requests
      for update
      using (
        exists (
          select 1 from public.profiles p
          where p.id = connection_requests.receiver_profile_id
            and p.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1 from public.profiles p
          where p.id = connection_requests.receiver_profile_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'post_reports'
      and policyname = 'Users create their own post reports'
  ) then
    create policy "Users create their own post reports"
      on public.post_reports
      for insert
      with check (
        exists (
          select 1 from public.profiles p
          where p.id = post_reports.reporter_id
            and p.user_id = auth.uid()
        )
      );
  end if;
end
$$;

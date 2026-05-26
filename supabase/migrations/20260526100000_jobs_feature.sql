-- Migration for Jobs feature: jobs table, applications, and push notifications.

create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null,
  company_name text,
  location text,
  job_type text not null default 'full-time'
    check (job_type in ('full-time', 'part-time', 'contract', 'freelance', 'internship')),
  category text not null default 'مدني',
  salary_range text,
  requirements text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.job_applications (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  resume_url text,
  cover_letter text,
  status text not null default 'pending'
    check (status in ('pending', 'reviewed', 'interviewing', 'accepted', 'rejected', 'withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (job_id, profile_id)
);

create index if not exists idx_jobs_profile_id on public.jobs(profile_id);
create index if not exists idx_job_applications_job_id on public.job_applications(job_id);
create index if not exists idx_job_applications_profile_id on public.job_applications(profile_id);

alter table public.jobs enable row level security;
alter table public.job_applications enable row level security;

-- Policies for Jobs
drop policy if exists "Jobs are visible to everyone" on public.jobs;
create policy "Jobs are visible to everyone" on public.jobs for select using (true);

drop policy if exists "Engineers and Companies can create jobs" on public.jobs;
create policy "Engineers and Companies can create jobs" on public.jobs for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = jobs.profile_id
        and p.user_id = auth.uid()
        and p.role in ('engineer', 'contractor', 'admin')
    )
  );

-- Policies for Job Applications
drop policy if exists "Users can see their own applications" on public.job_applications;
create policy "Users can see their own applications" on public.job_applications for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.id = job_applications.profile_id
        and p.user_id = auth.uid()
    )
    or
    exists (
      select 1 from public.jobs j
      where j.id = job_applications.job_id
        and exists (
          select 1 from public.profiles p
          where p.id = j.profile_id
            and p.user_id = auth.uid()
        )
    )
  );

drop policy if exists "Users can apply to jobs" on public.job_applications;
create policy "Users can apply to jobs" on public.job_applications for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = job_applications.profile_id
        and p.user_id = auth.uid()
    )
  );

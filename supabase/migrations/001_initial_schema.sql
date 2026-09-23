-- Demans Hasta Takip initial Supabase schema
-- Run this migration in a new Supabase project or adapt it for an existing schema.

create extension if not exists pgcrypto;

create type public.user_role as enum ('patient', 'caregiver', 'doctor', 'admin');
create type public.access_role as enum ('patient', 'caregiver', 'doctor', 'admin');
create type public.medication_log_status as enum ('taken', 'missed', 'cancelled');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role public.user_role not null,
  phone text,
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.patients (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  birth_date date,
  medical_conditions text[] not null default '{}',
  emergency_contact text,
  caregiver_name text,
  notes text,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.patient_access (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.access_role not null,
  granted_by uuid references auth.users(id) on delete set null,
  granted_at timestamptz not null default now(),
  unique (patient_id, user_id)
);

create table public.medications (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  name text not null,
  dosage text not null,
  time_slot text not null,
  scheduled_time time not null,
  instructions text,
  is_active boolean not null default true,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.medication_logs (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  medication_id uuid not null references public.medications(id) on delete cascade,
  status public.medication_log_status not null,
  logged_at timestamptz not null default now(),
  logged_by uuid not null references auth.users(id) on delete restrict,
  notes text,
  unique (medication_id, logged_at)
);

create table public.fluid_entries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  amount_ml integer not null check (amount_ml > 0 and amount_ml <= 10000),
  type text not null,
  logged_at timestamptz not null default now(),
  logged_by uuid not null references auth.users(id) on delete restrict,
  notes text
);

create table public.urine_entries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  amount_ml integer not null check (amount_ml > 0 and amount_ml <= 10000),
  status text not null,
  logged_at timestamptz not null default now(),
  logged_by uuid not null references auth.users(id) on delete restrict,
  notes text
);

create table public.daily_notes (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  note text not null check (length(trim(note)) > 0),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.alerts (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  type text not null,
  message text not null,
  resolved boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  resolved_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index patients_created_by_idx on public.patients(created_by);
create index patient_access_user_id_idx on public.patient_access(user_id);
create index medications_patient_id_idx on public.medications(patient_id);
create index medication_logs_patient_logged_at_idx on public.medication_logs(patient_id, logged_at desc);
create index fluid_entries_patient_logged_at_idx on public.fluid_entries(patient_id, logged_at desc);
create index urine_entries_patient_logged_at_idx on public.urine_entries(patient_id, logged_at desc);
create index daily_notes_patient_created_at_idx on public.daily_notes(patient_id, created_at desc);
create index alerts_patient_created_at_idx on public.alerts(patient_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger patients_set_updated_at
before update on public.patients
for each row execute function public.set_updated_at();

create trigger medications_set_updated_at
before update on public.medications
for each row execute function public.set_updated_at();

create trigger daily_notes_set_updated_at
before update on public.daily_notes
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
security definer
set search_path = public
language plpgsql
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    coalesce((new.raw_user_meta_data ->> 'role')::public.user_role, 'caregiver')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.has_patient_access(target_patient_id uuid)
returns boolean
security definer
set search_path = public
stable
language sql
as $$
  select exists (
    select 1
    from public.patient_access
    where patient_id = target_patient_id
      and user_id = auth.uid()
      and exists (
        select 1
        from public.profiles
        where id = auth.uid()
          and is_active = true
      )
  );
$$;

create or replace function public.can_manage_patient_access(target_patient_id uuid)
returns boolean
security definer
set search_path = public
stable
language sql
as $$
  select exists (
    select 1
    from public.patient_access pa
    join public.profiles p on p.id = pa.user_id
    where pa.patient_id = target_patient_id
      and pa.user_id = auth.uid()
      and pa.role in ('admin', 'doctor')
      and p.is_active = true
  ) or exists (
    select 1
    from public.patients
    where id = target_patient_id
      and created_by = auth.uid()
  );
$$;

alter table public.profiles enable row level security;
alter table public.patients enable row level security;
alter table public.patient_access enable row level security;
alter table public.medications enable row level security;
alter table public.medication_logs enable row level security;
alter table public.fluid_entries enable row level security;
alter table public.urine_entries enable row level security;
alter table public.daily_notes enable row level security;
alter table public.alerts enable row level security;

create policy profiles_select_self
on public.profiles for select
to authenticated
using (id = auth.uid());

create policy profiles_update_self
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy patients_select_authorized
on public.patients for select
to authenticated
using (public.has_patient_access(id) or created_by = auth.uid());

create policy patients_insert_authenticated
on public.patients for insert
to authenticated
with check (created_by = auth.uid());

create policy patients_update_authorized
on public.patients for update
to authenticated
using (public.has_patient_access(id))
with check (public.has_patient_access(id));

create policy patients_delete_creator
on public.patients for delete
to authenticated
using (created_by = auth.uid());

create policy patient_access_select_authorized
on public.patient_access for select
to authenticated
using (user_id = auth.uid() or public.has_patient_access(patient_id));

create policy patient_access_insert_manager
on public.patient_access for insert
to authenticated
with check (public.can_manage_patient_access(patient_id));

create policy patient_access_update_manager
on public.patient_access for update
to authenticated
using (public.can_manage_patient_access(patient_id))
with check (public.can_manage_patient_access(patient_id));

create policy patient_access_delete_manager
on public.patient_access for delete
to authenticated
using (public.can_manage_patient_access(patient_id));

create policy medications_all_authorized
on public.medications for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id));

create policy medication_logs_all_authorized
on public.medication_logs for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id) and logged_by = auth.uid());

create policy fluid_entries_all_authorized
on public.fluid_entries for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id) and logged_by = auth.uid());

create policy urine_entries_all_authorized
on public.urine_entries for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id) and logged_by = auth.uid());

create policy daily_notes_all_authorized
on public.daily_notes for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id) and created_by = auth.uid());

create policy alerts_all_authorized
on public.alerts for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id));

revoke all on all tables in schema public from anon;
grant select, insert, update, delete on all tables in schema public to authenticated;

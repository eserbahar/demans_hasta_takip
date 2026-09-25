-- Demans Hasta Takip: unified 9-category daily activity tracking
-- Additive-only migration: adds star ratings to existing log tables and
-- creates tables for the previously-untracked categories (nutrition, bowel,
-- physical/mental/social activity, vitals). Run in the Supabase SQL editor,
-- same as 001_initial_schema.sql.

create type public.activity_category as enum ('physical', 'mental', 'social');

alter table public.medication_logs add column rating smallint check (rating between 1 and 5);
alter table public.fluid_entries   add column rating smallint check (rating between 1 and 5);
alter table public.urine_entries   add column rating smallint check (rating between 1 and 5);

create table public.nutrition_entries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  meal_type text,
  portion_percent smallint check (portion_percent between 0 and 100),
  logged_at timestamptz not null default now(),
  logged_by uuid not null references auth.users(id) on delete restrict,
  notes text
);

create table public.bowel_entries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  consistency text,
  logged_at timestamptz not null default now(),
  logged_by uuid not null references auth.users(id) on delete restrict,
  notes text
);

create table public.activity_entries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  category public.activity_category not null,
  rating smallint not null check (rating between 1 and 5),
  duration_minutes integer check (duration_minutes > 0 and duration_minutes <= 600),
  logged_at timestamptz not null default now(),
  logged_by uuid not null references auth.users(id) on delete restrict,
  notes text
);

create table public.vitals_entries (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  temperature_c numeric(4,1) check (temperature_c between 30 and 45),
  pulse_bpm smallint check (pulse_bpm between 20 and 250),
  bp_systolic smallint check (bp_systolic between 50 and 260),
  bp_diastolic smallint check (bp_diastolic between 30 and 200),
  logged_at timestamptz not null default now(),
  logged_by uuid not null references auth.users(id) on delete restrict,
  notes text,
  constraint vitals_entries_has_a_value check (
    temperature_c is not null or pulse_bpm is not null
    or bp_systolic is not null or bp_diastolic is not null
  )
);

create index nutrition_entries_patient_logged_at_idx on public.nutrition_entries(patient_id, logged_at desc);
create index bowel_entries_patient_logged_at_idx      on public.bowel_entries(patient_id, logged_at desc);
create index activity_entries_patient_logged_at_idx   on public.activity_entries(patient_id, logged_at desc);
create index vitals_entries_patient_logged_at_idx     on public.vitals_entries(patient_id, logged_at desc);

alter table public.nutrition_entries enable row level security;
alter table public.bowel_entries     enable row level security;
alter table public.activity_entries  enable row level security;
alter table public.vitals_entries    enable row level security;

create policy nutrition_entries_all_authorized
on public.nutrition_entries for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id) and logged_by = auth.uid());

create policy bowel_entries_all_authorized
on public.bowel_entries for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id) and logged_by = auth.uid());

create policy activity_entries_all_authorized
on public.activity_entries for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id) and logged_by = auth.uid());

create policy vitals_entries_all_authorized
on public.vitals_entries for all
to authenticated
using (public.has_patient_access(patient_id))
with check (public.has_patient_access(patient_id) and logged_by = auth.uid());

grant select, insert, update, delete on all tables in schema public to authenticated;

-- bripo v1 — Altos de Maria house construction dashboard
-- Every table is RLS-locked to an allow-listed set of authenticated users.
-- No public read. No sync job — all data is entered through the dashboard.
-- See docs/CHARTER.md for the spec.

-- ---------------------------------------------------------------------------
-- Access control
-- ---------------------------------------------------------------------------
create table app_users (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  email    text,
  role     text not null default 'owner' check (role in ('owner', 'viewer')),
  added_at timestamptz not null default now()
);

-- security-definer so they bypass RLS on app_users (no recursion)
create or replace function public.is_member() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (select 1 from app_users where user_id = auth.uid());
$$;

create or replace function public.is_owner() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (select 1 from app_users where user_id = auth.uid() and role = 'owner');
$$;

-- ---------------------------------------------------------------------------
-- Contract meta (single row) — feeds the deterministic delay-penalty math
-- ---------------------------------------------------------------------------
create table contract_meta (
  id                        text primary key default 'current',
  contract_price            numeric not null default 73500,
  contract_name             text not null default 'Bripo Tiny House',
  weeks_allowed             int not null default 21,
  h1_disbursement_date      date,          -- the 21-week clock starts here
  delay_penalty_per_week    numeric not null default 250,
  delay_penalty_cap         numeric not null default 7350,     -- 10% of price; hitting it = termination trigger (Art 4.1e)
  warranty_labor_years      int not null default 2,            -- Art 8.1
  warranty_structural_years int not null default 10,           -- Art 8.2 (decennial)
  final_delivery_date       date,          -- both warranty clocks start here
  updated_at                timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Milestones (H1..H8) — schedule from the signed contract, Art 2.1
-- ---------------------------------------------------------------------------
create table milestones (
  id                       text primary key,   -- 'H1'..'H8'
  seq                      int not null,
  name                     text not null,
  pct_of_contract          numeric not null,
  contract_amount          numeric not null,
  approval_gate_notes      text,
  status                   text not null default 'not_started'
    check (status in ('not_started','in_progress','pending_inspection','complete','delayed')),
  planned_date             date,
  actual_date              date,
  paz_y_salvo_on_file      boolean not null default false,   -- H2+ worker-payment clearance, Art 2.2
  director_de_obra_approved boolean not null default false,  -- Art 2.1 independent inspector
  notes                    text,
  updated_at               timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Payments — milestone disbursements + material advances (Art 2.5)
-- ---------------------------------------------------------------------------
create table payments (
  id                        uuid primary key default gen_random_uuid(),
  date                      date not null,
  amount                    numeric not null,
  recipient                 text,
  method                    text,
  payment_type              text not null check (payment_type in ('milestone_disbursement','material_advance')),
  milestone_id              text references milestones(id),
  advance_category          text check (advance_category in ('steel','huurre_panels','roof_structure','electrical_cable')),
  -- Art 2.5 compliance gate on advances (both required before the next milestone pays out):
  proof_of_purchase_received boolean not null default false,   -- paid vendor receipt within 10 business days
  proof_of_purchase_deadline date,                             -- disbursement date + 10 business days
  proof_of_delivery_received boolean not null default false,   -- materials physically at Lote 254
  notes                     text,
  created_at                timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Invoices + many-to-many payment matching (never 1:1 in construction)
-- ---------------------------------------------------------------------------
create table invoices (
  id            uuid primary key default gen_random_uuid(),
  vendor        text not null,
  amount        numeric not null,
  date_received date not null,
  milestone_id  text references milestones(id),
  status        text not null default 'unmatched'
    check (status in ('unmatched','partially_matched','matched')),
  notes         text,
  created_at    timestamptz not null default now()
);

create table payment_invoice_links (
  payment_id     uuid not null references payments(id) on delete cascade,
  invoice_id     uuid not null references invoices(id) on delete cascade,
  amount_applied numeric not null,
  primary key (payment_id, invoice_id)
);

-- ---------------------------------------------------------------------------
-- Permits — simple status + document, no automation (Charter 3.4)
-- ---------------------------------------------------------------------------
create table permits (
  id                uuid primary key default gen_random_uuid(),
  seq               int,
  type              text not null,
  notes             text,
  status            text not null default 'not_started'
    check (status in ('not_started','submitted','under_review','approved')),
  completion_date   date,
  responsible_party text,      -- 'contractor' | 'owner'
  updated_at        timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Decision / change log — Gmail (on-request) + WhatsApp + manual (Charter 3.5)
-- ---------------------------------------------------------------------------
create table decision_log (
  id         uuid primary key default gen_random_uuid(),
  source     text not null check (source in ('email','whatsapp','manual','other')),
  date       date not null,
  party      text,
  summary    text not null,
  resolves   text,             -- which article / scope item it settled
  confirmed  boolean not null default false,   -- "confirm before it counts" step
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Change requests — modifications to the live Bripo contract (Charter 3.6)
-- ---------------------------------------------------------------------------
create table change_requests (
  id                          uuid primary key default gen_random_uuid(),
  description                  text not null,
  cost_impact                 numeric,
  schedule_impact_days        int,
  date_submitted              date not null default current_date,
  owner_approval              text not null default 'pending' check (owner_approval in ('pending','approved','rejected')),
  developer_approval          text not null default 'pending' check (developer_approval in ('pending','approved','rejected')),
  developer_approval_evidence text,     -- e.g. "email confirmation received 2026-09-10"
  status                      text not null default 'proposed' check (status in ('proposed','approved','rejected','superseded')),
  created_at                  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Future / independent work items — NOT contract modifications (Charter 3.8)
-- ---------------------------------------------------------------------------
create table future_work_items (
  id                  uuid primary key default gen_random_uuid(),
  description          text not null,
  estimated_cost      numeric,
  status              text not null default 'idea' check (status in ('idea','quoted','contracted','declined')),
  potential_vendor    text,
  time_sensitive_note text,
  created_at          timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Vendors / contacts (Charter 3.7)
-- ---------------------------------------------------------------------------
create table vendors (
  id    uuid primary key default gen_random_uuid(),
  name  text not null,
  role  text,
  phone text,
  email text,
  notes text
);

-- ---------------------------------------------------------------------------
-- Documents — metadata for files in Supabase Storage (private bucket, same RLS)
-- ---------------------------------------------------------------------------
create table documents (
  id                 uuid primary key default gen_random_uuid(),
  filename           text not null,
  storage_path       text not null,
  linked_entity_type text,     -- 'milestone' | 'permit' | 'payment' | 'invoice' | 'vendor' | 'change_request'
  linked_entity_id   text,
  uploaded_at        timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Activity log — timestamped record of manual edits (Charter 3.7)
-- ---------------------------------------------------------------------------
create table activity_log (
  id       bigint generated always as identity primary key,
  at       timestamptz not null default now(),
  actor    uuid default auth.uid(),
  entity   text,
  entity_id text,
  action   text,
  detail   jsonb
);

-- ---------------------------------------------------------------------------
-- Schema catalog RPC (for the docs/schema-snapshot.json drift check)
-- ---------------------------------------------------------------------------
create or replace function public.schema_catalog()
  returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_object_agg(x.table_name, x.cols order by x.table_name), '{}'::jsonb)
  from (
    select c.table_name,
           jsonb_agg(jsonb_build_object('column', c.column_name, 'type', c.data_type,
                     'nullable', (c.is_nullable = 'YES'), 'default', c.column_default)
                     order by c.ordinal_position) as cols
    from information_schema.columns c
    join information_schema.tables t
      on t.table_schema = c.table_schema and t.table_name = c.table_name
    where c.table_schema = 'public' and t.table_type = 'BASE TABLE'
    group by c.table_name
  ) x;
$$;
-- schema *shape* is not sensitive (the data behind it is RLS-locked), and the
-- CI drift check only has the publishable key -> grant to anon too.
grant execute on function public.schema_catalog() to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- RLS — members read everything; owners write everything. No anon access.
-- ---------------------------------------------------------------------------
do $$
declare tbl text;
begin
  foreach tbl in array array[
    'app_users','contract_meta','milestones','payments','invoices',
    'payment_invoice_links','permits','decision_log','change_requests',
    'future_work_items','vendors','documents','activity_log'
  ] loop
    execute format('alter table %I enable row level security', tbl);
    execute format('create policy %I on %I for select using (public.is_member())',
                   tbl||'_member_read', tbl);
    execute format('create policy %I on %I for all using (public.is_owner()) with check (public.is_owner())',
                   tbl||'_owner_write', tbl);
  end loop;
end $$;

-- app_users needs a tighter write policy: only owners manage the allow-list.
-- (the generic owner_write above already covers this; kept explicit for clarity)

insert into contract_meta (id) values ('current') on conflict do nothing;

-- bripo v1 — seed data, documents Storage bucket, and RPC hardening.
-- Idempotent: safe to re-run. The seed rows were originally loaded ad hoc into
-- the live project; this migration makes the repo reproducible from scratch.

-- ---------------------------------------------------------------------------
-- Milestones H1..H8 — schedule + split from the signed contract (Art 2.1)
-- ---------------------------------------------------------------------------
insert into milestones (id, seq, name, pct_of_contract, contract_amount, approval_gate_notes) values
  ('H1', 1, 'Movilización', 10, 7350,
   'Signed contract + CAR/liability insurance naming BC&P LLC delivered'),
  ('H2', 2, 'Movimiento de Tierra y Cimientos', 20, 14700,
   'Written permit confirmation (Art 3.4) + Ing. Gloria Flórez in-person rebar/formwork inspection before pour (Art 2.4)'),
  ('H3', 3, 'Chasis de Acero y Estructura', 20, 14700,
   'Any embedded MEP inspected before concealment (Art 2.4)'),
  ('H4', 4, 'Envolvente Impermeabilizada', 15, 11025,
   'HUURRE panel sealing + water test passed; concealed MEP inspected first'),
  ('H5', 5, 'Obra Exterior Restante', 10, 7350, null),
  ('H6', 6, 'Instalación Bruta de MEP', 10, 7350,
   'Written confirmation from Ing. Rodrigo Palacios (no life-safety circuit on deferred N-2 panel) + HOA/Altos del María confirmation reduced scope acceptable'),
  ('H7', 7, 'Acabado y Pruebas de MEP', 5, 3675,
   'Written test results delivered to Director de Obra'),
  ('H8', 8, 'Retención de Garantía', 10, 7350,
   'Director de Obra + Ing. Gloria Flórez (structural) + electrical engineer sign-off; released 30-90 days after final delivery pending a qualifying rain event (Art 2.3)')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Permits (11) — Art 1.4, 3.4, 5.3, 10.1, 11.3
-- ---------------------------------------------------------------------------
insert into permits (seq, type, status, responsible_party, notes)
select * from (values
  (1, 'Permiso de tala de árboles (tree clearing)', 'not_started', 'contractor',
   'Can be requested without approved plans (Art 3.4 / Anexo C.9)'),
  (2, 'Permiso de Movimiento de Tierra', 'not_started', 'contractor',
   'Required before any excavation, incl. septic (Art 3.4)'),
  (3, 'Planos isométricos de plomería approval', 'not_started', 'contractor',
   'Precondition to the construction permit itself (Decreto 323 de 1971, MINSA)'),
  (4, 'Permiso de Construcción (cimientos and/or final)', 'not_started', 'contractor',
   'Required before H2 foundation work'),
  (5, 'Permiso eléctrico', 'not_started', 'contractor', null),
  (6, 'Permiso de ocupación', 'not_started', 'contractor', 'Final permit'),
  (7, 'Bomberos (Fire Dept.) review', 'not_started', 'owner',
   'Direct owner cost (~$950 est., Presupuesto Maestro Sección 7)'),
  (8, 'MINSA review', 'not_started', 'owner', 'Same cost bucket as Bomberos'),
  (9, 'CAR (Contractor''s All Risk) insurance policy', 'not_started', 'contractor',
   'Hard gate: must be delivered before H1 disbursement (Art 5.3)'),
  (10, 'HOA / Altos del María–Grupo Melo approval of N-2 deferral', 'not_started', 'owner',
   'Required before H6 (Art 11.3)'),
  (11, 'Naturgy 200A service connection', 'not_started', 'owner', null)
) as v(seq, type, status, responsible_party, notes)
where not exists (select 1 from permits);

-- ---------------------------------------------------------------------------
-- Future / independent work items (3) — Charter 3.8, NOT contract mods
-- ---------------------------------------------------------------------------
insert into future_work_items (description, status, time_sensitive_note)
select * from (values
  ('Low-voltage / data conduit rough-in', 'idea',
   'Needs a written request BEFORE H6 or it gets much more expensive after walls close (Art 1.6)'),
  ('Entrance / underfloor basalt gravel landscaping', 'idea',
   'Contractor vs third party still undecided (Art 1.7)'),
  ('Full N-2 panel buildout (copper wiring + outlets/switches + sauna/grill/fridge/shower circuits)', 'idea',
   'Deferred; to be scoped and priced separately, possibly by Bripo, possibly another vendor (Art 11.2)')
) as v(description, status, time_sensitive_note)
where not exists (select 1 from future_work_items);

-- ---------------------------------------------------------------------------
-- Documents — private Storage bucket, same member-read / owner-write RLS
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

drop policy if exists documents_member_read on storage.objects;
create policy documents_member_read on storage.objects
  for select using (bucket_id = 'documents' and public.is_member());

drop policy if exists documents_owner_write on storage.objects;
create policy documents_owner_write on storage.objects
  for all using (bucket_id = 'documents' and public.is_owner())
  with check (bucket_id = 'documents' and public.is_owner());

-- ---------------------------------------------------------------------------
-- Note on is_member() / is_owner() EXECUTE grants
-- ---------------------------------------------------------------------------
-- The Supabase linter WARNs that these SECURITY DEFINER functions are callable
-- by anon. That is intentional and required: the RLS policies on every table
-- (`using (public.is_member())` for read, `using (public.is_owner())` for the
-- FOR ALL write policy) invoke both functions during policy evaluation for
-- *any* caller, including a logged-out anon request. Revoking anon EXECUTE makes
-- those queries fail with "permission denied for function is_owner" instead of
-- cleanly returning zero rows. The functions only ever return a boolean about
-- the caller's own membership — no data is exposed — so anon EXECUTE stays.
grant execute on function public.is_member() to anon, authenticated, service_role;
grant execute on function public.is_owner() to anon, authenticated, service_role;

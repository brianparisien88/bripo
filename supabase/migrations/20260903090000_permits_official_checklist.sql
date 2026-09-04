-- Replace the contract-derived permit list with the owner's official
-- permit/certificate checklist (10 items, with a permit-vs-non-permit
-- category). Existing progress is preserved by UPDATEing matched rows in
-- place rather than delete+reinsert; only rows with no counterpart in the
-- new list are deleted (verified: no documents reference them).

alter table permits add column if not exists category text not null default 'permit'
  check (category in ('permit', 'non_permit'));

-- 1. CAR insurance -> now #1, non-permit. Preserve existing approved status.
update permits set seq = 1, category = 'non_permit',
  type = 'Póliza de Seguro Todo Riesgo Contratista (CAR)',
  notes = 'Hard gate: must be delivered before H1 disbursement (Art 5.3)'
  where id = '74695720-1673-43ba-8945-f23fa870a65c';

-- 2. Tree-felling permit -> now #2. Preserve existing approved status.
update permits set seq = 2, category = 'permit',
  type = 'Permiso de Tala de Árboles',
  notes = 'Can be requested without approved plans (Art 3.4 / Anexo C.9)'
  where id = '291c5082-51c6-4e38-8f2a-83943b3814e5';

-- 5. Bomberos review -> now #5.
update permits set seq = 5, category = 'permit',
  type = 'Permiso del Cuerpo de Bomberos (DINASEPI/BCBRP)',
  notes = 'Direct owner cost (~$950 est., Presupuesto Maestro Sección 7)'
  where id = '50e7106d-1312-4a6e-9c0c-3fb3d18afb85';

-- 6. Plumbing isometric approval -> merged with MINSA review into "Permiso
-- Sanitario de MINSA" -> now #6. The old separate MINSA-review row is dropped
-- below (same subject, one line item).
update permits set seq = 6, category = 'permit', responsible_party = 'contractor',
  type = 'Permiso Sanitario de MINSA (incl. isométricos de plomería)',
  notes = 'Precondition to the construction permit (Decreto 323 de 1971); direct owner cost bucket ~$950 (Presupuesto Maestro Sección 7)'
  where id = '62941e5c-2ae7-444a-a712-eac3ff29b5cc';

-- 7. Construction permit -> now #7.
update permits set seq = 7, category = 'permit',
  type = 'Permiso de Construcción (Vivienda Unifamiliar)',
  notes = 'Required before H2 foundation work'
  where id = 'e5ff6511-67a5-4c08-81f6-2372550e5632';

-- 8. Electrical permit -> now #8.
update permits set seq = 8, category = 'permit', type = 'Permiso Eléctrico'
  where id = '7e1e9524-636f-4c40-98fc-d51e623e162d';

-- 9. Naturgy connection -> now #9, non-permit.
update permits set seq = 9, category = 'non_permit',
  type = 'Conexión de Servicio Eléctrico Naturgy (200A)'
  where id = 'f6129339-0593-4259-8077-cf38b159c1f7';

-- 10. Occupancy permit -> now #10.
update permits set seq = 10, category = 'permit',
  type = 'Permiso de Ocupación', notes = 'Final permit'
  where id = 'e852e9ea-bd0a-480f-88c2-977c58967432';

-- New checklist items with no prior counterpart.
insert into permits (seq, type, category, status, responsible_party) values
  (3, 'Certificado de Zonificación (MIVIOT)', 'non_permit', 'not_started', 'contractor'),
  (4, 'Certificado de Paz y Salvo Municipal', 'non_permit', 'not_started', 'contractor');

-- Dropped: no counterpart in the new checklist.
-- - Permiso de Movimiento de Tierra (folded into the construction permit above)
-- - MINSA review (merged into "Permiso Sanitario de MINSA" above)
-- - HOA / Altos del María approval of the N-2 deferral: this is a private HOA
--   sign-off, not a government permit, so it doesn't belong on this checklist.
--   It was also the H6 entry in MILESTONE_PERMIT_GATES (app/index.html) — that
--   gate is removed since no permit row backs it anymore. Track the N-2
--   deferral approval via decision_log / milestone notes instead, or ask to
--   re-add it as an explicit item if you want it back on this list.
delete from permits where id in (
  'f2cc5b6a-b383-47dc-8435-0bec0a54d3ea', -- Permiso de Movimiento de Tierra
  '7b3f2c7c-7e7b-4c44-8641-d1032d05aafe', -- MINSA review (merged above)
  'b2c28f8a-0ace-4460-b027-72996c6b1b50'  -- HOA N-2 deferral approval
);

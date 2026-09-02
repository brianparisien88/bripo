-- "Out of pocket" / off-contract flag. Some payments and invoices are the
-- owner's direct spend (HUURRE panels, Bomberos/MINSA fees, extras) — they must
-- be recorded and can be linked to a milestone for context, but they do NOT net
-- against the $73,500 fixed-price Bripo contract.
alter table payments add column if not exists out_of_pocket boolean not null default false;
alter table invoices add column if not exists out_of_pocket boolean not null default false;

# CLAUDE.md — bripo

Construction dashboard for the **Altos de Maria** house build (contractor: Bripo,
fixed-price "Bripo Tiny House" $73,500, 21-week clock, 8 milestones H1–H8).

**Spec:** `docs/CHARTER.md` — read it before building. It's **gitignored** (has
professional names / a lot number / an LLC) so it stays out of the public repo;
it lives in your local `docs/`. **Reusable patterns:** `docs/BUILD-PLAYBOOK.md`
(carried from the trading-ai project).

Single-owner (+ optional family viewer). Not for the contractor/vendors —
they interact by email/WhatsApp/paper; the owner enters that data here.

## Architecture

```
owner enters data in the dashboard  ──►  Supabase (Postgres + RLS + Auth)
                                          project ref  mxjoxxckekgtlvbmpkbd, region us-east-1
static dashboard (app/index.html, GitHub Pages)  ◄──  reads live via supabase-js + publishable key
```

- **No sync job, no backend, no webhooks, no Edge Functions** for v1. All data is
  manual entry through the dashboard.
- **No LLM at runtime.** The one ambiguous step ("is this correspondence a
  decision worth logging?") is done on-request by Claude via the Gmail MCP
  connector in a chat session — Claude surfaces candidates, the owner confirms
  and types them into `decision_log`. Everything else (netting advances, %
  complete, the $250/week delay-penalty math, permit status) is deterministic
  frontend/SQL logic.
- USD only. No FX.

## Security (this is real — the contract has PII)

- **GitHub Pages cannot enforce a login.** A client-side "password gate" is
  theatre. The real boundary is **Supabase Auth + RLS**: every table's policy
  requires `public.is_member()` (an allow-listed `auth.uid()`) before any row is
  returned. Ship `app/` as an empty shell — no data baked in at build time.
- `app/robots.txt` + `<meta name="robots" content="noindex, nofollow">` so it
  isn't indexed even though it's technically public.
- **Never store or render cédula / RUC numbers** anywhere. The dashboard tracks
  money, milestones, permits — it doesn't need identity numbers. The contract PDF,
  if stored, goes in a private Supabase Storage bucket under the same RLS, never
  a public link.
- No public signup. Owner is added to `app_users` manually (see below).

## Data model

Migration `supabase/migrations/20260831210000_init.sql` — 13 tables, all RLS
member-read / owner-write, no anon access:

`app_users` (allow-list) · `contract_meta` (single row 'current' — penalty +
warranty math) · `milestones` (H1–H8, seeded) · `payments` (milestone_disbursement
| material_advance, with the Art 2.5 proof-of-purchase / proof-of-delivery gate)
· `invoices` + `payment_invoice_links` (many-to-many, never 1:1) · `permits`
(11 seeded) · `decision_log` (email/whatsapp/manual, `confirmed` gate) ·
`change_requests` (two-party sign-off, no auto budget propagation) ·
`future_work_items` (3 seeded — NOT contract modifications) · `vendors` ·
`documents` (Storage metadata) · `activity_log` (audit).

Helpers: `public.is_member()`, `public.is_owner()`, `public.schema_catalog()`.

## Deterministic logic to build (no LLM)

- **% complete** = Σ(contract_amount of milestones where status='complete') / 73500.
- **Amount due at a milestone** = `milestones.contract_amount − Σ(payments.amount
  where payment_type='material_advance' and milestone_id = this)`.
- **Delay penalty** = `max(0, weeks_elapsed_since(h1_disbursement_date) −
  weeks_allowed) × delay_penalty_per_week`, capped at `delay_penalty_cap`
  ($7,350). Hitting the cap is a contract-termination trigger (Art 4.1e) —
  surface it prominently, not quietly.
- **Advance compliance flag** = red if `proof_of_purchase_deadline < today` and
  `not proof_of_purchase_received`, or `not proof_of_delivery_received` before
  the next milestone pays.
- **Alerts** (if built): payment due against an upcoming milestone; permit /
  insurance gate not met for the next milestone. Pure date comparison.

## Hard rules

- **Branch → PR → merge. No pushing to `main`.** `pr-checks.yml` scans the diff
  for unguarded destructive ops. Ask Claude Code / `/code-review` for a review
  before merge.
- Never commit `.env`. `.gitignore` has `.env` + `.env.*` (checked before this
  file was created).
- The publishable key is intentionally in `app/index.html`. There is no secret
  key in v1; if one is ever added it never touches `app/` or a committed file.
- After any migration: `python tools/schema_snapshot.py` (needs a secret key —
  add `SUPABASE_SECRET_KEY` to `.env` from the Supabase dashboard when needed)
  and commit `docs/schema-snapshot.json`; update this file.

## First-run setup (do once, in a build session)

1. `app/index.html` signup/login screen → owner creates their account in Supabase
   Auth (or via the dashboard).
2. Get the owner's `auth.uid()` and insert the allow-list row **via MCP
   `execute_sql`** (service role, bypasses RLS):
   `insert into app_users (user_id, email, role) values ('<uid>', '<email>', 'owner');`
3. Set `contract_meta.h1_disbursement_date` once H1 is paid — that starts the
   21-week clock and the penalty math.

## Open questions from the charter (Fog §6) — resolve before/while building

- Who else needs access (spouse / lawyer / accountant)?
- How far to take alerts in v1 vs defer?
- Is WhatsApp correspondence in scope for v1's decision log (manual entry only,
  or a chat-export import)?
- Director de Obra still "TBD" in the contract — track their sign-off as a field
  per milestone, or is the `director_de_obra_approved` checkbox enough?

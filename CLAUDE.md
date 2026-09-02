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
- **No signup UI.** The login screen is sign-in only. Accounts are created by
  the owner in the Supabase dashboard (Authentication → Add user) and then
  allow-listed in `app_users`. Keep "Allow new users to sign up" disabled in
  Supabase Auth settings. An account with no `app_users` row sees nothing — RLS
  is the boundary.

## Data model

Migrations in `supabase/migrations/`:
- `20260831210000_init.sql` — 13 tables + helpers + RLS.
- `20260831213000_seeds_storage_hardening.sql` — idempotent seeds (milestones
  H1–H8, 11 permits, 3 future-work items), the private `documents` Storage bucket
  with matching member-read / owner-write policies, and the `is_member()` /
  `is_owner()` EXECUTE grants (kept on `anon` on purpose — see the file's note;
  revoking breaks RLS evaluation for logged-out requests).
- `20260901120000_milestone_start_end_dates.sql` — `milestones.planned_date` →
  `start_date`, `actual_date` → `end_date`.
- `20260902130000_out_of_pocket_flag.sql` — `payments.out_of_pocket` +
  `invoices.out_of_pocket` booleans. When true on a payment it is the owner's
  direct/off-contract spend: recorded, may be linked to a milestone for context,
  but **excluded from every contract-budget calculation** (`paidToDate`,
  `paidFor`, `advancesFor`, `disbursedFor`, `amountDue`). Surfaced separately as
  "Out-of-pocket spend" + "Grand total" (= contract price + out-of-pocket) tiles.

**Invoices are not payments.** Money totals (Overview, Budget, milestone Paid)
are `payments`-driven only. An invoice is the paper trail; it moves nothing until
a payment is recorded against it. The Invoices tab has a per-row "Record a
payment for this invoice" that opens `buildPaymentForm` with `prefill` (amount =
invoice total − already applied, recipient, milestone, out_of_pocket) and
`linkInvoiceId` — on save it inserts the payment and the `payment_invoice_links`
row. Documents upload is multi-file (`uploadDocs`); each invoice row has an
attach-files sub-row (`entityFiles`).

13 tables, all RLS member-read / owner-write, no anon access:

`app_users` (allow-list) · `contract_meta` (single row 'current' — penalty +
warranty math) · `milestones` (H1–H8, seeded) · `payments` (milestone_disbursement
| material_advance, with the Art 2.5 proof-of-purchase / proof-of-delivery gate)
· `invoices` + `payment_invoice_links` (many-to-many, never 1:1) · `permits`
(11 seeded) · `decision_log` (email/whatsapp/manual, `confirmed` gate) ·
`change_requests` (two-party sign-off, no auto budget propagation) ·
`future_work_items` (3 seeded — NOT contract modifications) · `vendors` ·
`documents` (Storage metadata) · `activity_log` (audit).

Helpers: `public.is_member()`, `public.is_owner()`, `public.schema_catalog()`.

## Deterministic logic (no LLM) — BUILT in `app/index.html` (v1)

Single-file vanilla-JS dashboard, `supabase-js` from CDN, 10 tabs (Overview,
Milestones, Budget & payments, Invoices, Permits, Decision log, Change requests,
Future work, Vendors, Documents). **Look** carried from the Trading-AI summary
page: warm editorial palette (CSS vars `--ground/--surface/--ink/--ink-soft/
--line/--accent/--loss/--warn` + `--warn` added for the amber pills), theme-aware
via `prefers-color-scheme` (light default, dark block), Fraunces (serif headings
+ tile values), IBM Plex Sans (body), IBM Plex Mono (labels / table headers /
numbers) from Google Fonts. Sign-in shell → `is_member()` gate →
`is_owner()` decides read-only vs editable. Every write goes through RLS and
also appends to `activity_log`. **EN / ES** via the `t()` helper + `I18N` dict +
the header toggle (persisted to `localStorage['bripo_lang']`); user-entered data
is never translated, only the chrome. Overview also has a milestone strip
(status / paid / contract / start / end per H1–H8) so Milestones-tab edits are
visible there immediately. The Overview "Attention" panel is the v1 alerts
feature (deterministic date math): prominent delay-penalty banner, material-
advance PoP/PoD compliance flags, the next-milestone approval gate (Director de
Obra, Paz y Salvo H2+, gating permits per `MILESTONE_PERMIT_GATES`), and a
bookkeeping-drift check (milestone status vs recorded disbursements).

`milestones.start_date` / `end_date` (renamed from `planned_date` / `actual_date`
in migration `20260901120000`) are ACTUAL start/finish dates — the contract makes
no per-milestone date promises; the only schedule commitment is the 21-week clock.
The Milestones tab shows a read-only **Paid** column = Σ payments linked to that
milestone; recording a payment (incl. partial installments) is done from the
milestone's expand row (`buildPaymentForm` with a locked `milestoneId`) or the
Budget tab. The per-milestone advances / amount-due breakdown lives on the
Budget tab only.

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
- After any migration: `set -a && . ./.env && set +a && python tools/schema_snapshot.py`
  (uses `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY` — the `schema_catalog()` RPC
  is granted to anon on purpose) and commit `docs/schema-snapshot.json`; update
  this file. Only column shape is captured, not seed rows.

## First-run setup (do once) — NOT yet done as of v1 handoff

1. Supabase dashboard → Authentication → Users → **Add user** for each account
   (owner does this; the app has no signup UI). Then keep **"Allow new users to
   sign up" disabled** in Auth settings.
2. Get each `auth.uid()` and insert the allow-list rows **via MCP `execute_sql`**
   (service role, bypasses RLS):
   `insert into app_users (user_id, email, role) values ('<uid>', '<email>', '<owner|viewer>');`
3. Set `contract_meta.h1_disbursement_date` (Budget & payments tab) once H1 is
   paid — that starts the 21-week clock and the penalty math.

## Open questions from the charter (Fog §6) — RESOLVED

- **Access:** `app_users` has brianparisien@gmail.com + chipochitanda@gmail.com
  as `owner` (co-owners of BC&P LLC) and jmcklin06@gmail.com (Jorge, the
  contractor) as `viewer` — owner's explicit call, made knowing a viewer can
  read every table including `decision_log`. Keep genuinely owner-private matters
  (disputes, legal advice) out of the dashboard from here on.
- **Alerts:** shipped as the deterministic Overview "Attention" panel (passive,
  shown on open). No push/scheduled notifications.
- **WhatsApp in the decision log:** manual entry (`source='whatsapp'`). The
  Jul–Aug negotiation export was imported 2026-08-31 as 26 `confirmed=false`
  rows (owner confirms/prunes in the UI). Export sits at `docs/WhatsApp Chat
  with Jorge McKlin - Builder …/` (gitignored, has PII).
- **Director de Obra:** the `milestones.director_de_obra_approved` boolean +
  `milestones.notes` free-text is enough. No dedicated sub-record.

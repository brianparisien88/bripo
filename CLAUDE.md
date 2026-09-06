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
  H1–H8, 10 permits [see the `20260903090000` migration below for the current
  list], 3 future-work items), the private `documents` Storage bucket
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
- `20260903090000_permits_official_checklist.sql` — replaced the contract-derived
  permit seed list with the owner's official 10-item permit/certificate checklist
  (adds `permits.category` = `permit` | `non_permit`); preserved existing progress
  on matched rows (CAR policy, tree-felling permit) via UPDATE rather than
  delete+reinsert. Dropped "Permiso de Movimiento de Tierra" (folded into the
  construction permit) and the HOA N-2 deferral approval (not a government
  permit — no longer tracked here; re-add as an item or via decision_log/
  milestone notes if you want it back). `MILESTONE_PERMIT_GATES` in
  `app/index.html` updated to the new seq numbers; the H6 permit gate was removed
  since nothing in the new checklist backs it.
- `20260905170000_wishlist_items.sql` — new `wishlist_items` table (`seq`, `label`,
  `category`, `info`, `price`, `link`, `notes`), same member-read/owner-write RLS
  as every other table. Seeded with the 56 rows from the owner's "House
  Wishlist" Google Sheet ("Shopping List" tab), imported 2026-09-05 — materials/
  fixtures/finishes under consideration, NOT contract items or budget lines
  (that's `future_work_items` / the Budget tab). One sheet cell (a bamboo-variety
  note under "Privacy trees") was misfiled under Price/Budget in the source and
  was moved to `info` since `price` is numeric here.
- `20260906123000_decision_log_calendar_event.sql` — `decision_log.calendar_event_id`
  + `calendar_event_link` (both nullable text). Written and cleared by an
  out-of-band Claude Code Routine, not by the dashboard — see "Decision log ↔
  Google Calendar sync" below.
- `20260906130000_moodboard_images.sql` — new `moodboard_images` table
  (`storage_path`, `label`, `description`, `uploaded_at`), same member-read/
  owner-write RLS as every other table. No new Storage bucket: images live in
  the existing private `documents` bucket under a `moodboard/` path prefix, so
  no new bucket policy was needed. Not yet applied to the live project — apply
  it (`mcp__Supabase__apply_migration` or the Supabase dashboard) and then
  regenerate `docs/schema-snapshot.json` per "Hard rules" below.

**Invoices are not payments.** Money totals (Overview, Budget, milestone Paid)
are `payments`-driven only. An invoice is the paper trail; it moves nothing until
a payment is recorded against it. The Invoices tab has a per-row "Record a
payment for this invoice" that opens `buildPaymentForm` with `prefill` (amount =
invoice total − already applied, recipient, milestone, out_of_pocket) and
`linkInvoiceId` — on save it inserts the payment and the `payment_invoice_links`
row. Documents upload is multi-file (`uploadDocs`); each invoice row has an
attach-files sub-row (`entityFiles`).

15 tables, all RLS member-read / owner-write, no anon access:

`app_users` (allow-list) · `contract_meta` (single row 'current' — penalty +
warranty math) · `milestones` (H1–H8, seeded) · `payments` (milestone_disbursement
| material_advance, with the Art 2.5 proof-of-purchase / proof-of-delivery gate)
· `invoices` + `payment_invoice_links` (many-to-many, never 1:1) · `permits`
(10 seeded — the owner's official permit/certificate checklist, `category` =
permit | non_permit) · `decision_log` (email/whatsapp/manual, `confirmed` gate) ·
`change_requests` (two-party sign-off, no auto budget propagation) ·
`future_work_items` (3 seeded — NOT contract modifications) · `vendors` ·
`documents` (Storage metadata) · `wishlist_items` (56 seeded — materials/fixtures
shopping list, sortable/searchable table on the Wishlist tab) ·
`moodboard_images` (image upload metadata for the Moodboard tab, Storage-backed
same as `documents`) · `activity_log` (audit).

Helpers: `public.is_member()`, `public.is_owner()`, `public.schema_catalog()`.

## Deterministic logic (no LLM) — BUILT in `app/index.html` (v1)

Single-file vanilla-JS dashboard, `supabase-js` from CDN, 12 tabs (Overview,
Milestones, Budget & payments, Invoices, Permits, Decision log, Change requests,
Future work, Vendors, Documents, Moodboard, Wishlist). **Look** carried from the Trading-AI summary
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

### Decision log ↔ Google Calendar sync

Still no sync job, backend, webhook, or Edge Function *in the app* — this is a
recurring **Claude Code Routine** (a scheduled trigger, external to
`app/index.html` and to GitHub Pages/Supabase) that polls `decision_log` and:
one-way mirrors each unconfirmed row to a 1:00–1:30pm `America/Panama` event
on the owner's primary Google Calendar (`brianparisien@gmail.com`), storing
the event's id/htmlLink back on the row (`calendar_event_id` /
`calendar_event_link`) so a later edit updates the same event instead of
duplicating it; deletes the event and clears both columns once the row is
confirmed (or if the row itself is deleted while still unconfirmed). The
dashboard only *displays* `calendar_event_link` (a 📅 link on the Decision log
tab) — it never creates, edits, or deletes calendar events itself, and a
signed-in owner editing a row's date/summary/party/resolves takes effect on
the next Routine run, not instantly.

The **Wishlist** tab (`wishlist_items`) is a flat, spreadsheet-like editable
table — every cell writes straight through RLS like the rest of the app, "+
Add item" inserts a new row at the next `seq`, and the search box filters
client-side across label/category/info/link/notes. Column-header clicks toggle
sort (`wishlistSort`); both that and the search text (`wishlistQuery`) are kept
as plain module-level JS state (not on `S`) and only re-render the table body,
not the whole page — so typing in the search box doesn't lose focus the way a
full `render()` would. Long free-text columns (info/link/notes, which can hold
multiple newline-separated URLs) use a `<textarea>` cell, not a single-line
`<input>`, so editing never silently drops embedded newlines.

The **Moodboard** tab (`moodboard_images`) uploads image files straight into the
existing private `documents` Storage bucket under a `moodboard/` path prefix
(no new bucket) and stores the metadata row (`label`, `description`,
`storage_path`, `uploaded_at`). The 10 most recently uploaded images (sorted by
`uploaded_at` desc in `loadAll`, `MOODBOARD_GRID_SIZE`) render as a uniform,
auto-flowing grid (`grid-template-columns:repeat(auto-fill,minmax(220px,1fr))`,
all tiles the same size, no hero/featured image) via short-lived (1hr) signed
URLs fetched per-image, `object-fit:contain` so nothing is cropped; anything
older drops to a plain linkable list. Clicking any image (grid tile or an
older-list link) opens the full-size signed URL in a new tab. There is no
image-resizing/compression on upload — large source files are stored as-is.
Every row — every grid tile and every older-list row — is inline-editable via
a shared `moodboardRowEditing` Set (same pencil-toggle pattern as Decision
log/Wishlist row-editing): a pencil switches label + description into
editable fields, a checkmark switches back, and a Remove/× button deletes.
Deleting removes the Storage object first, then the metadata row, so a failed
Storage delete never leaves an orphaned row. While there are fewer than 10
real uploads the grid pads out with dashed, non-interactive placeholder tiles
(so the layout doesn't collapse) — the only place with placeholder content;
the older-list's empty state is just a plain message.
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

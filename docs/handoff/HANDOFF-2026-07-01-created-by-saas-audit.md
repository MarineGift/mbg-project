# Handoff - created_by audit + SaaS development standard

## What was done

1. **created_by added to entity tables** (`created_by_audit.sql`). The app was
   already mostly SaaS-consistent - core entities (parties, contacts, deals,
   campaigns, communications, engagements, teams, roles, pipelines, todo_items,
   etc.) already had `created_by`. The audit filled the remaining gaps:
   `created_by uuid default auth.uid()`, existing rows backfilled to the org
   owner. Idempotent (a second run skipped everything).

2. **Trimmed back to the correct set** (`created_by_cleanup.sql`). The audit was
   deliberately broad; the cleanup drops `created_by` from tables that should not
   have it (see rules below).

## Convention (confirmed)

- `created_by uuid default auth.uid()`.
- `app.users.id` **equals** the Supabase auth id (`auth.uid()` returned
  `551fc4a0-...`, same as the owner). So `default auth.uid()` is the correct
  value and works for additional users too.
- No FK is set yet. Optional finishing step: add
  `created_by uuid references app.users(id)` across entity tables for
  referential integrity (all current values are the owner or NULL, so it
  validates). Requires that every auth user has a mirrored `app.users` row.

## <!> SaaS / multi-tenant development standard (must follow)

**mbg-project is built to SaaS standards and must remain usable by multiple
users and organizations. No hardcoded single-user or single-org assumptions in
app logic.** Every change follows:

- **Tenant isolation:** all tenant data is org-scoped via RLS
  (`organization_id` + policy). Never rely on a single known org id in app code.
- **Attribution:** every user-created **entity** table carries
  `created_by uuid default auth.uid()` and `created_at` / `updated_at`. Writes
  attribute to the acting user via `auth.uid()`.
- **Where created_by belongs:** genuine entities the user creates/owns
  (campaigns, deals, parties, contacts, attachments, templates, sequences,
  saved_views, profiles, todo_groups, inbound_mailboxes, organizations, users,
  roles, ...).
- **Where it does NOT belong (do not add):**
  - join / link tables (`*_parties`, `*_focus`, `*_attendees`, `team_members`,
    `role_permissions`, `user_roles`, `mail_run_recipients`, `todo_dependencies`)
  - history / audit trails (`*_history`)
  - reference / lookup (`countries`, `sectors`, `*_types`, `meeting_modes`,
    `investment_stages`, `todo_status_options`, `permissions`, ...)
  - log / derived / worker-state (`*_log`, `*_tracking(_events)`, `*_scores`,
    `mailcarrier_state`, `email_sequence_sends`)
  - 1:1 detail extensions of a parent (`engagement_email_details`,
    `engagement_meeting_details`)
  - backups (`_bak_*`)
- **New tables** follow this from creation (entity -> created_by + timestamps +
  org scope; non-entity -> none).
- **This standard is embedded in every handoff.**

## How to run

Both are plain SQL, run once in the Supabase SQL editor (or via a direct
connection if the editor throws "Failed to fetch" / times out):

1. `created_by_audit.sql`  (already applied)
2. `created_by_cleanup.sql` (this trims the over-included tables; prints a grid
   of what it dropped)

No app code references these columns yet, so dropping is safe and instant.

## Repo storage (these migrations)

Both SQL files were **already applied manually** in the Supabase SQL editor.
They are stored in `supabase/migrations/` for version-control record only; the
Railway app deploy does **not** auto-run migrations, so storing them is inert.

Mover: `apply-created-by-migrations.ps1` (run from Downloads). It moves:

| Download | Repo path |
|----------|-----------|
| `20260701150000_created_by_audit.sql`   | `supabase/migrations/20260701150000_created_by_audit.sql` |
| `20260701150100_created_by_cleanup.sql` | `supabase/migrations/20260701150100_created_by_cleanup.sql` |
| `HANDOFF-2026-07-01-created-by-saas-audit.md` | `docs/handoff/HANDOFF-2026-07-01-created-by-saas-audit.md` |

Run:
```
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\apply-created-by-migrations.ps1"
```

Then commit + push:
```
cd C:\dev\mbg-project
git status -sb
git add supabase/migrations/20260701150000_created_by_audit.sql supabase/migrations/20260701150100_created_by_cleanup.sql docs/handoff/HANDOFF-2026-07-01-created-by-saas-audit.md
git commit -m "chore(db): store created_by audit + cleanup migrations; embed SaaS dev standard in handoff"
git pull --rebase
git push origin marinebiogroup
```
Push publishes to the web (Railway auto-deploys), but these files are docs/SQL
only - no app behavior changes.

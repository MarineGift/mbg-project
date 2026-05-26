# SESSION HANDOFF - 2026-05-18

## Project Info
- Path: C:\dev\mbg-project
- Stack: Next.js 14.2 / Supabase / Anthropic SDK
- Branch: fix/missing-modules-stubs
- Latest Tag: v5.22a-calendar-phase-b

---

## Completed Today (2026-05-18)

### v5.22a - Calendar Integration Phase B

#### DB Migrations Applied
- 030_calendar_integration.sql - 4 tables + 6 ENUMs
  - calendar_connections, calendar_events, meetings, meeting_attendees
  - meeting_type / meeting_mode ENUMs added separately
- 031_calendar_token_functions.sql - RPC functions
  - encrypt/decrypt/upsert_calendar_connection
  - update_calendar_tokens, update_calendar_sync_state

#### Files Deployed (17 files)
- src/lib/calendar/token-crypto.ts
- src/lib/calendar/google-client.ts
- src/lib/calendar/microsoft-client.ts
- src/lib/calendar/sync-engine.ts
- src/app/api/calendar/google/connect/route.ts
- src/app/api/calendar/google/callback/route.ts
- src/app/api/calendar/microsoft/connect/route.ts
- src/app/api/calendar/microsoft/callback/route.ts
- src/app/api/calendar/sync/route.ts
- src/app/actions/calendar-sync.ts
- src/lib/queries/calendar.ts (v2 - meetings integrated)
- src/lib/queries/meetings.ts (new)
- src/components/calendar/calendar-event-chip.tsx
- src/components/calendar/calendar-view.tsx
- src/components/meetings/meeting-create-modal.tsx
- src/app/(app)/calendar/page.tsx
- src/app/(app)/settings/calendar/page.tsx

#### Env Vars Added to .env.local
- CALENDAR_TOKEN_ENCRYPTION_KEY=bf680541...
- NEXT_PUBLIC_APP_URL=http://localhost:3000

#### Verified Working
- /settings/calendar page renders correctly
- Google Calendar / Microsoft Outlook connection cards displayed
- Env vars checklist displayed

---

## Known Issues / Pending

### 1. OAuth Apps Not Registered Yet
- Google and Microsoft OAuth apps not created
- Connection buttons will fail until registered

### 2. PowerShell Lesson Learned
- Do NOT use ps1 files downloaded from browser (execution policy blocks)
- Use inline PowerShell commands directly in terminal
- Korean text in Write-Host causes encoding errors - use English only

---

## Next Session Tasks

### Priority 1 - Google OAuth App Registration
- Go to console.cloud.google.com
- APIs & Services -> Credentials -> OAuth 2.0 Client ID
- Application type: Web application
- Authorized redirect URI: http://localhost:3000/api/calendar/google/callback
- Add to .env.local:
  GOOGLE_CALENDAR_CLIENT_ID=xxx
  GOOGLE_CALENDAR_CLIENT_SECRET=xxx
  GOOGLE_CALENDAR_REDIRECT_URI=http://localhost:3000/api/calendar/google/callback

### Priority 2 - Microsoft OAuth App Registration
- Go to portal.azure.com
- App registrations -> New registration
- Supported account types: Accounts in any organizational directory + personal
- Redirect URI: http://localhost:3000/api/calendar/microsoft/callback
- Add to .env.local:
  MICROSOFT_CALENDAR_CLIENT_ID=xxx
  MICROSOFT_CALENDAR_CLIENT_SECRET=xxx
  MICROSOFT_CALENDAR_REDIRECT_URI=http://localhost:3000/api/calendar/microsoft/callback

### Priority 3 - Test OAuth Flow
- npm run dev
- /settings/calendar -> click Connect button
- Verify OAuth redirect works
- Verify token saved to calendar_connections table

### Priority 4 - Test Sync
- POST /api/calendar/sync
- Verify events appear in calendar_events table
- Check /calendar page renders events

---

## Architecture Reference

### Token Security
- Tokens encrypted with pgp_sym_encrypt (pgcrypto)
- Encryption key: CALENDAR_TOKEN_ENCRYPTION_KEY env var
- Decryption only via service_role RPC

### Sync Strategy
- Google: syncToken based incremental sync (410 Gone = full resync)
- Microsoft: deltaLink based incremental sync
- First connect: 1 year history full sync

### Calendar Item Colors
- meeting: blue (bg-blue-600)
- task: orange (bg-orange-500)
- communication: gray (bg-slate-400)
- event/internal: purple (bg-violet-500)
- event/google: green (bg-emerald-500)
- event/microsoft: indigo (bg-indigo-500)

### Organization ID Pattern (JWT)
- payload.organization_id ?? payload.app_metadata?.organization_id ?? payload.user_metadata?.organization_id
- Reference: src/app/actions/delete-communication.ts

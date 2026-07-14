// src/app/(app)/mailing/outcomes/page.tsx
// Send-outcome dashboard: what happened after we pressed send.
//
//   1. Summary cards  - count per outcome              (snippets Q3)
//   2. Action board   - switch_contact / switch_deck / follow_up (Q5)
//   3. Resend queue   - resend_later, ordered by resend_not_before, D-day (Q4)
//   4. Recent log     - full table with party links + outcome badges
//   5. Manual entry   - quick form (recipient, outcome, reason, next action)
//
// Data source: app.email_send_outcomes (migration_20260714090000) via
// lib/actions/email-outcomes.ts. Auto rows are written by the MailCarrier
// NDR extension (lib/email/outcome-recorder.ts, source='mailcarrier');
// manual rows come from the form (source='manual').

import { listOutcomes } from '@/lib/actions/email-outcomes';
import { OutcomesClient } from './outcomes-client';

export const dynamic = 'force-dynamic';

export default async function MailingOutcomesPage() {
  const rows = await listOutcomes();
  return (
    <div className="p-4 sm:p-6">
      <OutcomesClient initialRows={rows} />
    </div>
  );
}

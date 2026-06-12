// src/app/attachments-test/page.tsx
// Temporary test page for the Kickstarter pilot.
// Visit /attachments-test to exercise the Attachments panel against the
// seeded deal, checklist and budget task. Delete this folder after testing.

import AttachmentsPanel from '@/components/attachments/attachments-panel';

const DEAL_ID = 'fb2249de-9a2d-4bab-81f9-4d8208db78a3';
const CHECKLIST_PREP_ID = 'e5055cb2-6dc2-47a1-a695-9f7211bef77b';
const TASK_BUDGET_ID = 'edceb03f-b5c0-4e60-880a-18e1b18e8aed';

export default function AttachmentsTestPage() {
  return (
    <main className="mx-auto max-w-2xl space-y-6 p-6">
      <div>
        <h1 className="text-lg font-bold text-gray-900">
          Attachments panel test (Kickstarter pilot)
        </h1>
        <p className="mt-1 text-sm text-gray-500">
          Paste Google Drive share links below. Rows are written to
          app.attachments with storage_provider google_drive.
        </p>
      </div>

      <AttachmentsPanel
        entityType="task"
        entityId={TASK_BUDGET_ID}
        title="Task: Confirm funding goal and budget"
      />

      <AttachmentsPanel
        entityType="deal_checklist"
        entityId={CHECKLIST_PREP_ID}
        title="Checklist: Campaign preparation"
      />

      <AttachmentsPanel
        entityType="deal"
        entityId={DEAL_ID}
        title="Deal: Kickstarter - MarineBio Crowdfunding (Pilot)"
      />
    </main>
  );
}

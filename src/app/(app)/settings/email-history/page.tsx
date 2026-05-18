// src/app/(app)/settings/email-history/page.tsx
import { fetchEmailHistory, countEmailHistory } from '@/lib/queries/email-history';
import { EmailHistoryClient } from '@/components/settings/email-history-client';

export const metadata = { title: 'Email History' };

export default async function EmailHistoryPage() {
  const orgId = process.env.NEXT_PUBLIC_DEFAULT_ORG_ID ?? '';
  if (!orgId) {
    return (
      <div className="max-w-6xl mx-auto p-6">
        <div className="text-red-700 bg-red-50 border border-red-200 rounded-lg p-4 text-sm">
          NEXT_PUBLIC_DEFAULT_ORG_ID not set.
        </div>
      </div>
    );
  }

  const [rows, total] = await Promise.all([
    fetchEmailHistory(orgId, 200, 0),
    countEmailHistory(orgId),
  ]);

  return (
    <div className="max-w-6xl mx-auto p-6">
      <EmailHistoryClient rows={rows} totalCount={total} />
    </div>
  );
}

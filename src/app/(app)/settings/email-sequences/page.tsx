// src/app/(app)/settings/email-sequences/page.tsx
import { fetchSequences } from '@/lib/queries/email-sequences';
import { EmailSequencesClient } from '@/components/settings/email-sequences-client';

export const metadata = { title: 'Email Sequences' };

export default async function EmailSequencesPage() {
  const orgId = process.env.NEXT_PUBLIC_DEFAULT_ORG_ID ?? '';

  if (!orgId) {
    return (
      <div className="max-w-5xl mx-auto p-6">
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-sm text-red-700">
          NEXT_PUBLIC_DEFAULT_ORG_ID 환경변수가 설정되지 않았습니다.
          <br />
          <code>.env.local</code>에 추가 후 dev 서버를 재시작하세요.
        </div>
      </div>
    );
  }

  const sequences = await fetchSequences(orgId);

  return (
    <div className="max-w-5xl mx-auto p-6">
      <EmailSequencesClient sequences={sequences} orgId={orgId} />
    </div>
  );
}

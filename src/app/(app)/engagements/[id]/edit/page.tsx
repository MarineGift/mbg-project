/**
 * app/(app)/engagements/[id]/edit/page.tsx
 *
 * Engagement 수정 페이지.
 *
 * 디자인 결정: detail 페이지(/engagements/[id])와 동일하게 module 세그먼트 없이
 * 직접 접근. existing.module이 form에 전달되며, partyId/partyName도 existing에서 추출.
 */

import { notFound } from 'next/navigation';
import { EngagementForm } from '@/components/engagements/engagement-form';
import { fetchEngagementDetail } from '@/lib/queries/engagements';
import { requireAuthOrRedirect } from '@/lib/auth';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function EditEngagementPage({ params }: PageProps) {
  const { id } = await params;

  // UUID 형식 검증
  if (!/^[0-9a-f-]{36}$/i.test(id)) {
    notFound();
  }

  // 인증
  await requireAuthOrRedirect();

  // engagement 로드 (없거나 다른 organization이면 RLS가 차단 → null)
  const engagement = await fetchEngagementDetail(id);
  if (!engagement) {
    notFound();
  }

  return (
    <div className="p-6 max-w-3xl mx-auto">
      <EngagementForm
        mode="edit"
        partyType={engagement.partyType}
        existing={engagement}
      />
    </div>
  );
}

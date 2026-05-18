import { Suspense } from 'react';
import { EmailSignatureClient } from '@/components/settings/email-signature-client';
import { getSignatures } from '@/lib/queries/email-signatures';
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';

async function getOrgId(): Promise<string> {
  const supabase = createServerComponentClient({ cookies });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');
  const { data } = await supabase
    .from('organization_members').select('organization_id')
    .eq('user_id', user.id).single();
  return data?.organization_id ?? '';
}

export default async function EmailSignaturePage() {
  const orgId = await getOrgId();
  const signatures = await getSignatures(orgId);
  return (
    <div className="max-w-3xl space-y-6 p-6">
      <div>
        <h2 className="text-lg font-semibold">이메일 서명</h2>
        <p className="text-sm text-muted-foreground">
          이메일 발송 시 자동으로 첨부되는 HTML 서명을 관리합니다.
        </p>
      </div>
      <Suspense fallback={<div className="text-sm text-muted-foreground">로딩 중...</div>}>
        <EmailSignatureClient orgId={orgId} initialSignatures={signatures} />
      </Suspense>
    </div>
  );
}
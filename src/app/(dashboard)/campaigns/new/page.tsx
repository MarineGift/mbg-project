import Link from 'next/link';
import CampaignWizard from './CampaignWizard';
import { getUserAndOrg } from '@/lib/supabase/server';
import { env } from '@/lib/env';

export const dynamic = 'force-dynamic';

export default async function NewCampaignPage() {
  // 인증 확인 (미들웨어가 우선 처리하지만 defense in depth)
  await getUserAndOrg();

  const defaultFromAddress = env.TABS_MAILER_FROM_DEFAULT
    ?? `noreply@${env.TABS_MAILER_FROM_DOMAIN}`;

  return (
    <div>
      <Link href="/campaigns" style={{ fontSize: 13, color: '#666', textDecoration: 'none' }}>
        ← Campaigns
      </Link>
      <CampaignWizard defaultFromAddress={defaultFromAddress} />
    </div>
  );
}

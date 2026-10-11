// src/app/(app)/marketing/page.tsx
// Marketing: directory-segment bulk outreach (e.g. global paper mills -> FCC).
// Loads selector inputs; segment resolution + sending happen in server actions
// (lib/actions/marketing-segment.ts + lib/actions/bulk-mail.ts).

import { createSupabaseServerClient } from '@/lib/supabase/server';
import { listMailAccountOptions } from '@/lib/actions/mail-account-options';
import { fetchCountryNames } from '@/lib/queries/countries';
import { MarketingClient } from './marketing-client';

export const dynamic = 'force-dynamic';

export default async function MarketingPage() {
  const supabase = await createSupabaseServerClient();

  const { data: ptRaw } = await supabase
    .schema('app')
    .from('party_types' as never)
    .select('code, display_name_en, sort_order, is_active')
    .eq('is_active', true)
    .order('sort_order', { ascending: true });
  const partyTypes = ((ptRaw ?? []) as Array<{ code: string; display_name_en: string }>).map((p) => ({
    code: p.code,
    name: p.display_name_en,
  }));

  const { data: tmplRaw } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .select('id, name, subject, body_plain, body_html, category, party_type')
    .eq('is_active', true)
    .order('name', { ascending: true });
  const templates = (
    (tmplRaw ?? []) as Array<{
      id: string; name: string; subject: string | null; body_plain: string | null;
      body_html: string | null; category: string | null; party_type: string | null;
    }>
  ).map((t) => ({
    id: t.id,
    name: t.name,
    subject: t.subject ?? '',
    body: t.body_plain && t.body_plain.trim() ? t.body_plain : (t.body_html ?? '').replace(/<[^>]+>/g, ''),
    category: t.category,
    module: t.party_type,
  }));

  const acctRes = await listMailAccountOptions();
  const accounts = acctRes.accounts.map((a) => ({
    id: a.id,
    address: a.address,
    displayName: a.displayName,
    isDefault: a.isDefault,
  }));

  const countryNames = await fetchCountryNames();

  return <MarketingClient partyTypes={partyTypes} templates={templates} accounts={accounts} countryNames={countryNames} />;
}

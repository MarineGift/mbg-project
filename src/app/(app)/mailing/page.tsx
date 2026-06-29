// src/app/(app)/mailing/page.tsx
// Bulk mailing (Fork A): send a template to a pipeline-stage's deal parties OR
// a hand-picked set of parties, excluding any party that already received that
// template. Candidate resolution, dedup and whitelist status are computed
// server-side (lib/actions/bulk-mail.ts + lib/queries/bulk-mail.ts); this page
// only loads the selector inputs and hands them to the client.

import { createSupabaseServerClient } from '@/lib/supabase/server';
import { listMailAccountOptions } from '@/lib/actions/mail-account-options';
import { fetchSequences } from '@/lib/queries/email-sequences';
import { MailingTabsClient } from './mailing-tabs-client';

export const dynamic = 'force-dynamic';

export default async function MailingPage() {
  const supabase = await createSupabaseServerClient();

  // Active pipelines (sidebar order).
  const { data: pipelinesRaw } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, code, name, sort_order')
    .eq('is_active', true)
    .order('sort_order', { ascending: true });
  const pipelines = (
    (pipelinesRaw ?? []) as Array<{ id: string; code: string; name: string; sort_order: number }>
  ).map((p) => ({ id: p.id, code: p.code, name: p.name }));

  // Active stages of those pipelines, grouped client-side by pipelineId.
  const pipelineIds = pipelines.map((p) => p.id);
  let stages: Array<{ id: string; pipelineId: string; name: string }> = [];
  if (pipelineIds.length > 0) {
    const { data: stagesRaw } = await supabase
      .schema('app')
      .from('stages' as never)
      .select('id, pipeline_id, code, name, sort_order')
      .in('pipeline_id', pipelineIds)
      .eq('is_active', true)
      .order('sort_order', { ascending: true });
    stages = (
      (stagesRaw ?? []) as Array<{ id: string; pipeline_id: string; code: string | null; name: string; sort_order: number }>
    ).map((s) => ({ id: s.id, pipelineId: s.pipeline_id, code: s.code, name: s.name }));
  }

  // Active templates (party_type is the module tag, not a stage mapping).
  const { data: tmplRaw } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .select('id, name, subject, category, party_type, stage_code')
    .eq('is_active', true)
    .order('name', { ascending: true });
  const templates = (
    (tmplRaw ?? []) as Array<{
      id: string;
      name: string;
      subject: string | null;
      category: string | null;
      party_type: string | null;
      stage_code: string | null;
    }>
  ).map((t) => ({
    id: t.id,
    name: t.name,
    subject: t.subject ?? '',
    category: t.category,
    module: t.party_type,
    stageCode: t.stage_code,
  }));

  // From accounts (active SMTP-ready inbound_mailboxes).
  const acctRes = await listMailAccountOptions();
  const accounts = acctRes.accounts.map((a) => ({
    id: a.id,
    address: a.address,
    displayName: a.displayName,
    isDefault: a.isDefault,
  }));

  // Email sequences (for the second tab). Same org source as the
  // settings/email-sequences page.
  const orgId = process.env.NEXT_PUBLIC_DEFAULT_ORG_ID ?? '';
  let sequences: Awaited<ReturnType<typeof fetchSequences>> = [];
  if (orgId) {
    try {
      sequences = await fetchSequences(orgId);
    } catch {
      sequences = [];
    }
  }

  return (
    <MailingTabsClient
      mailing={{ pipelines, stages, templates, accounts }}
      sequences={sequences}
      orgId={orgId}
    />
  );
}

import 'server-only';
import type { SupabaseClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { applyVariables } from '@/lib/csv/parser';
import { env } from '@/lib/env';

export class CampaignCreateError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'CampaignCreateError';
  }
}

export interface CampaignBlueprint {
  name: string;
  subjectTemplate: string;
  bodyTemplate: string;
  fromName?: string;
  fromAddress?: string;
  replyToAddress?: string;
  recipients: Array<{
    email: string;
    variables: Record<string, string>;
  }>;
}

export interface CampaignCreateResult {
  mailMergeJobId: string;
  totalRecipients: number;
  insertedCommunications: number;
  invalidEmails: string[];
}

/**
 * 캠페인 빌더 wizard에서 받은 청사진을 받아:
 *   1. 입력 검증 (수신자 수, 이메일 형식)
 *   2. mail_merge_jobs 행 INSERT (status='queued', payload에 템플릿/설정 저장)
 *   3. 각 수신자에 대해 communications 행 INSERT (direction='outbound', status='queued')
 *      - subject/body는 미리 변수 치환된 결과로 저장 (start endpoint에서 추가 작업 없이 sendOne)
 *   4. mail_merge_job_id 반환
 *
 * 부분 실패 처리: communications INSERT 중 일부 실패해도 mail_merge_job은 유지.
 * 완전 실패 시(jobs INSERT 실패) CampaignCreateError throw.
 *
 * NOTE: app.mail_merge_jobs 테이블에 `payload jsonb` 컬럼이 있다고 가정.
 * STEP 1 SQL에 없으면 `ALTER TABLE app.mail_merge_jobs ADD COLUMN payload jsonb;` 추가.
 */
export async function createCampaign(
  supabase: SupabaseClient,
  organizationId: string,
  createdByUserId: string,
  blueprint: CampaignBlueprint,
): Promise<CampaignCreateResult> {
  // 1. 입력 검증
  if (!blueprint.name.trim()) {
    throw new CampaignCreateError('캠페인 이름이 필요합니다');
  }
  if (!blueprint.subjectTemplate.trim()) {
    throw new CampaignCreateError('제목 템플릿이 필요합니다');
  }
  if (!blueprint.bodyTemplate.trim()) {
    throw new CampaignCreateError('본문 템플릿이 필요합니다');
  }
  if (blueprint.recipients.length === 0) {
    throw new CampaignCreateError('수신자가 0명입니다');
  }

  const fromAddress = blueprint.fromAddress
    ?? env.TABS_MAILER_FROM_DEFAULT
    ?? `noreply@${env.TABS_MAILER_FROM_DOMAIN}`;

  const invalidEmails: string[] = [];
  const validRecipients = blueprint.recipients.filter((r) => {
    const ok = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(r.email.trim());
    if (!ok) invalidEmails.push(r.email);
    return ok;
  });

  if (validRecipients.length === 0) {
    throw new CampaignCreateError('유효한 이메일 수신자가 없습니다');
  }

  // 2. mail_merge_jobs INSERT
  const payload = {
    subject_template: blueprint.subjectTemplate,
    body_template: blueprint.bodyTemplate,
    from_name: blueprint.fromName ?? null,
    from_address: fromAddress,
    reply_to_address: blueprint.replyToAddress ?? null,
    total_recipients: validRecipients.length,
    invalid_email_count: invalidEmails.length,
    created_by: createdByUserId,
  };

  const { data: jobRow, error: jobErr } = await supabase
    .schema('app')
    .from('mail_merge_jobs')
    .insert({
      organization_id: organizationId,
      name: blueprint.name.trim(),
      status: 'queued',
      progress: {
        totalRecipients: validRecipients.length,
        totalSent: 0,
        totalDelivered: 0,
        totalOpened: 0,
        totalClicked: 0,
        totalBounced: 0,
        totalFailed: 0,
        upstreamStatus: 'pending',
        syncedAt: new Date().toISOString(),
      },
      payload,
    })
    .select('id')
    .single();

  if (jobErr || !jobRow) {
    throw new CampaignCreateError(
      `mail_merge_jobs INSERT 실패: ${jobErr?.message ?? 'unknown'}`,
      jobErr,
    );
  }

  const jobId = String((jobRow as { id: string }).id);

  // 3. communications 행 INSERT (배치)
  const now = new Date().toISOString();
  const fromDomain = env.TABS_MAILER_FROM_DOMAIN;

  const commRows = validRecipients.map((r) => {
    const renderedSubject = applyVariables(blueprint.subjectTemplate, r.variables);
    const renderedBody = applyVariables(blueprint.bodyTemplate, r.variables);
    return {
      organization_id: organizationId,
      direction: 'outbound' as const,
      channel: 'email' as const,
      message_id: `<urm-camp-${randomUUID()}@${fromDomain}>`,
      from_address: fromAddress,
      from_name: blueprint.fromName ?? null,
      to_addresses: [r.email],
      cc_addresses: [],
      bcc_addresses: [],
      reply_to_address: blueprint.replyToAddress ?? null,
      subject: renderedSubject,
      body_plain: renderedBody,
      status: 'queued' as const,
      occurred_at: now,
      external_data: {
        campaign_id: jobId,
        campaign_name: blueprint.name.trim(),
        template_variables: r.variables,
      },
      template_variables: r.variables,
      ai_generated: false,
      ai_processing_status: 'skipped',
      sent_by_user_id: createdByUserId,
      pii_masked: false,
      is_starred: false,
      is_important: false,
    };
  });

  // Supabase는 한 번에 1000행까지 INSERT 가능. 보수적으로 100씩 chunk.
  const CHUNK_SIZE = 100;
  let inserted = 0;

  for (let i = 0; i < commRows.length; i += CHUNK_SIZE) {
    const chunk = commRows.slice(i, i + CHUNK_SIZE);
    const { error: commErr, data: commData } = await supabase
      .schema('app')
      .from('communications')
      .insert(chunk)
      .select('id');

    if (commErr) {
      // eslint-disable-next-line no-console
      console.error(
        `[campaign-creator] communications batch ${i}-${i + chunk.length} 실패: ${commErr.message}`,
      );
      // 부분 실패 — 진행 상황은 progress.totalFailed에 기록하고 계속
    } else {
      inserted += (commData ?? []).length;
    }
  }

  if (inserted === 0) {
    throw new CampaignCreateError(
      'communications 행이 하나도 INSERT되지 않았습니다 — 캠페인 무효',
    );
  }

  return {
    mailMergeJobId: jobId,
    totalRecipients: validRecipients.length,
    insertedCommunications: inserted,
    invalidEmails,
  };
}

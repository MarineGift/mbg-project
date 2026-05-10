'use server';

import { revalidatePath } from 'next/cache';
import { getUserAndOrg } from '@/lib/supabase/server';
import { createCampaign, CampaignCreateError, type CampaignBlueprint } from '@/lib/email/campaign-creator';

export interface CreateCampaignActionInput {
  name: string;
  subjectTemplate: string;
  bodyTemplate: string;
  fromName?: string;
  fromAddress?: string;
  replyToAddress?: string;
  recipients: Array<{ email: string; variables: Record<string, string> }>;
}

export interface CreateCampaignActionResult {
  ok: boolean;
  mailMergeJobId?: string;
  totalRecipients?: number;
  insertedCommunications?: number;
  invalidEmails?: string[];
  error?: string;
}

/**
 * 캠페인 wizard에서 호출되는 Server Action.
 * 클라이언트가 구조화된 입력을 전달 (FormData 직렬화 회피).
 */
export async function createCampaignAction(
  input: CreateCampaignActionInput,
): Promise<CreateCampaignActionResult> {
  let auth;
  try {
    auth = await getUserAndOrg();
  } catch (err) {
    return { ok: false, error: `unauthorized: ${(err as Error).message}` };
  }

  const blueprint: CampaignBlueprint = {
    name: input.name,
    subjectTemplate: input.subjectTemplate,
    bodyTemplate: input.bodyTemplate,
    fromName: input.fromName,
    fromAddress: input.fromAddress,
    replyToAddress: input.replyToAddress,
    recipients: input.recipients,
  };

  try {
    const result = await createCampaign(
      auth.supabase,
      auth.organizationId,
      auth.userId,
      blueprint,
    );
    revalidatePath('/campaigns');
    return {
      ok: true,
      mailMergeJobId: result.mailMergeJobId,
      totalRecipients: result.totalRecipients,
      insertedCommunications: result.insertedCommunications,
      invalidEmails: result.invalidEmails,
    };
  } catch (err) {
    const message = err instanceof CampaignCreateError ? err.message : (err as Error).message;
    return { ok: false, error: message };
  }
}

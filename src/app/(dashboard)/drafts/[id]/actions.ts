'use server';

import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { getUserAndOrg } from '@/lib/supabase/server';
import { sendDraft, DraftSendError, type SendDraftOverrides } from '@/lib/email/draft-sender';

export async function approveDraftAction(formData: FormData): Promise<void> {
  const id = String(formData.get('id') ?? '');
  if (!id) redirect('/drafts');

  const overrides: SendDraftOverrides = {};
  const subj = formData.get('subject');
  const bp = formData.get('body_plain');
  if (typeof subj === 'string' && subj.trim()) overrides.subject = subj;
  if (typeof bp === 'string' && bp.trim()) overrides.bodyPlain = bp;

  const auth = await getUserAndOrg();
  try {
    await sendDraft(auth.supabase, auth.organizationId, id, auth.userId, overrides);
  } catch (err) {
    const message = err instanceof DraftSendError ? err.message : (err as Error).message;
    redirect(`/drafts/${id}?error=${encodeURIComponent(message)}`);
  }

  revalidatePath('/drafts');
  redirect('/drafts?info=approved');
}

export async function rejectDraftAction(formData: FormData): Promise<void> {
  const id = String(formData.get('id') ?? '');
  const reason = String(formData.get('reason') ?? '').trim();
  if (!id) redirect('/drafts');

  const auth = await getUserAndOrg();
  const { error } = await auth.supabase
    .schema('ai')
    .from('drafts')
    .update({
      status: 'rejected',
      rejected_at: new Date().toISOString(),
      rejected_by: auth.userId,
      rejected_reason: reason || null,
    })
    .eq('organization_id', auth.organizationId)
    .eq('id', id)
    .eq('status', 'pending');

  if (error) {
    redirect(`/drafts/${id}?error=${encodeURIComponent(error.message)}`);
  }
  revalidatePath('/drafts');
  redirect('/drafts?info=rejected');
}

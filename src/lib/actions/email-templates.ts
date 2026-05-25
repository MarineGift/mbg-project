'use server';

/**
 * lib/actions/email-templates.ts
 *
 * Server actions for email templates (Track B / Stage 29-c).
 *
 * Pattern matches src/lib/actions/contacts.ts:
 *   - requireAuth() for AuthContext
 *   - .schema('app').from('email_templates' as never)
 *   - explicit organization_id + created_by on insert
 *   - revalidatePath after mutations
 */

import 'server-only';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';
import { requireAuth } from '@/lib/auth';
import { createSupabaseServerClient } from '@/lib/supabase/server';

const MODULES = ['investor', 'paper_mill', 'partner', 'customer', 'filler'] as const;

const TemplateInputSchema = z.object({
  name: z.string().min(1, 'Name is required').max(200),
  category: z.string().max(100).nullable().optional(),
  subject: z.string().min(1, 'Subject is required').max(500),
  bodyPlain: z.string().min(1, 'Body is required'),
  bodyHtml: z.string().nullable().optional(),
  module: z.enum(MODULES).nullable().optional(),
  isActive: z.boolean().optional(),
});

export type TemplateInput = z.infer<typeof TemplateInputSchema>;

export type ActionResult<T = { id: string }> =
  | { ok: true; data: T }
  | { ok: false; errorCode: string; errorMessage: string };

export async function createEmailTemplate(
  input: TemplateInput,
): Promise<ActionResult> {
  const auth = await requireAuth();
  const parsed = TemplateInputSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();
  const insertRow: Record<string, unknown> = {
    organization_id: auth.organizationId,
    name: parsed.data.name.trim(),
    category: parsed.data.category?.trim() || null,
    subject: parsed.data.subject.trim(),
    body_plain: parsed.data.bodyPlain,
    body_html: parsed.data.bodyHtml?.trim() || null,
    module: parsed.data.module || null,
    is_active: parsed.data.isActive ?? true,
    created_by: auth.userId,
  };

  const { data, error } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .insert(insertRow as never)
    .select('id')
    .single();

  if (error || !data) {
    return {
      ok: false,
      errorCode: 'database',
      errorMessage: error?.message ?? 'Insert failed',
    };
  }

  revalidatePath('/settings/email-templates');
  return { ok: true, data: { id: (data as { id: string }).id } };
}

export async function updateEmailTemplate(
  id: string,
  input: TemplateInput,
): Promise<ActionResult> {
  await requireAuth();
  const parsed = TemplateInputSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      errorCode: 'validation',
      errorMessage: parsed.error.issues[0]?.message ?? 'Invalid input',
    };
  }

  const supabase = await createSupabaseServerClient();
  const updateRow: Record<string, unknown> = {
    name: parsed.data.name.trim(),
    category: parsed.data.category?.trim() || null,
    subject: parsed.data.subject.trim(),
    body_plain: parsed.data.bodyPlain,
    body_html: parsed.data.bodyHtml?.trim() || null,
    module: parsed.data.module || null,
    is_active: parsed.data.isActive ?? true,
    updated_at: new Date().toISOString(),
  };

  const { error } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .update(updateRow as never)
    .eq('id', id);

  if (error) {
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }

  revalidatePath('/settings/email-templates');
  return { ok: true, data: { id } };
}

export async function deleteEmailTemplate(id: string): Promise<ActionResult> {
  await requireAuth();
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .delete()
    .eq('id', id);

  if (error) {
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }

  revalidatePath('/settings/email-templates');
  return { ok: true, data: { id } };
}

export async function toggleEmailTemplateActive(
  id: string,
  isActive: boolean,
): Promise<ActionResult> {
  await requireAuth();
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .update({ is_active: isActive, updated_at: new Date().toISOString() } as never)
    .eq('id', id);

  if (error) {
    return { ok: false, errorCode: 'database', errorMessage: error.message };
  }

  revalidatePath('/settings/email-templates');
  return { ok: true, data: { id } };
}

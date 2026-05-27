/**
 * lib/queries/email-templates.ts
 *
 * Read-side queries for email templates (Track B / Stage 29-c).
 *
 * RLS: organization_id auto-filtered via JWT app_metadata.
 *
 * 2026-05-25: Initial implementation (V1 scope).
 */

import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export interface EmailTemplate {
  id: string;
  organizationId: string;
  name: string;
  category: string | null;
  subject: string;
  bodyPlain: string;
  bodyHtml: string | null;
  module: string | null;
  isActive: boolean;
  createdBy: string | null;
  createdAt: string;
  updatedAt: string;
}

interface RawEmailTemplate {
  id: string;
  organization_id: string;
  name: string;
  category: string | null;
  subject: string;
  body_plain: string;
  body_html: string | null;
  module: string | null;
  is_active: boolean;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

const SELECT_COLS =
  'id, organization_id, name, category, subject, body_plain, body_html, module:party_type, is_active, created_by, created_at, updated_at';

function mapTemplate(row: RawEmailTemplate): EmailTemplate {
  return {
    id: row.id,
    organizationId: row.organization_id,
    name: row.name,
    category: row.category,
    subject: row.subject,
    bodyPlain: row.body_plain,
    bodyHtml: row.body_html,
    module: row.module,
    isActive: row.is_active,
    createdBy: row.created_by,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export async function listEmailTemplates(): Promise<EmailTemplate[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .select(SELECT_COLS)
    .order('updated_at', { ascending: false });

  if (error) {
    console.error('[listEmailTemplates]', error);
    return [];
  }
  return ((data ?? []) as unknown as RawEmailTemplate[]).map(mapTemplate);
}

export async function getEmailTemplate(id: string): Promise<EmailTemplate | null> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('email_templates' as never)
    .select(SELECT_COLS)
    .eq('id', id)
    .maybeSingle();

  if (error) {
    console.error('[getEmailTemplate]', error);
    return null;
  }
  if (!data) return null;
  return mapTemplate(data as unknown as RawEmailTemplate);
}

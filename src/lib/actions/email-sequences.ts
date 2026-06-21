'use server';

import type { EmailSequenceWithSteps } from '@/types/phase21b';
// src/lib/actions/email-sequences.ts

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { rpc } from '@/lib/rpc/typed-rpc';
import type { SequenceDraft } from '@/types/phase21b';
import { getSequenceFromAccountId, setSequenceFromAccount } from '@/lib/actions/sequence-sender';

// ===== Sequence CRUD =====

export async function createSequence(
  orgId: string,
  draft: SequenceDraft,
): Promise<{ id: string } | { error: string }> {
  const supabase = await createSupabaseServerClient();

  const stepsJson = draft.steps.map((s, i) => ({
    step_order: i,
    day_offset: s.day_offset,
    subject:    s.subject,
    body_plain:  s.body_plain,
  }));

  const { data, error } = await rpc(supabase, 'create_sequence', {
    p_organization_id: orgId,
    p_name:        draft.name.trim(),
    p_description: draft.description.trim(),
    p_steps:       stepsJson,
  });

  if (error) return { error: error.message };
  revalidatePath('/settings/email-sequences');
  return { id: data as string };
}

export async function updateSequence(
  sequenceId: string,
  draft: SequenceDraft,
): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();

  const stepsJson = draft.steps.map((s, i) => ({
    step_order: i,
    day_offset: s.day_offset,
    subject:    s.subject,
    body_plain:  s.body_plain,
  }));

  const { error } = await rpc(supabase, 'update_sequence', {
    p_sequence_id: sequenceId,
    p_name:        draft.name.trim(),
    p_description: draft.description.trim(),
    p_steps:       stepsJson,
  });

  if (error) return { error: error.message };
  revalidatePath('/settings/email-sequences');
  return {};
}

export async function archiveSequence(
  sequenceId: string,
): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { error } = await rpc(supabase, 'archive_sequence', {
    p_sequence_id: sequenceId,
  });
  if (error) return { error: error.message };
  revalidatePath('/settings/email-sequences');
  return {};
}

// ===== Enrollment =====

export async function enrollParty(
  orgId:      string,
  sequenceId: string,
  partyId:    string,
  contactId:  string | null,
): Promise<{ enrollment_id: string } | { error: string }> {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'Not authenticated' };

  const { data, error } = await rpc(supabase, 'enroll_in_sequence', {
    p_organization_id: orgId,
    p_sequence_id: sequenceId,
    p_party_id:    partyId,
    p_contact_id:  contactId ?? '',
    p_enrolled_by: user.id,
  });

  if (error) {
    // may already exist on unique-constraint violation
    if (error.code === '23505') {
      return { error: 'Already enrolled in this sequence (active).' };
    }
    return { error: error.message };
  }

  revalidatePath('/', 'layout');
  return { enrollment_id: data as string };
}

export async function cancelEnrollment(
  enrollmentId: string,
  partyId:      string,
): Promise<{ error?: string }> {
  const supabase = await createSupabaseServerClient();
  const { error } = await rpc(supabase, 'cancel_enrollment', {
    p_enrollment_id: enrollmentId,
  });
  if (error) return { error: error.message };
  revalidatePath('/', 'layout');
  return {};
}

// ===== Manual processor trigger (admin only) =====

/** Called when the "Run Now" button in Settings is clicked -> calls the processor API */
export async function triggerSequenceProcessor(sequenceId?: string | null): Promise<{
  processed: number;
  sent: number;
  failed: number;
  skipped: number;
  errors?: unknown[];
} | { error: string }> {
  const appUrl    = process.env.NEXT_PUBLIC_APP_URL ?? 'http://localhost:3000';
  const cronSecret = process.env.CRON_SECRET ?? '';

  const url = sequenceId
    ? `${appUrl}/api/sequences/process?sequence_id=${encodeURIComponent(sequenceId)}`
    : `${appUrl}/api/sequences/process`;

  try {
    const res = await fetch(url, {
      method:  'POST',
      headers: {
        'Content-Type':  'application/json',
        'x-cron-secret': cronSecret,
      },
    });
    if (!res.ok) {
      const txt = await res.text();
      return { error: `Processor returned ${res.status}: ${txt}` };
    }
    return await res.json();
  } catch (err) {
    return { error: String(err) };
  }
}


// ===== Read action (for client components that need sequence + steps) =====

/**
 * Duplicate a sequence: creates a new sequence with the same name + " (copy)",
 * the same description, identical steps, and the same From (sender) account.
 * Active enrollments and send history are NOT copied (the copy starts clean) --
 * ideal for testing without touching the live sequence's enrollments.
 */
export async function duplicateSequence(
  orgId: string,
  sequenceId: string,
): Promise<{ id: string } | { error: string }> {
  const src = await getSequenceForEdit(sequenceId);
  if ('error' in src) return { error: src.error };
  const seq = src.data;

  const draft: SequenceDraft = {
    name: `${seq.name} (copy)`,
    description: seq.description ?? '',
    steps: seq.steps
      .slice()
      .sort((a, b) => a.step_order - b.step_order)
      .map(s => ({
        step_order: s.step_order,
        day_offset: s.day_offset,
        subject:    s.subject,
        body_plain: s.body_plain,
      })),
  };

  const created = await createSequence(orgId, draft);
  if ('error' in created) return created;

  // Copy the From (sender) account so the duplicate sends identically.
  const from = await getSequenceFromAccountId(sequenceId);
  if ('accountId' in from && from.accountId) {
    await setSequenceFromAccount(created.id, from.accountId);
  }

  revalidatePath('/settings/email-sequences');
  return { id: created.id };
}

export async function getSequenceForEdit(
  sequenceId: string
): Promise<{ data: EmailSequenceWithSteps } | { error: string }> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await rpc(supabase, 'get_sequence_with_steps', {
    p_sequence_id: sequenceId,
  });
  if (error) return { error: error.message };
  return { data: data as unknown as EmailSequenceWithSteps };
}

// ===== Bulk enrollment =====

export interface BulkEnrollFilters {
  module?:        string | null;
  tiers?:         string[] | null;
  status?:        string | null;
  countryCode?:   string | null;
  industryTag?:   string | null;
  nameContains?:  string | null;
  priorities?:    string[] | null;   // investor priority: high | medium | low (multi)
}

export interface BulkEnrollResult {
  total_matching:           number;
  enrolled_count:           number;
  skipped_already_enrolled: number;
  skipped_no_email:         number;
  sample_names:             string[];
}

async function callBulkEnrollRpc(
  orgId:      string,
  sequenceId: string,
  filters:    BulkEnrollFilters,
  enrolledBy: string | null,
  dryRun:     boolean,
): Promise<BulkEnrollResult | { error: string }> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await rpc(supabase, 'bulk_enroll_filtered', {
    p_organization_id: orgId,
    p_sequence_id:   sequenceId,
    p_module:        filters.module       ?? undefined,
    p_tiers:         filters.tiers && filters.tiers.length > 0 ? filters.tiers : undefined,
    p_status:        filters.status       ?? undefined,
    p_country_code:  filters.countryCode  ?? undefined,
    p_industry_tag:  filters.industryTag  ?? undefined,
    p_name_contains: filters.nameContains ?? undefined,
    p_priority:      filters.priorities && filters.priorities.length > 0 ? filters.priorities : undefined,
    p_enrolled_by:   enrolledBy ?? undefined,
    p_dry_run:       dryRun,
  });
  if (error) return { error: error.message };
  const row = (data ?? [])[0];
  if (!row) return { error: 'No result from RPC' };
  return {
    total_matching:           row.total_matching ?? 0,
    enrolled_count:           row.enrolled_count ?? 0,
    skipped_already_enrolled: row.skipped_already_enrolled ?? 0,
    skipped_no_email:         row.skipped_no_email ?? 0,
    sample_names:             (row.sample_names ?? []) as string[],
  };
}

export async function previewBulkEnroll(
  orgId:      string,
  sequenceId: string,
  filters:    BulkEnrollFilters,
): Promise<BulkEnrollResult | { error: string }> {
  return callBulkEnrollRpc(orgId, sequenceId, filters, null, true);
}

export async function bulkEnrollFiltered(
  orgId:      string,
  sequenceId: string,
  filters:    BulkEnrollFilters,
): Promise<BulkEnrollResult | { error: string }> {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: 'Not authenticated' };

  const result = await callBulkEnrollRpc(orgId, sequenceId, filters, user.id, false);
  if (!('error' in result)) {
    revalidatePath('/settings/email-sequences');
    revalidatePath('/', 'layout');
  }
  return result;
}

// ===== Campaign from template =====

export interface CampaignTemplate {
  id:          string;
  name:        string;
  category:    string | null;
  subject:     string;
  body_plain:  string;
  module:      string | null;
}

export interface CampaignPreview {
  total_matching: number;
  with_email:     number;
  no_email:       number;
  sample_names:   string[];
}

export interface CampaignResult {
  sequence_id:              string;
  total_matching:           number;
  enrolled_count:           number;
  skipped_already_enrolled: number;
  skipped_no_email:         number;
  sample_names:             string[];
}

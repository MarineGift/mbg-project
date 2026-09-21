// src/app/(app)/ipo/actions.ts
//
// Server Actions for the IPO readiness module (app.ipo_* tables).
//   setGateVerdict        -- human judgment on a readiness gate (L1–L6)
//   addMetricSnapshot     -- the ONLY numeric input point (ipo_metric_snapshots)
//   setMilestoneStatus    -- milestone status; 'done' requires actual_date
//   recordDecisionReview  -- quarterly / gate1 / gate2 / gate3 log
//
// All actions use the RLS-scoped server client (organization_id from JWT).
// Views are security_invoker, so no org filter is needed here.

'use server';

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';

type Result = { ok: true } | { ok: false; error: string };

const VERDICTS = ['unknown', 'pass', 'watch', 'fail'] as const;
const STATUSES = ['not_started', 'in_progress', 'blocked', 'done', 'waived'] as const;
const STAGES = ['quarterly', 'gate1', 'gate2', 'gate3'] as const;
const DECISIONS = ['undecided', 'accelerated_2029q4', 'base_2030q2', 'defer'] as const;

export async function setGateVerdict(input: {
  gateId: string;
  verdict: string;
  evidence: string;
}): Promise<Result> {
  if (!input.gateId) return { ok: false, error: 'gateId required' };
  if (!(VERDICTS as readonly string[]).includes(input.verdict)) {
    return { ok: false, error: 'invalid verdict' };
  }
  if (input.verdict !== 'unknown' && !input.evidence.trim()) {
    return { ok: false, error: 'A verdict other than unknown requires evidence.' };
  }
  const supabase = await createSupabaseServerClient();
  const patch: Record<string, unknown> = {
    verdict: input.verdict,
    evidence: input.evidence.trim() || null,
    assessed_at: input.verdict === 'unknown' ? null : new Date().toISOString().slice(0, 10),
  };
  const { error } = await supabase
    .schema('app')
    .from('ipo_readiness_gates' as never)
    .update(patch as never)
    .eq('id', input.gateId);
  if (error) return { ok: false, error: error.message };
  revalidatePath('/ipo');
  return { ok: true };
}

export async function addMetricSnapshot(input: {
  metricId: string;
  asOf: string;
  value: number;
  verified: boolean;
  sourceNote: string;
}): Promise<Result> {
  if (!input.metricId || !input.asOf || !Number.isFinite(input.value)) {
    return { ok: false, error: 'metric, as_of and value are required.' };
  }
  const supabase = await createSupabaseServerClient();
  const { data: m, error: mErr } = await supabase
    .schema('app')
    .from('ipo_metrics' as never)
    .select('organization_id')
    .eq('id', input.metricId)
    .maybeSingle();
  if (mErr || !m) return { ok: false, error: mErr?.message ?? 'metric not found' };
  const orgId = (m as { organization_id: string }).organization_id;

  const row = {
    organization_id: orgId,
    metric_id: input.metricId,
    as_of: input.asOf,
    value: input.value,
    verified: input.verified,
    source_note: input.sourceNote.trim() || null,
  };
  // UNIQUE(metric_id, as_of): same date = overwrite.
  const { error } = await supabase
    .schema('app')
    .from('ipo_metric_snapshots' as never)
    .upsert(row as never, { onConflict: 'metric_id,as_of' });
  if (error) return { ok: false, error: error.message };
  revalidatePath('/ipo');
  return { ok: true };
}

export async function setMilestoneStatus(input: {
  milestoneId: string;
  status: string;
  actualDate?: string | null;
}): Promise<Result> {
  if (!input.milestoneId) return { ok: false, error: 'milestoneId required' };
  if (!(STATUSES as readonly string[]).includes(input.status)) {
    return { ok: false, error: 'invalid status' };
  }
  const patch: Record<string, unknown> = { status: input.status };
  if (input.status === 'done') {
    patch.actual_date = input.actualDate || new Date().toISOString().slice(0, 10);
  } else {
    patch.actual_date = null;
  }
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase
    .schema('app')
    .from('ipo_milestones' as never)
    .update(patch as never)
    .eq('id', input.milestoneId);
  if (error) return { ok: false, error: error.message };
  revalidatePath('/ipo');
  return { ok: true };
}

export async function recordDecisionReview(input: {
  programId: string;
  stage: string;
  decision: string;
  rationale: string;
}): Promise<Result> {
  if (!(STAGES as readonly string[]).includes(input.stage)) return { ok: false, error: 'invalid stage' };
  if (!(DECISIONS as readonly string[]).includes(input.decision)) return { ok: false, error: 'invalid decision' };
  const supabase = await createSupabaseServerClient();
  const { data: p } = await supabase
    .schema('app')
    .from('ipo_programs' as never)
    .select('organization_id')
    .eq('id', input.programId)
    .maybeSingle();
  if (!p) return { ok: false, error: 'program not found' };
  const orgId = (p as { organization_id: string }).organization_id;

  let scheduleId: string | null = null;
  if (input.stage !== 'quarterly') {
    const { data: s } = await supabase
      .schema('app')
      .from('ipo_decision_schedule' as never)
      .select('id')
      .eq('program_id', input.programId)
      .eq('stage', input.stage)
      .maybeSingle();
    scheduleId = (s as { id: string } | null)?.id ?? null;
  }
  const row = {
    organization_id: orgId,
    program_id: input.programId,
    schedule_id: scheduleId,
    review_date: new Date().toISOString().slice(0, 10),
    stage: input.stage,
    window_decision: input.decision,
    rationale: input.rationale.trim() || null,
  };
  const { error } = await supabase
    .schema('app')
    .from('ipo_decision_reviews' as never)
    .upsert(row as never, { onConflict: 'program_id,review_date,stage' });
  if (error) return { ok: false, error: error.message };
  revalidatePath('/ipo');
  return { ok: true };
}

// ============================================================
// Patents (app.patents) -- entered here, never committed to the repo.
// ============================================================

const FAMILY_ROLES = ['foundational', 'improvement', 'application_specific'] as const;
const ASSIGN = ['not_started', 'executed', 'recorded', 'not_required'] as const;
const PSTATUS = ['pending', 'granted', 'opposed', 'lapsed', 'expired', 'abandoned'] as const;

export type PatentInput = {
  id?: string | null;
  program_id: string;
  family_code: string;
  family_role: string;
  jurisdiction: string;
  application_no: string;
  patent_no: string;
  title_short: string;
  assignment_status: string;
  recordation_date: string;
  priority_date: string;
  filing_date: string;
  grant_date: string;
  expected_expiration: string;
  status: string;
  is_material: boolean;
  royalty_weight: string;
  challenge_note: string;
  maintenance_next_due: string;
};

const nz = (s: string) => (s && s.trim() ? s.trim() : null);

export async function upsertPatent(p: PatentInput): Promise<Result> {
  if (!p.family_code.trim() || !p.jurisdiction.trim()) return { ok: false, error: 'family_code and jurisdiction are required.' };
  if (!(FAMILY_ROLES as readonly string[]).includes(p.family_role)) return { ok: false, error: 'invalid family_role' };
  if (!(ASSIGN as readonly string[]).includes(p.assignment_status)) return { ok: false, error: 'invalid assignment_status' };
  if (!(PSTATUS as readonly string[]).includes(p.status)) return { ok: false, error: 'invalid status' };
  if (p.is_material && !nz(p.expected_expiration)) return { ok: false, error: 'A material patent needs expected_expiration (drives L4 and patent-life KPI).' };
  if (p.assignment_status === 'recorded' && !nz(p.recordation_date)) return { ok: false, error: 'recorded requires recordation_date.' };

  const supabase = await createSupabaseServerClient();
  const { data: prog } = await supabase.schema('app').from('ipo_programs' as never).select('organization_id').eq('id', p.program_id).maybeSingle();
  if (!prog) return { ok: false, error: 'program not found' };
  const orgId = (prog as { organization_id: string }).organization_id;

  const row = {
    organization_id: orgId,
    program_id: p.program_id,
    family_code: p.family_code.trim(),
    family_role: p.family_role,
    jurisdiction: p.jurisdiction.trim().toUpperCase(),
    application_no: nz(p.application_no),
    patent_no: nz(p.patent_no),
    title_short: nz(p.title_short),
    assignment_status: p.assignment_status,
    recordation_date: nz(p.recordation_date),
    priority_date: nz(p.priority_date),
    filing_date: nz(p.filing_date),
    grant_date: nz(p.grant_date),
    expected_expiration: nz(p.expected_expiration),
    status: p.status,
    is_material: p.is_material,
    royalty_weight: nz(p.royalty_weight) ? Number(p.royalty_weight) : null,
    challenge_note: nz(p.challenge_note),
    maintenance_next_due: nz(p.maintenance_next_due),
  };
  const q = supabase.schema('app').from('patents' as never);
  const { error } = p.id
    ? await q.update(row as never).eq('id', p.id)
    : await q.insert(row as never);
  if (error) return { ok: false, error: error.message };
  revalidatePath('/ipo');
  return { ok: true };
}

export async function deletePatent(id: string): Promise<Result> {
  if (!id) return { ok: false, error: 'id required' };
  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.schema('app').from('patents' as never).delete().eq('id', id);
  if (error) return { ok: false, error: error.message };
  revalidatePath('/ipo');
  return { ok: true };
}

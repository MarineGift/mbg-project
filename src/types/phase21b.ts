// src/types/phase21b.ts
// Phase 21b — Email Sequence Types

export type SequenceStatus    = 'active' | 'paused' | 'archived';
export type EnrollmentStatus  = 'active' | 'paused' | 'completed' | 'cancelled';
export type SequenceSendStatus = 'sent' | 'failed' | 'skipped';

// ── DB rows ──────────────────────────────────────────────────

export interface EmailSequence {
  id:                 string;
  org_id:             string;
  name:               string;
  description:        string | null;
  status:             SequenceStatus;
  step_count:         number;
  active_enrollments: number;
  total_sends:        number;
  created_at:         string;
}

export interface EmailSequenceStep {
  id:          string;
  sequence_id: string;
  step_order:  number;
  day_offset:  number;
  subject:     string;
  body_text:   string;
  created_at:  string;
  updated_at:  string;
}

export interface EmailSequenceWithSteps
  extends Omit<EmailSequence, 'step_count' | 'active_enrollments' | 'total_sends'> {
  steps: EmailSequenceStep[];
}

export interface PartyEnrollmentSummary {
  id:              string;
  sequence_id:     string;
  sequence_name:   string;
  status:          EnrollmentStatus;
  next_step_order: number;
  total_steps:     number;
  next_send_at:    string | null;
  enrolled_at:     string;
  sends_count:     number;
}

export interface DueEnrollmentRow {
  enrollment_id:   string;
  org_id:          string;
  sequence_id:     string;
  party_id:        string | null;
  contact_id:      string | null;
  enrolled_by:     string | null;
  enrolled_at:     string;
  next_step_order: number;
  step_id:         string;
  step_day_offset: number;
  step_subject:    string;
  step_body_text:  string;
  is_last_step:    boolean;
}

// ── Processor result ─────────────────────────────────────────

export interface ProcessorResult {
  enrollment_id: string;
  status:        'sent' | 'skipped' | 'error';
  to?:           string;
  reason?:       string;
  error?:        string;
}

// ── Form / draft types ───────────────────────────────────────

export interface StepDraft {
  /** undefined = brand new step (no DB id yet) */
  id?:         string;
  step_order:  number;
  day_offset:  number;
  subject:     string;
  body_text:   string;
}

export interface SequenceDraft {
  name:        string;
  description: string;
  steps:       StepDraft[];
}

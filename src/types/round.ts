/**
 * types/round.ts
 *
 * Fundraising round domain type (app.rounds).
 *
 * A round is an org-level dimension that groups Investor deals
 * (Seed / Series A / Series B ...). A deal references at most one round via
 * deals.round_id (FK, nullable -> only Investor deals carry it). Round
 * attributes live here once; deals only store the pointer = normalized.
 *
 * NOTE: numeric columns (targetAmount, preMoneyValuation) come back from
 *       PostgREST as strings (precision preservation). Keep them string|null
 *       and parseFloat at the point of use.
 */

export type RoundStatus = 'planned' | 'open' | 'closed' | 'cancelled';

/** Ordered list of statuses (for selects / iteration). */
export const ROUND_STATUSES: readonly RoundStatus[] = [
  'planned',
  'open',
  'closed',
  'cancelled',
] as const;

/** Display label per status. */
export const ROUND_STATUS_LABEL: Record<RoundStatus, string> = {
  planned: 'Planned',
  open: 'Open',
  closed: 'Closed',
  cancelled: 'Cancelled',
};

export interface Round {
  id: string;
  organizationId: string;
  name: string;
  roundType: string | null;
  targetAmount: string | null;
  preMoneyValuation: string | null;
  currency: string;
  status: RoundStatus;
  openedAt: string | null;
  closedAt: string | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

/** Minimal shape passed to client components (board filter + modal selector). */
export interface RoundOption {
  id: string;
  name: string;
}

/* ------------------------------------------------------------------
 * Rollup types (Round management screen)
 *
 * Derived aggregates over a round's deals. Unlike the raw Round numeric
 * fields (string|null from PostgREST), these are already parsed to numbers
 * in the query layer. Single-currency assumption (USD): commitments are
 * summed without currency conversion -- rounds carry no FX dimension.
 * ------------------------------------------------------------------ */

export interface RoundStageBreakdown {
  stageId: string;
  stageName: string;
  sortOrder: number;
  dealCount: number;
  /** Sum of commitment_amount for this round's deals in this stage. */
  committed: number;
}

export interface RoundWithRollup extends Round {
  /** Distinct non-deleted deals attached to this round. */
  dealCount: number;
  /** Sum of every deal_parties.commitment_amount across the round's deals. */
  committedTotal: number;
  /** committedTotal / targetAmount * 100; null when no target is set. */
  progressPct: number | null;
  /** Per-stage breakdown, stages with >=1 deal only, ordered by sort_order. */
  stageBreakdown: RoundStageBreakdown[];
}

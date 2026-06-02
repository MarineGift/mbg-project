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

export type RoundStatus = 'open' | 'closed' | 'cancelled';

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

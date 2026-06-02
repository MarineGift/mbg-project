/**
 * types/deal-party.ts
 *
 * A company's participation on a deal (app.deal_parties row, joined to the
 * party master). One deal has many of these; each carries the party's role
 * and its own commitment amount. The deal's total = sum(commitmentAmount).
 *
 * NOTE: commitment_amount is numeric -> PostgREST returns it as a string.
 *       Keep it string|null and parse at the point of use.
 */

export type DealPartyRole =
  | 'lead'
  | 'co_investor'
  | 'participant'
  | 'advisor'
  | 'primary';

export interface DealParty {
  id: string;
  partyId: string;
  partyName: string;
  countryCode: string | null;
  role: DealPartyRole;
  commitmentAmount: string | null;
  currency: string;
}

/**
 * types/party-detail.ts
 *
 * Data model for the party (parties) detail screen.
 * Phase 1 is read-only.
 *
 * Change history:
 *   - 2026-05-11: aligned with the DB schema - removed the single industry/tags field,
 *                 split into industryTags/interestTags arrays.
 *                 (actual DB columns: industry_tags ARRAY, interest_tags ARRAY)
 *   - 2026-05-14: Phase 6 - industryPaperCompanyId /
 *                 added the industryFillerSupplierId FK field.
 *   - 2026-06-11: added ContactProfile (app.contact_profiles 1:1 enrichment) and
 *                 attached it to PartyContact as an optional `profile` field.
 */

import type { PartyTypeCode } from './ai';
import type {
  CommunicationChannel,
  CommunicationDirection,
  CommunicationStatus,
} from './inbox';

/** Matches the parties.tier CHECK constraint. */
export type PartyTier = 'tier_1' | 'tier_2' | 'tier_3' | 'cold';

/** Matches the parties.status CHECK constraint. */
export type PartyStatus = 'active' | 'paused' | 'closed_won' | 'closed_lost' | 'archived';

export interface PartyDetail {
  id: string;
  organizationId: string;
  name: string;
  partyType: PartyTypeCode;
  tier: PartyTier | null;
  status: PartyStatus;
  countryCode: string | null;
  city: string | null;
  region: string | null;
  website: string | null;
  /** Industry classification tags (e.g. "Venture Capital", "Software", "Healthcare") */
  industryTags: string[];
  /** Interest/focus tags (e.g. "Early Stage", "AI", "Growth") */
  interestTags: string[];
  notes: string | null;
  source: string | null;
  /** Long free-text introduction (Korean / English) - app.parties.intro_ko / intro_en */
  introKo: string | null;
  introEn: string | null;
  /** Organization-level contact: HQ email and street address (single line). */
  email: string | null;
  streetAddress: string | null;
  createdAt: string;
  updatedAt: string;

  /** Phase 6 - FK linking to the industry master DB */
  industryPaperCompanyId: number | null;
  industryFillerSupplierId: number | null;

  /** statistics - filled via RPC or a separate COUNT query */
  counts: {
    contacts: number;
    communications: number;
    pendingDrafts: number;
    openEngagements: number;
    openTasks: number;
  };
}

/** One activity-timeline item - communications + tasks merged. */
export type TimelineItem =
  | TimelineCommunicationItem
  | TimelineTaskItem;

export interface TimelineCommunicationItem {
  kind: 'communication';
  id: string;
  occurredAt: string;
  channel: CommunicationChannel;
  direction: CommunicationDirection;
  status: CommunicationStatus;
  subject: string | null;
  bodyPreview: string;
  fromAddress: string | null;
  aiGenerated: boolean;
}

export interface TimelineTaskItem {
  kind: 'task';
  id: string;
  occurredAt: string;     // created_at or completed_at
  event: 'created' | 'completed';
  title: string;
  status: string;
  priority: string | null;
  dueAt: string | null;
}

/**
 * Enrichment fields from app.contact_profiles (1:1 extension of app.contacts).
 * Present only when a profile row exists for the contact; most contacts have none.
 */
export interface ContactProfile {
  coverageRegion: string | null;
  locationText: string | null;
  boardRoles: string | null;
  mbgFitRating: 'HIGH' | 'moderate-high' | 'moderate' | 'LOW' | null;
  mbgFitNote: string | null;
  entryChannel: string | null;
  verifiedAt: string | null;
  verifySource: string | null;
}

export interface PartyContact {
  id: string;
  fullName: string | null;
  email: string | null;
  jobTitle: string | null;
  phone: string | null;
  notes: string | null;
  isPrimary: boolean;
  /** all emails from app.contact_emails, primary first; [] when none */
  emails: { email: string; isPrimary: boolean; label: string | null }[];
  /** undefined when no app.contact_profiles row exists for this contact */
  profile?: ContactProfile;
}

export interface PartyEngagement {
  id: string;
  name: string;
  status: string;
  stage: string | null;
  valueAmount: number | null;
  valueCurrency: string;
  closeDate: string | null;
  updatedAt: string;
}

export interface PartyTask {
  id: string;
  title: string;
  status: string;
  priority: string | null;
  dueAt: string | null;
  createdAt: string;
}

/** Investor priority / tier. high = Tier A, medium = Tier B, low = Tier C. */
export type InvestorPriority = 'high' | 'medium' | 'low';

export interface InvestorProfile {
  /** editable on the Investor Profile card; null = unset */
  priority: InvestorPriority | null;
  fundName: string | null;
  typeCode: string | null;
  typeName: string | null;
  investorCategory: string | null;
  fundSizeUsd: number | null;
  aumUsd: number | null;
  fundVintageYear: number | null;
  ticketMinUsd: number | null;
  ticketMaxUsd: number | null;
  sectorFocus: string[];
  geographicFocus: string[];
  isLeadInvestor: boolean;
  isStrategic: boolean;
}

export interface PartyDetailFull {
  party: PartyDetail;
  contacts: PartyContact[];
  engagements: PartyEngagement[];
  tasks: PartyTask[];
  timeline: TimelineItem[];
  investorProfile: InvestorProfile | null;
}

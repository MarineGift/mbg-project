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
 *   - 2026-05-14: Phase 6 — industryPaperCompanyId /
 *                 added the industryFillerSupplierId FK field.
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
  website: string | null;
  /** Industry classification tags (e.g. "Venture Capital", "Software", "Healthcare") */
  industryTags: string[];
  /** Interest/focus tags (e.g. "Early Stage", "AI", "Growth") */
  interestTags: string[];
  notes: string | null;
  source: string | null;
  createdAt: string;
  updatedAt: string;

  /** ▼ Phase 6 - FK linking to the industry master DB */
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

export interface PartyContact {
  id: string;
  fullName: string | null;
  email: string | null;
  jobTitle: string | null;
  phone: string | null;
  isPrimary: boolean;
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

export interface PartyDetailFull {
  party: PartyDetail;
  contacts: PartyContact[];
  engagements: PartyEngagement[];
  tasks: PartyTask[];
  timeline: TimelineItem[];
}

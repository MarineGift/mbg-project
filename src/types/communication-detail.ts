/**
 * types/communication-detail.ts
 *
 * Detail-screen model for a single communications row.
 */

import type { PartyTypeCode } from './ai';
import type {
  CommunicationChannel,
  CommunicationDirection,
  CommunicationStatus,
} from './inbox';

export interface CommunicationDetail {
  id: string;
  organizationId: string;
  channel: CommunicationChannel;
  direction: CommunicationDirection;
  status: CommunicationStatus;
  fromAddress: string | null;
  fromName: string | null;
  toAddresses: string[];
  ccAddresses: string[];
  bccAddresses: string[];
  subject: string | null;
  bodyPlain: string | null;
  bodyHtml: string | null;
  messageId: string | null;
  threadId: string | null;
  inReplyTo: string | null;
  references: string[];
  occurredAt: string;
  sentAt: string | null;
  receivedAt: string | null;
  errorMessage: string | null;
  attachmentCount: number;
  aiGenerated: boolean;
  /** Which AI draft this outbound was generated from (if any) */
  aiDraftId: string | null;
  /** Party summary */
  party: {
    id: string;
    name: string;
    partyType: PartyTypeCode;
  } | null;
  /** Contact summary */
  contact: {
    id: string;
    fullName: string | null;
    email: string | null;
  } | null;
  /** AI drafts generated from this inbound */
  generatedDrafts: Array<{
    id: string;
    status: string;
    classificationCategory: string | null;
    confidenceScore: number | null;
  }>;
}

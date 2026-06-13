/**
 * types/inbox.ts
 *
 * Data model for the Inbox screen.
 * Displays inbound + outbound from the communications table merged in chronological order.
 *
 * Change history:
 *   - 2026-05-12 (1st): aligned CommunicationChannel to the 9 DB enum values.
 *   - 2026-05-12 (2nd): expanded to 11 for UI compatibility (added slack, other).
 *   - 2026-05-12 (3rd): fully matches the DB enum (12) - added webform.
 *                       now 1:1 with the DB enum app.channel_type.
 */

import type { PartyTypeCode } from './ai';

/**
 * Communication channel - 1:1 with the DB enum app.channel_type (12).
 *
 * email, phone, sms, linkedin, kakaotalk, wechat, whatsapp,
 * in_person, video_call, webform, other, slack
 */
export type CommunicationChannel =
  | 'email'
  | 'phone'
  | 'sms'
  | 'linkedin'
  | 'kakaotalk'
  | 'wechat'
  | 'whatsapp'
  | 'in_person'
  | 'video_call'
  | 'webform'
  | 'other'
  | 'slack';

/**
 * Communication direction - matches the DB enum app.direction_type.
 * 'internal' is in the enum too, but Phase 1 handles only inbound/outbound.
 */
export type CommunicationDirection = 'inbound' | 'outbound';

/** Communication status - tracks the outbound send result. */
export type CommunicationStatus =
  | 'received'    // inbound received
  | 'pending'     // pending send
  | 'sending'     // sending
  | 'sent'        // sent
  | 'failed'      // send failed
  | 'bounced';    // bounced

/**
 * Inbox row model (for the list page).
 */
export interface InboxRow {
  id: string;
  channel: CommunicationChannel;
  direction: CommunicationDirection;
  status: CommunicationStatus;
  fromAddress: string | null;
  fromName: string | null;
  toAddresses: string[];
  subject: string | null;
  bodyPreview: string;       // first 120 chars
  occurredAt: string;
  sentAt: string | null;
  partyId: string | null;
  partyName: string | null;
  partyTypeCode: PartyTypeCode | null;
  /** Whether an AI draft was generated from this inbound (if applicable) */
  hasDraft: boolean;
  /** Whether this outbound was generated from an AI draft */
  aiGenerated: boolean;
  /** attachment count - not implemented in Phase 1, always 0 (no DB column) */
  attachmentCount: number;
  /** Thread group: id of conversation thread (= self id if standalone) */
  threadId: string;
  /** Thread group: total message count in this thread */
  threadCount: number;
  /**
   * Read state. Outbound is always considered read; an inbound message (or thread)
   * is read once every inbound message in it has read_at set. Unread => emphasized
   * in the list and counted by the sidebar inbox badge.
   */
  isRead: boolean;
}

/**
 * Inbox search field scope - which column(s) the query term targets.
 *   all     -> from (address+name), to, subject, body
 *   from    -> from_address + from_name
 *   to      -> to_addresses (exact element match; see query note)
 *   subject -> subject
 */
export type InboxSearchField = 'all' | 'from' | 'to' | 'subject';

/**
 * Inbox filter - passed via URL searchParams.
 */
export interface InboxFilters {
  channel: CommunicationChannel | 'all';
  direction: CommunicationDirection | 'all';
  /** search term (ilike + pg_trgm) */
  query: string;
  /** which field(s) the search term targets (default: all) */
  searchField: InboxSearchField;
  /** only inbound that has an AI draft */
  hasDraft: boolean;
  /** a specific party (UUID) - Phase 1 supports only direct URL input */
  partyId: string | null;
}

export interface InboxPagination {
  page: number;
  pageSize: number;
}

export interface InboxResult {
  rows: InboxRow[];
  totalCount: number;
  filters: InboxFilters;
  pagination: InboxPagination;
}

export const DEFAULT_INBOX_FILTERS: InboxFilters = {
  channel: 'all',
  // D6-5e: default to inbound only so list count matches sidebar/dashboard
  // "Unread inbound" indicator. Users can still toggle to outbound via UI dropdown.
  direction: 'inbound',
  query: '',
  searchField: 'all',
  hasDraft: false,
  partyId: null,
};

export const DEFAULT_SENT_FILTERS: InboxFilters = {
  ...DEFAULT_INBOX_FILTERS,
  direction: 'outbound',
};

export const INBOX_DEFAULT_PAGE_SIZE = 25;
export const INBOX_PAGE_SIZE_OPTIONS: readonly number[] = [25, 50, 100] as const;

// src/types/phase21.ts
// Phase 21a — Email Tracking types

export interface EmailTracking {
  id: string;
  org_id: string;
  draft_id: string | null;
  party_id: string | null;
  contact_id: string | null;
  subject: string | null;
  sent_to: string;
  open_token: string;
  sent_at: string;
  first_opened_at: string | null;
  open_count: number;
  click_count: number;
  created_at: string;
}

export interface EmailTrackingLink {
  id: string;
  tracking_id: string;
  token: string;
  original_url: string;
  click_count: number;
}

export interface EmailTrackingEvent {
  id: string;
  tracking_id: string;
  link_id: string | null;
  event_type: 'open' | 'click';
  url: string | null;
  ip: string | null;
  user_agent: string | null;
  created_at: string;
}

export interface TrackingPayload {
  tracking_id: string;
  open_token: string;
  links: Array<{ token: string; url: string }>;
}

/** Returned by get_tracking_for_drafts RPC */
export interface DraftTrackingSummary {
  draft_id: string;
  tracking_id: string;
  open_count: number;
  click_count: number;
  first_opened_at: string | null;
  sent_at: string;
}

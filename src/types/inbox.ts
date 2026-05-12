/**
 * types/inbox.ts
 *
 * 받은 편지함(Inbox) 화면의 데이터 모델.
 * communications 테이블의 inbound + outbound를 시간순으로 통합 표시.
 */

import type { ModuleType } from './ai';

/** 통신 채널 — communications.channel CHECK 제약과 일치. */
export type CommunicationChannel = 'email' | 'slack' | 'sms' | 'phone' | 'other';

/** 통신 방향 — communications.direction CHECK 제약과 일치. */
export type CommunicationDirection = 'inbound' | 'outbound';

/** 통신 상태 — outbound 발송 결과 추적. */
export type CommunicationStatus =
  | 'received'    // inbound 수신 완료
  | 'pending'     // 발송 대기
  | 'sending'     // 발송 중
  | 'sent'        // 발송 완료
  | 'failed'      // 발송 실패
  | 'bounced';    // 반송

/**
 * 인박스 한 행 (목록용 평탄화).
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
  bodyPreview: string;       // 첫 120자
  occurredAt: string;
  sentAt: string | null;
  partyId: string | null;
  partyName: string | null;
  partyModule: ModuleType | null;
  /** 이 인바운드에서 생성된 AI 초안의 존재 여부 (해당 시) */
  hasDraft: boolean;
  /** 이 아웃바운드가 AI 초안에서 생성되었는지 */
  aiGenerated: boolean;
  /** 첨부 파일 개수 */
  attachmentCount: number;
}

/**
 * 인박스 필터 — URL searchParams로 전달.
 */
export interface InboxFilters {
  channel: CommunicationChannel | 'all';
  direction: CommunicationDirection | 'all';
  /** 검색어 (ilike + pg_trgm). subject + body_plain 대상. */
  query: string;
  /** AI 초안 있는 인바운드만 */
  hasDraft: boolean;
  /** 특정 거래처 (UUID) — Phase 1은 URL 직접 입력만 지원 */
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
  direction: 'all',
  query: '',
  hasDraft: false,
  partyId: null,
};

export const INBOX_DEFAULT_PAGE_SIZE = 25;
export const INBOX_PAGE_SIZE_OPTIONS: readonly number[] = [25, 50, 100] as const;

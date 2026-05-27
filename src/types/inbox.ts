/**
 * types/inbox.ts
 *
 * 받은 편지함(Inbox) 화면의 데이터 모델.
 * communications 테이블의 inbound + outbound를 시간순으로 통합 표시.
 *
 * 변경 이력:
 *   - 2026-05-12 (1차): CommunicationChannel을 DB enum 9개로 정렬.
 *   - 2026-05-12 (2차): UI 호환을 위해 11개로 확장 (slack, other 추가).
 *   - 2026-05-12 (3차): DB enum과 완전 일치 (12개) — webform 추가.
 *                       이제 DB enum app.channel_type과 1:1 매칭.
 */

import type { PartyTypeCode } from './ai';

/**
 * 통신 채널 — DB enum app.channel_type과 1:1 매칭 (12개).
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
 * 통신 방향 — DB enum app.direction_type과 일치.
 * 'internal'도 enum에는 있지만 Phase 1은 inbound/outbound만 처리.
 */
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
 * 인박스 행 모델 (목록 페이지용).
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
  partyModule: PartyTypeCode | null;
  /** 이 인바운드에서 생성된 AI 초안이 존재하는가 (해당 시) */
  hasDraft: boolean;
  /** 이 아웃바운드가 AI 초안에서 생성되었는가 */
  aiGenerated: boolean;
  /** 첨부 파일 개수 — Phase 1 미구현, 항상 0 (DB 컬럼 없음) */
  attachmentCount: number;
  /** Thread group: id of conversation thread (= self id if standalone) */
  threadId: string;
  /** Thread group: total message count in this thread */
  threadCount: number;
}

/**
 * 인박스 필터 — URL searchParams로 전달.
 */
export interface InboxFilters {
  channel: CommunicationChannel | 'all';
  direction: CommunicationDirection | 'all';
  /** 검색어 (ilike + pg_trgm). subject + body_plain 대상 */
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
  // D6-5e: default to inbound only so list count matches sidebar/dashboard
  // "Unread inbound" indicator. Users can still toggle to outbound via UI dropdown.
  direction: 'inbound',
  query: '',
  hasDraft: false,
  partyId: null,
};

export const DEFAULT_SENT_FILTERS: InboxFilters = {
  ...DEFAULT_INBOX_FILTERS,
  direction: 'outbound',
};

export const INBOX_DEFAULT_PAGE_SIZE = 25;
export const INBOX_PAGE_SIZE_OPTIONS: readonly number[] = [25, 50, 100] as const;

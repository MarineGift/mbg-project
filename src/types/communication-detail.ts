/**
 * types/communication-detail.ts
 *
 * 단일 communications 행의 상세 화면 모델.
 */

import type { ModuleType } from './ai';
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
  /** 이 outbound가 어떤 AI 초안에서 생성됐는지 (있다면) */
  aiDraftId: string | null;
  /** 거래처 요약 */
  party: {
    id: string;
    name: string;
    module: ModuleType;
  } | null;
  /** 컨택트 요약 */
  contact: {
    id: string;
    fullName: string | null;
    email: string | null;
  } | null;
  /** 이 inbound로부터 생성된 AI 초안들 */
  generatedDrafts: Array<{
    id: string;
    status: string;
    classificationCategory: string | null;
    confidenceScore: number | null;
  }>;
}

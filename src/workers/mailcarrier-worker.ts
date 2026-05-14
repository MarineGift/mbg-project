/**
 * src/workers/mailcarrier-worker.ts
 *
 * IMAP에서 새 메일을 수신하고 ai.drafts 파이프라인을 트리거하는 워커.
 *
 * Phase 2 변경:
 *   - 단일 MAILCARRIER_USERNAME → MAILCARRIER_POLL_KINDS 배열 기반
 *   - kinds 길이만큼 MailCarrierClient 인스턴스 (personal/role/shared)
 *   - 각 client 독립 IDLE 루프 (한 box 장애가 다른 box에 영향 없음)
 *   - graceful shutdown: 모든 client 병렬 stop()
 *   - kinds 빈 값 시 Phase 1 fallback (단일 MAILCARRIER_USERNAME)
 *
 * 흐름:
 *   [1] Supabase service_role 클라이언트 생성 (RLS 우회)
 *   [2] MAILCARRIER_POLL_KINDS에 따라 1~3개 MailCarrierClient 생성 + connect()
 *   [3] 각 client.startListening(onMessage) 병렬 실행
 *   [4] 새 메일 도착 시 → persistInbound → processInbound → ai.drafts INSERT
 *   [5] SIGTERM/SIGINT → 모든 client 병렬 graceful shutdown
 *
 * 실행:
 *   npm run worker:mailcarrier
 *
 * 필수 환경변수:
 *   - SUPABASE_SERVICE_ROLE_KEY
 *   - ANTHROPIC_API_KEY
 *   - MAILCARRIER_HOST / PORT (공통)
 *   - MAILCARRIER_POLL_KINDS (예: "personal,role,shared")
 *   - MAIL_<KIND>_USERNAME / PASSWORD (각 kind별)
 *   - 또는 MAILCARRIER_USERNAME / PASSWORD (POLL_KINDS 빈 값 시 fallback)
 *
 * 비고:
 *   - Phase 1은 단일 조직(MBG Project) 처리.
 *   - 처리 중 에러는 communications.ai_processing_status='failed'로 기록.
 */

import { createClient } from '@supabase/supabase-js';
import { env } from '../lib/env';
import { MailCarrierClient } from '../lib/email/mailcarrier';
import { processInbound } from '../lib/email/processor';
import type { InboundMessageEvent, SendingAddressKind } from '../types/email';
import { createShutdownController, isMainEntry } from './runtime';


// =============================================================================
// PATCH 2: src/workers/mailcarrier-worker.ts
// =============================================================================
// 적용 위치: 파일 최상단 (import문 직후, 메인 로직 위)에 아래 블록 그대로 추가
//
// 핵심 진단 신호:
//   - beforeExit 로그가 뜨면 = event loop가 비었다 = polling loop가 모두 종료된 결정적 신호
//     → 핸드오프의 가설 (B-1) 확정
//   - uncaughtException/unhandledRejection → 비동기 에러가 워커를 죽이려 하는 경우
//   - SIGTERM/SIGINT → 외부에서 종료 (Task Scheduler, Defender, 사용자 등)
//
// 운영 단계 진입 시 주의:
//   - uncaughtException 핸들러에서 process.exit(1)을 호출하도록 변경 필요
//   - 진단 단계에서는 의도적으로 exit 안 함 (어떤 에러가 워커를 죽이려 하는지 보기 위함)
// =============================================================================

// ─── Process-level diagnostics ─────────────────────────────────────────────
process.on('uncaughtException', (err) => {
  console.error('[worker] uncaughtException:', err);
  // 진단 단계: 의도적으로 exit 안 함
  // 운영 단계로 가면 process.exit(1)로 바꿔야 함
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('[worker] unhandledRejection at:', promise, 'reason:', reason);
});

process.on('SIGTERM', () => {
  console.warn('[worker] SIGTERM received — exiting');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.warn('[worker] SIGINT received — exiting');
  process.exit(0);
});

process.on('exit', (code) => {
  console.warn(`[worker] process.on('exit') code=${code}`);
});

process.on('beforeExit', (code) => {
  console.warn(
    `[worker] beforeExit code=${code} — event loop empty, ` +
    `no more work scheduled (this means polling loop has exited)`,
  );
});
// ───────────────────────────────────────────────────────────────────────────



/* ============================================================
 * 1. 조직 ID (Phase 1: 단일 조직 하드코딩)
 * ============================================================ */
const ORG_ID = 'b25de8f2-1020-482f-9012-183f63883169'; // MBG Project

/* ============================================================
 * 2. 메인 워커 루프
 * ============================================================ */

export async function runMailCarrierWorker(): Promise<void> {
  const label = 'mailcarrier-worker';
  const ctl = createShutdownController(label);

  // Supabase service_role (RLS 우회)
  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  // ─ kind 목록 결정 ─
  // MAILCARRIER_POLL_KINDS 비어있으면 Phase 1 fallback (단일 MAILCARRIER_USERNAME)
  const configuredKinds = env.MAILCARRIER_POLL_KINDS;
  const targetKinds: Array<SendingAddressKind | undefined> =
    configuredKinds.length > 0 ? configuredKinds : [undefined];

  // ─ MailCarrierClient 인스턴스 생성 ─
  const carriers: MailCarrierClient[] = [];
  for (const kind of targetKinds) {
    try {
      const carrier = new MailCarrierClient(supabase, ORG_ID, { kind });
      carriers.push(carrier);
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error(
        `[${label}:${kind ?? 'default'}] 자격증명 누락 또는 잘못된 설정:`,
        (err as Error).message,
      );
      // 한 kind 실패 시 다른 kind는 계속
    }
  }

  if (carriers.length === 0) {
    // eslint-disable-next-line no-console
    console.error(
      `[${label}] No valid carriers configured. Check MAILCARRIER_POLL_KINDS or MAILCARRIER_USERNAME/PASSWORD.`,
    );
    process.exit(1);
  }

  // ─ graceful shutdown 설정 ─
  const originalShutdown = ctl.shutdown.bind(ctl);
  const shutdownWithCleanup = async (): Promise<void> => {
    originalShutdown();
    // 모든 carrier 병렬 stop()
    await Promise.all(
      carriers.map(async (c) => {
        try {
          await c.stop();
        } catch (err) {
          // eslint-disable-next-line no-console
          console.error(`[${label}:${c.kind}] stop() error:`, err);
        }
      }),
    );
  };
  process.on('SIGTERM', shutdownWithCleanup);
  process.on('SIGINT', shutdownWithCleanup);

  // ─ 각 carrier 연결 ─
  const connected: MailCarrierClient[] = [];
  for (const carrier of carriers) {
    const tag = `${label}:${carrier.kind}`;
    // eslint-disable-next-line no-console
    console.log(
      `[${tag}] connecting to IMAP ${env.MAILCARRIER_HOST}:${env.MAILCARRIER_PORT} (user=${carrier.username})`,
    );
    try {
      await carrier.connect();
      connected.push(carrier);
      // eslint-disable-next-line no-console
      console.log(
        `[${tag}] connected (folder=${env.MAILCARRIER_INBOX_FOLDER}, mode=${env.MAILCARRIER_USE_IDLE ? 'IDLE' : 'POLL'})`,
      );
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error(`[${tag}] IMAP 연결 실패:`, err);
      // 한 kind 연결 실패해도 다른 kind는 계속
    }
  }

  if (connected.length === 0) {
    // eslint-disable-next-line no-console
    console.error(`[${label}] All IMAP connections failed. Exiting.`);
    process.exit(1);
  }

  // ─ 새 메일 처리 콜백 (carrier별) ─
  const makeOnMessage =
    (carrierKind: SendingAddressKind | 'default') =>
    async (event: InboundMessageEvent): Promise<void> => {
      if (ctl.isShuttingDown()) {
        return;
      }
      const tag = `[${label}:${carrierKind}:${event.communicationId.slice(0, 8)}]`;
      // eslint-disable-next-line no-console
      console.log(
        `${tag} new inbound — from=${event.fromAddress} message_id=${event.messageId}`,
      );
      try {
        await ctl.track(
          (async () => {
            const result = await processInbound(supabase, ORG_ID, event.communicationId);
            // eslint-disable-next-line no-console
            console.log(
              `${tag} processed → draft.id=${result.draftId} ` +
                `category=${result.classification?.category} ` +
                `confidence=${result.classification?.confidence?.toFixed(2)} ` +
                `auto_send=${result.autoSendAllowed}`,
            );
          })(),
        );
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(`${tag} processInbound 실패:`, err);
      }
    };

  // ─ 모든 carrier startListening 병렬 실행 ─
  // eslint-disable-next-line no-console
  console.log(
    `[${label}] listening on ${connected.length} inbox(es)… (Ctrl+C to stop)`,
  );

  const listeners = connected.map((carrier) => {
    const tag = `${label}:${carrier.kind}`;
    return carrier.startListening(makeOnMessage(carrier.kind)).catch((err) => {
      if (ctl.isShuttingDown()) {
        // eslint-disable-next-line no-console
        console.log(`[${tag}] listener stopped due to shutdown signal`);
      } else {
        // eslint-disable-next-line no-console
        console.error(`[${tag}] listener crashed:`, err);
        // 한 listener crash 시에도 다른 listener는 계속
      }
    });
  });

  // 모든 listener가 종료될 때까지 대기
  await Promise.all(listeners);

  // ─ Graceful shutdown 마무리 ─
  await ctl.waitForInflight(30_000);
  // eslint-disable-next-line no-console
  console.log(`[${label}] shutdown complete`);
}

/* ============================================================
 * 3. CLI 엔트리
 * ============================================================ */
if (isMainEntry(import.meta.url)) {
  runMailCarrierWorker().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[mailcarrier-worker] fatal:', err);
    process.exit(1);
  });
}

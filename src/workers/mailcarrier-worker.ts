/**
 * src/workers/mailcarrier-worker.ts
 *
 * Worker that receives new mail from IMAP and triggers the ai.drafts pipeline.
 *
 * Phase 2 changes:
 *   - from a single MAILCARRIER_USERNAME -> based on the MAILCARRIER_POLL_KINDS array
 *   - one MailCarrierClient instance per kind (personal/role/shared)
 *   - each client has an independent IDLE loop (one box's failure doesn't affect others)
 *   - graceful shutdown: stop() all clients in parallel
 *   - if kinds is empty, Phase 1 fallback (single MAILCARRIER_USERNAME)
 *
 * Flow:
 *   [1] create the Supabase service_role client (bypasses RLS)
 *   [2] create 1-3 MailCarrierClients per MAILCARRIER_POLL_KINDS + connect()
 *   [3] run each client.startListening(onMessage) in parallel
 *   [4] on new mail arrival -> persistInbound -> processInbound -> ai.drafts INSERT
 *   [5] SIGTERM/SIGINT -> graceful shutdown of all clients in parallel
 *
 * Run:
 *   npm run worker:mailcarrier
 *
 * Required environment variables:
 *   - SUPABASE_SERVICE_ROLE_KEY
 *   - ANTHROPIC_API_KEY
 *   - MAILCARRIER_HOST / PORT (common)
 *   - MAILCARRIER_POLL_KINDS (e.g. "personal,role,shared")
 *   - MAIL_<KIND>_USERNAME / PASSWORD (per kind)
 *   - or MAILCARRIER_USERNAME / PASSWORD (fallback when POLL_KINDS is empty)
 *
 * Notes:
 *   - Phase 1 handles a single organization (MBG Project).
 *   - errors during processing are recorded as communications.ai_processing_status='failed'.
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
// Where to apply: add the block below verbatim at the top of the file (right after imports, above the main logic)
//
// Key diagnostic signals:
//   - a beforeExit log = the event loop is empty = a definitive sign that all polling loops ended
//     -> confirms the handoff hypothesis (B-1)
//   - uncaughtException/unhandledRejection -> an async error trying to kill the worker
//   - SIGTERM/SIGINT -> terminated externally (Task Scheduler, Defender, user, etc.)
//
// Caution when entering the production phase:
//   - the uncaughtException handler needs to be changed to call process.exit(1)
//   - during diagnosis it deliberately does not exit (to see which error tries to kill the worker)
// =============================================================================

// ─── Process-level diagnostics ─────────────────────────────────────────────
process.on('uncaughtException', (err) => {
  console.error('[worker] uncaughtException:', err);
  // diagnosis phase: deliberately do not exit
  // switch to process.exit(1) when moving to production
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
 * 1. Organization ID (Phase 1: single org hardcoded)
 * ============================================================ */
const ORG_ID = 'b25de8f2-1020-482f-9012-183f63883169'; // MBG Project

/* ============================================================
 * 2. Main worker loop
 * ============================================================ */

export async function runMailCarrierWorker(): Promise<void> {
  const label = 'mailcarrier-worker';
  const ctl = createShutdownController(label);

  // Supabase service_role (bypasses RLS)
  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  // ─ determine the list of receiving accounts ─
  // Phase 3: if app.inbound_mailboxes (active) has rows, poll those accounts.
  //          if there are 0 rows, fall back to the existing env path (MAILCARRIER_POLL_KINDS / single fallback).
  //          (service_role, so RLS is bypassed)
  type InboundMailboxRow = {
    id: string;
    address: string;
    imap_host: string;
    imap_port: number;
    password_encrypted: string;
  };

  let dbMailboxes: InboundMailboxRow[] = [];
  try {
    const { data, error } = await supabase
      .schema('app')
      .from('inbound_mailboxes')
      .select('id, address, imap_host, imap_port, password_encrypted')
      .eq('organization_id', ORG_ID)
      .eq('is_active', true);
    if (error) {
      // eslint-disable-next-line no-console
      console.error(
        `[${label}] inbound_mailboxes lookup failed - falling back to env path:`,
        error.message,
      );
    } else if (data) {
      dbMailboxes = data as unknown as InboundMailboxRow[];
    }
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error(
      `[${label}] inbound_mailboxes lookup error - falling back to env path:`,
      (err as Error).message,
    );
  }

  // ─ create MailCarrierClient instances ─
  const carriers: MailCarrierClient[] = [];

  if (dbMailboxes.length > 0) {
    // Phase 3: arbitrary DB-based receiving accounts (per-account host/port + encrypted password)
    // eslint-disable-next-line no-console
    console.log(
      `[${label}] using ${dbMailboxes.length} DB mailbox(es) from app.inbound_mailboxes`,
    );
    for (const mb of dbMailboxes) {
      try {
        const carrier = new MailCarrierClient(supabase, ORG_ID, {
          account: {
            id: mb.id,
            address: mb.address,
            host: mb.imap_host,
            port: mb.imap_port,
            passwordEncrypted: mb.password_encrypted,
          },
        });
        carriers.push(carrier);
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(
          `[${label}:${mb.address}] account init failed:`,
          (err as Error).message,
        );
        // if one account fails, the others continue
      }
    }
  } else {
    // Phase 1/2 fallback: env kind list (keeps the existing behavior when not registered in the DB)
    const configuredKinds = env.MAILCARRIER_POLL_KINDS;
    const targetKinds: Array<SendingAddressKind | undefined> =
      configuredKinds.length > 0 ? configuredKinds : [undefined];
    for (const kind of targetKinds) {
      try {
        const carrier = new MailCarrierClient(supabase, ORG_ID, { kind });
        carriers.push(carrier);
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(
          `[${label}:${kind ?? 'default'}] missing credentials or bad config:`,
          (err as Error).message,
        );
        // if one kind fails, the others continue
      }
    }
  }

  if (carriers.length === 0) {
    // eslint-disable-next-line no-console
    console.error(
      `[${label}] No valid carriers configured. Check MAILCARRIER_POLL_KINDS or MAILCARRIER_USERNAME/PASSWORD.`,
    );
    process.exit(1);
  }

  // ─ graceful shutdown setup ─
  const originalShutdown = ctl.shutdown.bind(ctl);
  const shutdownWithCleanup = async (): Promise<void> => {
    originalShutdown();
    // stop() all carriers in parallel
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

  // ─ connect each carrier ─
  const connected: MailCarrierClient[] = [];
  for (const carrier of carriers) {
    const tag = `${label}:${carrier.kind}`;
    // eslint-disable-next-line no-console
    console.log(
      `[${tag}] connecting to IMAP ${carrier.connectHost}:${carrier.connectPort} (user=${carrier.username})`,
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
      console.error(`[${tag}] IMAP connection failed:`, err);
      // even if one kind fails to connect, the others continue
    }
  }

  if (connected.length === 0) {
    // eslint-disable-next-line no-console
    console.error(`[${label}] All IMAP connections failed. Exiting.`);
    process.exit(1);
  }

  // ─ new-mail processing callback (per carrier) ─
  const makeOnMessage =
    (carrierKind: SendingAddressKind | 'default' | 'account') =>
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
        console.error(`${tag} processInbound failed:`, err);
      }
    };

  // ─ run startListening for all carriers in parallel ─
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
        // even if one listener crashes, the others continue
      }
    });
  });

  // wait until all listeners terminate
  await Promise.all(listeners);

  // ─ finalize graceful shutdown ─
  await ctl.waitForInflight(30_000);
  // eslint-disable-next-line no-console
  console.log(`[${label}] shutdown complete`);
}

/* ============================================================
 * 3. CLI entry
 * ============================================================ */
if (isMainEntry(import.meta.url)) {
  runMailCarrierWorker().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[mailcarrier-worker] fatal:', err);
    process.exit(1);
  });
}

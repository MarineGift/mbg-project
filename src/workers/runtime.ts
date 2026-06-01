/**
 * workers/runtime.ts
 *
 * graceful shutdown helper shared by the 3 workers.
 *
 * Usage:
 *   const ctl = createShutdownController('mail-merge-worker');
 *   while (!ctl.isShuttingDown()) {
 *     await ctl.track(processOnce());
 *     await ctl.sleep(POLL_INTERVAL_MS);
 *   }
 *   await ctl.waitForInflight();
 *   process.exit(0);
 */

import { fileURLToPath } from 'node:url';

/* ============================================================
 * 1. ShutdownController
 * ============================================================ */

export interface ShutdownController {
  isShuttingDown(): boolean;
  /** Register a Promise for inflight tracking. Returns the same Promise (chainable). */
  track<T>(p: Promise<T>): Promise<T>;
  /** Wait for all inflight to complete. Force-exit if the timeout is exceeded. */
  waitForInflight(timeoutMs?: number): Promise<void>;
  /** A sleep that wakes immediately on a shutdown signal. */
  sleep(ms: number): Promise<void>;
  /** Trigger a forced shutdown externally (for tests). */
  shutdown(): void;
}

export function createShutdownController(label: string): ShutdownController {
  let shuttingDown = false;
  const inflight: Set<Promise<unknown>> = new Set();
  const wakeupResolvers: Array<() => void> = [];

  const triggerWakeup = (): void => {
    while (wakeupResolvers.length > 0) {
      const resolve = wakeupResolvers.shift();
      try {
        resolve?.();
      } catch {
        /* ignore */
      }
    }
  };

  const onSignal = (sig: NodeJS.Signals): void => {
    if (shuttingDown) return;
    shuttingDown = true;
    // eslint-disable-next-line no-console
    console.log(
      `[${label}] received ${sig}, draining inflight tasks (count=${inflight.size})…`,
    );
    triggerWakeup();
  };

  process.on('SIGTERM', onSignal);
  process.on('SIGINT', onSignal);

  return {
    isShuttingDown: () => shuttingDown,

    track<T>(p: Promise<T>): Promise<T> {
      inflight.add(p);
      const cleanup = (): void => {
        inflight.delete(p);
      };
      p.then(cleanup, cleanup);
      return p;
    },

    async waitForInflight(timeoutMs = 30_000): Promise<void> {
      if (inflight.size === 0) return;
      // eslint-disable-next-line no-console
      console.log(
        `[${label}] waiting for ${inflight.size} inflight task(s) (timeout=${timeoutMs}ms)`,
      );
      const settled = Promise.allSettled([...inflight]);
      const timer = new Promise<'timeout'>((resolve) =>
        setTimeout(() => resolve('timeout'), timeoutMs),
      );
      const result = await Promise.race([settled, timer]);
      if (result === 'timeout') {
        // eslint-disable-next-line no-console
        console.error(
          `[${label}] graceful shutdown timed out, ${inflight.size} task(s) still running`,
        );
      }
    },

    sleep(ms: number): Promise<void> {
      if (shuttingDown) return Promise.resolve();
      return new Promise<void>((resolve) => {
        const timer = setTimeout(() => {
          // attempt to remove from wakeupResolvers
          const idx = wakeupResolvers.indexOf(resolve);
          if (idx >= 0) wakeupResolvers.splice(idx, 1);
          resolve();
        }, ms);
        wakeupResolvers.push(() => {
          clearTimeout(timer);
          resolve();
        });
      });
    },

    shutdown(): void {
      onSignal('SIGTERM');
    },
  };
}

/* ============================================================
 * 2. Entry-point guard (ESM)
 * ----------------------------------------------------------
 * Helper to call main() when running `tsx src/workers/foo.ts` directly.
 * Not called on import, so unit tests are safe.
 * ============================================================ */
export function isMainEntry(importMetaUrl: string): boolean {
  try {
    const thisFile = fileURLToPath(importMetaUrl);
    const argv1 = process.argv[1] ?? '';
    return thisFile === argv1 || argv1.endsWith(thisFile);
  } catch {
    return false;
  }
}

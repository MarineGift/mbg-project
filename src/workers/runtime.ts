/**
 * workers/runtime.ts
 *
 * 3 워커가 공유하는 graceful shutdown 헬퍼.
 *
 * 사용:
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
  /** Promise를 inflight 추적에 등록. 반환값은 동일 Promise (chain 가능). */
  track<T>(p: Promise<T>): Promise<T>;
  /** 모든 inflight 완료 대기. timeout 초과 시 강제 종료. */
  waitForInflight(timeoutMs?: number): Promise<void>;
  /** 셧다운 신호를 받으면 즉시 깨어나는 sleep. */
  sleep(ms: number): Promise<void>;
  /** 외부에서 강제 셧다운을 트리거 (테스트용). */
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
        /* 무시 */
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
          // wakeupResolvers에서 제거 시도
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
 * 2. Entry-point 가드 (ESM)
 * ----------------------------------------------------------
 * `tsx src/workers/foo.ts` 직접 실행 시 main()을 호출하기 위한 헬퍼.
 * import 시에는 호출되지 않아 단위 테스트가 안전.
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

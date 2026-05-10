'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';

interface StartResponse {
  ok: boolean;
  campaign_id: string;
  processed: number;
  sent: number;
  failed: number;
  remaining: number;
  campaign_status: string;
  error?: string;
  detail?: string;
}

export default function StartButton({
  campaignId,
  initialStatus,
}: {
  campaignId: string;
  initialStatus: string;
}) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [lastResult, setLastResult] = useState<StartResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState(initialStatus);

  const isTerminal = status === 'completed' || status === 'failed';

  async function trigger() {
    setError(null);
    try {
      const res = await fetch(`/api/campaigns/${campaignId}/start`, {
        method: 'POST',
      });
      const json = (await res.json()) as StartResponse;
      if (!res.ok || !json.ok) {
        setError(json.error ?? json.detail ?? `HTTP ${res.status}`);
        return;
      }
      setLastResult(json);
      setStatus(json.campaign_status);
      startTransition(() => {
        router.refresh();
      });
    } catch (err) {
      setError((err as Error).message);
    }
  }

  if (isTerminal) {
    return (
      <div className="card-tight">
        <div className="text-base text-muted-foreground">
          캠페인이 <strong>{status}</strong> 상태입니다. 더 이상 발송할 수 없습니다.
        </div>
      </div>
    );
  }

  return (
    <div className="card-tight grid gap-3">
      <div className="flex items-center justify-between gap-3">
        <div>
          <div className="text-md font-semibold">발송 제어</div>
          <div className="text-sm text-muted-foreground mt-1">
            현재 상태: <strong>{status}</strong>
          </div>
        </div>
        <button
          onClick={trigger}
          disabled={isPending}
          className="btn-accent"
        >
          {isPending ? '처리 중…' : '발송 시작 / 이어서 처리'}
        </button>
      </div>

      {error ? <div className="alert-error">⚠ {error}</div> : null}

      {lastResult ? (
        <div className="alert-info">
          이번 호출 결과 — 처리: {lastResult.processed} · 성공: {lastResult.sent} · 실패: {lastResult.failed} · 남음: {lastResult.remaining}
        </div>
      ) : null}

      <div className="text-xs text-muted-foreground">
        한 번 호출 시 일정 시간 안에서 처리하고 종료합니다. 남은 큐가 있으면 다시 눌러 이어 처리하세요.
      </div>
    </div>
  );
}

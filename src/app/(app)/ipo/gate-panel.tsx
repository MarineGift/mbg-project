// src/app/(app)/ipo/gate-panel.tsx
//
// L1–L6 readiness gates. Verdict is a human judgment; linked-milestone
// progress is shown as a hint only and never changes the verdict.

'use client';

import { useState } from 'react';
import { setGateVerdict } from './actions';

export type GateRow = {
  id: string; level: number; code: string; question: string; pass_condition: string | null;
  verdict: 'unknown' | 'pass' | 'watch' | 'fail'; evidence: string | null; assessed_at: string | null;
  is_blocking: boolean; linked_done: number; linked_total: number;
};

const LEVEL_NAMES: Record<number, string> = {
  1: 'Nasdaq Legal Eligibility — 상장할 수 있는가',
  2: 'Audit & Financial Reporting — SEC에 제출 가능한가',
  3: 'FCC Commercialization — 상장시킬 만한 사업인가',
  4: 'IP & Legal — 로열티 스트림을 소유·보호하는가',
  5: 'Governance — 상장사로 운영 가능한가',
  6: 'Capital Markets — 주간사가 받고 투자자가 살 것인가',
};
const VERDICT_STYLE: Record<string, string> = {
  unknown: 'bg-muted text-muted-foreground', pass: 'bg-emerald-100 text-emerald-800',
  watch: 'bg-amber-100 text-amber-800', fail: 'bg-red-100 text-red-800',
};

function GateEditor({ g }: { g: GateRow }) {
  const [open, setOpen] = useState(false);
  const [verdict, setVerdict] = useState<string>(g.verdict);
  const [evidence, setEvidence] = useState(g.evidence ?? '');
  const [err, setErr] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const start = (fn: () => Promise<void>) => { setPending(true); void fn().finally(() => setPending(false)); };
  return (
    <div className="border-b py-2">
      <div className="flex items-start gap-3">
        <span className={'mt-0.5 shrink-0 rounded px-1.5 py-0.5 text-[11px] font-medium ' + VERDICT_STYLE[g.verdict]}>{g.verdict}</span>
        <div className="min-w-0 flex-1">
          <div className="text-sm">
            <span className="mr-2 text-xs text-muted-foreground">{g.code}</span>
            {g.question}
            {g.is_blocking && <span className="ml-2 rounded border border-red-300 px-1 text-[10px] text-red-700">blocking</span>}
          </div>
          {g.pass_condition && <div className="text-xs text-muted-foreground">통과 조건: {g.pass_condition}</div>}
          <div className="text-xs text-muted-foreground">
            연결 마일스톤 {g.linked_done}/{g.linked_total} 완료
            {g.assessed_at && <> · 판정일 {g.assessed_at}</>}
            {g.evidence && !open && <> · 근거: {g.evidence}</>}
          </div>
        </div>
        <button type="button" className="shrink-0 rounded border px-2 py-1 text-xs" onClick={() => setOpen(!open)}>{open ? '닫기' : '판정'}</button>
      </div>
      {open && (
        <div className="mt-2 flex flex-col gap-2 pl-14">
          <div className="flex gap-2">
            {(['unknown', 'pass', 'watch', 'fail'] as const).map((v) => (
              <button key={v} type="button" onClick={() => setVerdict(v)}
                className={'rounded px-2 py-1 text-xs ' + (verdict === v ? VERDICT_STYLE[v] + ' ring-1 ring-foreground' : 'border')}>{v}</button>
            ))}
          </div>
          <textarea value={evidence} onChange={(e) => setEvidence(e.target.value)} rows={2}
            placeholder="무엇을 보고 판정했는가 (문서명, 수치, 날짜)" className="rounded border bg-background p-2 text-sm" />
          <div className="flex items-center gap-2">
            <button type="button" disabled={pending}
              onClick={() => start(async () => {
                const r = await setGateVerdict({ gateId: g.id, verdict, evidence });
                if (!r.ok) setErr(r.error); else { setErr(null); setOpen(false); }
              })}
              className="rounded bg-foreground px-3 py-1 text-xs text-background disabled:opacity-50">저장</button>
            {err && <span className="text-xs text-red-600">{err}</span>}
          </div>
        </div>
      )}
    </div>
  );
}

export function GatePanel({ gates }: { gates: GateRow[] }) {
  const levels = [1, 2, 3, 4, 5, 6];
  return (
    <div className="flex flex-col gap-6">
      {levels.map((lv) => {
        const gs = gates.filter((g) => g.level === lv);
        const blockingOpen = gs.filter((g) => g.is_blocking && g.verdict !== 'pass').length;
        const unknown = gs.filter((g) => g.verdict === 'unknown').length;
        const failedBlocking = gs.filter((g) => g.is_blocking && g.verdict === 'fail').length;
        const verdict = failedBlocking ? 'no_go' : unknown ? 'incomplete' : blockingOpen ? 'at_risk' : 'go';
        return (
          <section key={lv}>
            <h3 className="mb-1 flex items-center gap-2 text-sm font-semibold">
              <span className="w-6 text-muted-foreground">L{lv}</span>{LEVEL_NAMES[lv]}
              <span className={'ml-auto rounded px-2 py-0.5 text-xs ' + (verdict === 'go' ? 'bg-emerald-100 text-emerald-800' : verdict === 'no_go' ? 'bg-red-100 text-red-800' : verdict === 'at_risk' ? 'bg-amber-100 text-amber-800' : 'bg-muted text-muted-foreground')}>{verdict}</span>
            </h3>
            {gs.map((g) => <GateEditor key={g.id} g={g} />)}
          </section>
        );
      })}
    </div>
  );
}

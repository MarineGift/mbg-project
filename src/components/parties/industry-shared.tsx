/**
 * components/parties/industry-shared.tsx
 *
 * Phase 6 — Industry detail 섹션(paper / filler)에서 공통으로 사용하는 작은 헬퍼들.
 *
 * 모두 server-render 가능 (no client hooks).
 */

import type { ConfidenceGrade, EvidenceLevel } from '@/types/industry-link';

/* ------------------------------------------------------------
 * Meta — <dl> 내부의 라벨/값 한 쌍
 * ------------------------------------------------------------ */
export function Meta({ label, value }: { label: string; value: string }) {
  return (
    <>
      <dt className="text-gray-500">{label}</dt>
      <dd className="text-gray-900">{value}</dd>
    </>
  );
}

/* ------------------------------------------------------------
 * StatCell — 통계 strip의 한 칸
 * ------------------------------------------------------------ */
type StatAccent = 'gray' | 'amber' | 'emerald';

const STAT_ACCENT_COLOR: Record<StatAccent, string> = {
  gray: 'text-gray-900',
  amber: 'text-amber-700',
  emerald: 'text-emerald-700',
};

export function StatCell({
  label,
  value,
  accent = 'gray',
}: {
  label: string;
  value: number;
  accent?: StatAccent;
}) {
  return (
    <div className="px-5 py-3">
      <div className={`text-lg font-semibold ${STAT_ACCENT_COLOR[accent]}`}>
        {value}
      </div>
      <div className="text-xs text-gray-500">{label}</div>
    </div>
  );
}

/* ------------------------------------------------------------
 * EvidenceBadge / ConfidenceBadge — A/B/C 등급 표시
 *
 * Evidence(회사·공급사 단위)와 Confidence(linkage 단위)는 같은 A/B/C 척도라
 * 색상 매핑 공유.
 * ------------------------------------------------------------ */
const GRADE_COLOR: Record<EvidenceLevel | ConfidenceGrade, string> = {
  A: 'bg-emerald-100 text-emerald-800',
  B: 'bg-yellow-100 text-yellow-800',
  C: 'bg-gray-100 text-gray-700',
};

export function EvidenceBadge({ level }: { level: EvidenceLevel }) {
  return (
    <span
      className={`inline-flex items-center rounded px-2 py-0.5 text-xs font-medium ${GRADE_COLOR[level]}`}
    >
      Evidence {level}
    </span>
  );
}

export function ConfidenceBadge({
  grade,
  size = 'sm',
}: {
  grade: ConfidenceGrade;
  size?: 'xs' | 'sm';
}) {
  const sizing = size === 'xs' ? 'px-1 py-0 text-[10px]' : 'px-1.5 py-0.5 text-xs';
  return (
    <span
      className={`inline-flex items-center rounded font-medium ${GRADE_COLOR[grade]} ${sizing}`}
    >
      {grade}
    </span>
  );
}

/* ------------------------------------------------------------
 * truncate — 긴 텍스트 줄이기 (title 속성에 원문 보존 권장)
 * ------------------------------------------------------------ */
export function truncate(s: string, n: number): string {
  return s.length > n ? s.slice(0, n) + '…' : s;
}

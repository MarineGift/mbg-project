// src/components/schedule/constants.ts
// 일과표(Routine) 공통 상수 — 카테고리 메타 & 날짜 헬퍼

export type RoutineStatus = 'done' | 'partial' | 'skipped';

// 기본 일정(템플릿)
export type RoutineBlock = {
  id: string;
  title: string;
  category: string;
  start_time: string; // "HH:MM:SS"
  end_time: string;   // "HH:MM:SS"
  weekday_mask: number;
  sort_order: number;
  active: boolean;
  note: string | null;
};

export type RoutineLog = {
  id: string;
  block_id: string;
  log_date: string;   // "YYYY-MM-DD"
  status: RoutineStatus;
  actual_minutes: number | null;
  note: string | null;
};

// 특정 날짜의 실제 일정 인스턴스 (materialize된 날에만 존재)
export type RoutineDayBlock = {
  id: string;
  block_date: string;                 // "YYYY-MM-DD"
  template_block_id: string | null;
  title: string;
  category: string;
  start_time: string;                 // "HH:MM:SS"
  end_time: string;                   // "HH:MM:SS"
  sort_order: number;
  status: RoutineStatus | null;       // null = 미체크
  note: string | null;
};

// 오늘 화면/에디터가 공통으로 다루는 "그날의 한 블록" 뷰 모델.
// materialize된 날이면 id=day_block id, 아니면 템플릿에서 투영(id=템플릿 id).
export type DayBlockView = {
  id: string;
  template_block_id: string | null;
  title: string;
  category: string;
  start_time: string;                 // "HH:MM:SS"
  end_time: string;                   // "HH:MM:SS"
  sort_order: number;
  status: RoutineStatus | null;
};

// 카테고리 코드 → 라벨/색 (DB에는 코드만 저장, 색은 프론트에서 매핑)
export const CATEGORY_META: Record<
  string,
  { label: string; dot: string; chip: string; bar: string }
> = {
  work:     { label: '업무',     dot: 'bg-blue-500',   chip: 'bg-blue-50 text-blue-700 ring-blue-600/20',       bar: 'bg-blue-500' },
  english:  { label: '영어',     dot: 'bg-indigo-500', chip: 'bg-indigo-50 text-indigo-700 ring-indigo-600/20', bar: 'bg-indigo-500' },
  exercise: { label: '운동',     dot: 'bg-emerald-500',chip: 'bg-emerald-50 text-emerald-700 ring-emerald-600/20', bar: 'bg-emerald-500' },
  meal:     { label: '식사',     dot: 'bg-amber-500',  chip: 'bg-amber-50 text-amber-700 ring-amber-600/20',    bar: 'bg-amber-500' },
  rest:     { label: '휴식',     dot: 'bg-zinc-400',   chip: 'bg-zinc-100 text-zinc-600 ring-zinc-500/20',      bar: 'bg-zinc-400' },
  growth:   { label: '자기계발', dot: 'bg-violet-500', chip: 'bg-violet-50 text-violet-700 ring-violet-600/20', bar: 'bg-violet-500' },
  personal: { label: '개인',     dot: 'bg-slate-500',  chip: 'bg-slate-100 text-slate-700 ring-slate-500/20',   bar: 'bg-slate-500' },
  other:    { label: '기타',     dot: 'bg-gray-400',   chip: 'bg-gray-100 text-gray-600 ring-gray-500/20',      bar: 'bg-gray-400' },
};

export const CATEGORY_ORDER = ['work', 'english', 'exercise', 'growth', 'meal', 'rest', 'personal', 'other'];

export function catMeta(code: string) {
  return CATEGORY_META[code] ?? CATEGORY_META.other;
}

// "HH:MM:SS" → "HH:MM"
export function hhmm(t: string): string {
  return (t ?? '').slice(0, 5);
}

// 하루의 시작 시각(분)으로 정렬용 키
export function toMinutes(t: string): number {
  const [h, m] = hhmm(t).split(':').map(Number);
  return (h || 0) * 60 + (m || 0);
}

// 휴스턴(America/Chicago) 기준 오늘 날짜 "YYYY-MM-DD"
// (사용자 이전/여행 시 이 tz만 바꾸면 됩니다)
export const APP_TIMEZONE = 'America/Chicago';

export function todayISO(tz: string = APP_TIMEZONE): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: tz,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
}

// ISO 날짜에 delta일 더하기 (정오 기준으로 tz 경계 흔들림 방지)
export function isoAddDays(iso: string, delta: number): string {
  const d = new Date(`${iso}T12:00:00`);
  d.setDate(d.getDate() + delta);
  return new Intl.DateTimeFormat('en-CA', {
    year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(d);
}

// "YYYY-MM-DD" → "9월 11일 (목)" 같은 한국어 라벨
const DOW_KO = ['일', '월', '화', '수', '목', '금', '토'];
export function humanDate(iso: string): string {
  const [, m, d] = iso.split('-').map(Number);
  return `${m}월 ${d}일 (${DOW_KO[dowOf(iso)]})`;
}

// JS Date/ISO → 요일 인덱스(0=일 .. 6=토)
export function dowOf(isoDate: string): number {
  // 정오로 파싱해 tz 경계 흔들림 방지
  return new Date(`${isoDate}T12:00:00`).getDay();
}

// 이 블록이 해당 요일에 활성인가
export function blockActiveOn(mask: number, dow: number): boolean {
  return (mask & (1 << dow)) !== 0;
}

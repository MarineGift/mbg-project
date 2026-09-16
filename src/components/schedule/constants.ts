// src/components/schedule/constants.ts
// Routine schedule shared constants — category meta & date helpers.

export type RoutineStatus = 'done' | 'partial' | 'skipped';

// Default schedule (template)
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

// A specific date's actual schedule instance (exists only on materialized days)
export type RoutineDayBlock = {
  id: string;
  block_date: string;                 // "YYYY-MM-DD"
  template_block_id: string | null;
  title: string;
  category: string;
  start_time: string;                 // "HH:MM:SS"
  end_time: string;                   // "HH:MM:SS"
  sort_order: number;
  status: RoutineStatus | null;       // null = not checked
  note: string | null;
};

// Unified "one block on a day" view used by the day view and the editor.
// On a materialized day, id = day_block id; otherwise projected from the
// template (id = template id).
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

// Category code → label / color (DB stores only the code; colors mapped here)
export const CATEGORY_META: Record<
  string,
  { label: string; dot: string; chip: string; bar: string }
> = {
  work:     { label: 'Work',     dot: 'bg-blue-500',   chip: 'bg-blue-50 text-blue-700 ring-blue-600/20',       bar: 'bg-blue-500' },
  english:  { label: 'English',  dot: 'bg-indigo-500', chip: 'bg-indigo-50 text-indigo-700 ring-indigo-600/20', bar: 'bg-indigo-500' },
  exercise: { label: 'Exercise', dot: 'bg-emerald-500',chip: 'bg-emerald-50 text-emerald-700 ring-emerald-600/20', bar: 'bg-emerald-500' },
  meal:     { label: 'Meal',     dot: 'bg-amber-500',  chip: 'bg-amber-50 text-amber-700 ring-amber-600/20',    bar: 'bg-amber-500' },
  rest:     { label: 'Rest',     dot: 'bg-zinc-400',   chip: 'bg-zinc-100 text-zinc-600 ring-zinc-500/20',      bar: 'bg-zinc-400' },
  growth:   { label: 'Growth',   dot: 'bg-violet-500', chip: 'bg-violet-50 text-violet-700 ring-violet-600/20', bar: 'bg-violet-500' },
  personal: { label: 'Personal', dot: 'bg-slate-500',  chip: 'bg-slate-100 text-slate-700 ring-slate-500/20',   bar: 'bg-slate-500' },
  other:    { label: 'Other',    dot: 'bg-gray-400',   chip: 'bg-gray-100 text-gray-600 ring-gray-500/20',      bar: 'bg-gray-400' },
};

export const CATEGORY_ORDER = ['work', 'english', 'exercise', 'growth', 'meal', 'rest', 'personal', 'other'];

export function catMeta(code: string) {
  return CATEGORY_META[code] ?? CATEGORY_META.other;
}

// "HH:MM:SS" → "HH:MM"
export function hhmm(t: string): string {
  return (t ?? '').slice(0, 5);
}

// Start time (minutes) as a sort key
export function toMinutes(t: string): number {
  const [h, m] = hhmm(t).split(':').map(Number);
  return (h || 0) * 60 + (m || 0);
}

// "Today" in Houston (America/Chicago) as "YYYY-MM-DD".
// (Change this tz if the user relocates/travels.)
export const APP_TIMEZONE = 'America/Chicago';

export function todayISO(tz: string = APP_TIMEZONE): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: tz,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date());
}

// Add delta days to an ISO date (parsed at noon to avoid tz boundary drift)
export function isoAddDays(iso: string, delta: number): string {
  const d = new Date(`${iso}T12:00:00`);
  d.setDate(d.getDate() + delta);
  return new Intl.DateTimeFormat('en-CA', {
    year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(d);
}

// "YYYY-MM-DD" → "Thu, Sep 11"
const DOW_EN = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MON_EN = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
export function humanDate(iso: string): string {
  const [, m, d] = iso.split('-').map(Number);
  return `${DOW_EN[dowOf(iso)]}, ${MON_EN[(m || 1) - 1]} ${d}`;
}

// JS Date/ISO → weekday index (0=Sun .. 6=Sat)
export function dowOf(isoDate: string): number {
  // parse at noon to avoid tz boundary drift
  return new Date(`${isoDate}T12:00:00`).getDay();
}

// Is this block active on the given weekday?
export function blockActiveOn(mask: number, dow: number): boolean {
  return (mask & (1 << dow)) !== 0;
}

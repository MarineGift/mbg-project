// src/lib/tasks/quick-add-parser.ts
// Natural-language quick-add parser for the Todo task engine (Phase 1).
//
// Turns a one-line capture like
//   "Pangaea 팔로업 next thu p1 @pangaea"
//   "IR deck 검토 내일 !high"
//   "Batch 9c-2 이메일 7/10~7/12"
// into { title, dueDate, startDate, priority, partyQuery }.
//
// Design rules (mbg-project):
//  - PURE + ISOMORPHIC: no imports, no I/O. Runs on the CLIENT so relative
//    dates ("내일", "next thu") resolve in the user's local timezone, not the
//    Railway server's UTC. Party lookup happens separately on the server
//    (resolvePartyIdByName in src/lib/tasks/actions.ts).
//  - due_date / start_date are DATE-only ('YYYY-MM-DD') to match app.todo_items.
//    Time-of-day tokens ("3pm", "오후 3시") are intentionally LEFT IN THE TITLE.
//  - Korean tokens have no \b word boundary; whitespace/edge lookarounds are
//    used instead. English tokens are case-insensitive.
//  - Unrecognized text is preserved verbatim; only matched tokens are removed.
//
// Supported tokens
//  Priority : p1 p2 p3 p4  (p1=urgent p2=high p3=med p4=low)
//             !urgent !high !med !low   /   !긴급 !높음 !보통 !낮음
//  Due date : today tomorrow tmr / 오늘 내일 모레
//             next week / 다음주            -> next Monday
//             mon..sun, monday..sunday      -> next occurrence (never today)
//             next mon..sun / 다음주 월(요일) -> occurrence in NEXT week
//             월요일..일요일, 월욜..일욜      -> next occurrence
//             in N days / N일 뒤 / N일 후
//             YYYY-MM-DD, M/D, M월 D일
//  Range    : M/D~M/D, M/D-M/D, YYYY-MM-DD~YYYY-MM-DD  -> startDate + dueDate
//  Party    : @token  or  @"multi word name"  -> partyQuery (resolved server-side)

import type { TaskPriority } from './types';

export interface QuickAddParse {
  /** Title with all recognized tokens stripped (never empty: falls back to raw). */
  title: string;
  dueDate: string | null;    // 'YYYY-MM-DD'
  startDate: string | null;  // 'YYYY-MM-DD' (only from an explicit range)
  priority: TaskPriority | null;
  /** Raw @mention text; resolve to party_id via resolvePartyIdByName(). */
  partyQuery: string | null;
  /** RRULE subset ('FREQ=WEEKLY;INTERVAL=1') or null. Matches app.todo_items.recurrence. */
  recurrence: string | null;
  /** Human-readable list of what was recognized (for UI feedback/toast). */
  matched: string[];
}

const pad2 = (n: number) => (n < 10 ? `0${n}` : `${n}`);

function ymd(d: Date): string {
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

function addDays(base: Date, n: number): Date {
  const d = new Date(base.getFullYear(), base.getMonth(), base.getDate());
  d.setDate(d.getDate() + n);
  return d;
}

/** Next occurrence of weekday wd (0=Sun..6=Sat), strictly after `base`. */
function nextWeekday(base: Date, wd: number): Date {
  let diff = (wd - base.getDay() + 7) % 7;
  if (diff === 0) diff = 7;
  return addDays(base, diff);
}

/** Occurrence of weekday wd in NEXT calendar week (week starts Monday). */
function weekdayNextWeek(base: Date, wd: number): Date {
  const dow = base.getDay(); // 0=Sun..6=Sat
  const daysToNextMonday = ((8 - dow) % 7) || 7; // Mon->7, Sun->1
  const nextMonday = addDays(base, daysToNextMonday);
  const offset = (wd - 1 + 7) % 7; // Mon=0 .. Sun=6
  return addDays(nextMonday, offset);
}

/** M/D with year rollover: if the date already passed this year, use next year. */
function monthDay(base: Date, m: number, d: number): Date | null {
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  let y = base.getFullYear();
  const cand = new Date(y, m - 1, d);
  if (cand.getMonth() !== m - 1 || cand.getDate() !== d) return null; // e.g. 2/30
  const today = new Date(base.getFullYear(), base.getMonth(), base.getDate());
  if (cand < today) y += 1;
  const rolled = new Date(y, m - 1, d);
  return rolled.getMonth() === m - 1 ? rolled : null;
}

// EN weekday name -> 0..6 (Sun..Sat)
const EN_WD: Record<string, number> = {
  sun: 0, sunday: 0, mon: 1, monday: 1, tue: 2, tues: 2, tuesday: 2,
  wed: 3, wednesday: 3, thu: 4, thur: 4, thurs: 4, thursday: 4,
  fri: 5, friday: 5, sat: 6, saturday: 6,
};
// KO weekday char -> 0..6
const KO_WD: Record<string, number> = {
  '일': 0, '월': 1, '화': 2, '수': 3, '목': 4, '금': 5, '토': 6,
};

interface Rule {
  re: RegExp;
  apply: (m: RegExpMatchArray, base: Date, out: MutableParse) => boolean;
}
interface MutableParse {
  dueDate: string | null;
  startDate: string | null;
  priority: TaskPriority | null;
  partyQuery: string | null;
  recurrence: string | null;
  matched: string[];
}

// Korean-safe boundaries: start-or-space before, space-or-end after.
const B = '(?:^|\\s)';
const E = '(?=\\s|$)';

/**
 * Parse a one-line quick-add capture. `now` is injectable for tests.
 * Only the FIRST match of each category (priority / date / party) wins;
 * later duplicates are left in the title untouched.
 */
export function parseQuickAdd(raw: string, now: Date = new Date()): QuickAddParse {
  const base = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const out: MutableParse = {
    dueDate: null, startDate: null, priority: null, partyQuery: null,
    recurrence: null, matched: [],
  };
  let text = ` ${raw.trim()} `; // pad so B/E boundaries behave uniformly

  const consume = (m: RegExpMatchArray): void => {
    // Replace the matched slice with a single space, preserving boundaries.
    const idx = m.index ?? 0;
    text = `${text.slice(0, idx)} ${text.slice(idx + m[0].length)}`;
  };

  // ---- 1) Party: @"multi word" first, then @token -------------------------
  {
    const quoted = text.match(new RegExp(`${B}@"([^"]+)"${E}`));
    const bare = quoted ? null : text.match(new RegExp(`${B}@([^\\s@#"]+)${E}`));
    const m = quoted ?? bare;
    if (m && m[1]) {
      out.partyQuery = m[1].trim();
      out.matched.push(`@${out.partyQuery}`);
      consume(m);
    }
  }

  // ---- 2) Priority ---------------------------------------------------------
  const PRI_RULES: Array<[RegExp, TaskPriority]> = [
    [new RegExp(`${B}[pP]1${E}`), 'urgent'],
    [new RegExp(`${B}[pP]2${E}`), 'high'],
    [new RegExp(`${B}[pP]3${E}`), 'med'],
    [new RegExp(`${B}[pP]4${E}`), 'low'],
    [new RegExp(`${B}!urgent${E}`, 'i'), 'urgent'],
    [new RegExp(`${B}!high${E}`, 'i'), 'high'],
    [new RegExp(`${B}!med(?:ium)?${E}`, 'i'), 'med'],
    [new RegExp(`${B}!low${E}`, 'i'), 'low'],
    [new RegExp(`${B}!긴급${E}`), 'urgent'],
    [new RegExp(`${B}!높음${E}`), 'high'],
    [new RegExp(`${B}!보통${E}`), 'med'],
    [new RegExp(`${B}!낮음${E}`), 'low'],
  ];
  for (const [re, pri] of PRI_RULES) {
    const m = text.match(re);
    if (m) {
      out.priority = pri;
      out.matched.push(`priority:${pri}`);
      consume(m);
      break;
    }
  }

  // ---- 2.5) Recurrence -----------------------------------------------------
  // EN: !daily !weekly !monthly !yearly / every day|week|month|year
  //     every N days|weeks|months|years
  // KO: 매일 매주 매월(매달) 매년 / N일마다 N주마다 N개월마다 N년마다
  const RECUR_SIMPLE: Array<[RegExp, string]> = [
    [new RegExp(`${B}!daily${E}`, 'i'), 'FREQ=DAILY'],
    [new RegExp(`${B}!weekly${E}`, 'i'), 'FREQ=WEEKLY'],
    [new RegExp(`${B}!monthly${E}`, 'i'), 'FREQ=MONTHLY'],
    [new RegExp(`${B}!yearly${E}`, 'i'), 'FREQ=YEARLY'],
    [new RegExp(`${B}every\\s+day${E}`, 'i'), 'FREQ=DAILY'],
    [new RegExp(`${B}every\\s+week${E}`, 'i'), 'FREQ=WEEKLY'],
    [new RegExp(`${B}every\\s+month${E}`, 'i'), 'FREQ=MONTHLY'],
    [new RegExp(`${B}every\\s+year${E}`, 'i'), 'FREQ=YEARLY'],
    [new RegExp(`${B}매일${E}`), 'FREQ=DAILY'],
    [new RegExp(`${B}매주${E}`), 'FREQ=WEEKLY'],
    [new RegExp(`${B}매월${E}`), 'FREQ=MONTHLY'],
    [new RegExp(`${B}매달${E}`), 'FREQ=MONTHLY'],
    [new RegExp(`${B}매년${E}`), 'FREQ=YEARLY'],
  ];
  // "every N days" / "N일마다" -> FREQ + INTERVAL
  const RECUR_INTERVAL: Array<[RegExp, string]> = [
    [new RegExp(`${B}every\\s+(\\d{1,3})\\s+days?${E}`, 'i'), 'DAILY'],
    [new RegExp(`${B}every\\s+(\\d{1,3})\\s+weeks?${E}`, 'i'), 'WEEKLY'],
    [new RegExp(`${B}every\\s+(\\d{1,3})\\s+months?${E}`, 'i'), 'MONTHLY'],
    [new RegExp(`${B}every\\s+(\\d{1,3})\\s+years?${E}`, 'i'), 'YEARLY'],
    [new RegExp(`${B}(\\d{1,3})일\\s*마다${E}`), 'DAILY'],
    [new RegExp(`${B}(\\d{1,3})주\\s*마다${E}`), 'WEEKLY'],
    [new RegExp(`${B}(\\d{1,3})(?:개월|달)\\s*마다${E}`), 'MONTHLY'],
    [new RegExp(`${B}(\\d{1,3})년\\s*마다${E}`), 'YEARLY'],
  ];
  {
    let done = false;
    for (const [re, freq] of RECUR_INTERVAL) {
      const m = text.match(re);
      if (m) {
        const n = Math.max(1, parseInt(m[1]!, 10));
        out.recurrence = `FREQ=${freq};INTERVAL=${n}`;
        out.matched.push(`recur:${out.recurrence}`);
        consume(m);
        done = true;
        break;
      }
    }
    if (!done) {
      for (const [re, rule] of RECUR_SIMPLE) {
        const m = text.match(re);
        if (m) {
          out.recurrence = rule;
          out.matched.push(`recur:${rule}`);
          consume(m);
          break;
        }
      }
    }
  }

  // ---- 3) Dates (longest / most specific first) ---------------------------
  const setDue = (d: Date | null, label: string, m: RegExpMatchArray): boolean => {
    if (!d) return false;
    out.dueDate = ymd(d);
    out.matched.push(`due:${out.dueDate} (${label})`);
    consume(m);
    return true;
  };

  const DATE_RULES: Rule[] = [
    // ISO range: YYYY-MM-DD~YYYY-MM-DD
    {
      re: new RegExp(`${B}(\\d{4}-\\d{2}-\\d{2})\\s*[~]\\s*(\\d{4}-\\d{2}-\\d{2})${E}`),
      apply: (m, _b, o) => {
        o.startDate = m[1]!; o.dueDate = m[2]!;
        o.matched.push(`range:${m[1]}~${m[2]}`);
        return true;
      },
    },
    // M/D range: 7/10~7/12 or 7/10-7/12
    {
      re: new RegExp(`${B}(\\d{1,2})/(\\d{1,2})\\s*[~-]\\s*(\\d{1,2})/(\\d{1,2})${E}`),
      apply: (m, b, o) => {
        const s = monthDay(b, Number(m[1]), Number(m[2]));
        const e2 = monthDay(b, Number(m[3]), Number(m[4]));
        if (!s || !e2) return false;
        o.startDate = ymd(s); o.dueDate = ymd(e2);
        o.matched.push(`range:${o.startDate}~${o.dueDate}`);
        return true;
      },
    },
    // ISO single: YYYY-MM-DD
    {
      re: new RegExp(`${B}(\\d{4})-(\\d{2})-(\\d{2})${E}`),
      apply: (m, _b, o) => {
        const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
        if (d.getMonth() !== Number(m[2]) - 1) return false;
        o.dueDate = ymd(d);
        o.matched.push(`due:${o.dueDate}`);
        return true;
      },
    },
    // KO: N월 D일
    {
      re: new RegExp(`${B}(\\d{1,2})월\\s*(\\d{1,2})일${E}`),
      apply: (m, b, o) => {
        const d = monthDay(b, Number(m[1]), Number(m[2]));
        if (!d) return false;
        o.dueDate = ymd(d);
        o.matched.push(`due:${o.dueDate}`);
        return true;
      },
    },
    // M/D single
    {
      re: new RegExp(`${B}(\\d{1,2})/(\\d{1,2})${E}`),
      apply: (m, b, o) => {
        const d = monthDay(b, Number(m[1]), Number(m[2]));
        if (!d) return false;
        o.dueDate = ymd(d);
        o.matched.push(`due:${o.dueDate}`);
        return true;
      },
    },
    // in N days / N일 뒤 / N일 후
    {
      re: new RegExp(`${B}in\\s+(\\d{1,3})\\s+days?${E}`, 'i'),
      apply: (m, b, o) => {
        o.dueDate = ymd(addDays(b, Number(m[1])));
        o.matched.push(`due:${o.dueDate} (+${m[1]}d)`);
        return true;
      },
    },
    {
      re: new RegExp(`${B}(\\d{1,3})일\\s*[뒤후]${E}`),
      apply: (m, b, o) => {
        o.dueDate = ymd(addDays(b, Number(m[1])));
        o.matched.push(`due:${o.dueDate} (+${m[1]}d)`);
        return true;
      },
    },
    // next <weekday> (EN)
    {
      re: new RegExp(
        `${B}next\\s+(sun(?:day)?|mon(?:day)?|tue(?:s|sday)?|wed(?:nesday)?|thu(?:r|rs|rsday)?|fri(?:day)?|sat(?:urday)?)${E}`,
        'i',
      ),
      apply: (m, b, o) => {
        const wd = EN_WD[m[1]!.toLowerCase()];
        if (wd === undefined) return false;
        o.dueDate = ymd(weekdayNextWeek(b, wd));
        o.matched.push(`due:${o.dueDate} (next ${m[1]})`);
        return true;
      },
    },
    // 다음주 목(요일)? (KO, weekday optional -> defaults to next Monday)
    {
      re: new RegExp(`${B}다음\\s*주\\s*([월화수목금토일])?(?:요일|욜)?${E}`),
      apply: (m, b, o) => {
        const wd = m[1] ? KO_WD[m[1]] : 1; // default: next Monday
        if (wd === undefined) return false;
        o.dueDate = ymd(weekdayNextWeek(b, wd));
        o.matched.push(`due:${o.dueDate} (다음주${m[1] ?? ''})`);
        return true;
      },
    },
    // next week (EN) -> next Monday
    {
      re: new RegExp(`${B}next\\s+week${E}`, 'i'),
      apply: (_m, b, o) => {
        o.dueDate = ymd(weekdayNextWeek(b, 1));
        o.matched.push(`due:${o.dueDate} (next week)`);
        return true;
      },
    },
    // today / tomorrow / tmr
    {
      re: new RegExp(`${B}today${E}`, 'i'),
      apply: (_m, b, o) => { o.dueDate = ymd(b); o.matched.push(`due:${o.dueDate} (today)`); return true; },
    },
    {
      re: new RegExp(`${B}(?:tomorrow|tmr)${E}`, 'i'),
      apply: (_m, b, o) => { o.dueDate = ymd(addDays(b, 1)); o.matched.push(`due:${o.dueDate} (tomorrow)`); return true; },
    },
    // 오늘 / 내일 / 모레
    {
      re: new RegExp(`${B}오늘${E}`),
      apply: (_m, b, o) => { o.dueDate = ymd(b); o.matched.push(`due:${o.dueDate} (오늘)`); return true; },
    },
    {
      re: new RegExp(`${B}내일${E}`),
      apply: (_m, b, o) => { o.dueDate = ymd(addDays(b, 1)); o.matched.push(`due:${o.dueDate} (내일)`); return true; },
    },
    {
      re: new RegExp(`${B}모레${E}`),
      apply: (_m, b, o) => { o.dueDate = ymd(addDays(b, 2)); o.matched.push(`due:${o.dueDate} (모레)`); return true; },
    },
    // bare EN weekday -> next occurrence (never today)
    {
      re: new RegExp(
        `${B}(sunday|monday|tuesday|wednesday|thursday|friday|saturday|sun|mon|tue|tues|wed|thu|thur|thurs|fri|sat)${E}`,
        'i',
      ),
      apply: (m, b, o) => {
        const wd = EN_WD[m[1]!.toLowerCase()];
        if (wd === undefined) return false;
        o.dueDate = ymd(nextWeekday(b, wd));
        o.matched.push(`due:${o.dueDate} (${m[1]})`);
        return true;
      },
    },
    // bare KO weekday: 목요일 / 목욜 (suffix REQUIRED to avoid eating title chars)
    {
      re: new RegExp(`${B}([월화수목금토일])(?:요일|욜)${E}`),
      apply: (m, b, o) => {
        const wd = KO_WD[m[1]!];
        if (wd === undefined) return false;
        o.dueDate = ymd(nextWeekday(b, wd));
        o.matched.push(`due:${o.dueDate} (${m[1]}요일)`);
        return true;
      },
    },
  ];

  for (const rule of DATE_RULES) {
    const m = text.match(rule.re);
    if (m && rule.apply(m, base, out)) {
      consume(m);
      break; // first date expression wins
    }
  }

  // ---- 4) Clean title ------------------------------------------------------
  const title = text.replace(/\s+/g, ' ').trim();
  return {
    title: title.length ? title : raw.trim(),
    dueDate: out.dueDate,
    startDate: out.startDate,
    priority: out.priority,
    partyQuery: out.partyQuery,
    recurrence: out.recurrence,
    matched: out.matched,
  };
}

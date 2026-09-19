// src/lib/meetings/parse-meeting-invite.ts
//
// 2026-09-19 - "Add to Calendar" from an email.
//
// Pure module (no server-only / client-only imports) so the same parser runs in
// the timeline row, in the modal and in the server action.
//
// What it does: given an email (subject + plain and/or html body) it pulls out
//   1. the video meeting URL (Google Meet first, then Zoom / Teams / Webex)
//   2. the dial-in line, when the provider appended one
//   3. every date+time it can anchor on a real calendar date, converted to an
//      absolute instant using whatever timezone the email itself stated
//
// Design notes
// - Every time candidate is ANCHORED ON A DATE MATCH. A bare "9:00" with no
//   date nearby is ignored: an email signature or a phone PIN would otherwise
//   produce garbage events.
// - The instant (startIso) is the single source of truth. displayTimeZone is
//   only the zone the modal should preselect so the wall clock reads the way
//   the email wrote it.
// - Nothing here writes to the DB and nothing throws; a body it cannot read
//   just yields hasSignal = false and the UI hides the button.

export type MeetingProvider =
  | 'google_meet'
  | 'zoom'
  | 'teams'
  | 'webex'
  | 'other'

export interface ParsedTimeCandidate {
  /** Absolute instant, ISO-8601 UTC. The value actually stored. */
  startIso: string
  /** IANA zone the modal should preselect (best guess from the email). */
  displayTimeZone: string
  /** Timezone token as written in the email ("CDT", "Central Time"), if any. */
  timeZoneLabel: string | null
  /** Minutes, when the email stated an end time. null = unknown (default 30). */
  durationMin: number | null
  /** True when only a date was found and 09:00 was assumed. */
  timeAssumed: boolean
  /** The matched text, shown in the UI so the user can sanity-check the pick. */
  snippet: string
  /** Higher = more likely the real meeting time. */
  score: number
}

export interface ParsedMeetingInvite {
  meetingUrl: string | null
  provider: MeetingProvider | null
  /** Phone bridge line, e.g. "(US) +1 650-555-1234 PIN: 123 456 789#". */
  dialIn: string | null
  /** All candidates, best first. */
  times: ParsedTimeCandidate[]
  /** times[0] or null. */
  best: ParsedTimeCandidate | null
  /** True when there is something worth offering an "Add to Calendar" for. */
  hasSignal: boolean
}

export interface ParseMeetingInviteInput {
  subject?: string | null
  bodyPlain?: string | null
  bodyHtml?: string | null
  /** Used to fill in a missing year and to score future dates. Default: now. */
  referenceDate?: string | Date | null
  /** Zone assumed when the email states none. Default: America/Chicago. */
  fallbackTimeZone?: string | null
}

// ─────────────────────────────────────────────────────────────
// Timezone helpers (Intl-based; no date-fns-tz dependency)
// ─────────────────────────────────────────────────────────────

/** Offset of `timeZone` at instant `date`, in milliseconds (east of UTC > 0). */
function zoneOffsetMs(date: Date, timeZone: string): number {
  try {
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hourCycle: 'h23',
    }).formatToParts(date)
    const get = (t: string) => Number(parts.find((p) => p.type === t)?.value ?? '0')
    const asUtc = Date.UTC(
      get('year'), get('month') - 1, get('day'),
      get('hour'), get('minute'), get('second'),
    )
    return asUtc - date.getTime()
  } catch {
    return 0
  }
}

/**
 * Wall-clock fields in `timeZone` -> absolute instant.
 * Two passes so a DST boundary resolves correctly.
 */
export function wallClockToInstant(
  wall: { year: number; month: number; day: number; hour: number; minute: number },
  timeZone: string,
): Date {
  const utcGuess = Date.UTC(wall.year, wall.month - 1, wall.day, wall.hour, wall.minute)
  let ts = utcGuess - zoneOffsetMs(new Date(utcGuess), timeZone)
  ts = utcGuess - zoneOffsetMs(new Date(ts), timeZone)
  return new Date(ts)
}

/** "YYYY-MM-DDTHH:mm" as read in `timeZone` - the value a datetime-local wants. */
export function instantToWallClockInput(iso: string, timeZone: string): string {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  try {
    const parts = new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
    }).formatToParts(d)
    const get = (t: string) => parts.find((p) => p.type === t)?.value ?? ''
    return `${get('year')}-${get('month')}-${get('day')}T${get('hour')}:${get('minute')}`
  } catch {
    return d.toISOString().slice(0, 16)
  }
}

/** "YYYY-MM-DDTHH:mm" (datetime-local value) read in `timeZone` -> ISO instant. */
export function wallClockInputToInstant(value: string, timeZone: string): string | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})/.exec(value)
  if (!m) return null
  const d = wallClockToInstant(
    {
      year: Number(m[1]), month: Number(m[2]), day: Number(m[3]),
      hour: Number(m[4]), minute: Number(m[5]),
    },
    timeZone,
  )
  return Number.isNaN(d.getTime()) ? null : d.toISOString()
}

/** Short zone label for display, e.g. "CDT". */
export function zoneAbbreviation(iso: string, timeZone: string): string {
  try {
    const parts = new Intl.DateTimeFormat('en-US', {
      timeZone, timeZoneName: 'short',
    }).formatToParts(new Date(iso))
    return parts.find((p) => p.type === 'timeZoneName')?.value ?? timeZone
  } catch {
    return timeZone
  }
}

// Abbreviations an email is likely to carry. US abbreviations win where they
// collide (CST = US Central, not China Standard Time) - this CRM's counterparts
// are US investors and mills.
const TZ_ABBR: Record<string, string> = {
  UTC: 'UTC', GMT: 'UTC', Z: 'UTC',
  ET: 'America/New_York', EST: 'America/New_York', EDT: 'America/New_York',
  CT: 'America/Chicago', CST: 'America/Chicago', CDT: 'America/Chicago',
  MT: 'America/Denver', MST: 'America/Denver', MDT: 'America/Denver',
  PT: 'America/Los_Angeles', PST: 'America/Los_Angeles', PDT: 'America/Los_Angeles',
  AKST: 'America/Anchorage', AKDT: 'America/Anchorage',
  HST: 'Pacific/Honolulu',
  BST: 'Europe/London',
  CET: 'Europe/Paris', CEST: 'Europe/Paris',
  EET: 'Europe/Helsinki', EEST: 'Europe/Helsinki',
  KST: 'Asia/Seoul', JST: 'Asia/Tokyo',
  HKT: 'Asia/Hong_Kong', SGT: 'Asia/Singapore',
  IST: 'Asia/Kolkata',
  AEST: 'Australia/Sydney', AEDT: 'Australia/Sydney',
}

// Spelled-out zones, as Google Calendar invitations write them.
const TZ_PHRASES: Array<[RegExp, string]> = [
  [/\beastern (?:standard |daylight )?time\b/i, 'America/New_York'],
  [/\bcentral (?:standard |daylight )?time\b/i, 'America/Chicago'],
  [/\bmountain (?:standard |daylight )?time\b/i, 'America/Denver'],
  [/\bpacific (?:standard |daylight )?time\b/i, 'America/Los_Angeles'],
  [/\bkorean? (?:standard )?time\b|\bseoul\b/i, 'Asia/Seoul'],
  [/\bjapan (?:standard )?time\b|\btokyo\b/i, 'Asia/Tokyo'],
  [/\blondon\b|\bbritish (?:summer )?time\b/i, 'Europe/London'],
  [/\bnew york\b/i, 'America/New_York'],
  [/\bchicago\b/i, 'America/Chicago'],
  [/\blos angeles\b/i, 'America/Los_Angeles'],
]

const IANA_RE = /\b(?:America|Europe|Asia|Australia|Africa|Pacific|Atlantic|Indian)\/[A-Za-z_]+(?:\/[A-Za-z_]+)?\b/
const OFFSET_RE = /\b(?:UTC|GMT)\s*([+-])\s*(\d{1,2})(?::?(\d{2}))?/i

/**
 * Capture group as a plain string ('' when the group did not participate).
 * The repo runs with noUncheckedIndexedAccess, so m[i] is string | undefined.
 */
function cap(m: RegExpExecArray, i: number): string {
  return m[i] ?? ''
}

interface ZoneHit {
  /** IANA zone, or null when only a numeric offset was given. */
  zone: string | null
  /** Minutes east of UTC, when the email gave a raw offset. */
  offsetMinutes: number | null
  label: string
}

function findZone(text: string): ZoneHit | null {
  const off = OFFSET_RE.exec(text)
  if (off) {
    const sign = off[1] === '-' ? -1 : 1
    const mins = sign * (Number(off[2]) * 60 + Number(off[3] ?? 0))
    return { zone: null, offsetMinutes: mins, label: off[0].replace(/\s+/g, '') }
  }
  const iana = IANA_RE.exec(text)
  if (iana) return { zone: iana[0], offsetMinutes: null, label: iana[0] }

  for (const [re, zone] of TZ_PHRASES) {
    const m = re.exec(text)
    if (m) return { zone, offsetMinutes: null, label: m[0] }
  }
  // Abbreviations are uppercase-only on purpose: lowercase "pst" inside a word
  // (and "Est." / "ist") produce far too many false hits.
  // NOTE: no lookbehind anywhere in this file - Safari < 16.4 throws a SYNTAX
  // error on the regex literal, which would take the whole bundle down.
  const abbr = /(^|[^A-Za-z])(UTC|GMT|EST|EDT|CST|CDT|MST|MDT|PST|PDT|AKST|AKDT|HST|BST|CEST|CET|EEST|EET|KST|JST|HKT|SGT|AEST|AEDT)(?![A-Za-z])/.exec(text)
  if (abbr) {
    const tok = cap(abbr, 2)
    return { zone: TZ_ABBR[tok] ?? null, offsetMinutes: null, label: tok }
  }

  const loose = /(^|[^A-Za-z])(ET|CT|MT|PT)(?![A-Za-z])/.exec(text)
  if (loose) {
    const tok = cap(loose, 2)
    return { zone: TZ_ABBR[tok] ?? null, offsetMinutes: null, label: tok }
  }

  return null
}

// ─────────────────────────────────────────────────────────────
// Body normalisation
// ─────────────────────────────────────────────────────────────

const ENTITIES: Record<string, string> = {
  '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"',
  '&#39;': "'", '&#x27;': "'", '&nbsp;': ' ', '&middot;': '.',
  '&ndash;': '-', '&mdash;': '-', '&hellip;': '...',
}

function decodeEntities(s: string): string {
  return s
    .replace(/&[a-z]+;|&#x?[0-9a-f]+;/gi, (m) => {
      const lower = m.toLowerCase()
      if (ENTITIES[lower]) return ENTITIES[lower]
      const num = /^&#(x?)([0-9a-f]+);$/i.exec(m)
      if (num) {
        const code = parseInt(cap(num, 2), cap(num, 1) ? 16 : 10)
        if (Number.isFinite(code) && code > 0 && code < 0x10000) {
          return String.fromCharCode(code)
        }
      }
      return ' '
    })
}

export function htmlToText(html: string): string {
  return decodeEntities(
    html
      .replace(/<(script|style)[\s\S]*?<\/\1>/gi, ' ')
      .replace(/<br\s*\/?>/gi, '\n')
      .replace(/<\/(p|div|tr|li|h[1-6]|table)>/gi, '\n')
      .replace(/<[^>]+>/g, ' '),
  ).replace(/[ \t\u00a0]+/g, ' ')
}

function hrefsOf(html: string): string[] {
  const out: string[] = []
  const re = /href\s*=\s*["']([^"']+)["']/gi
  let m: RegExpExecArray | null
  while ((m = re.exec(html)) !== null) out.push(decodeEntities(cap(m, 1)))
  return out
}

// ─────────────────────────────────────────────────────────────
// Meeting link
// ─────────────────────────────────────────────────────────────

const LINK_PATTERNS: Array<[MeetingProvider, RegExp]> = [
  ['google_meet', /https?:\/\/meet\.google\.com\/[A-Za-z0-9._\-/?=&%]+/i],
  ['zoom', /https?:\/\/[\w.-]*zoom\.us\/(?:j|my|w|s)\/[A-Za-z0-9._\-/?=&%]+/i],
  ['teams', /https?:\/\/teams\.(?:microsoft|live)\.com\/[A-Za-z0-9._\-/?=&%]+/i],
  ['webex', /https?:\/\/[\w.-]*webex\.com\/[A-Za-z0-9._\-/?=&%]+/i],
]

function cleanUrl(url: string): string {
  // Trailing punctuation from prose ("...abc-defg-hij.") and wrapping brackets.
  return url.replace(/[)\]>.,;"']+$/, '')
}

function findMeetingLink(
  haystacks: string[],
): { url: string; provider: MeetingProvider; index: number; source: string } | null {
  for (const [provider, re] of LINK_PATTERNS) {
    for (const hay of haystacks) {
      const m = re.exec(hay)
      if (m) {
        return { url: cleanUrl(m[0]), provider, index: m.index, source: hay }
      }
    }
  }
  return null
}

function findDialIn(text: string): string | null {
  for (const raw of text.split('\n')) {
    const line = raw.trim()
    if (!line || line.length > 160) continue
    if (!/\+\d/.test(line)) continue
    if (/\bPIN\b|\bdial\b|\bphone\b|\bjoin by phone\b/i.test(line)) {
      return line.replace(/\s+/g, ' ')
    }
  }
  return null
}

// ─────────────────────────────────────────────────────────────
// Date / time parsing
// ─────────────────────────────────────────────────────────────

const MONTHS: Record<string, number> = {
  jan: 1, january: 1, feb: 2, february: 2, mar: 3, march: 3, apr: 4, april: 4,
  may: 5, jun: 6, june: 6, jul: 7, july: 7, aug: 8, august: 8,
  sep: 9, sept: 9, september: 9, oct: 10, october: 10,
  nov: 11, november: 11, dec: 12, december: 12,
}

const MONTH_ALT = Object.keys(MONTHS).sort((a, b) => b.length - a.length).join('|')

interface DateHit {
  year: number | null
  month: number
  day: number
  start: number
  end: number
}

function collectDates(text: string): DateHit[] {
  const hits: DateHit[] = []
  const push = (h: DateHit) => {
    if (h.month >= 1 && h.month <= 12 && h.day >= 1 && h.day <= 31) hits.push(h)
  }

  // "September 23, 2026" / "Sep 23" / "Sept 23rd 2026"
  const reMonthDay = new RegExp(
    String.raw`\b(${MONTH_ALT})\.?\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s*,?\s*(\d{4}))?`,
    'gi',
  )
  // "23 September 2026"
  const reDayMonth = new RegExp(
    String.raw`\b(\d{1,2})(?:st|nd|rd|th)?\s+(${MONTH_ALT})\.?(?:\s*,?\s*(\d{4}))?`,
    'gi',
  )
  const reIso = /\b(\d{4})-(\d{1,2})-(\d{1,2})\b/g
  const reUs = /\b(\d{1,2})\/(\d{1,2})\/(\d{4})\b/g
  const reKo = /(\d{4})\s*년\s*(\d{1,2})\s*월\s*(\d{1,2})\s*일/g
  const reKoShort = /(^|[^\d])(\d{1,2})\s*월\s*(\d{1,2})\s*일/g

  let m: RegExpExecArray | null
  while ((m = reMonthDay.exec(text)) !== null) {
    push({
      month: MONTHS[cap(m, 1).toLowerCase()] ?? 0, day: Number(cap(m, 2)),
      year: m[3] ? Number(m[3]) : null, start: m.index, end: m.index + m[0].length,
    })
  }
  while ((m = reDayMonth.exec(text)) !== null) {
    push({
      month: MONTHS[cap(m, 2).toLowerCase()] ?? 0, day: Number(cap(m, 1)),
      year: m[3] ? Number(m[3]) : null, start: m.index, end: m.index + m[0].length,
    })
  }
  while ((m = reIso.exec(text)) !== null) {
    push({
      year: Number(m[1]), month: Number(m[2]), day: Number(m[3]),
      start: m.index, end: m.index + m[0].length,
    })
  }
  while ((m = reUs.exec(text)) !== null) {
    push({
      month: Number(m[1]), day: Number(m[2]), year: Number(m[3]),
      start: m.index, end: m.index + m[0].length,
    })
  }
  while ((m = reKo.exec(text)) !== null) {
    push({
      year: Number(m[1]), month: Number(m[2]), day: Number(m[3]),
      start: m.index, end: m.index + m[0].length,
    })
  }
  while ((m = reKoShort.exec(text)) !== null) {
    const at = m.index + cap(m, 1).length
    const overlaps = hits.some((h) => at >= h.start - 6 && at <= h.end)
    if (!overlaps) {
      push({
        year: null, month: Number(m[2]), day: Number(m[3]),
        start: at, end: m.index + m[0].length,
      })
    }
  }

  return hits.sort((a, b) => a.start - b.start)
}

interface TimeHit {
  hour: number
  minute: number
  endHour: number | null
  endMinute: number | null
  raw: string
  index: number
}

const AMPM = String.raw`(?:\s*(a\.?m\.?|p\.?m\.?))`
const CLOCK = String.raw`(\d{1,2})(?::(\d{2}))?`
const RANGE_SEP = String.raw`\s*(?:-|–|—|~|to|until|till)\s*`

function normalizeHour(hour: number, meridiem: string | undefined): number {
  if (!meridiem) return hour
  const pm = /^p/i.test(meridiem)
  if (pm) return hour === 12 ? 12 : hour + 12
  return hour === 12 ? 0 : hour
}

function findTime(window: string): TimeHit | null {
  // 1. Range first: "9:00 - 9:30 AM", "09:00~10:00", "9 to 10 pm".
  const reRange = new RegExp(
    `${CLOCK}${AMPM}?${RANGE_SEP}${CLOCK}${AMPM}?`, 'i',
  )
  const r = reRange.exec(window)
  if (r) {
    const endMer = r[6]
    const startMer = r[3] ?? endMer          // "9:00 - 9:30 AM" -> both AM
    const h1 = normalizeHour(Number(r[1]), startMer)
    const h2 = normalizeHour(Number(r[4]), endMer)
    const ok = h1 <= 23 && h2 <= 23 && (r[3] || r[6] || (r[2] && r[5]))
    if (ok) {
      return {
        hour: h1, minute: Number(r[2] ?? 0),
        endHour: h2, endMinute: Number(r[5] ?? 0),
        raw: r[0].trim(), index: r.index,
      }
    }
  }

  // 2. Single time with a meridiem: "9am", "9:30 PM", "at 9 a.m."
  const reMer = new RegExp(`${CLOCK}${AMPM}`, 'i')
  const s = reMer.exec(window)
  if (s) {
    const h = normalizeHour(Number(s[1]), s[3])
    if (h <= 23) {
      return {
        hour: h, minute: Number(s[2] ?? 0),
        endHour: null, endMinute: null, raw: s[0].trim(), index: s.index,
      }
    }
  }

  // 3. Korean: "오후 2시 30분"
  const ko = /(오전|오후)?\s*(\d{1,2})\s*시(?:\s*(\d{1,2})\s*분)?/.exec(window)
  if (ko) {
    let h = Number(ko[2])
    if (ko[1] === '오후' && h !== 12) h += 12
    if (ko[1] === '오전' && h === 12) h = 0
    if (h <= 23) {
      return {
        hour: h, minute: Number(ko[3] ?? 0),
        endHour: null, endMinute: null, raw: ko[0].trim(), index: ko.index,
      }
    }
  }

  // 4. Bare 24h "14:00" - only accepted because the window is date-anchored.
  const bare = /(^|[^\d:+])(\d{1,2}):(\d{2})(?![\d:])/.exec(window)
  if (bare) {
    const h = Number(bare[2])
    if (h <= 23) {
      return {
        hour: h, minute: Number(bare[3]),
        endHour: null, endMinute: null,
        raw: cap(bare, 0).slice(cap(bare, 1).length).trim(),
        index: bare.index + cap(bare, 1).length,
      }
    }
  }

  return null
}

function resolveYear(hit: DateHit, hour: number, minute: number, ref: Date): number {
  if (hit.year) return hit.year
  const refYear = ref.getUTCFullYear()
  const candidate = Date.UTC(refYear, hit.month - 1, hit.day, hour, minute)
  // A date more than ~2 months in the past almost always means "next year"
  // (an email sent in December proposing "January 8").
  if (candidate < ref.getTime() - 60 * 24 * 3600 * 1000) return refYear + 1
  return refYear
}

// ─────────────────────────────────────────────────────────────
// Main entry
// ─────────────────────────────────────────────────────────────

export const DEFAULT_PARSE_TIMEZONE = 'America/Chicago'

export function parseMeetingInvite(
  input: ParseMeetingInviteInput,
): ParsedMeetingInvite {
  const fallbackZone = input.fallbackTimeZone || DEFAULT_PARSE_TIMEZONE
  const ref = input.referenceDate ? new Date(input.referenceDate) : new Date()
  const refDate = Number.isNaN(ref.getTime()) ? new Date() : ref

  const plain = input.bodyPlain ?? ''
  const html = input.bodyHtml ?? ''
  const htmlText = html ? htmlToText(html) : ''
  const links = html ? hrefsOf(html) : []

  // Prefer whichever body actually carries content; keep both for link hunting.
  const text = [input.subject ?? '', plain, htmlText]
    .filter(Boolean)
    .join('\n')
    .replace(/\r/g, '')

  const link = findMeetingLink([plain, htmlText, ...links])
  const dialIn = findDialIn(text)

  // Where the link sits in `text`, so nearby times can be scored higher.
  const linkIndexInText = link ? text.indexOf(link.url) : -1

  const globalZone = findZone(text)
  const candidates: ParsedTimeCandidate[] = []

  for (const hit of collectDates(text)) {
    const winStart = Math.max(0, hit.start - 40)
    const winEnd = Math.min(text.length, hit.end + 160)
    const window = text.slice(winStart, winEnd)
    // Only look for a time AFTER the date text, plus a short lead-in before it
    // ("at 9am on September 23" still works because of the 40-char lead).
    const afterDate = text.slice(hit.end, winEnd)
    const time = findTime(afterDate) ?? findTime(text.slice(winStart, hit.start))

    const hour = time ? time.hour : 9
    const minute = time ? time.minute : 0
    const year = resolveYear(hit, hour, minute, refDate)

    const zoneWindow = time
      ? afterDate.slice(0, Math.min(afterDate.length, (time.index ?? 0) + time.raw.length + 60))
      : window
    const zoneHit = findZone(zoneWindow) ?? globalZone

    let startIso: string
    let displayTimeZone: string
    if (zoneHit?.offsetMinutes != null) {
      const utcMs = Date.UTC(year, hit.month - 1, hit.day, hour, minute)
        - zoneHit.offsetMinutes * 60000
      startIso = new Date(utcMs).toISOString()
      displayTimeZone = fallbackZone
    } else {
      displayTimeZone = zoneHit?.zone ?? fallbackZone
      const d = wallClockToInstant(
        { year, month: hit.month, day: hit.day, hour, minute },
        displayTimeZone,
      )
      if (Number.isNaN(d.getTime())) continue
      startIso = d.toISOString()
    }

    let durationMin: number | null = null
    if (time?.endHour != null) {
      let diff = (time.endHour * 60 + (time.endMinute ?? 0)) - (hour * 60 + minute)
      if (diff <= 0) diff += 24 * 60
      if (diff > 0 && diff <= 12 * 60) durationMin = diff
    }

    let score = 0
    if (time) score += 3
    if (time?.endHour != null) score += 1
    if (hit.year) score += 2
    if (zoneHit) score += 2
    if (new Date(startIso).getTime() >= refDate.getTime() - 3600 * 1000) score += 3
    if (linkIndexInText >= 0 && Math.abs(linkIndexInText - hit.start) < 400) score += 3

    candidates.push({
      startIso,
      displayTimeZone,
      timeZoneLabel: zoneHit?.label ?? null,
      durationMin,
      timeAssumed: !time,
      snippet: text.slice(winStart, Math.min(text.length, hit.end + 60))
        .replace(/\s+/g, ' ')
        .trim()
        .slice(0, 140),
      score,
    })
  }

  // De-dupe identical instants, keeping the best-scored one.
  const byInstant = new Map<string, ParsedTimeCandidate>()
  for (const c of candidates) {
    const prev = byInstant.get(c.startIso)
    if (!prev || c.score > prev.score) byInstant.set(c.startIso, c)
  }
  const times = Array.from(byInstant.values())
    .sort((a, b) => b.score - a.score || a.startIso.localeCompare(b.startIso))
    .slice(0, 6)

  return {
    meetingUrl: link?.url ?? null,
    provider: link?.provider ?? null,
    dialIn,
    times,
    best: times[0] ?? null,
    hasSignal: !!link || times.length > 0,
  }
}

/** Subject line cleaned of Re:/Fwd: noise, for use as a default meeting title. */
export function titleFromSubject(subject: string | null | undefined): string {
  const s = (subject ?? '').replace(/^\s*(re|fw|fwd|답장|전달)\s*:\s*/gi, '').trim()
  return s.slice(0, 160)
}

/**
 * scripts/import-linkedin-messages.ts
 *
 * Import a LinkedIn data-export "messages.csv" into app.communications.
 * LinkedIn has no API for personal DMs, so the only supported source is the
 * official export: Settings & Privacy > Data privacy > Get a copy of your data
 * > select "Messages" (or "Download larger data archive") > Request archive.
 * The emailed ZIP contains messages.csv (it usually starts with a few note
 * lines before the real header row; this script skips them automatically).
 *
 * Mapping -> app.communications:
 *   channel        = 'linkedin'
 *   direction      = 'outbound' if the sender is you, else 'inbound'
 *   occurred_at    = DATE
 *   from_name      = FROM
 *   from_address   = SENDER PROFILE URL
 *   subject        = SUBJECT or CONVERSATION TITLE
 *   body_plain     = CONTENT
 *   message_id     = synthesized "li:<conversationId>:<date>:<hash>" (dedupe key)
 *   contact_id     = matched by the counterparty's profile URL vs app.contacts.linkedin_url
 *   party_id       = the matched contact's party
 *   external_data  = { conversation_id, sender_profile_url, recipient_profile_urls, folder, from_name, to_names }
 *
 * Idempotent: rows whose message_id already exists are skipped.
 *
 * Usage (PowerShell):
 *   npx tsx scripts/import-linkedin-messages.ts "$env:USERPROFILE\Downloads\messages.csv" "https://www.linkedin.com/in/<your-handle>"
 *
 * The 2nd arg (your own LinkedIn profile URL) sets inbound/outbound. You can
 * instead set env LINKEDIN_SELF_URL and/or LINKEDIN_SELF_NAME. If neither is
 * given, every message is logged as 'inbound' (a warning is printed).
 *
 * Required env (from .env.local):
 *   NEXT_PUBLIC_SUPABASE_URL  (or SUPABASE_URL)
 *   SUPABASE_SERVICE_ROLE_KEY
 *   NEXT_PUBLIC_DEFAULT_ORG_ID (optional; falls back to the known org id)
 */

import { config as loadEnv } from 'dotenv';
loadEnv({ path: '.env.local' });
loadEnv({ path: '.env' });

import { createClient } from '@supabase/supabase-js';
import * as fs from 'node:fs';
import { createHash } from 'node:crypto';

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const CSV_PATH = process.argv[2] || './messages.csv';
const SELF_URL = process.argv[3] || process.env.LINKEDIN_SELF_URL || '';
const SELF_NAME = process.env.LINKEDIN_SELF_NAME || '';
const ORG_ID =
  process.env.NEXT_PUBLIC_DEFAULT_ORG_ID || 'b25de8f2-1020-482f-9012-183f63883169';
const BATCH = 500;

const SUPABASE_URL = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('ERROR: missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env.local');
  process.exit(1);
}
if (!fs.existsSync(CSV_PATH)) {
  console.error('ERROR: CSV not found at ' + CSV_PATH);
  process.exit(1);
}
if (!SELF_URL && !SELF_NAME) {
  console.warn('WARN: no LINKEDIN_SELF_URL / 2nd arg given -> every message will be logged as inbound.');
}

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

// ---------------------------------------------------------------------------
// Minimal RFC4180 CSV parser (handles quotes, escaped "" , newlines in fields)
// ---------------------------------------------------------------------------
function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = '';
  let inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') { field += '"'; i++; }
        else inQuotes = false;
      } else field += c;
    } else if (c === '"') {
      inQuotes = true;
    } else if (c === ',') {
      row.push(field); field = '';
    } else if (c === '\n') {
      row.push(field); field = '';
      rows.push(row); row = [];
    } else if (c === '\r') {
      // ignore; \n handles row end
    } else {
      field += c;
    }
  }
  if (field.length > 0 || row.length > 0) { row.push(field); rows.push(row); }
  return rows.filter((r) => r.length > 1 || (r.length === 1 && r[0].trim() !== ''));
}

const norm = (h: string) => h.toUpperCase().replace(/_/g, ' ').replace(/\s+/g, ' ').trim();
function normUrl(u: string | undefined | null): string {
  if (!u) return '';
  let s = u.trim().toLowerCase();
  s = s.replace(/^https?:\/\//, '').replace(/^www\./, '');
  s = s.split('?')[0].replace(/\/+$/, '');
  return s;
}
function parseDate(s: string | undefined): string | null {
  if (!s) return null;
  let d = new Date(s);
  if (Number.isNaN(d.getTime())) d = new Date(s.replace(/\//g, '-').replace(' UTC', 'Z'));
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

interface CommRow {
  organization_id: string;
  channel: 'linkedin';
  direction: 'inbound' | 'outbound';
  occurred_at: string | null;
  from_name: string | null;
  from_address: string | null;
  subject: string | null;
  body_plain: string | null;
  message_id: string;
  contact_id: string | null;
  party_id: string | null;
  ai_generated: boolean;
  external_data: Record<string, unknown>;
}

async function main() {
  console.log('LinkedIn messages import');
  console.log('  csv:  ' + CSV_PATH);
  console.log('  self: ' + (SELF_URL || SELF_NAME || '(none -> all inbound)'));

  const raw = fs.readFileSync(CSV_PATH, 'utf8').replace(/^\uFEFF/, '');
  const grid = parseCsv(raw);
  if (!grid.length) { console.error('ERROR: empty CSV'); process.exit(1); }

  // find header row (skip leading note lines)
  const wanted = ['CONVERSATION ID', 'FROM', 'CONTENT'];
  let headerIdx = grid.findIndex((r) => {
    const cells = r.map(norm);
    return wanted.some((w) => cells.includes(w));
  });
  if (headerIdx < 0) headerIdx = 0;
  const header = grid[headerIdx].map(norm);
  const col = (name: string) => header.indexOf(name);
  const idx = {
    convId: col('CONVERSATION ID'),
    title: col('CONVERSATION TITLE'),
    from: col('FROM'),
    senderUrl: col('SENDER PROFILE URL'),
    to: col('TO'),
    recipUrls: col('RECIPIENT PROFILE URLS'),
    date: col('DATE'),
    subject: col('SUBJECT'),
    content: col('CONTENT'),
    folder: col('FOLDER'),
  };
  if (idx.content < 0 || idx.senderUrl < 0) {
    console.error('ERROR: could not find CONTENT / SENDER PROFILE URL columns.');
    console.error('  detected header: ' + header.join(' | '));
    process.exit(1);
  }

  // contacts: linkedin_url -> {contact_id, party_id}
  const linkMap = new Map<string, { contact_id: string; party_id: string | null }>();
  {
    const pageSize = 1000;
    for (let from = 0; ; from += pageSize) {
      const { data, error } = await supabase.schema('app')
        .from('contacts')
        .select('id, party_id, linkedin_url')
        .not('linkedin_url', 'is', null)
        .is('deleted_at', null)
        .range(from, from + pageSize - 1);
      if (error) { console.error('contacts fetch error: ' + error.message); break; }
      const rows = (data ?? []) as any[];
      for (const r of rows) {
        const k = normUrl(r.linkedin_url);
        if (k) linkMap.set(k, { contact_id: r.id, party_id: r.party_id ?? null });
      }
      if (rows.length < pageSize) break;
    }
  }
  console.log('  contacts with linkedin_url: ' + linkMap.size);

  const selfUrlN = normUrl(SELF_URL);
  const selfNameN = SELF_NAME.trim().toLowerCase();

  const out: CommRow[] = [];
  let linked = 0;
  for (let i = headerIdx + 1; i < grid.length; i++) {
    const r = grid[i];
    const get = (j: number) => (j >= 0 && j < r.length ? (r[j] ?? '').trim() : '');
    const content = get(idx.content);
    const subject = get(idx.subject) || get(idx.title);
    if (!content && !subject) continue;

    const fromName = get(idx.from);
    const senderUrl = get(idx.senderUrl);
    const recipUrls = get(idx.recipUrls);
    const dateStr = get(idx.date);
    const convId = get(idx.convId);
    const folder = get(idx.folder);
    const toNames = get(idx.to);

    const isSelf =
      (!!selfUrlN && normUrl(senderUrl) === selfUrlN) ||
      (!!selfNameN && fromName.toLowerCase() === selfNameN);
    const direction: 'inbound' | 'outbound' = isSelf ? 'outbound' : 'inbound';

    // counterparty profile url -> contact link
    const counterpartyUrl = isSelf ? recipUrls.split(/[;, ]+/)[0] : senderUrl;
    const match = linkMap.get(normUrl(counterpartyUrl));
    if (match) linked++;

    const hash = createHash('md5').update(content).digest('hex').slice(0, 10);
    const message_id = `li:${convId || 'na'}:${dateStr || 'na'}:${hash}`;

    out.push({
      organization_id: ORG_ID,
      channel: 'linkedin',
      direction,
      occurred_at: parseDate(dateStr),
      from_name: fromName || null,
      from_address: senderUrl || null,
      subject: subject || null,
      body_plain: content || null,
      message_id,
      contact_id: match?.contact_id ?? null,
      party_id: match?.party_id ?? null,
      ai_generated: false,
      external_data: {
        conversation_id: convId || null,
        sender_profile_url: senderUrl || null,
        recipient_profile_urls: recipUrls || null,
        folder: folder || null,
        from_name: fromName || null,
        to_names: toNames || null,
      },
    });
  }
  console.log('  parsed messages: ' + out.length + ' (linked to a contact: ' + linked + ')');
  if (!out.length) { console.log('nothing to import.'); return; }

  // dedupe against existing message_id
  const existing = new Set<string>();
  const allIds = out.map((o) => o.message_id);
  for (let i = 0; i < allIds.length; i += BATCH) {
    const slice = allIds.slice(i, i + BATCH);
    const { data, error } = await supabase.schema('app')
      .from('communications').select('message_id').in('message_id', slice);
    if (error) { console.error('dedupe check error: ' + error.message); break; }
    for (const r of ((data ?? []) as any[])) existing.add(r.message_id);
  }
  const toInsert = out.filter((o) => !existing.has(o.message_id));
  console.log('  already in DB: ' + existing.size + ' | to insert: ' + toInsert.length);

  let inserted = 0;
  for (let i = 0; i < toInsert.length; i += BATCH) {
    const slice = toInsert.slice(i, i + BATCH);
    const { error } = await supabase.schema('app').from('communications').insert(slice as any);
    if (error) { console.error('insert error: ' + error.message); break; }
    inserted += slice.length;
    console.log('  inserted ' + inserted + '/' + toInsert.length);
  }
  console.log('DONE. inserted ' + inserted + ' linkedin messages.');
}

main().catch((e) => { console.error(e); process.exit(1); });

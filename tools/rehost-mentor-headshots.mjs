// tools/rehost-mentor-headshots.mjs
// Copy mentor headshots from a fresh Airtable CSV export into Supabase Storage
// (bucket mentor-headshots, public) and point app.mentors.headshot_url at them.
//
// Airtable attachment links in a CSV export look like
//   photo.jpg (https://v5.airtableusercontent.com/...)
// and EXPIRE about 2 hours after export -> run this right after downloading.
//
// Usage (from C:\dev\mbg-project):
//   node --env-file=.env.local tools/rehost-mentor-headshots.mjs <export.csv> [--dry] [--all]
//     --dry  report matches only, no download/upload/update
//     --all  also redo mentors that already have a rehosted photo
// Needs NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.local.
// Output is ASCII only.

import fs from 'node:fs';
import { createClient } from '@supabase/supabase-js';

const args = process.argv.slice(2);
const file = args.find((a) => !a.startsWith('--'));
const DRY = args.includes('--dry');
const ALL = args.includes('--all');
const BUCKET = 'mentor-headshots';
if (!file) { console.error('usage: node --env-file=.env.local tools/rehost-mentor-headshots.mjs <export.csv> [--dry] [--all]'); process.exit(2); }

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) { console.error('NEXT_PUBLIC_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY missing in .env.local'); process.exit(2); }
const sb = createClient(url, key, { auth: { persistSession: false } });

const ascii = (s) => String(s ?? '').normalize('NFKD').replace(/[^\x20-\x7E]/g, '');

// --- minimal RFC4180 CSV parser (quoted fields, embedded commas/newlines) ---
function parseCsv(text) {
  const rows = []; let row = []; let f = ''; let q = false;
  text = text.replace(/^\uFEFF/, '');
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) {
      if (c === '"') { if (text[i + 1] === '"') { f += '"'; i++; } else q = false; }
      else f += c;
    } else if (c === '"') q = true;
    else if (c === ',') { row.push(f); f = ''; }
    else if (c === '\n' || c === '\r') {
      if (c === '\r' && text[i + 1] === '\n') i++;
      row.push(f); f = ''; if (row.some((x) => x !== '')) rows.push(row); row = [];
    } else f += c;
  }
  row.push(f); if (row.some((x) => x !== '')) rows.push(row);
  return rows;
}

const rows = parseCsv(fs.readFileSync(file, 'utf8'));
const header = rows.shift().map((h) => h.trim().toLowerCase());
const col = (pred) => header.findIndex(pred);
const iName = col((h) => h === 'name' || h === 'full name' || h.includes('name'));
const iEmail = col((h) => h.includes('email'));
const iShot = col((h) => h.includes('headshot') || h.includes('photo') || h.includes('picture'));
if (iShot < 0 || (iEmail < 0 && iName < 0)) {
  console.error('CSV needs a Headshot/Photo column and an Email or Name column. Header: ' + ascii(header.join(' | ')));
  process.exit(2);
}
console.log(`CSV rows: ${rows.length}  columns -> name:${iName} email:${iEmail} headshot:${iShot}`);

const { data: mentors, error } = await sb.schema('app').from('mentors')
  .select('id, full_name, email, headshot_url');
if (error) { console.error('mentors read failed: ' + ascii(error.message)); process.exit(1); }
const byEmail = new Map(); const byName = new Map();
for (const m of mentors) {
  if (m.email) byEmail.set(m.email.trim().toLowerCase(), m);
  if (m.full_name) byName.set(m.full_name.trim().toLowerCase(), m);
}
const isRehosted = (u) => !!u && u.includes(`/storage/v1/object/public/${BUCKET}/`);

if (!DRY) {
  const { data: b } = await sb.storage.getBucket(BUCKET);
  if (!b) {
    const { error: e } = await sb.storage.createBucket(BUCKET, { public: true });
    if (e) { console.error('bucket create failed: ' + ascii(e.message)); process.exit(1); }
    console.log('created bucket ' + BUCKET);
  }
}

const EXT = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/gif': 'gif' };
let done = 0, skipped = 0, nomatch = 0, nophoto = 0, failed = 0;

for (const r of rows) {
  const name = iName >= 0 ? (r[iName] ?? '').trim() : '';
  const email = iEmail >= 0 ? (r[iEmail] ?? '').trim().toLowerCase() : '';
  const link = ((r[iShot] ?? '').match(/https?:\/\/[^\s)]+/) ?? [])[0];
  const m = (email && byEmail.get(email)) || (name && byName.get(name.toLowerCase()));
  const tag = ascii(name || email);
  if (!m) { nomatch++; console.log('NOMATCH  ' + tag); continue; }
  if (!link) { nophoto++; continue; }
  if (!ALL && isRehosted(m.headshot_url)) { skipped++; continue; }
  if (DRY) { done++; console.log('WOULD    ' + tag); continue; }
  try {
    const res = await fetch(link, { headers: { 'User-Agent': 'mbg-urm-headshot-rehost/1.0' } });
    if (!res.ok) throw new Error('download HTTP ' + res.status + (res.status === 410 || res.status === 403 ? ' (link expired? re-export the CSV)' : ''));
    const type = (res.headers.get('content-type') ?? '').split(';')[0].trim();
    const ext = EXT[type];
    if (!ext) throw new Error('not an image: ' + type);
    const body = Buffer.from(await res.arrayBuffer());
    const path = `${m.id}.${ext}`;
    const up = await sb.storage.from(BUCKET).upload(path, body, { contentType: type, upsert: true });
    if (up.error) throw new Error('upload: ' + up.error.message);
    const pub = sb.storage.from(BUCKET).getPublicUrl(path).data.publicUrl + `?v=${Date.now()}`;
    const upd = await sb.schema('app').from('mentors').update({ headshot_url: pub, updated_at: new Date().toISOString() }).eq('id', m.id);
    if (upd.error) throw new Error('update: ' + upd.error.message);
    done++; console.log('OK       ' + tag);
  } catch (e) {
    failed++; console.log('FAIL     ' + tag + ' - ' + ascii(e.message));
  }
}

console.log(`\n${DRY ? 'DRY RUN ' : ''}done=${done} already_rehosted=${skipped} no_photo=${nophoto} no_match=${nomatch} failed=${failed}`);

// tools/run-sql.mjs - run a .sql file directly against Postgres (bypasses the dashboard)
// Usage: node --env-file=.env.local tools/run-sql.mjs sql\<file>.sql
// If SUPABASE_DB_URL is the IPv6-only direct host (db.<ref>.supabase.co),
// the Supavisor session pooler (IPv4) is discovered and used automatically.
import fs from 'node:fs';
import pg from 'pg';

const file = process.argv[2];
if (!file) { console.error('usage: node --env-file=.env.local tools/run-sql.mjs <file.sql>'); process.exit(2); }
const raw = process.env.SUPABASE_DB_URL;
if (!raw) { console.error('SUPABASE_DB_URL missing in .env.local'); process.exit(2); }

const REGIONS = ['us-east-1', 'us-east-2', 'us-west-1', 'us-west-2', 'ca-central-1', 'sa-east-1',
  'eu-west-1', 'eu-west-2', 'eu-west-3', 'eu-central-1', 'eu-central-2', 'eu-north-1',
  'ap-northeast-1', 'ap-northeast-2', 'ap-south-1', 'ap-southeast-1', 'ap-southeast-2', 'ap-east-1'];

function makeClient(url, timeoutMs) {
  const u = new URL(url);
  u.searchParams.delete('sslmode');
  const local = ['localhost', '127.0.0.1'].includes(u.hostname);
  return new pg.Client({
    connectionString: u.toString(),
    ssl: local ? false : { rejectUnauthorized: false },
    connectionTimeoutMillis: timeoutMs,
    statement_timeout: 900_000,
    application_name: 'run-sql',
  });
}

async function tryConnect(url, timeoutMs) {
  const c = makeClient(url, timeoutMs);
  try { await c.connect(); return { ok: true, client: c }; }
  catch (e) { await c.end().catch(() => {}); return { ok: false, err: String(e && e.message ? e.message : e) }; }
}

async function connect() {
  const first = await tryConnect(raw, 60_000);
  if (first.ok) return first.client;
  const u = new URL(raw);
  const m = u.hostname.match(/^db\.([a-z0-9]+)\.supabase\.co$/);
  if (!m || !/ENOTFOUND|ENETUNREACH|EHOSTUNREACH|EAI_AGAIN/.test(first.err)) throw new Error(first.err);
  const ref = m[1];
  console.log('direct host unreachable (IPv6) - searching session pooler for ' + ref);
  const cands = [];
  for (const p of ['aws-0', 'aws-1']) for (const r of REGIONS) {
    const v = new URL(raw);
    v.hostname = p + '-' + r + '.pooler.supabase.com';
    v.port = '5432';
    v.username = 'postgres.' + ref;
    cands.push(v.toString());
  }
  const results = await Promise.all(cands.map(async (url) => ({ url, ...(await tryConnect(url, 45_000)) })));
  const hit = results.find((x) => x.ok);
  for (const x of results) if (x.ok && x !== hit) await x.client.end().catch(() => {});
  if (hit) {
    console.log('POOLER_HOST=' + new URL(hit.url).hostname + '  (user postgres.' + ref + ', port 5432)');
    return hit.client;
  }
  const near = results.filter((x) => !/tenant or user not found|ENOTFOUND|EAI_AGAIN/i.test(x.err));
  for (const x of near) console.log('candidate ' + new URL(x.url).hostname + ' -> ' + x.err);
  throw new Error('no pooler connected (direct: ' + first.err + ')');
}

const t0 = Date.now();
let client;
try {
  client = await connect();
  // 2026-09-17: long maintenance statements (pooler default timeout is short); show NOTICEs
  await client.query("set statement_timeout = '30min'");
  client.on('notice', (n) => console.log('NOTICE ' + n.message));
  console.log('connected (' + (Date.now() - t0) + ' ms) - running ' + file);
  const res = await client.query(fs.readFileSync(file, 'utf8'));
  const list = Array.isArray(res) ? res : [res];
  const last = list[list.length - 1];
  if (last && last.rows) for (const r of last.rows.slice(0, 500)) console.log(JSON.stringify(r));
  console.log('OK ' + list.length + ' statement(s) in ' + (Date.now() - t0) + ' ms');
} catch (e) {
  console.error('ERROR ' + (e && e.message ? e.message : e));
  process.exitCode = 1;
} finally {
  if (client) await client.end().catch(() => {});
}
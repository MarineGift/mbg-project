// tools/run-sql.mjs - run a .sql file directly against Postgres (bypasses the dashboard)
// Usage: node --env-file=.env.local tools/run-sql.mjs sql\<file>.sql
import fs from 'node:fs';
import pg from 'pg';

const file = process.argv[2];
if (!file) { console.error('usage: node --env-file=.env.local tools/run-sql.mjs <file.sql>'); process.exit(2); }
const raw = process.env.SUPABASE_DB_URL;
if (!raw) { console.error('SUPABASE_DB_URL missing in .env.local'); process.exit(2); }
const u = new URL(raw);
u.searchParams.delete('sslmode');
const local = ['localhost', '127.0.0.1'].includes(u.hostname) || u.hostname.startsWith('/');
const client = new pg.Client({
  connectionString: u.toString(),
  ssl: local ? false : { rejectUnauthorized: false },
  connectionTimeoutMillis: 60_000,
  statement_timeout: 900_000,
  application_name: 'run-sql',
});
const t0 = Date.now();
try {
  await client.connect();
  console.log('connected (' + (Date.now() - t0) + ' ms) - running ' + file);
  const res = await client.query(fs.readFileSync(file, 'utf8'));
  const list = Array.isArray(res) ? res : [res];
  const last = list[list.length - 1];
  if (last && last.rows) for (const r of last.rows.slice(0, 60)) console.log(JSON.stringify(r));
  console.log('OK ' + list.length + ' statement(s) in ' + (Date.now() - t0) + ' ms');
} catch (e) {
  console.error('ERROR ' + (e && e.message ? e.message : e));
  process.exitCode = 1;
} finally {
  await client.end().catch(() => {});
}
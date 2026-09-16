// tools/imap-find.mjs - READ-ONLY: find messages in one inbound mailbox by sender, show their IMAP uids
// Usage: node --env-file=.env.local tools/imap-find.mjs <mailbox address> <from text> [days=3]
// Example: node --env-file=.env.local tools/imap-find.mjs yunyoung.heo@marinebiogroup.com speros 2
// List mode: node --env-file=.env.local tools/imap-find.mjs <mailbox address> --list <from uid>
// Opens INBOX read-only. Never prints the mailbox password.
import pg from 'pg';
import { ImapFlow } from 'imapflow';

const [addr, fromText, daysArg] = process.argv.slice(2);
if (!addr || !fromText) {
  console.error('usage: node --env-file=.env.local tools/imap-find.mjs <mailbox address> <from text> [days]');
  process.exit(2);
}
const days = Number(fromText === '--list' ? 3 : (daysArg ?? 3));
const encKey = process.env.CALENDAR_TOKEN_ENCRYPTION_KEY;
if (!encKey) { console.error('CALENDAR_TOKEN_ENCRYPTION_KEY missing in .env.local'); process.exit(2); }
const raw = process.env.SUPABASE_DB_URL;
if (!raw) { console.error('SUPABASE_DB_URL missing in .env.local'); process.exit(2); }

const u = new URL(raw);
u.searchParams.delete('sslmode');
const local = ['localhost', '127.0.0.1'].includes(u.hostname);
const db = new pg.Client({ connectionString: u.toString(), ssl: local ? false : { rejectUnauthorized: false }, connectionTimeoutMillis: 30_000 });

let imap;
try {
  await db.connect();
  const fn = await db.query(
    "select pg_get_function_identity_arguments(p.oid) as args from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'app' and p.proname = 'decrypt_inbound_mailbox_password' limit 1",
  );
  if (!fn.rows.length) throw new Error('app.decrypt_inbound_mailbox_password not found');
  const encType = /encrypted\s+bytea/i.test(fn.rows[0].args) ? 'bytea' : 'text';
  const expr = encType === 'bytea' ? 'mb.password_encrypted' : 'mb.password_encrypted::text';
  const { rows } = await db.query(
    `select mb.imap_host, mb.imap_port,
            app.decrypt_inbound_mailbox_password(encrypted => ${expr}, enc_key => $2) as pw
       from app.inbound_mailboxes mb
      where lower(mb.address) = lower($1) and mb.is_active
      limit 1`,
    [addr, encKey],
  );
  if (!rows.length) throw new Error('no active inbound mailbox for ' + addr);
  const { imap_host: host, imap_port: portRaw, pw } = rows[0];
  const port = Number(portRaw);
  const implicitTls = port === 993;
  const rejectUnauthorized = String(process.env.MAILCARRIER_TLS_REJECT_UNAUTHORIZED ?? 'true') !== 'false';

  imap = new ImapFlow({
    host, port, secure: implicitTls,
    doSTARTTLS: implicitTls ? undefined : false,
    auth: { user: addr, pass: pw },
    tls: { rejectUnauthorized },
    logger: false,
    socketTimeout: 60_000,
  });
  await imap.connect();
  const box = await imap.mailboxOpen('INBOX', { readOnly: true });
  console.log(`INBOX ${addr}: exists=${box.exists} uidNext=${box.uidNext}`);

  if (fromText === '--list') {
    const start = Math.max(1, Number(daysArg ?? 1));
    console.log(`messages from uid ${start}:`);
    for await (const m of imap.fetch(`${start}:*`, { envelope: true, internalDate: true, size: true }, { uid: true })) {
      const f = m.envelope?.from?.[0];
      const who = f ? (f.address || f.name || '?') : '?';
      const kb = Math.round((m.size ?? 0) / 1024);
      console.log(`  uid=${m.uid}  ${new Date(m.internalDate).toISOString()}  ${kb} KB  ${who}  ${(m.envelope?.subject ?? '').slice(0, 60)}`);
    }
    process.exitCode = 0;
  } else {
  const since = new Date(Date.now() - days * 86_400_000);
  const uids = (await imap.search({ since, from: fromText }, { uid: true })) || [];
  console.log(`search from~"${fromText}" since ${since.toISOString().slice(0, 10)}: ${uids.length} message(s)`);
  if (uids.length) {
    for await (const m of imap.fetch(uids.join(','), { envelope: true, internalDate: true }, { uid: true })) {
      const f = m.envelope?.from?.[0]?.address ?? '?';
      console.log(`  uid=${m.uid}  date=${new Date(m.internalDate).toISOString()}  from=${f}  subject=${m.envelope?.subject ?? ''}`);
    }
  }
  const lastFrom = Math.max(1, Number(box.uidNext) - 5);
  console.log('newest messages in INBOX:');
  for await (const m of imap.fetch(`${lastFrom}:*`, { envelope: true, internalDate: true }, { uid: true })) {
    const f = m.envelope?.from?.[0]?.address ?? '?';
    console.log(`  uid=${m.uid}  date=${new Date(m.internalDate).toISOString()}  from=${f}`);
  }
  }
} catch (e) {
  console.error('ERROR ' + (e && e.message ? e.message : e));
  process.exitCode = 1;
} finally {
  if (imap) await imap.logout().catch(() => {});
  await db.end().catch(() => {});
}
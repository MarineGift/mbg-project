/**
 * scripts/register-inbound-mailbox.ts
 *
 * Register (or update) one receiving account in app.inbound_mailboxes.
 *
 * Key point: the enc_key used for password encryption is read from process.env.CALENDAR_TOKEN_ENCRYPTION_KEY
 * - the same source as the key the mailcarrier worker uses to decrypt, so
 * a key mismatch is structurally impossible. (prevents errors from hand-pasting the key via raw SQL)
 *
 * Run (inject .env.local just like the worker):
 *   npx tsx --env-file=.env.local src/scripts/register-inbound-mailbox.ts \
 *     --address you@gmail.com --host imap.gmail.com --port 993 --label "Gmail"
 *
 * The password is not taken as an argument but entered via a stdin prompt (echo hidden) at runtime ->
 * so the password does not remain in the process list (ps) or shell history.
 *
 * Arguments:
 *   --address  (required) receiving address = IMAP username
 *   --host     (required) IMAP host (e.g. imap.gmail.com, imap.naver.com)
 *   --port     (optional, default 993)
 *   --label    (optional) display label
 *   --org      (optional, default MBG org)
 */

import { createClient } from '@supabase/supabase-js';
import { env } from '../lib/env';
import { createInterface } from 'node:readline';
import { Writable } from 'node:stream';

const DEFAULT_ORG = 'b25de8f2-1020-482f-9012-183f63883169'; // MBG Project

/* ── simple --flag value parser ── */
function parseArgs(argv: string[]): Record<string, string> {
  const out: Record<string, string> = {};
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (!a) continue;
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) {
        out[key] = next;
        i += 1;
      } else {
        out[key] = 'true';
      }
    }
  }
  return out;
}

/* ── password input (echo hidden) ── */
function promptHidden(question: string): Promise<string> {
  return new Promise((resolve) => {
    // a mutable stream that does not echo input to the screen
    let muted = false;
    const mutedOut = new Writable({
      write(chunk, _enc, cb) {
        if (!muted) process.stdout.write(chunk);
        cb();
      },
    });
    const rl = createInterface({
      input: process.stdin,
      output: mutedOut,
      terminal: true,
    });
    rl.question(question, (answer) => {
      rl.close();
      process.stdout.write('\n');
      resolve(answer.trim());
    });
    muted = true; // block input echo right after the question is printed
  });
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));

  const address = args.address;
  const host = args.host;
  const port = args.port ? Number(args.port) : 993;
  const label = args.label ?? null;
  const org = args.org ?? DEFAULT_ORG;

  if (!address || !host) {
    console.error(
      'Usage: tsx --env-file=.env.local src/scripts/register-inbound-mailbox.ts ' +
        '--address you@gmail.com --host imap.gmail.com [--port 993] [--label "Gmail"]',
    );
    process.exit(1);
  }
  if (!Number.isFinite(port) || port < 1 || port > 65535) {
    console.error(`Invalid --port: ${args.port}`);
    process.exit(1);
  }

  // enc_key - the same source as the very key the worker (mailcarrier) uses to decrypt.
  const encKey = process.env.CALENDAR_TOKEN_ENCRYPTION_KEY;
  if (!encKey) {
    console.error(
      'CALENDAR_TOKEN_ENCRYPTION_KEY not set. Run with: tsx --env-file=.env.local ...',
    );
    process.exit(1);
  }

  const password = await promptHidden(
    `IMAP app password for ${address} (input hidden): `,
  );
  if (!password) {
    console.error('Empty password. Aborted.');
    process.exit(1);
  }

  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  // bare .rpc (app schema function), same as calendar token-crypto.
  const { data: id, error } = await supabase.schema('app').rpc('upsert_inbound_mailbox', {
    p_organization_id: org,
    p_address: address,
    p_label: label,
    p_imap_host: host,
    p_imap_port: port,
    p_use_tls: true,
    p_password: password,
    p_enc_key: encKey,
  });

  if (error) {
    console.error('upsert_inbound_mailbox failed:', error.message);
    process.exit(1);
  }

  console.log(`OK — inbound mailbox registered/updated.`);
  console.log(`  id:      ${id}`);
  console.log(`  address: ${address}`);
  console.log(`  host:    ${host}:${port}`);
  console.log(`  label:   ${label ?? '(none)'}`);

  // ── round-trip decryption check ──
  // decrypt the just-saved ciphertext with the same key -> it must match the entered password.
  // (same source as the worker's decryption key, so if this succeeds the worker will too)
  const { data: row, error: selErr } = await supabase
    .schema('app')
    .from('inbound_mailboxes')
    .select('password_encrypted')
    .eq('id', id as string)
    .single();

  if (selErr || !row) {
    console.warn(
      `\n[warn] could not re-fetch row for verification: ${selErr?.message ?? 'no row'}`,
    );
  } else {
    const { data: decrypted, error: decErr } = await supabase.schema('app').rpc(
      'decrypt_inbound_mailbox_password',
      {
        encrypted: (row as { password_encrypted: string }).password_encrypted,
        enc_key: encKey,
      },
    );
    if (decErr || typeof decrypted !== 'string') {
      console.error(
        `\n[FAIL] decrypt verification error: ${decErr?.message ?? 'no data'}`,
      );
      process.exit(1);
    }
    if (decrypted === password) {
      console.log('\n[verify] OK — decrypt matches input. Worker key will work.');
    } else {
      console.error(
        '\n[FAIL] decrypted password does NOT match input — key mismatch or storage issue.',
      );
      process.exit(1);
    }
  }

  console.log('\nNext: start the worker and watch for this mailbox:');
  console.log('  npm run worker:mailcarrier');

  process.exit(0);
}

main().catch((err) => {
  console.error('register-inbound-mailbox error:', err);
  process.exit(1);
});

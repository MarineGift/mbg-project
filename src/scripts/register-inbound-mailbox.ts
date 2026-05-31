/**
 * scripts/register-inbound-mailbox.ts
 *
 * app.inbound_mailboxes 에 수신 계정을 1개 등록(또는 갱신)한다.
 *
 * 핵심: 비밀번호 암호화에 쓰는 enc_key 를 process.env.CALENDAR_TOKEN_ENCRYPTION_KEY
 * 에서 읽는다 — mailcarrier 워커가 복호에 쓰는 키와 "같은 출처"이므로
 * 키 불일치가 구조적으로 불가능하다. (직접 SQL 로 키를 손으로 붙이다 틀리는 사고 방지)
 *
 * 실행 (워커와 동일하게 .env.local 주입):
 *   npx tsx --env-file=.env.local src/scripts/register-inbound-mailbox.ts \
 *     --address you@gmail.com --host imap.gmail.com --port 993 --label "Gmail"
 *
 * 비밀번호는 인자로 받지 않고 실행 중 stdin 프롬프트(에코 숨김)로 입력 →
 * 프로세스 목록(ps)·셸 히스토리에 비번이 안 남는다.
 *
 * 인자:
 *   --address  (필수) 수신 주소 = IMAP username
 *   --host     (필수) IMAP host (예: imap.gmail.com, imap.naver.com)
 *   --port     (선택, 기본 993)
 *   --label    (선택) 표시용 라벨
 *   --org      (선택, 기본 MBG org)
 */

import { createClient } from '@supabase/supabase-js';
import { env } from '../lib/env';
import { createInterface } from 'node:readline';
import { Writable } from 'node:stream';

const DEFAULT_ORG = 'b25de8f2-1020-482f-9012-183f63883169'; // MBG Project

/* ── 간단한 --flag value 파서 ───────────────────────────── */
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

/* ── 비번 입력 (에코 숨김) ──────────────────────────────── */
function promptHidden(question: string): Promise<string> {
  return new Promise((resolve) => {
    // 입력 문자를 화면에 안 찍는 mutable stream
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
    muted = true; // question 출력 직후부터 입력 에코 차단
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

  // enc_key — 워커(mailcarrier)가 복호에 쓰는 바로 그 키와 동일 출처.
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

  // calendar token-crypto 와 동일하게 bare .rpc (app 스키마 함수).
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

  // ── 라운드트립 복호 검증 ────────────────────────────────
  // 방금 저장한 암호문을 같은 키로 복호 → 입력 비번과 일치해야 한다.
  // (워커가 복호에 쓰는 키와 동일 출처이므로, 여기서 성공하면 워커도 성공)
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

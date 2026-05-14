/**
 * src/scripts/verify-smtp-all.ts
 *
 * 3개 발신 계정(personal / role / shared)의 SMTP 연결·인증을
 * 한 번에 검증한다. 메일은 실제 발송 안 함.
 *
 * 실행:
 *   npx tsx --env-file=.env.local src/scripts/verify-smtp-all.ts
 *   또는 npm run verify:smtp-all
 *
 * 출력 예:
 *   ✓ personal  ceo@marinebiogroup.com         (1100ms)
 *   ✓ role      yunyoung.heo@marinebiogroup.com (980ms)
 *   ✗ shared    contact@marinebiogroup.com     auth failed (incorrect password)
 */

import { env } from '../lib/env';
import { TabsMailerClient } from '../lib/email/tabs-mailer';

async function main(): Promise<void> {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('  TABS Mailer — 3계정 일괄 SMTP 검증');
  console.log('═══════════════════════════════════════════════════════════\n');

  console.log('[공통 설정]');
  console.log(`  host: ${env.TABS_MAILER_HOST}`);
  console.log(`  port: ${env.TABS_MAILER_PORT}`);
  console.log(`  use_tls: ${env.TABS_MAILER_USE_TLS}`);
  console.log(`  tls_reject_unauthorized: ${env.TABS_MAILER_TLS_REJECT_UNAUTHORIZED ?? '(default)'}`);
  console.log('');

  console.log('[계정 설정]');
  const accounts = [
    { kind: 'personal', user: env.MAIL_PERSONAL_USERNAME, display: env.MAIL_PERSONAL_DISPLAY_NAME },
    { kind: 'role', user: env.MAIL_ROLE_USERNAME, display: env.MAIL_ROLE_DISPLAY_NAME },
    { kind: 'shared', user: env.MAIL_SHARED_USERNAME, display: env.MAIL_SHARED_DISPLAY_NAME },
  ];
  for (const a of accounts) {
    if (a.user) {
      console.log(`  ${a.kind.padEnd(8)} ${a.user} (display: "${a.display}")`);
    } else {
      console.log(`  ${a.kind.padEnd(8)} (not configured)`);
    }
  }
  console.log('');

  console.log('[검증 시작] 각 계정 SMTP AUTH LOGIN 시도…\n');
  const client = new TabsMailerClient();
  const results = await client.verifyAll();
  await client.close();

  let okCount = 0;
  let failCount = 0;
  for (const r of results) {
    if (r.kind === 'default') continue; // hidden — TABS_MAILER_USERNAME/PASSWORD 단일 fallback
    if (r.ok) {
      console.log(`  ✓ ${r.kind.padEnd(8)} OK`);
      okCount++;
    } else {
      console.log(`  ✗ ${r.kind.padEnd(8)} FAILED — ${r.error}`);
      failCount++;
    }
  }

  console.log('');
  console.log('═══════════════════════════════════════════════════════════');
  if (failCount === 0) {
    console.log(`  ✅ 모든 계정 검증 성공 (${okCount}/3)`);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('\n다음 단계:');
    console.log('  1. 외부 메일 → ceo@marinebiogroup.com 또는 다른 계정으로 발송');
    console.log('  2. (Phase 2 후) mailcarrier 워커가 처리 → /drafts에 새 초안');
    console.log('  3. /drafts → 초안 클릭 → Approve 버튼');
    console.log('  4. 다이얼로그에서 발신 주소 select → "Approve & Send"');
    console.log('  5. 외부 inbox에서 회신 도착 확인');
  } else {
    console.log(`  ⚠ ${okCount}/3 성공, ${failCount}/3 실패`);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('\n실패한 계정 점검:');
    console.log('  - 비밀번호 오타 (.env.local의 MAIL_*_PASSWORD)');
    console.log('  - 계정 활성화 여부 (메일 호스팅 패널)');
    console.log('  - 계정 잠금 여부');
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Fatal:', err);
  process.exit(1);
});

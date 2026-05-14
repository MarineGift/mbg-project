/**
 * src/scripts/verify-smtp.ts
 *
 * TABS Mailer SMTP 연결·인증을 확인하는 헬스체크 스크립트.
 * 실제 메일을 발송하지 않고, 연결과 LOGIN만 검증한다.
 *
 * 실행:
 *   npx tsx --env-file=.env.local src/scripts/verify-smtp.ts
 *   또는 npm run verify:smtp
 *
 * 성공 시: "✓ SMTP 연결·인증 정상" 출력
 * 실패 시: 구체적 에러 메시지 + 흔한 원인 가이드
 */

import { env, isUsingMockMailer } from '../lib/env';
import { TabsMailerClient } from '../lib/email/tabs-mailer';

async function main(): Promise<void> {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  TABS Mailer SMTP 연결 검증');
  console.log('═══════════════════════════════════════════════════════\n');

  console.log('[설정]');
  console.log(`  host: ${env.TABS_MAILER_HOST}`);
  console.log(`  port: ${env.TABS_MAILER_PORT}`);
  console.log(`  use_tls: ${env.TABS_MAILER_USE_TLS}`);
  console.log(`  auth_method: ${env.TABS_MAILER_AUTH_METHOD}`);
  console.log(`  username: ${env.TABS_MAILER_USERNAME ?? '(none)'}`);
  console.log(`  use_mock: ${env.TABS_MAILER_USE_MOCK}`);
  console.log(`  tls_reject_unauthorized: ${env.TABS_MAILER_TLS_REJECT_UNAUTHORIZED ?? '(default: true)'}`);
  console.log('');

  if (isUsingMockMailer()) {
    console.log('⚠️  USE_MOCK=true 또는 host=mock 상태입니다.');
    console.log('   실제 SMTP 발송을 검증하려면 TABS_MAILER_USE_MOCK=false 로 설정하세요.');
    process.exit(1);
  }

  console.log('[검증] SMTP 연결 + AUTH LOGIN 시도…');
  const mailer = new TabsMailerClient();
  const startMs = Date.now();
  try {
    await mailer.verify();
    const elapsedMs = Date.now() - startMs;
    console.log(`      ✓ SMTP 연결·인증 정상 (${elapsedMs}ms)\n`);
    console.log('═══════════════════════════════════════════════════════');
    console.log('  ✅ 검증 성공');
    console.log('═══════════════════════════════════════════════════════');
    console.log('\n다음 단계:');
    console.log('  1. 브라우저 → http://localhost:3002/drafts');
    console.log('  2. 대기 중인 초안 클릭 → 상세 페이지');
    console.log('  3. "승인 및 발송" 버튼 클릭');
    console.log('  4. 외부 inbox에서 실제 도착 확인');
  } catch (err) {
    console.error('      ❌ SMTP 검증 실패\n');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error(err);
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error('\n흔한 원인:');
    console.error('  - Authentication failed → 비밀번호 또는 USERNAME 오타');
    console.error('  - self signed certificate → TABS_MAILER_TLS_REJECT_UNAUTHORIZED=false 미설정');
    console.error('  - ECONNREFUSED / timeout → 호스트/포트 오타 또는 방화벽');
    console.error('  - STARTTLS not supported → USE_TLS=false 시도 또는 포트 변경(465)');
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Fatal:', err);
  process.exit(1);
});

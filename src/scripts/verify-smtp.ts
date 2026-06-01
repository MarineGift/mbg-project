/**
 * src/scripts/verify-smtp.ts
 *
 * Health-check script that verifies the TABS Mailer SMTP connection/auth.
 * Verifies only the connection and LOGIN, without sending real mail.
 *
 * Run:
 *   npx tsx --env-file=.env.local src/scripts/verify-smtp.ts
 *   or npm run verify:smtp
 *
 * On success: prints "SMTP connection/auth OK"
 * On failure: a specific error message + common-cause guide
 */

import { env, isUsingMockMailer } from '../lib/env';
import { TabsMailerClient } from '../lib/email/tabs-mailer';

async function main(): Promise<void> {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  TABS Mailer SMTP connection check');
  console.log('═══════════════════════════════════════════════════════\n');

  console.log('[Settings]');
  console.log(`  host: ${env.TABS_MAILER_HOST}`);
  console.log(`  port: ${env.TABS_MAILER_PORT}`);
  console.log(`  use_tls: ${env.TABS_MAILER_USE_TLS}`);
  console.log(`  auth_method: ${env.TABS_MAILER_AUTH_METHOD}`);
  console.log(`  username: ${env.TABS_MAILER_USERNAME ?? '(none)'}`);
  console.log(`  use_mock: ${env.TABS_MAILER_USE_MOCK}`);
  console.log(`  tls_reject_unauthorized: ${env.TABS_MAILER_TLS_REJECT_UNAUTHORIZED ?? '(default: true)'}`);
  console.log('');

  if (isUsingMockMailer()) {
    console.log('⚠️  USE_MOCK=true or host=mock is set.');
    console.log('   Set TABS_MAILER_USE_MOCK=false to verify real SMTP sending.');
    process.exit(1);
  }

  console.log('[Check] Trying SMTP connection + AUTH LOGIN...');
  const mailer = new TabsMailerClient();
  const startMs = Date.now();
  try {
    await mailer.verify();
    const elapsedMs = Date.now() - startMs;
    console.log(`      SMTP connection/auth OK (${elapsedMs}ms)\n`);
    console.log('═══════════════════════════════════════════════════════');
    console.log('  Check succeeded');
    console.log('═══════════════════════════════════════════════════════');
    console.log('\nNext steps:');
    console.log('  1. Browser -> http://localhost:3002/drafts');
    console.log('  2. Click a pending draft -> detail page');
    console.log('  3. Click the "Approve & Send" button');
    console.log('  4. Confirm actual delivery in an external inbox');
  } catch (err) {
    console.error('      SMTP check failed\n');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error(err);
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error('\nCommon causes:');
    console.error('  - Authentication failed -> wrong password or USERNAME');
    console.error('  - self signed certificate -> TABS_MAILER_TLS_REJECT_UNAUTHORIZED=false not set');
    console.error('  - ECONNREFUSED / timeout -> wrong host/port or firewall');
    console.error('  - STARTTLS not supported -> try USE_TLS=false or change port (465)');
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Fatal:', err);
  process.exit(1);
});

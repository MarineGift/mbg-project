/**
 * src/scripts/verify-smtp-all.ts
 *
 * Verifies the SMTP connection/auth of the 3 sending accounts (personal / role / shared)
 * all at once. Does not actually send mail.
 *
 * Run:
 *   npx tsx --env-file=.env.local src/scripts/verify-smtp-all.ts
 *   or npm run verify:smtp-all
 *
 * Example output:
 *   ✓ personal  ceo@marinebiogroup.com         (1100ms)
 *   ✓ role      yunyoung.heo@marinebiogroup.com (980ms)
 *   ✗ shared    contact@marinebiogroup.com     auth failed (incorrect password)
 */

import { env } from '../lib/env';
import { TabsMailerClient } from '../lib/email/tabs-mailer';

async function main(): Promise<void> {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('  TABS Mailer - batch SMTP check for 3 accounts');
  console.log('═══════════════════════════════════════════════════════════\n');

  console.log('[Common settings]');
  console.log(`  host: ${env.TABS_MAILER_HOST}`);
  console.log(`  port: ${env.TABS_MAILER_PORT}`);
  console.log(`  use_tls: ${env.TABS_MAILER_USE_TLS}`);
  console.log(`  tls_reject_unauthorized: ${env.TABS_MAILER_TLS_REJECT_UNAUTHORIZED ?? '(default)'}`);
  console.log('');

  console.log('[Account settings]');
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

  console.log('[Start] Trying SMTP AUTH LOGIN for each account...\n');
  const client = new TabsMailerClient();
  const results = await client.verifyAll();
  await client.close();

  let okCount = 0;
  let failCount = 0;
  for (const r of results) {
    if (r.kind === 'default') continue; // hidden - single TABS_MAILER_USERNAME/PASSWORD fallback
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
    console.log(`  All accounts verified (${okCount}/3)`);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('\nNext steps:');
    console.log('  1. Send external mail -> ceo@marinebiogroup.com or another account');
    console.log('  2. (After Phase 2) the mailcarrier worker processes it -> new draft in /drafts');
    console.log('  3. /drafts -> click a draft -> Approve button');
    console.log('  4. In the dialog, select the sender address -> "Approve & Send"');
    console.log('  5. Confirm the reply arrives in an external inbox');
  } else {
    console.log(`  ⚠ ${okCount}/3 ok, ${failCount}/3 failed`);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('\nTroubleshoot failed accounts:');
    console.log('  - Wrong password (MAIL_*_PASSWORD in .env.local)');
    console.log('  - Account enabled? (mail hosting panel)');
    console.log('  - Account locked?');
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Fatal:', err);
  process.exit(1);
});

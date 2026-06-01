/**
 * src/scripts/simulate-inbound.ts
 *
 * AI Drafts pipeline simulation (Path A verification)
 *
 * Assumes mail arrived from outside, INSERTs a communications row directly, then
 * calls processInbound() to verify the Haiku (classify) + Opus (reply) pipeline runs
 * end to end. Bypasses the MailCarrier worker (IMAP).
 *
 * Flow:
 *   [1] look up the UPM-Kymmene party (uses seed data)
 *   [2] INSERT a new inbound communication
 *   [3] call processInbound() -> 2 Anthropic API calls (Haiku -> Opus)
 *   [4] dump the return value
 *   [5] verify the ai.drafts row
 *
 * Run:
 *   npx tsx src/scripts/simulate-inbound.ts
 *
 * Required environment variables (env.local.mjs):
 *   - NEXT_PUBLIC_SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY  (for bypassing RLS)
 *   - ANTHROPIC_API_KEY          (a real key - a dummy value will fail)
 *
 * Notes:
 *   - using service_role = bypass RLS (for verification)
 *   - message_id is unique per run -> re-runnable
 *   - on failure, marked as communications.ai_processing_status='failed'
 */

import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { env } from '../lib/env';
import { processInbound } from '../lib/email/processor';

const ORG_ID = 'b25de8f2-1020-482f-9012-183f63883169'; // MBG (seed hardcoded)
const TEST_PARTY_NAME = 'UPM-Kymmene';

async function main(): Promise<void> {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  AI Drafts simulation - receive mail -> verify draft generation');
  console.log('═══════════════════════════════════════════════════════\n');

  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  // ── [1] Party lookup ──
  console.log('[1/5] Looking up UPM-Kymmene party...');
  const { data: party, error: pErr } = await supabase
    .schema('app')
    .from('parties')
    .select('id, name, country_code')
    .eq('organization_id', ORG_ID)
    .eq('name', TEST_PARTY_NAME)
    .maybeSingle();

  if (pErr) throw new Error(`Party lookup failed: ${pErr.message}`);
  if (!party) {
    throw new Error(
      `'${TEST_PARTY_NAME}' party not found - did you apply supabase/seed/01-parties-paper-industry.sql?`,
    );
  }
  console.log(`      ✓ ${party.name} (${party.country_code})`);
  console.log(`        id: ${party.id}\n`);

  // ── [2] Communication INSERT ────────────────────────────────
  console.log('[2/5] Inserting test inbound communication...');
  const commId = randomUUID();
  const messageId = `<sim-${Date.now()}-${randomUUID().slice(0, 8)}@simulation.local>`;
  const subject = 'Inquiry: GCC-88H Sample Request — Specialty Paper Trial';
  const bodyPlain = [
    'Dear MBG Sales,',
    '',
    'We are evaluating new GCC suppliers for our Tervasaari specialty paper line',
    'and are interested in your GCC-88H grade based on recent industry reports.',
    '',
    'Could you please share:',
    '1. Latest technical datasheet (brightness, top-cut, oil absorption)',
    '2. Lead time for a 5kg sample to Tervasaari mill',
    '3. Indicative pricing for 5-10t monthly volume, Q3 2026 onwards',
    '',
    'If results match our spec, we plan to run a pilot trial in Q4.',
    '',
    'Best regards,',
    'Mika Lehtinen',
    'Senior Procurement Manager',
    'UPM Specialty Papers',
  ].join('\n');

  const { error: cErr } = await supabase
    .schema('app')
    .from('communications')
    .insert({
      id: commId,
      organization_id: ORG_ID,
      party_id: party.id,
      direction: 'inbound',
      channel: 'email',
      subject,
      body_plain: bodyPlain,
      from_address: 'mika.lehtinen@upm.com',
      message_id: messageId,
      ai_processing_status: 'pending',
      occurred_at: new Date().toISOString(),
    });

  if (cErr) {
    throw new Error(
      `Communication INSERT failed: ${cErr.message}\n` +
        '-> check communications table columns / NOT NULL constraints',
    );
  }
  console.log(`      ✓ communication id: ${commId}`);
  console.log(`        subject: ${subject}`);
  console.log(`        from: mika.lehtinen@upm.com\n`);

  // ── [3] call processInbound ──
  console.log('[3/5] Calling processInbound() -> Haiku classification + Opus reply drafting...');
  console.log('      (2 Anthropic API calls - about 5-20s)\n');

  const startMs = Date.now();
  let result: unknown;
  try {
    result = await processInbound(supabase, ORG_ID, commId);
  } catch (err) {
    console.error('      Error while running processInbound\n');
    throw err;
  }
  const elapsedMs = Date.now() - startMs;
  console.log(`      Done (${(elapsedMs / 1000).toFixed(1)}s)\n`);

  // ── [4] dump the return value ──
  console.log('[4/5] processInbound return value:');
  const dump = JSON.stringify(result, null, 2)
    .split('\n')
    .map((l) => `      ${l}`)
    .join('\n');
  console.log(dump);
  console.log('');

  // ── [5] verify the ai.drafts row ──
  console.log('[5/5] Verifying ai.drafts row...');
  const { data: draft, error: dErr } = await supabase
    .schema('ai')
    .from('drafts')
    .select(
      'id, classification_category, confidence_score, status, subject, ' +
        'language, requires_human_approval, auto_send_eligible, expires_at, risk_flags',
    )
    .eq('inbound_communication_id', commId)
    .maybeSingle();

  if (dErr) throw new Error(`Draft lookup failed: ${dErr.message}`);
  if (!draft) {
    throw new Error('Draft was not inserted - suspected error inside processor');
  }

  // ── type cast (works around Supabase JS .schema() + string select inference limits) ──
  const d = draft as unknown as {
    id: string;
    classification_category: string;
    confidence_score: number;
    status: string;
    subject: string;
    language: string;
    requires_human_approval: boolean;
    auto_send_eligible: boolean;
    expires_at: string;
    risk_flags: unknown;
  };

  console.log(`      ✓ draft.id: ${d.id}`);
  console.log(`        classification : ${d.classification_category} (confidence=${d.confidence_score})`);
  console.log(`        status         : ${d.status}`);
  console.log(`        language       : ${d.language}`);
  console.log(`        requires_human : ${d.requires_human_approval}`);
  console.log(`        auto_send_ok   : ${d.auto_send_eligible}`);
  console.log(`        risk_flags     : ${JSON.stringify(d.risk_flags)}`);
  console.log(`        expires_at     : ${d.expires_at}\n`);

  console.log('═══════════════════════════════════════════════════════');
  console.log('  Simulation succeeded');
  console.log('═══════════════════════════════════════════════════════');
  console.log('\nNext steps:');
  console.log('  1. Browser -> refresh http://localhost:3002/drafts');
  console.log('  2. Click the new draft -> check body/reply on the detail page');
  console.log('  3. Verify approve / reject / edit actions');
  console.log('  4. If it works -> tell me to proceed with Path B (real IMAP)\n');
}

main().catch((err) => {
  console.error('\nSimulation failed');
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error(err);
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error('\nPlease share the error message verbatim (mask any keys).');
  process.exit(1);
});

/**
 * src/scripts/simulate-inbound.ts
 *
 * AI Drafts 파이프라인 시뮬레이션 (Path A 검증)
 *
 * 외부에서 메일이 도착했다고 가정하고 communications 행을 직접 INSERT한 다음
 * processInbound()를 호출해 Haiku(분류) + Opus(회신) 파이프라인이 끝까지
 * 동작하는지 검증한다. MailCarrier 워커(IMAP)는 우회한다.
 *
 * 흐름:
 *   [1] UPM-Kymmene party 조회 (시드 데이터 사용)
 *   [2] 새 inbound communication INSERT
 *   [3] processInbound() 호출 → Anthropic API 2회 호출 (Haiku → Opus)
 *   [4] 반환값 dump
 *   [5] ai.drafts 행 검증
 *
 * 실행:
 *   npx tsx src/scripts/simulate-inbound.ts
 *
 * 필요한 환경변수 (env.local.mjs):
 *   - NEXT_PUBLIC_SUPABASE_URL
 *   - SUPABASE_SERVICE_ROLE_KEY  (RLS 우회용)
 *   - ANTHROPIC_API_KEY          (실제 키 — 더미값이면 실패)
 *
 * 비고:
 *   - service_role 사용 = RLS 우회 (검증 목적)
 *   - message_id는 매 실행마다 unique → 재실행 가능
 *   - 실패 시 communications.ai_processing_status='failed'로 마킹됨
 */

import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';
import { env } from '../lib/env';
import { processInbound } from '../lib/email/processor';

const ORG_ID = 'b25de8f2-1020-482f-9012-183f63883169'; // MBG (시드 하드코딩)
const TEST_PARTY_NAME = 'UPM-Kymmene';

async function main(): Promise<void> {
  console.log('═══════════════════════════════════════════════════════');
  console.log('  AI Drafts 시뮬레이션 — 메일 수신 → 초안 생성 검증');
  console.log('═══════════════════════════════════════════════════════\n');

  const supabase = createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  // ── [1] Party 조회 ──────────────────────────────────────────
  console.log('[1/5] UPM-Kymmene party 조회…');
  const { data: party, error: pErr } = await supabase
    .schema('app')
    .from('parties')
    .select('id, name, country_code, module')
    .eq('organization_id', ORG_ID)
    .eq('name', TEST_PARTY_NAME)
    .maybeSingle();

  if (pErr) throw new Error(`Party 조회 실패: ${pErr.message}`);
  if (!party) {
    throw new Error(
      `'${TEST_PARTY_NAME}' party 없음 — supabase/seed/01-parties-paper-industry.sql 적용했나요?`,
    );
  }
  console.log(`      ✓ ${party.name} (${party.country_code}, module=${party.module})`);
  console.log(`        id: ${party.id}\n`);

  // ── [2] Communication INSERT ────────────────────────────────
  console.log('[2/5] 테스트 inbound communication INSERT…');
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
      module: party.module ?? 'buyer',
      subject,
      body_plain: bodyPlain,
      from_address: 'mika.lehtinen@upm.com',
      message_id: messageId,
      ai_processing_status: 'pending',
      occurred_at: new Date().toISOString(),
    });

  if (cErr) {
    throw new Error(
      `Communication INSERT 실패: ${cErr.message}\n` +
        '→ communications 테이블 컬럼/NOT NULL 제약 확인 필요',
    );
  }
  console.log(`      ✓ communication id: ${commId}`);
  console.log(`        subject: ${subject}`);
  console.log(`        from: mika.lehtinen@upm.com\n`);

  // ── [3] processInbound 호출 ─────────────────────────────────
  console.log('[3/5] processInbound() 호출 → Haiku 분류 + Opus 회신 작성…');
  console.log('      (Anthropic API 2회 호출 — 약 5~20초 소요)\n');

  const startMs = Date.now();
  let result: unknown;
  try {
    result = await processInbound(supabase, ORG_ID, commId);
  } catch (err) {
    console.error('      ❌ processInbound 실행 중 에러 발생\n');
    throw err;
  }
  const elapsedMs = Date.now() - startMs;
  console.log(`      ✓ 처리 완료 (${(elapsedMs / 1000).toFixed(1)}s)\n`);

  // ── [4] 반환값 dump ────────────────────────────────────────
  console.log('[4/5] processInbound 반환값:');
  const dump = JSON.stringify(result, null, 2)
    .split('\n')
    .map((l) => `      ${l}`)
    .join('\n');
  console.log(dump);
  console.log('');

  // ── [5] ai.drafts 행 검증 ───────────────────────────────────
  console.log('[5/5] ai.drafts 행 검증…');
  const { data: draft, error: dErr } = await supabase
    .schema('ai')
    .from('drafts')
    .select(
      'id, classification_category, confidence_score, status, subject, ' +
        'language, requires_human_approval, auto_send_eligible, expires_at, risk_flags',
    )
    .eq('inbound_communication_id', commId)
    .maybeSingle();

  if (dErr) throw new Error(`Draft 조회 실패: ${dErr.message}`);
  if (!draft) {
    throw new Error('Draft INSERT 안 됨 — processor 내부 에러 의심');
  }

  // ── 타입 cast (Supabase JS의 .schema() + 문자열 select 추론 한계 우회) ──
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
  console.log('  ✅ 시뮬레이션 성공');
  console.log('═══════════════════════════════════════════════════════');
  console.log('\n다음 단계:');
  console.log('  1. 브라우저 → http://localhost:3002/drafts 새로고침');
  console.log('  2. 새 초안 클릭 → 상세 페이지에서 본문/회신 확인');
  console.log('  3. 승인 / 거부 / 편집 동작 확인');
  console.log('  4. 동작 OK → Path B (실제 IMAP) 진행 알려주세요\n');
}

main().catch((err) => {
  console.error('\n❌ 시뮬레이션 실패');
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error(err);
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error('\n에러 메시지 그대로 (키 부분 마스킹해서) 공유해주세요.');
  process.exit(1);
});

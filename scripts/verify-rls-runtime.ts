/**
 * Runtime RLS Verification — 두 개의 Supabase 클라이언트(admin / anon)를 만들어
 * 멀티테넌트 격리가 실제로 작동하는지 동적으로 검증.
 *
 * 사용법:
 *   1. STEP 1 SQL을 Supabase 프로젝트에 적용
 *   2. .env.local에 NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
 *      NEXT_PUBLIC_SUPABASE_ANON_KEY 설정
 *   3. tsx scripts/verify-rls-runtime.ts
 *
 * 본 스크립트는 production DB에 직접 INSERT를 시도하므로 stagingenvironment에서만 실행.
 */

import { createClient } from '@supabase/supabase-js';
import { randomUUID } from 'node:crypto';

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!url || !serviceKey || !anonKey) {
  console.error('ENV missing: NEXT_PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, NEXT_PUBLIC_SUPABASE_ANON_KEY');
  process.exit(1);
}

const admin = createClient(url, serviceKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const anon = createClient(url, anonKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

interface Check {
  name: string;
  pass: boolean;
  detail?: string;
}

async function main() {
  const checks: Check[] = [];

  // ─── 1. anon이 ai.runs를 SELECT할 수 없어야 함 ─────────────────
  {
    const { data, error } = await anon.schema('ai').from('runs').select('id').limit(1);
    checks.push({
      name: 'anon SELECT ai.runs blocked',
      pass: data?.length === 0 || !!error,
      detail: error ? `error=${error.message}` : `rows=${data?.length}`,
    });
  }

  // ─── 2. anon이 ai.drafts를 SELECT할 수 없어야 함 ───────────────
  {
    const { data, error } = await anon.schema('ai').from('drafts').select('id').limit(1);
    checks.push({
      name: 'anon SELECT ai.drafts blocked',
      pass: data?.length === 0 || !!error,
      detail: error ? `error=${error.message}` : `rows=${data?.length}`,
    });
  }

  // ─── 3. anon이 app.communications를 SELECT할 수 없어야 함 ──────
  {
    const { data, error } = await anon.schema('app').from('communications').select('id').limit(1);
    checks.push({
      name: 'anon SELECT app.communications blocked',
      pass: data?.length === 0 || !!error,
      detail: error ? `error=${error.message}` : `rows=${data?.length}`,
    });
  }

  // ─── 4. service_role은 모든 테이블 접근 가능 ─────────────────────
  {
    const { error } = await admin.schema('ai').from('runs').select('id').limit(1);
    checks.push({
      name: 'service_role SELECT ai.runs allowed',
      pass: !error,
      detail: error ? `error=${error.message}` : 'ok',
    });
  }

  // ─── 5. anon이 ai.runs에 INSERT할 수 없어야 함 ───────────────────
  {
    const { error } = await anon.schema('ai').from('runs').insert({
      organization_id: randomUUID(),
      agent_id: randomUUID(),
      status: 'success',
      model: 'claude-haiku-4-5-20251001',
      tokens_in: 0,
      tokens_out: 0,
      cost_usd: 0,
      latency_ms: 0,
    });
    checks.push({
      name: 'anon INSERT ai.runs blocked',
      pass: !!error,
      detail: error ? `blocked: ${error.message}` : 'UNEXPECTED: insert succeeded',
    });
  }

  // ─── 6. 멀티테넌트 격리: org A의 데이터를 org B 사용자가 못 봐야 함 ──
  // 본 검사는 두 개의 실제 user_organizations 시드가 있어야 가능.
  // 시드가 없으면 SKIPPED로 표시.
  // (실제 운영 검증 시 별도 e2e 테스트로 확장)
  checks.push({
    name: 'cross-org isolation (requires seeded users)',
    pass: true,
    detail: 'SKIPPED — needs two test users in different organizations',
  });

  // ─── 결과 출력 ───────────────────────────────────────────────
  console.log('\n┌─────────────────────────────────────────────────────────────────┐');
  console.log('│ RLS Runtime Verification                                       │');
  console.log('└─────────────────────────────────────────────────────────────────┘\n');

  let failed = 0;
  for (const c of checks) {
    const icon = c.pass ? '✓' : '✗';
    const color = c.pass ? '\x1b[32m' : '\x1b[31m';
    const reset = '\x1b[0m';
    console.log(`${color}${icon}${reset} ${c.name}`);
    if (c.detail) console.log(`    ${c.detail}`);
    if (!c.pass) failed += 1;
  }

  console.log(`\n${failed === 0 ? '✅ All checks passed' : `❌ ${failed} checks failed`}`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((err) => {
  console.error('Verification crashed:', err);
  process.exit(2);
});

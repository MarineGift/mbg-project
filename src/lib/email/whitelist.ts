/**
 * lib/email/whitelist.ts
 *
 * 발신자 이메일 주소가 조직의 화이트리스트에 등록되어 있는지 확인.
 *
 * 매칭 우선순위:
 *   1. address — 정확 일치
 *   2. domain — @ 뒤 도메인 일치
 *   3. regex — 정규식 매칭
 *
 * is_active = true 인 항목만 검사.
 *
 * 사용처:
 *   - mailcarrier.ts persistInbound() 진입 시
 *   - 허용 안 된 발신자는 communications INSERT 스킵
 */

import type { SupabaseClient } from '@supabase/supabase-js';

interface WhitelistRow {
  pattern: string;
  kind: 'domain' | 'address' | 'regex';
}

/**
 * 발신자 주소가 화이트리스트에 등록되어 있으면 true.
 * 화이트리스트가 비어있어도 false 반환 (명시적 허용 정책).
 */
export async function isFromAllowedSender(
  supabase: SupabaseClient,
  organizationId: string,
  fromAddress: string,
): Promise<boolean> {
  if (!fromAddress) return false;
  const normalized = fromAddress.trim().toLowerCase();
  const domain = normalized.includes('@')
    ? normalized.split('@').pop() ?? ''
    : '';

  const { data, error } = await supabase
    .schema('app')
    .from('email_whitelist')
    .select('pattern, kind')
    .eq('organization_id', organizationId)
    .eq('is_active', true);

  if (error) {
    // 화이트리스트 조회 실패 — 보수적으로 차단
    // eslint-disable-next-line no-console
    console.error('[whitelist] lookup failed:', error);
    return false;
  }

  const rows = (data ?? []) as WhitelistRow[];

  for (const row of rows) {
    const pattern = row.pattern.trim().toLowerCase();
    switch (row.kind) {
      case 'address':
        if (normalized === pattern) return true;
        break;
      case 'domain':
        if (domain === pattern || normalized.endsWith(`@${pattern}`)) return true;
        break;
      case 'regex':
        try {
          const re = new RegExp(row.pattern, 'i');
          if (re.test(fromAddress)) return true;
        } catch {
          // 잘못된 정규식 — 무시
        }
        break;
    }
  }

  return false;
}

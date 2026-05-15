// src/app/(app)/industry/paper-companies/page.tsx
// v5.7 신규: paper-mills 패턴 복제 + paper_companies 스키마 반영
// 핵심 차이:
//   - paper_companies는 자기 자신이 회사 → embed 불필요
//   - tier_role 직접 컬럼 → 필터 dropdown 추가
//   - evidence_level (A/B/C/D/E) 첫 활용 → EvidenceBadge

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { PaperCompaniesTable } from './PaperCompaniesTable'

const PAGE_SIZE = 50

export default async function PaperCompaniesPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; market?: string; tier?: string; page?: string }>
}) {
  const params = await searchParams
  const supabase = await createSupabaseServerClient()
  const page = Math.max(1, Number(params.page ?? 1))
  const from = (page - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1

  // 1) Paper Companies fetch (no embed — this IS the company)
  let companiesQuery = supabase
    .schema('industry' as never)
    .from('paper_companies')
    .select(`
      id,
      name,
      market_code,
      headquarters,
      tier_role,
      main_product_category,
      main_products,
      evidence_level,
      legacy_id
    `, { count: 'exact' })
    .order('id', { ascending: true })

  if (params.q) {
    // Simple OR — no nested table, no 2-stage pre-fetch needed
    companiesQuery = companiesQuery.or(
      `name.ilike.%${params.q}%,headquarters.ilike.%${params.q}%,main_products.ilike.%${params.q}%`
    )
  }

  if (params.market) {
    companiesQuery = companiesQuery.eq('market_code', params.market)
  }

  if (params.tier) {
    companiesQuery = companiesQuery.eq('tier_role', params.tier)
  }

  const { data: companies, count } = await companiesQuery.range(from, to)

  // 2) Markets (filter dropdown) — shared schema with paper-mills
  const { data: markets } = await supabase
    .schema('industry' as never)
    .from('markets')
    .select('code, name, region')
    .order('name')

  return (
    <PaperCompaniesTable
      companies={(companies ?? []) as any[]}
      total={count ?? 0}
      markets={(markets ?? []) as any[]}
      currentPage={page}
      pageSize={PAGE_SIZE}
    />
  )
}
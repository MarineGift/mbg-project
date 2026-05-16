// src/app/(app)/industry/paper-companies/page.tsx
// v5.8 패치: 
//   - notes 컬럼 검색에 포함 (family 통합 검색 가능)
//   - OBSOLETE / FAMILY ERROR / FAMILY — prefix 자동 제외 (default)
//   - showObsolete=1 query param으로 모두 보기 (검증용)

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { PaperCompaniesTable } from './PaperCompaniesTable'

const PAGE_SIZE = 50

export default async function PaperCompaniesPage({
  searchParams,
}: {
  searchParams: Promise<{ 
    q?: string; 
    market?: string; 
    tier?: string; 
    page?: string;
    showObsolete?: string;
  }>
}) {
  const params = await searchParams
  const supabase = await createSupabaseServerClient()
  const page = Math.max(1, Number(params.page ?? 1))
  const from = (page - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1
  const showObsolete = params.showObsolete === '1'

  // 1) Paper Companies fetch
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
    // ✅ notes 컬럼도 검색에 포함 — family 통합 키워드 (예: "Nine Dragons" 검색이 ND Paper도 매치)
    companiesQuery = companiesQuery.or(
      `name.ilike.%${params.q}%,headquarters.ilike.%${params.q}%,main_products.ilike.%${params.q}%,notes.ilike.%${params.q}%`
    )
  }

  if (params.market) {
    companiesQuery = companiesQuery.eq('market_code', params.market)
  }

  if (params.tier) {
    companiesQuery = companiesQuery.eq('tier_role', params.tier)
  }

  // ✅ OBSOLETE / FAMILY ERROR / FAMILY — prefix 자동 제외 (default)
  if (!showObsolete) {
    companiesQuery = companiesQuery
      .not('name', 'ilike', '[OBSOLETE]%')
      .not('name', 'ilike', '[OBSOLETE-SUPPLIER-AGG]%')
      .not('name', 'ilike', '[FAMILY ERROR%')
      .not('name', 'ilike', '[FAMILY — %')
  }

  const { data: companies, count } = await companiesQuery.range(from, to)

  // 2) Markets (filter dropdown)
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
      showObsolete={showObsolete}
    />
  )
}

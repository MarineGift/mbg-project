// src/app/(app)/industry/paper-mills/page.tsx
// v5.7 fix: 검색 OR에 paper_company.name 포함 (Sappi NA 누락 해결)
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { PaperMillsTable } from './PaperMillsTable'

const PAGE_SIZE = 50

export default async function PaperMillsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; market?: string; tier?: string; page?: string }>
}) {
  const params = await searchParams
  const supabase = await createSupabaseServerClient()
  const page = Math.max(1, Number(params.page ?? 1))
  const from = (page - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1

  // 1) Paper Mills fetch (with paper_companies embed via FK)
  let millsQuery = supabase
    .schema('industry' as never)
    .from('paper_mills')
    .select(`
      id,
      mill_name,
      market_code,
      city,
      main_products,
      legacy_id,
      paper_company:paper_company_id (
        id,
        name,
        tier_role
      )
    `, { count: 'exact' })
    .order('id', { ascending: true })

  if (params.q) {
    // Pre-fetch paper_company IDs matching the search term
    const { data: matchingCompanies } = await supabase
      .schema('industry' as never)
      .from('paper_companies')
      .select('id')
      .ilike('name', `%${params.q}%`)

    const companyIds = (matchingCompanies ?? []).map((c: { id: number }) => c.id)

    // Build OR conditions, optionally appending paper_company_id match
    const orParts = [
      `mill_name.ilike.%${params.q}%`,
      `city.ilike.%${params.q}%`,
      `main_products.ilike.%${params.q}%`,
    ]
    if (companyIds.length > 0) {
      orParts.push(`paper_company_id.in.(${companyIds.join(',')})`)
    }

    millsQuery = millsQuery.or(orParts.join(','))
  }

  if (params.market) {
    millsQuery = millsQuery.eq('market_code', params.market)
  }

  const { data: mills, count } = await millsQuery.range(from, to)

  // 2) Markets (filter dropdown)
  const { data: markets } = await supabase
    .schema('industry' as never)
    .from('markets')
    .select('code, name, region')
    .order('name')

  return (
    <PaperMillsTable
      mills={(mills ?? []) as any[]}
      total={count ?? 0}
      markets={(markets ?? []) as any[]}
      currentPage={page}
      pageSize={PAGE_SIZE}
    />
  )
}
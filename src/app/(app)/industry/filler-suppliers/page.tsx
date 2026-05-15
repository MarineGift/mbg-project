// src/app/(app)/industry/filler-suppliers/page.tsx
// v5.7 Step 3: paper-companies 패턴 복제 + filler_suppliers 스키마 적응
// 주의: tier_role는 현재 전체 NULL (filler 측 데이터 정리 Step B 미진행)

import { createSupabaseServerClient } from '@/lib/supabase/server'
import { FillerSuppliersTable } from './FillerSuppliersTable'

const PAGE_SIZE = 50

export default async function FillerSuppliersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; market?: string; tier?: string; page?: string }>
}) {
  const params = await searchParams
  const supabase = await createSupabaseServerClient()
  const page = Math.max(1, Number(params.page ?? 1))
  const from = (page - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1

  // 1) Filler Suppliers fetch
  let suppliersQuery = supabase
    .schema('industry' as never)
    .from('filler_suppliers')
    .select(`
      id,
      name,
      market_code,
      tier_role,
      supplier_type,
      market_role,
      relevant_filler_types,
      supply_model,
      evidence_level,
      legacy_id
    `, { count: 'exact' })
    .order('id', { ascending: true })

  if (params.q) {
    // Note: relevant_filler_types (ARRAY) is not in search.
    // Filler-type search → v5.8 (#37) via ARRAY contains pre-fetch.
    suppliersQuery = suppliersQuery.or(
      `name.ilike.%${params.q}%,supplier_type.ilike.%${params.q}%,market_role.ilike.%${params.q}%`
    )
  }

  if (params.market) {
    suppliersQuery = suppliersQuery.eq('market_code', params.market)
  }

  if (params.tier) {
    suppliersQuery = suppliersQuery.eq('tier_role', params.tier)
  }

  const { data: suppliers, count } = await suppliersQuery.range(from, to)

  // 2) Markets (filter dropdown) — shared
  const { data: markets } = await supabase
    .schema('industry' as never)
    .from('markets')
    .select('code, name, region')
    .order('name')

  return (
    <FillerSuppliersTable
      suppliers={(suppliers ?? []) as any[]}
      total={count ?? 0}
      markets={(markets ?? []) as any[]}
      currentPage={page}
      pageSize={PAGE_SIZE}
    />
  )
}
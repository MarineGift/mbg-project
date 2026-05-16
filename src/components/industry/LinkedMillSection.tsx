// src/components/industry/LinkedMillSection.tsx
// Phase 7-b-3: CRM party detail → industry mill 데이터 양방향 연결
// Server Component

import Link from 'next/link'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { createSupabaseServerClient } from '@/lib/supabase/server'

interface Props {
  industryPaperMillId: number
}

export async function LinkedMillSection({ industryPaperMillId }: Props) {
  const supabase = await createSupabaseServerClient()

  const { data: millRaw } = await supabase
    .schema('industry' as never)
    .from('paper_mills')
    .select(
      `id, mill_name, market_code, city, region, paper_company_id,
       main_product_category, main_products,
       filler_probability, likely_filler_types, likely_supplier_note`,
    )
    .eq('id', industryPaperMillId)
    .single()

  if (!millRaw) return null
  const mill = millRaw as {
    id: number
    mill_name: string
    market_code: string | null
    city: string | null
    region: string | null
    paper_company_id: number | null
    main_product_category: string | null
    main_products: string | null
    filler_probability: string | null
    likely_filler_types: string[] | null
    likely_supplier_note: string | null
  }

  // 확인된 supplier 수
  const { count: supplierCount } = await supabase
    .schema('industry' as never)
    .from('supplier_mill_linkages')
    .select('id', { count: 'exact', head: true })
    .eq('paper_mill_id', industryPaperMillId)

  const likelyTypes = mill.likely_filler_types ?? []

  return (
    <section className="space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-muted-foreground">
          Industry Data
        </h3>
        <Link
          href={`/industry/paper-mills/${industryPaperMillId}`}
          className="text-xs text-blue-600 hover:underline dark:text-blue-400"
        >
          Industry 상세 →
        </Link>
      </div>

      <Card>
        <CardContent className="p-4 space-y-3 text-sm">

          {/* 위치 / 카테고리 배지 */}
          <div className="flex flex-wrap gap-1.5">
            {mill.market_code && (
              <Badge variant="outline" className="text-xs">{mill.market_code}</Badge>
            )}
            {mill.city && (
              <Badge variant="outline" className="text-xs">{mill.city}</Badge>
            )}
            {mill.region && mill.region !== mill.city && (
              <Badge variant="outline" className="text-xs">{mill.region}</Badge>
            )}
            {mill.main_product_category && (
              <Badge variant="secondary" className="text-xs">
                {mill.main_product_category}
              </Badge>
            )}
          </div>

          {/* 주요 제품 */}
          {mill.main_products && (
            <p className="text-xs text-muted-foreground whitespace-pre-wrap">
              {mill.main_products}
            </p>
          )}

          {/* 통계 바 */}
          <div className="flex gap-6 border-t pt-2 text-xs text-muted-foreground">
            <span>
              <span className="font-semibold text-foreground">{supplierCount ?? 0}</span>
              {' '}confirmed suppliers
            </span>
            {mill.filler_probability && (
              <span>
                Probability:{' '}
                <span className="font-semibold text-foreground">
                  {mill.filler_probability}
                </span>
              </span>
            )}
          </div>

          {/* Likely filler types */}
          {likelyTypes.length > 0 && (
            <div className="flex flex-wrap gap-1">
              {likelyTypes.map((t) => (
                <Badge
                  key={t}
                  variant="outline"
                  className="text-[10px] border-dashed"
                >
                  likely: {t}
                </Badge>
              ))}
            </div>
          )}

          {/* 공급 인텔 노트 */}
          {mill.likely_supplier_note && (
            <p className="text-xs text-muted-foreground">
              💡 {mill.likely_supplier_note}
            </p>
          )}
        </CardContent>
      </Card>
    </section>
  )
}

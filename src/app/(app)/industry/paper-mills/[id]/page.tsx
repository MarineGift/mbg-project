// src/app/(app)/industry/paper-mills/[id]/page.tsx
// v5.8 Step B2 EN: Paper Mill Detail (English)

import { notFound } from 'next/navigation'
import Link from 'next/link'
import { ChevronLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { getCountryFillerSuppliers } from '@/lib/queries/industry-link-extensions'
import { MillSuppliersMatrix } from './MillSuppliersMatrix'
import { CountrySuppliersList } from './CountrySuppliersList'

export default async function PaperMillDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id: idStr } = await params
  const id = Number(idStr)
  if (!Number.isFinite(id) || id <= 0) notFound()

  const supabase = await createSupabaseServerClient()

  const { data: millRaw, error: millErr } = await supabase
    .schema('industry' as never)
    .from('paper_mills')
    .select(
      `id, mill_name, market_code, city, region, paper_company_id,
       main_product_category, main_products,
       filler_probability, likely_filler_types, likely_supply_structure, likely_supplier_note`,
    )
    .eq('id', id)
    .single()

  if (millErr || !millRaw) notFound()
  const mill = millRaw as any

  let parentCompany: { id: number; name: string; tier_role: string | null } | null = null
  if (mill.paper_company_id) {
    const { data: companyRaw } = await supabase
      .schema('industry' as never)
      .from('paper_companies')
      .select('id, name, tier_role')
      .eq('id', mill.paper_company_id)
      .single()
    parentCompany = companyRaw as any
  }

  const { data: linkagesRaw } = await supabase
    .schema('industry' as never)
    .from('supplier_mill_linkages')
    .select(
      `id, filler_supplier_id, filler_type, supply_structure,
       relationship_type, confidence_grade, assessment_scope, confirmation_status`,
    )
    .eq('paper_mill_id', id)

  const linkages = (linkagesRaw ?? []) as any[]

  const supplierIds = Array.from(
    new Set(linkages.map((l) => l.filler_supplier_id).filter((v): v is number => v != null)),
  )
  const supplierMap = new Map<number, string>()
  if (supplierIds.length > 0) {
    const { data: supplierRaw } = await supabase
      .schema('industry' as never)
      .from('filler_suppliers')
      .select('id, name')
      .in('id', supplierIds)

    for (const s of (supplierRaw ?? []) as Array<{ id: number; name: string }>) {
      supplierMap.set(s.id, s.name)
    }
  }

  const supplierLinks = linkages.map((l) => ({
    id: l.id,
    fillerSupplierId: l.filler_supplier_id,
    supplierName: l.filler_supplier_id
      ? supplierMap.get(l.filler_supplier_id) ?? '(unknown)'
      : '(no FK)',
    fillerType: l.filler_type,
    supplyStructure: l.supply_structure,
    relationshipType: l.relationship_type,
    confidenceGrade: l.confidence_grade,
    assessmentScope: l.assessment_scope,
    confirmationStatus: l.confirmation_status,
  }))

  const countrySuppliers = mill.market_code
    ? await getCountryFillerSuppliers(mill.market_code, id)
    : []

  const likelyTypes = (mill.likely_filler_types as string[]) ?? []

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/industry/paper-mills">
            <ChevronLeft className="h-4 w-4 mr-1" />
            Back to mills
          </Link>
        </Button>
      </div>

      <div className="space-y-2">
        <div className="flex items-start justify-between gap-4">
          <div className="space-y-1">
            <h2 className="text-2xl font-bold">{mill.mill_name}</h2>
            <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
              <code className="text-xs">ID {mill.id}</code>
              {mill.market_code && (<><span>·</span><code className="text-xs">{mill.market_code}</code></>)}
              {mill.city && (
                <>
                  <span>·</span>
                  <span>
                    {mill.city}
                    {mill.region && mill.region !== mill.city && ` · ${mill.region}`}
                  </span>
                </>
              )}
              {parentCompany && (
                <>
                  <span>·</span>
                  <Link href={`/industry/paper-companies/${parentCompany.id}`} className="hover:underline">
                    {parentCompany.name}
                    {parentCompany.tier_role && (
                      <Badge variant="outline" className="ml-1 text-[10px]">{parentCompany.tier_role}</Badge>
                    )}
                  </Link>
                </>
              )}
            </div>
          </div>
        </div>

        {(mill.main_product_category || mill.main_products) && (
          <div className="rounded-md border bg-muted/30 p-3 text-sm space-y-1">
            {mill.main_product_category && (
              <div>
                <span className="text-muted-foreground">Category: </span>
                <span className="font-medium">{mill.main_product_category}</span>
              </div>
            )}
            {mill.main_products && (
              <div className="text-muted-foreground whitespace-pre-wrap">{mill.main_products}</div>
            )}
          </div>
        )}

        {(likelyTypes.length > 0 || mill.filler_probability || mill.likely_supplier_note) && (
          <Card>
            <CardContent className="p-3 text-sm space-y-2">
              <div className="text-xs uppercase text-muted-foreground tracking-wide">
                Likely Supplier Intel (fallback)
              </div>
              {likelyTypes.length > 0 && (
                <div className="flex flex-wrap gap-1">
                  {likelyTypes.map((t) => (
                    <Badge key={t} variant="outline" className="border-dashed text-xs">
                      likely: {t}
                    </Badge>
                  ))}
                </div>
              )}
              {mill.likely_supply_structure && (
                <div>
                  <span className="text-muted-foreground">Supply: </span>
                  <span>{mill.likely_supply_structure}</span>
                </div>
              )}
              {mill.filler_probability && (
                <div className="text-muted-foreground italic">{mill.filler_probability}</div>
              )}
              {mill.likely_supplier_note && (
                <div className="text-muted-foreground">💡 {mill.likely_supplier_note}</div>
              )}
            </CardContent>
          </Card>
        )}
      </div>

      <section className="space-y-3">
        <div className="flex items-baseline justify-between">
          <h3 className="text-lg font-semibold">
            Confirmed Suppliers ({supplierLinks.length})
          </h3>
        </div>
        <MillSuppliersMatrix links={supplierLinks} />
      </section>

      {mill.market_code && (
        <section className="space-y-3">
          <div className="flex items-baseline justify-between">
            <h3 className="text-lg font-semibold">
              Same-country Filler Suppliers ({countrySuppliers.length})
              <span className="ml-2 text-sm font-normal text-muted-foreground">
                · {mill.market_code}
              </span>
            </h3>
            <Badge variant="outline" className="text-xs">⭐ Sales candidates</Badge>
          </div>
          <p className="text-sm text-muted-foreground">
            Filler suppliers in the same country as this mill. Existing trading partners marked "Active". Matching filler types highlighted.
          </p>
          <CountrySuppliersList suppliers={countrySuppliers} likelyTypes={likelyTypes} />
        </section>
      )}
    </div>
  )
}

// src/app/(app)/industry/paper-companies/[id]/page.tsx
// v5.8 Step B1 EN: Paper Company Detail Page (English UI)

import { notFound } from 'next/navigation'
import Link from 'next/link'
import { ChevronLeft, ExternalLink } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { TierRoleBadge } from '@/components/industry/TierRoleBadge'
import { EvidenceBadge } from '@/components/industry/EvidenceBadge'
import { getPaperCompanyIntel } from '@/lib/queries/industry-link'
import { getCountryFillerSuppliers } from '@/lib/queries/industry-link-extensions'
import { createSupabaseServerClient } from '@/lib/supabase/server'
import { CompanyMillsTable } from './CompanyMillsTable'
import { CompanySupplierSummary } from './CompanySupplierSummary'
import { CompanyStatsCards } from './CompanyStatsCards'
import { CountrySuppliersList } from './CountrySuppliersList'

export default async function PaperCompanyDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id: idStr } = await params
  const id = Number(idStr)
  if (!Number.isFinite(id) || id <= 0) notFound()

  const intel = await getPaperCompanyIntel(id)
  if (!intel) notFound()

  const supabase = await createSupabaseServerClient()
  const { data: rawCompany } = await supabase
    .schema('industry' as never)
    .from('paper_companies')
    .select('tier_role, source_url')
    .eq('id', id)
    .single()

  const tierRole = (rawCompany as any)?.tier_role ?? null
  const sourceUrl = (rawCompany as any)?.source_url ?? intel.company.sourceUrl

  // Country filler suppliers cross-link
  const countrySuppliers = intel.company.marketCode
    ? await getCountryFillerSuppliers(intel.company.marketCode)
    : []

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/industry/paper-companies">
            <ChevronLeft className="h-4 w-4 mr-1" />
            Back to companies
          </Link>
        </Button>
      </div>

      {/* Header */}
      <div className="space-y-2">
        <div className="flex items-start justify-between gap-4">
          <div className="space-y-1">
            <h2 className="text-2xl font-bold">{intel.company.name}</h2>
            <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
              <code className="text-xs">ID {intel.company.id}</code>
              {intel.company.marketCode && (
                <>
                  <span>·</span>
                  <code className="text-xs">{intel.company.marketCode}</code>
                </>
              )}
              {intel.company.headquarters && (
                <>
                  <span>·</span>
                  <span>{intel.company.headquarters}</span>
                </>
              )}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <TierRoleBadge tier={tierRole} />
            <EvidenceBadge level={intel.company.evidenceLevel} />
            {sourceUrl && (
              <Button variant="outline" size="sm" asChild>
                <a href={sourceUrl} target="_blank" rel="noopener noreferrer">
                  <ExternalLink className="h-3 w-3 mr-1" />
                  Source
                </a>
              </Button>
            )}
          </div>
        </div>

        {(intel.company.mainProductCategory || intel.company.mainProducts) && (
          <div className="rounded-md border bg-muted/30 p-3 text-sm space-y-1">
            {intel.company.mainProductCategory && (
              <div>
                <span className="text-muted-foreground">Category: </span>
                <span className="font-medium">{intel.company.mainProductCategory}</span>
              </div>
            )}
            {intel.company.mainProducts && (
              <div className="text-muted-foreground">
                {intel.company.mainProducts}
              </div>
            )}
          </div>
        )}

        {intel.company.notes && (
          <details className="rounded-md border bg-muted/20 p-3 text-sm">
            <summary className="cursor-pointer font-medium text-muted-foreground">
              Notes
            </summary>
            <div className="mt-2 whitespace-pre-wrap text-sm">
              {intel.company.notes}
            </div>
          </details>
        )}
      </div>

      <CompanyStatsCards stats={intel.stats} />

      {/* Mills */}
      <section className="space-y-3">
        <div className="flex items-baseline justify-between">
          <h3 className="text-lg font-semibold">
            Mills ({intel.mills.length})
          </h3>
          {intel.stats.millsWithLikelyOnly > 0 && (
            <Badge variant="outline" className="text-xs">
              {intel.stats.millsWithLikelyOnly} likely-only · sales priority
            </Badge>
          )}
        </div>
        <CompanyMillsTable mills={intel.mills} />
      </section>

      {/* Supplier summary */}
      {intel.supplierSummary.length > 0 && (
        <section className="space-y-3">
          <h3 className="text-lg font-semibold">
            Supplier Summary ({intel.supplierSummary.length})
          </h3>
          <p className="text-sm text-muted-foreground">
            Top filler suppliers by mill count for this company.
          </p>
          <CompanySupplierSummary suppliers={intel.supplierSummary} />
        </section>
      )}

      {/* Same-country Filler Suppliers (cross-link) */}
      {intel.company.marketCode && (
        <section className="space-y-3">
          <div className="flex items-baseline justify-between">
            <h3 className="text-lg font-semibold">
              Same-country Filler Suppliers ({countrySuppliers.length})
              <span className="ml-2 text-sm font-normal text-muted-foreground">
                · {intel.company.marketCode}
              </span>
            </h3>
            <Badge variant="outline" className="text-xs">⭐ Sales candidates</Badge>
          </div>
          <p className="text-sm text-muted-foreground">
            Filler suppliers in the same country. Existing trading partners marked "Active".
          </p>
          <CountrySuppliersList suppliers={countrySuppliers} likelyTypes={[]} />
        </section>
      )}
    </div>
  )
}

// src/app/(app)/industry/filler-suppliers/[id]/page.tsx
// v5.8 Step B3 EN: Filler Supplier Detail (English)

import { notFound } from 'next/navigation'
import Link from 'next/link'
import { ChevronLeft, ExternalLink } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { EvidenceBadge } from '@/components/industry/EvidenceBadge'
import { getFillerSupplierIntel } from '@/lib/queries/industry-link'
import { getCountryPaperMills } from '@/lib/queries/industry-link-extensions'
import { SupplierLinkagesTable } from './SupplierLinkagesTable'
import { SupplierStatsCards } from './SupplierStatsCards'
import { CountryPaperMillsList } from './CountryPaperMillsList'

export default async function FillerSupplierDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id: idStr } = await params
  const id = Number(idStr)
  if (!Number.isFinite(id) || id <= 0) notFound()

  const intel = await getFillerSupplierIntel(id)
  if (!intel) notFound()

  const countryMills = intel.supplier.marketCode
    ? await getCountryPaperMills(intel.supplier.marketCode, id)
    : []

  const supplierTypeSet = new Set(
    intel.supplier.relevantFillerTypes.map((t) => t.toLowerCase()),
  )

  const sortedMills = [...countryMills].sort((a, b) => {
    if (a.hasExistingLinkage && !b.hasExistingLinkage) return -1
    if (!a.hasExistingLinkage && b.hasExistingLinkage) return 1
    const aMatch = a.likelyFillerTypes.some((t) => supplierTypeSet.has(t.toLowerCase()))
    const bMatch = b.likelyFillerTypes.some((t) => supplierTypeSet.has(t.toLowerCase()))
    if (aMatch && !bMatch) return -1
    if (!aMatch && bMatch) return 1
    return a.id - b.id
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/industry/filler-suppliers">
            <ChevronLeft className="h-4 w-4 mr-1" />
            Back to suppliers
          </Link>
        </Button>
      </div>

      <div className="space-y-2">
        <div className="flex items-start justify-between gap-4">
          <div className="space-y-1">
            <h2 className="text-2xl font-bold">{intel.supplier.name}</h2>
            <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
              <code className="text-xs">ID {intel.supplier.id}</code>
              {intel.supplier.marketCode && (<><span>·</span><code className="text-xs">{intel.supplier.marketCode}</code></>)}
              {intel.supplier.supplierType && (<><span>·</span><span>{intel.supplier.supplierType}</span></>)}
              {intel.supplier.marketRole && (<><span>·</span><span>{intel.supplier.marketRole}</span></>)}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <EvidenceBadge level={intel.supplier.evidenceLevel} />
            {intel.supplier.sourceUrl && (
              <Button variant="outline" size="sm" asChild>
                <a href={intel.supplier.sourceUrl} target="_blank" rel="noopener noreferrer">
                  <ExternalLink className="h-3 w-3 mr-1" />
                  Source
                </a>
              </Button>
            )}
          </div>
        </div>

        {intel.supplier.relevantFillerTypes.length > 0 && (
          <div className="rounded-md border bg-muted/30 p-3">
            <div className="text-xs uppercase text-muted-foreground tracking-wide mb-2">
              Filler Types
            </div>
            <div className="flex flex-wrap gap-1.5">
              {intel.supplier.relevantFillerTypes.map((t) => (
                <Badge key={t} variant="secondary" className="text-xs">{t}</Badge>
              ))}
            </div>
            {intel.supplier.supplyModel && (
              <div className="mt-2 text-sm">
                <span className="text-muted-foreground">Supply Model: </span>
                <span className="font-medium">{intel.supplier.supplyModel}</span>
              </div>
            )}
          </div>
        )}

        {intel.supplier.notes && (
          <details className="rounded-md border bg-muted/20 p-3 text-sm">
            <summary className="cursor-pointer font-medium text-muted-foreground">Notes</summary>
            <div className="mt-2 whitespace-pre-wrap text-sm">{intel.supplier.notes}</div>
          </details>
        )}

        {(intel.supplier.europePaperEvidence || intel.supplier.onsitePccEvidence) && (
          <div className="rounded-md border bg-blue-50/50 dark:bg-blue-950/20 p-3 text-sm space-y-1">
            {intel.supplier.europePaperEvidence && (
              <div>
                <span className="text-muted-foreground">EU Paper Evidence: </span>
                {intel.supplier.europePaperEvidence}
              </div>
            )}
            {intel.supplier.onsitePccEvidence && (
              <div>
                <span className="text-muted-foreground">Onsite PCC: </span>
                {intel.supplier.onsitePccEvidence}
              </div>
            )}
          </div>
        )}
      </div>

      <SupplierStatsCards stats={intel.stats} />

      {intel.millSpecificLinks.length > 0 && (
        <section className="space-y-3">
          <div className="flex items-baseline justify-between">
            <h3 className="text-lg font-semibold">
              Mill-Specific Linkages ({intel.millSpecificLinks.length})
            </h3>
            <Badge variant="default" className="text-xs">Plant-level confirmed</Badge>
          </div>
          <SupplierLinkagesTable links={intel.millSpecificLinks} />
        </section>
      )}

      {intel.footprintLinks.length > 0 && (
        <section className="space-y-3">
          <div className="flex items-baseline justify-between">
            <h3 className="text-lg font-semibold">
              Footprint Linkages ({intel.footprintLinks.length})
            </h3>
            <Badge variant="outline" className="text-xs">Region-level only</Badge>
          </div>
          <SupplierLinkagesTable links={intel.footprintLinks} />
        </section>
      )}

      {intel.supplier.marketCode && (
        <section className="space-y-3">
          <div className="flex items-baseline justify-between">
            <h3 className="text-lg font-semibold">
              Same-country Paper Mills ({sortedMills.length})
              <span className="ml-2 text-sm font-normal text-muted-foreground">
                · {intel.supplier.marketCode}
              </span>
            </h3>
            <Badge variant="outline" className="text-xs">⭐ Sales candidates</Badge>
          </div>
          <p className="text-sm text-muted-foreground">
            Paper mills in the same country. Existing customers marked "Active". Sorted by filler-type match.
          </p>
          <CountryPaperMillsList
            mills={sortedMills}
            supplierRelevantTypes={intel.supplier.relevantFillerTypes}
          />
        </section>
      )}
    </div>
  )
}

// src/app/(app)/industry/paper-companies/[id]/CompanyMillsTable.tsx
// v5.8 Step B1 EN: Mills list (English)
'use client'

import Link from 'next/link'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import type { IndustryMillRow } from '@/types/industry-link'

export function CompanyMillsTable({ mills }: { mills: IndustryMillRow[] }) {
  if (mills.length === 0) {
    return (
      <div className="rounded-md border p-8 text-center text-sm text-muted-foreground">
        No mills registered for this company.
      </div>
    )
  }

  return (
    <div className="rounded-md border overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-16">ID</TableHead>
            <TableHead>Mill</TableHead>
            <TableHead className="w-32">Market</TableHead>
            <TableHead>Products</TableHead>
            <TableHead>Suppliers / Likely</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {mills.map((mill) => {
            const hasConfirmedSuppliers = mill.suppliers.length > 0
            return (
              <TableRow key={mill.id}>
                <TableCell className="text-muted-foreground font-mono text-xs">
                  {mill.id}
                </TableCell>
                <TableCell>
                  <Link
                    href={`/industry/paper-mills/${mill.id}`}
                    className="font-medium hover:underline"
                  >
                    {mill.millName}
                  </Link>
                  {mill.city && (
                    <div className="text-xs text-muted-foreground mt-0.5">
                      {mill.city}
                      {mill.region && mill.region !== mill.city && ` · ${mill.region}`}
                    </div>
                  )}
                </TableCell>
                <TableCell>
                  <code className="text-xs text-muted-foreground">{mill.marketCode ?? '—'}</code>
                </TableCell>
                <TableCell className="max-w-[280px]">
                  {mill.mainProductCategory && (
                    <div className="text-sm font-medium truncate">{mill.mainProductCategory}</div>
                  )}
                  {mill.mainProducts && (
                    <div className="text-xs text-muted-foreground truncate">{mill.mainProducts}</div>
                  )}
                  {!mill.mainProductCategory && !mill.mainProducts && (
                    <span className="text-muted-foreground text-sm">—</span>
                  )}
                </TableCell>
                <TableCell className="max-w-[320px]">
                  {hasConfirmedSuppliers ? (
                    <div className="space-y-1">
                      {mill.suppliers.map((s, idx) => (
                        <div key={`${s.fillerSupplierId ?? 'raw'}-${idx}`} className="flex items-center gap-1.5 text-xs">
                          {s.fillerSupplierId ? (
                            <Link href={`/industry/filler-suppliers/${s.fillerSupplierId}`} className="font-medium hover:underline">
                              {s.supplierName}
                            </Link>
                          ) : (
                            <span className="font-medium">{s.supplierName}</span>
                          )}
                          {s.fillerType && (
                            <Badge variant="secondary" className="text-[10px] px-1 py-0">{s.fillerType}</Badge>
                          )}
                          {s.confidenceGrade && (
                            <Badge variant={s.confidenceGrade === 'A' ? 'default' : 'outline'} className="text-[10px] px-1 py-0">
                              {s.confidenceGrade}
                            </Badge>
                          )}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="space-y-1.5">
                      {mill.likelyFillerTypes.length > 0 ? (
                        <div className="flex flex-wrap gap-1">
                          {mill.likelyFillerTypes.map((t) => (
                            <Badge key={t} variant="outline" className="text-[10px] border-dashed">
                              likely: {t}
                            </Badge>
                          ))}
                        </div>
                      ) : (
                        <span className="text-muted-foreground text-xs">No mapping</span>
                      )}
                      {mill.fillerProbability && (
                        <div className="text-[11px] text-muted-foreground italic">{mill.fillerProbability}</div>
                      )}
                      {mill.likelySupplierNote && (
                        <div className="text-[11px] text-muted-foreground truncate">💡 {mill.likelySupplierNote}</div>
                      )}
                    </div>
                  )}
                </TableCell>
              </TableRow>
            )
          })}
        </TableBody>
      </Table>
    </div>
  )
}

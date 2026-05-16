// src/app/(app)/industry/paper-companies/[id]/CountrySuppliersList.tsx
// v5.8 Step B1 EN: Same-country filler suppliers
'use client'

import Link from 'next/link'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { EvidenceBadge } from '@/components/industry/EvidenceBadge'
import type { CountryFillerSupplierRow } from '@/lib/queries/industry-link-extensions'

export function CountrySuppliersList({
  suppliers,
  likelyTypes,
}: {
  suppliers: CountryFillerSupplierRow[]
  likelyTypes: string[]
}) {
  if (suppliers.length === 0) {
    return (
      <div className="rounded-md border p-6 text-center text-sm text-muted-foreground">
        No filler suppliers registered in this country.
      </div>
    )
  }

  const likelyTypeSet = new Set(likelyTypes.map((t) => t.toLowerCase()))

  return (
    <div className="rounded-md border overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-16">ID</TableHead>
            <TableHead>Supplier</TableHead>
            <TableHead className="w-24">Evidence</TableHead>
            <TableHead>Type / Role</TableHead>
            <TableHead>Filler Types</TableHead>
            <TableHead className="w-32">Status</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {suppliers.map((s) => {
            const matchedTypes = s.relevantFillerTypes.filter((t) =>
              likelyTypeSet.has(t.toLowerCase()),
            )
            const hasMatch = matchedTypes.length > 0

            return (
              <TableRow
                key={s.id}
                className={s.hasExistingLinkage ? 'bg-muted/20' : hasMatch ? 'bg-primary/5' : ''}
              >
                <TableCell className="text-muted-foreground font-mono text-xs">{s.id}</TableCell>
                <TableCell className="font-medium">
                  <Link href={`/industry/filler-suppliers/${s.id}`} className="hover:underline">
                    {s.name}
                  </Link>
                </TableCell>
                <TableCell><EvidenceBadge level={s.evidenceLevel} /></TableCell>
                <TableCell className="text-sm">
                  {s.supplierType && <div className="font-medium">{s.supplierType}</div>}
                  {s.marketRole && <div className="text-xs text-muted-foreground">{s.marketRole}</div>}
                  {!s.supplierType && !s.marketRole && <span className="text-muted-foreground text-xs">—</span>}
                </TableCell>
                <TableCell className="max-w-[280px]">
                  {s.relevantFillerTypes.length > 0 ? (
                    <div className="flex flex-wrap gap-1">
                      {s.relevantFillerTypes.slice(0, 4).map((t) => {
                        const isMatch = likelyTypeSet.has(t.toLowerCase())
                        return (
                          <Badge key={t} variant={isMatch ? 'default' : 'secondary'} className="text-[10px]">
                            {isMatch && '★ '}{t}
                          </Badge>
                        )
                      })}
                      {s.relevantFillerTypes.length > 4 && (
                        <span className="text-xs text-muted-foreground self-center">
                          +{s.relevantFillerTypes.length - 4}
                        </span>
                      )}
                    </div>
                  ) : (
                    <span className="text-muted-foreground text-xs">—</span>
                  )}
                </TableCell>
                <TableCell>
                  {s.hasExistingLinkage ? (
                    <Badge variant="default" className="text-[10px]">Active</Badge>
                  ) : hasMatch ? (
                    <Badge variant="outline" className="text-[10px] border-primary text-primary">
                      ⭐ Match {matchedTypes.length}
                    </Badge>
                  ) : (
                    <span className="text-muted-foreground text-xs">New</span>
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

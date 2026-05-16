// src/app/(app)/industry/filler-suppliers/[id]/SupplierLinkagesTable.tsx
// v5.8 Step B3: Mill-Specific 또는 Footprint linkages 표시
'use client'

import Link from 'next/link'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import type { FillerLinkageRow } from '@/types/industry-link'

export function SupplierLinkagesTable({ links }: { links: FillerLinkageRow[] }) {
  return (
    <div className="rounded-md border overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Paper Company / Mill</TableHead>
            <TableHead className="w-32">Market</TableHead>
            <TableHead className="w-32">Filler Type</TableHead>
            <TableHead className="w-32">Supply</TableHead>
            <TableHead className="w-24">Confidence</TableHead>
            <TableHead className="w-32">Status</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {links.map((l) => (
            <TableRow key={l.id}>
              <TableCell>
                <div className="space-y-0.5">
                  {l.paperCompanyId ? (
                    <Link
                      href={`/industry/paper-companies/${l.paperCompanyId}`}
                      className="font-medium hover:underline"
                    >
                      {l.paperCompanyName}
                    </Link>
                  ) : (
                    <span className="font-medium text-muted-foreground">
                      {l.paperCompanyName}
                      <Badge variant="outline" className="ml-2 text-[10px]">raw</Badge>
                    </span>
                  )}
                  {l.millName && (
                    <div className="text-xs">
                      {l.paperMillId ? (
                        <Link
                          href={`/industry/paper-mills/${l.paperMillId}`}
                          className="text-muted-foreground hover:underline"
                        >
                          · {l.millName}
                        </Link>
                      ) : (
                        <span className="text-muted-foreground">· {l.millName}</span>
                      )}
                    </div>
                  )}
                </div>
              </TableCell>
              <TableCell className="text-xs">
                <code className="text-muted-foreground">{l.marketCode ?? '—'}</code>
                {l.countryRegion && (
                  <div className="text-muted-foreground mt-0.5">{l.countryRegion}</div>
                )}
              </TableCell>
              <TableCell>
                {l.fillerType ? (
                  <Badge variant="secondary" className="text-xs">{l.fillerType}</Badge>
                ) : (
                  <span className="text-muted-foreground text-xs">—</span>
                )}
              </TableCell>
              <TableCell className="text-xs text-muted-foreground">
                {l.supplyStructure ?? '—'}
              </TableCell>
              <TableCell>
                {l.confidenceGrade ? (
                  <Badge
                    variant={l.confidenceGrade === 'A' ? 'default' : 'outline'}
                    className="text-xs"
                  >
                    {l.confidenceGrade}
                  </Badge>
                ) : (
                  <span className="text-muted-foreground text-xs">—</span>
                )}
              </TableCell>
              <TableCell className="text-xs">
                {l.confirmationStatus ? (
                  <Badge variant="outline" className="text-[10px]">
                    {l.confirmationStatus}
                  </Badge>
                ) : (
                  <span className="text-muted-foreground">—</span>
                )}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}

// src/app/(app)/industry/paper-companies/[id]/CompanySupplierSummary.tsx
// v5.8 Step B1 EN
'use client'

import Link from 'next/link'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import type { PaperCompanySupplierSummaryRow } from '@/types/industry-link'

export function CompanySupplierSummary({
  suppliers,
}: {
  suppliers: PaperCompanySupplierSummaryRow[]
}) {
  return (
    <div className="rounded-md border overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Supplier</TableHead>
            <TableHead className="w-24">Mill Count</TableHead>
            <TableHead className="w-32">Top Confidence</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {suppliers.map((s, idx) => (
            <TableRow key={`${s.fillerSupplierId ?? 'raw'}-${idx}`}>
              <TableCell>
                {s.fillerSupplierId ? (
                  <Link href={`/industry/filler-suppliers/${s.fillerSupplierId}`} className="font-medium hover:underline">
                    {s.supplierName}
                  </Link>
                ) : (
                  <span className="font-medium text-muted-foreground">
                    {s.supplierName}
                    <Badge variant="outline" className="ml-2 text-[10px]">raw name only</Badge>
                  </span>
                )}
              </TableCell>
              <TableCell><Badge variant="secondary">{s.millCount}</Badge></TableCell>
              <TableCell>
                {s.topConfidence ? (
                  <Badge variant={s.topConfidence === 'A' ? 'default' : 'outline'} className="text-xs">
                    {s.topConfidence}
                  </Badge>
                ) : (
                  <span className="text-muted-foreground text-xs">—</span>
                )}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}

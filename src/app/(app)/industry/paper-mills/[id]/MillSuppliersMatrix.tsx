// src/app/(app)/industry/paper-mills/[id]/MillSuppliersMatrix.tsx
// v5.8 Step B2 EN
'use client'

import Link from 'next/link'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'

type SupplierLink = {
  id: string | number
  fillerSupplierId: number | null
  supplierName: string
  fillerType: string | null
  supplyStructure: string | null
  relationshipType: string | null
  confidenceGrade: string | null
  assessmentScope: string | null
  confirmationStatus: string | null
}

export function MillSuppliersMatrix({ links }: { links: SupplierLink[] }) {
  if (links.length === 0) {
    return (
      <div className="rounded-md border p-6 text-center text-sm text-muted-foreground">
        No confirmed supplier mapping. See "Same-country Filler Suppliers" below for candidates.
      </div>
    )
  }

  return (
    <div className="rounded-md border overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Supplier</TableHead>
            <TableHead className="w-32">Filler Type</TableHead>
            <TableHead className="w-32">Supply</TableHead>
            <TableHead className="w-24">Confidence</TableHead>
            <TableHead className="w-32">Scope</TableHead>
            <TableHead className="w-32">Status</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {links.map((l) => (
            <TableRow key={l.id}>
              <TableCell className="font-medium">
                {l.fillerSupplierId ? (
                  <Link href={`/industry/filler-suppliers/${l.fillerSupplierId}`} className="hover:underline">
                    {l.supplierName}
                  </Link>
                ) : (
                  <span className="text-muted-foreground">{l.supplierName}</span>
                )}
              </TableCell>
              <TableCell>
                {l.fillerType ? (
                  <Badge variant="secondary" className="text-xs">{l.fillerType}</Badge>
                ) : (<span className="text-muted-foreground text-xs">—</span>)}
              </TableCell>
              <TableCell className="text-xs text-muted-foreground">{l.supplyStructure ?? '—'}</TableCell>
              <TableCell>
                {l.confidenceGrade ? (
                  <Badge variant={l.confidenceGrade === 'A' ? 'default' : 'outline'} className="text-xs">
                    {l.confidenceGrade}
                  </Badge>
                ) : (<span className="text-muted-foreground text-xs">—</span>)}
              </TableCell>
              <TableCell className="text-xs text-muted-foreground">{l.assessmentScope ?? '—'}</TableCell>
              <TableCell className="text-xs">
                {l.confirmationStatus ? (
                  <Badge variant="outline" className="text-[10px]">{l.confirmationStatus}</Badge>
                ) : (<span className="text-muted-foreground">—</span>)}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}

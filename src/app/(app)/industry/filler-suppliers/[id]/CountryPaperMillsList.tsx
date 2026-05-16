// src/app/(app)/industry/filler-suppliers/[id]/CountryPaperMillsList.tsx
// v5.8 Step B3: 같은 국가 paper mill 리스트 (잠재 고객)
//
// 정렬 우선순위 (page.tsx에서 미리 정렬됨):
//   1. 이미 거래 중 (hasExistingLinkage)
//   2. likely_filler_types가 supplier의 relevant_filler_types와 매칭
//   3. 그 외 (id 순)
'use client'

import Link from 'next/link'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import type { CountryPaperMillRow } from '@/lib/queries/industry-link-extensions'

export function CountryPaperMillsList({
  mills,
  supplierRelevantTypes,
}: {
  mills: CountryPaperMillRow[]
  supplierRelevantTypes: string[]
}) {
  if (mills.length === 0) {
    return (
      <div className="rounded-md border p-6 text-center text-sm text-muted-foreground">
        이 국가에 등록된 paper mill이 없습니다.
      </div>
    )
  }

  const supplierTypeSet = new Set(supplierRelevantTypes.map((t) => t.toLowerCase()))

  return (
    <div className="rounded-md border overflow-x-auto">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-16">ID</TableHead>
            <TableHead>Mill</TableHead>
            <TableHead>Paper Company</TableHead>
            <TableHead>Products</TableHead>
            <TableHead>Likely Types</TableHead>
            <TableHead className="w-32">Status</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {mills.map((m) => {
            const matchedTypes = m.likelyFillerTypes.filter((t) =>
              supplierTypeSet.has(t.toLowerCase()),
            )
            const hasMatch = matchedTypes.length > 0

            return (
              <TableRow
                key={m.id}
                className={m.hasExistingLinkage ? 'bg-muted/20' : hasMatch ? 'bg-primary/5' : ''}
              >
                <TableCell className="text-muted-foreground font-mono text-xs">
                  {m.id}
                </TableCell>
                <TableCell>
                  <Link
                    href={`/industry/paper-mills/${m.id}`}
                    className="font-medium hover:underline"
                  >
                    {m.millName}
                  </Link>
                  {m.city && (
                    <div className="text-xs text-muted-foreground mt-0.5">{m.city}</div>
                  )}
                </TableCell>
                <TableCell className="text-sm">
                  {m.paperCompanyId && m.paperCompanyName ? (
                    <Link
                      href={`/industry/paper-companies/${m.paperCompanyId}`}
                      className="hover:underline"
                    >
                      {m.paperCompanyName}
                    </Link>
                  ) : (
                    <span className="text-muted-foreground">—</span>
                  )}
                </TableCell>
                <TableCell className="max-w-[240px]">
                  {m.mainProductCategory && (
                    <div className="text-xs font-medium truncate">
                      {m.mainProductCategory}
                    </div>
                  )}
                  {m.mainProducts && (
                    <div className="text-xs text-muted-foreground truncate">
                      {m.mainProducts}
                    </div>
                  )}
                </TableCell>
                <TableCell className="max-w-[200px]">
                  {m.likelyFillerTypes.length > 0 ? (
                    <div className="flex flex-wrap gap-1">
                      {m.likelyFillerTypes.slice(0, 3).map((t) => {
                        const isMatch = supplierTypeSet.has(t.toLowerCase())
                        return (
                          <Badge
                            key={t}
                            variant={isMatch ? 'default' : 'outline'}
                            className="text-[10px] border-dashed"
                          >
                            {isMatch && '★ '}
                            {t}
                          </Badge>
                        )
                      })}
                      {m.likelyFillerTypes.length > 3 && (
                        <span className="text-xs text-muted-foreground self-center">
                          +{m.likelyFillerTypes.length - 3}
                        </span>
                      )}
                    </div>
                  ) : (
                    <span className="text-muted-foreground text-xs">—</span>
                  )}
                </TableCell>
                <TableCell>
                  {m.hasExistingLinkage ? (
                    <Badge variant="default" className="text-[10px]">
                      거래 중
                    </Badge>
                  ) : hasMatch ? (
                    <Badge variant="outline" className="text-[10px] border-primary text-primary">
                      ⭐ 매칭 {matchedTypes.length}
                    </Badge>
                  ) : (
                    <span className="text-muted-foreground text-xs">신규</span>
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

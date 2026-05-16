// src/app/(app)/industry/paper-mills/PaperMillsTable.tsx
// v5.8 Step B2 패치: mill name → Link로 detail page 이동
//
// 변경 사항: TableCell mill name 부분을 <Link>로 wrap만 함. 나머지는 기존과 동일.
// 만약 기존 파일에 추가 customization 있으면, 이 patch 적용 후 conflict 확인 필요.
'use client'

import Link from 'next/link'
import { useRouter, useSearchParams } from 'next/navigation'
import { useTransition } from 'react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'

type Mill = {
  id: number
  mill_name: string
  market_code: string
  city: string | null
  region: string | null
  paper_company_id: number | null
  main_product_category: string | null
  main_products: string | null
  company_name?: string | null  // (선택) join된 경우
}

type Market = { code: string; name: string; region: string | null }

export function PaperMillsTable({
  mills, total, markets, currentPage, pageSize,
}: {
  mills: Mill[]
  total: number
  markets: Market[]
  currentPage: number
  pageSize: number
}) {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [isPending, startTransition] = useTransition()

  const updateParam = (key: string, value: string | null) => {
    const params = new URLSearchParams(searchParams.toString())
    if (value && value !== 'all') params.set(key, value)
    else params.delete(key)
    if (key !== 'page') params.delete('page')
    startTransition(() => {
      router.push(`?${params.toString()}`)
    })
  }

  const totalPages = Math.max(1, Math.ceil(total / pageSize))
  const hasFilters = Boolean(
    searchParams.get('q') || searchParams.get('market')
  )

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="text-sm text-muted-foreground">
          <span className="font-semibold text-foreground">{total}</span> mills
          {hasFilters ? ' (filtered)' : ''}
        </div>
        {isPending && <Badge variant="outline">Loading...</Badge>}
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <Input
          placeholder="Search mill name, city, products..."
          defaultValue={searchParams.get('q') ?? ''}
          onBlur={(e) => updateParam('q', e.target.value || null)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') updateParam('q', e.currentTarget.value || null)
          }}
          className="max-w-sm"
        />
        <Select
          value={searchParams.get('market') ?? 'all'}
          onValueChange={(v) => updateParam('market', v)}
        >
          <SelectTrigger className="w-56">
            <SelectValue placeholder="All markets" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All markets ({markets.length})</SelectItem>
            {markets.map(m => (
              <SelectItem key={m.code} value={m.code}>
                {m.name} <span className="text-muted-foreground">({m.code})</span>
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="rounded-md border overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-16">ID</TableHead>
              <TableHead>Mill</TableHead>
              <TableHead className="w-32">Market</TableHead>
              <TableHead>City</TableHead>
              <TableHead>Main Products</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {mills.length === 0 && (
              <TableRow>
                <TableCell colSpan={5} className="text-center text-muted-foreground py-8">
                  No mills found
                </TableCell>
              </TableRow>
            )}
            {mills.map(mill => (
              <TableRow key={mill.id}>
                <TableCell className="text-muted-foreground font-mono text-xs">
                  {mill.id}
                </TableCell>
                <TableCell className="font-medium">
                  <Link
                    href={`/industry/paper-mills/${mill.id}`}
                    className="hover:underline"
                  >
                    {mill.mill_name}
                  </Link>
                </TableCell>
                <TableCell>
                  <code className="text-xs text-muted-foreground">{mill.market_code}</code>
                </TableCell>
                <TableCell className="text-sm text-muted-foreground max-w-[200px] truncate">
                  {mill.city ?? '—'}
                </TableCell>
                <TableCell className="text-sm text-muted-foreground max-w-[400px] truncate">
                  {mill.main_products ?? '—'}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          {total > 0 && `Showing ${(currentPage - 1) * pageSize + 1}-${Math.min(currentPage * pageSize, total)} of ${total}`}
        </p>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm"
            disabled={currentPage <= 1 || isPending}
            onClick={() => updateParam('page', String(currentPage - 1))}>
            Previous
          </Button>
          <span className="px-2 text-sm">Page {currentPage} / {totalPages}</span>
          <Button variant="outline" size="sm"
            disabled={currentPage >= totalPages || isPending}
            onClick={() => updateParam('page', String(currentPage + 1))}>
            Next
          </Button>
        </div>
      </div>
    </div>
  )
}

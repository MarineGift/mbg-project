// src/app/(app)/industry/paper-mills/PaperMillsTable.tsx
// 변경: 경로만 (app)/industry, 코드 자체는 동일
'use client'

import { useRouter, useSearchParams } from 'next/navigation'
import { useTransition } from 'react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { TierRoleBadge } from '@/components/industry/TierRoleBadge'

type Mill = {
  id: number
  mill_name: string
  market_code: string
  city: string | null
  main_products: string | null
  legacy_id: number | null
  paper_company: {
    id: number
    name: string
    tier_role: 'HQ' | 'Regional' | 'Country' | 'Plant' | null
  } | null
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
    if (key !== 'page') params.delete('page') // reset page on filter
    startTransition(() => {
      router.push(`?${params.toString()}`)
    })
  }

  const totalPages = Math.max(1, Math.ceil(total / pageSize))

  return (
    <div className="space-y-4">
      {/* Header with count */}
      <div className="flex items-center justify-between">
        <div className="text-sm text-muted-foreground">
          <span className="font-semibold text-foreground">{total}</span> mills
          {searchParams.get('q') || searchParams.get('market') ? ' (filtered)' : ''}
        </div>
        {isPending && <Badge variant="outline">Loading...</Badge>}
      </div>

      {/* Filters */}
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

      {/* Table */}
      <div className="rounded-md border overflow-x-auto">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-16">ID</TableHead>
              <TableHead>Mill Name</TableHead>
              <TableHead>Paper Company</TableHead>
              <TableHead className="w-24">Tier</TableHead>
              <TableHead className="w-32">Market</TableHead>
              <TableHead>City</TableHead>
              <TableHead>Main Products</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {mills.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-muted-foreground py-8">
                  No mills found
                </TableCell>
              </TableRow>
            )}
            {mills.map(mill => (
              <TableRow key={mill.id}>
                <TableCell className="text-muted-foreground font-mono text-xs">
                  {mill.id}
                </TableCell>
                <TableCell className="font-medium">{mill.mill_name}</TableCell>
                <TableCell>
                  {mill.paper_company ? (
                    <span>{mill.paper_company.name}</span>
                  ) : (
                    <span className="text-muted-foreground text-xs">unassigned</span>
                  )}
                </TableCell>
                <TableCell>
                  <TierRoleBadge tier={mill.paper_company?.tier_role ?? null} />
                </TableCell>
                <TableCell>
                  <code className="text-xs text-muted-foreground">{mill.market_code}</code>
                </TableCell>
                <TableCell className="text-sm text-muted-foreground max-w-[200px] truncate">
                  {mill.city ?? '—'}
                </TableCell>
                <TableCell className="text-sm text-muted-foreground max-w-[300px] truncate">
                  {mill.main_products ?? '—'}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
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
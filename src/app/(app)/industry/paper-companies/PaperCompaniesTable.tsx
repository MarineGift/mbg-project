// src/app/(app)/industry/paper-companies/PaperCompaniesTable.tsx
// v5.7 신규: PaperMillsTable.tsx 패턴 복제 + paper_companies 적응
'use client'

import { useRouter, useSearchParams } from 'next/navigation'
import { useTransition } from 'react'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { TierRoleBadge } from '@/components/industry/TierRoleBadge'
import { EvidenceBadge } from '@/components/industry/EvidenceBadge'

type TierRole = 'HQ' | 'Regional' | 'Country' | 'Plant'

type Company = {
  id: number
  name: string
  market_code: string
  headquarters: string | null
  tier_role: TierRole | null
  main_product_category: string | null
  main_products: string | null
  evidence_level: string | null
  legacy_id: number | null
}

type Market = { code: string; name: string; region: string | null }

const TIER_OPTIONS: TierRole[] = ['HQ', 'Regional', 'Country', 'Plant']

export function PaperCompaniesTable({
  companies, total, markets, currentPage, pageSize,
}: {
  companies: Company[]
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
  const hasFilters = Boolean(
    searchParams.get('q') || searchParams.get('market') || searchParams.get('tier')
  )

  return (
    <div className="space-y-4">
      {/* Header with count */}
      <div className="flex items-center justify-between">
        <div className="text-sm text-muted-foreground">
          <span className="font-semibold text-foreground">{total}</span> companies
          {hasFilters ? ' (filtered)' : ''}
        </div>
        {isPending && <Badge variant="outline">Loading...</Badge>}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2">
        <Input
          placeholder="Search company name, HQ, products..."
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
        <Select
          value={searchParams.get('tier') ?? 'all'}
          onValueChange={(v) => updateParam('tier', v)}
        >
          <SelectTrigger className="w-40">
            <SelectValue placeholder="All tiers" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All tiers</SelectItem>
            {TIER_OPTIONS.map(t => (
              <SelectItem key={t} value={t}>{t}</SelectItem>
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
              <TableHead>Name</TableHead>
              <TableHead className="w-24">Tier</TableHead>
              <TableHead className="w-24">Evidence</TableHead>
              <TableHead className="w-32">Market</TableHead>
              <TableHead>Headquarters</TableHead>
              <TableHead>Main Products</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {companies.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-muted-foreground py-8">
                  No companies found
                </TableCell>
              </TableRow>
            )}
            {companies.map(company => (
              <TableRow key={company.id}>
                <TableCell className="text-muted-foreground font-mono text-xs">
                  {company.id}
                </TableCell>
                <TableCell className="font-medium">{company.name}</TableCell>
                <TableCell>
                  <TierRoleBadge tier={company.tier_role ?? null} />
                </TableCell>
                <TableCell>
                  <EvidenceBadge level={company.evidence_level ?? null} />
                </TableCell>
                <TableCell>
                  <code className="text-xs text-muted-foreground">{company.market_code}</code>
                </TableCell>
                <TableCell className="text-sm text-muted-foreground max-w-[200px] truncate">
                  {company.headquarters ?? '—'}
                </TableCell>
                <TableCell className="text-sm text-muted-foreground max-w-[300px] truncate">
                  {company.main_products ?? '—'}
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
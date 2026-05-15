// src/app/(app)/industry/filler-suppliers/FillerSuppliersTable.tsx
// v5.7 Step 3: PaperCompaniesTable 패턴 복제 + filler_suppliers 적응
// 핵심 차이:
//   - HQ 컬럼 없음 → "Type" (supplier_type + market_role)
//   - relevant_filler_types ARRAY → Badge 그룹 렌더링
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

type Supplier = {
  id: number
  name: string
  market_code: string
  tier_role: TierRole | null
  supplier_type: string | null
  market_role: string | null
  relevant_filler_types: string[] | null
  supply_model: string | null
  evidence_level: string | null
  legacy_id: number | null
}

type Market = { code: string; name: string; region: string | null }

const TIER_OPTIONS: TierRole[] = ['HQ', 'Regional', 'Country', 'Plant']

export function FillerSuppliersTable({
  suppliers, total, markets, currentPage, pageSize,
}: {
  suppliers: Supplier[]
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
    searchParams.get('q') || searchParams.get('market') || searchParams.get('tier')
  )

  return (
    <div className="space-y-4">
      {/* Header with count */}
      <div className="flex items-center justify-between">
        <div className="text-sm text-muted-foreground">
          <span className="font-semibold text-foreground">{total}</span> suppliers
          {hasFilters ? ' (filtered)' : ''}
        </div>
        {isPending && <Badge variant="outline">Loading...</Badge>}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2">
        <Input
          placeholder="Search supplier name, type, role..."
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
              <TableHead>Type / Role</TableHead>
              <TableHead>Filler Types</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {suppliers.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} className="text-center text-muted-foreground py-8">
                  No suppliers found
                </TableCell>
              </TableRow>
            )}
            {suppliers.map(supplier => (
              <TableRow key={supplier.id}>
                <TableCell className="text-muted-foreground font-mono text-xs">
                  {supplier.id}
                </TableCell>
                <TableCell className="font-medium">{supplier.name}</TableCell>
                <TableCell>
                  <TierRoleBadge tier={supplier.tier_role ?? null} />
                </TableCell>
                <TableCell>
                  <EvidenceBadge level={supplier.evidence_level ?? null} />
                </TableCell>
                <TableCell>
                  <code className="text-xs text-muted-foreground">{supplier.market_code}</code>
                </TableCell>
                <TableCell className="text-sm text-muted-foreground max-w-[200px]">
                  {supplier.supplier_type || supplier.market_role ? (
                    <div className="flex flex-col">
                      {supplier.supplier_type && (
                        <span className="truncate">{supplier.supplier_type}</span>
                      )}
                      {supplier.market_role && (
                        <span className="truncate text-xs">{supplier.market_role}</span>
                      )}
                    </div>
                  ) : (
                    '—'
                  )}
                </TableCell>
                <TableCell className="max-w-[280px]">
                  {Array.isArray(supplier.relevant_filler_types) &&
                  supplier.relevant_filler_types.length > 0 ? (
                    <div className="flex flex-wrap gap-1">
                      {supplier.relevant_filler_types.slice(0, 3).map(t => (
                        <Badge key={t} variant="secondary" className="text-xs">
                          {t}
                        </Badge>
                      ))}
                      {supplier.relevant_filler_types.length > 3 && (
                        <span className="text-xs text-muted-foreground self-center">
                          +{supplier.relevant_filler_types.length - 3}
                        </span>
                      )}
                    </div>
                  ) : (
                    <span className="text-muted-foreground text-sm">—</span>
                  )}
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
# URM Platform — Industry UI Phase 1 (Paper Mills / Paper Companies / Filler Suppliers)

**컨텍스트:** v5.5 Phase 7-c Step A 데이터 정리 진행 중. Sappi family 25→6 row 완료. 화면 작업으로 정리 결과를 시각화 + 다음 family 정리에도 활용.

**스택 가정:** Next.js 14.2 App Router, TypeScript strict, Supabase, shadcn/ui, Tailwind.

다른 UI lib 쓰면 알려주세요 (Mantine, Ant Design 등). 코드 구조는 같고 컴포넌트 이름만 다름.

---

## 1. File Tree

```
src/app/(authenticated)/industry/
├── layout.tsx                              # sub-nav: Mills / Companies / Fillers
├── paper-mills/
│   ├── page.tsx                            # Server Component (fetch)
│   └── PaperMillsTable.tsx                 # Client Component (interactions)
├── paper-companies/
│   ├── page.tsx
│   └── PaperCompaniesTable.tsx
└── filler-suppliers/
    ├── page.tsx
    └── FillerSuppliersTable.tsx

src/components/industry/
├── TierRoleBadge.tsx                       # color-coded HQ/Regional/Country/Plant
└── EvidenceBadge.tsx                       # A/B/C/D/E grade
```

`(authenticated)` route group은 기존 인증 wrapper 가정. 본인 코드에 맞춰 경로 조정.

---

## 2. Supabase Schema 접근 노트

핸드오프 v5.4 #8: `Supabase 타입 재생성 (.schema('industry' as never) 8곳)`. 타입 재생성 전이라 `as never` 캐스팅이 현재 패턴.

### RLS 사전 점검

```sql
-- industry.* 테이블에 RLS 정책 + read 권한 있는지
SELECT schemaname, tablename, rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'industry'
  AND tablename IN ('paper_mills', 'paper_companies', 'filler_suppliers', 'markets')
ORDER BY tablename;

-- 권한 점검 (authenticated role에 SELECT 권한 있는지)
SELECT table_schema, table_name, privilege_type, grantee
FROM information_schema.table_privileges
WHERE table_schema = 'industry'
  AND grantee IN ('anon', 'authenticated', 'service_role')
ORDER BY table_name, grantee;
```

화면에서 데이터 안 보이면:
1. RLS 정책 없거나 deny — `CREATE POLICY industry_read ON industry.paper_mills FOR SELECT USING (true);` (마스터 데이터, organization-independent 가정)
2. SELECT GRANT 없음 — `GRANT SELECT ON ALL TABLES IN SCHEMA industry TO authenticated;`

---

## 3. industry layout (sub-nav)

```tsx
// src/app/(authenticated)/industry/layout.tsx
import Link from 'next/link'
import { IndustryTabs } from './IndustryTabs'

export default function IndustryLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-baseline justify-between">
        <div>
          <h1 className="text-3xl font-bold">Industry Data</h1>
          <p className="text-sm text-muted-foreground">
            Paper mills, paper companies, and filler suppliers — master data
          </p>
        </div>
      </div>
      <IndustryTabs />
      <div>{children}</div>
    </div>
  )
}
```

```tsx
// src/app/(authenticated)/industry/IndustryTabs.tsx
'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'

const tabs = [
  { href: '/industry/paper-mills', label: 'Paper Mills' },
  { href: '/industry/paper-companies', label: 'Paper Companies' },
  { href: '/industry/filler-suppliers', label: 'Filler Suppliers' },
]

export function IndustryTabs() {
  const pathname = usePathname()
  return (
    <nav className="flex gap-1 border-b">
      {tabs.map(tab => {
        const isActive = pathname.startsWith(tab.href)
        return (
          <Link
            key={tab.href}
            href={tab.href}
            className={cn(
              "px-4 py-2 text-sm font-medium -mb-px border-b-2",
              isActive
                ? "border-primary text-foreground"
                : "border-transparent text-muted-foreground hover:text-foreground"
            )}
          >
            {tab.label}
          </Link>
        )
      })}
    </nav>
  )
}
```

---

## 4. Shared Components

```tsx
// src/components/industry/TierRoleBadge.tsx
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

type TierRole = 'HQ' | 'Regional' | 'Country' | 'Plant'

const tierStyles: Record<TierRole, string> = {
  HQ:       'bg-purple-100 text-purple-900 border-purple-200',
  Regional: 'bg-blue-100   text-blue-900   border-blue-200',
  Country:  'bg-green-100  text-green-900  border-green-200',
  Plant:    'bg-amber-100  text-amber-900  border-amber-200',
}

export function TierRoleBadge({ tier }: { tier: TierRole | null }) {
  if (!tier) return <span className="text-xs text-muted-foreground">—</span>
  return (
    <Badge variant="outline" className={cn('font-mono text-xs', tierStyles[tier])}>
      {tier}
    </Badge>
  )
}
```

```tsx
// src/components/industry/EvidenceBadge.tsx
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

export function EvidenceBadge({ level }: { level: string | null }) {
  if (!level) return <span className="text-xs text-muted-foreground">—</span>
  const styles: Record<string, string> = {
    A: 'bg-emerald-100 text-emerald-900',
    B: 'bg-lime-100    text-lime-900',
    C: 'bg-yellow-100  text-yellow-900',
    D: 'bg-orange-100  text-orange-900',
    E: 'bg-rose-100    text-rose-900',
  }
  return (
    <Badge variant="outline" className={cn('font-mono text-xs', styles[level] ?? '')}>
      {level}
    </Badge>
  )
}
```

---

## 5. Paper Mills Page (가장 큰 데이터, 552 row)

### page.tsx (Server Component)

```tsx
// src/app/(authenticated)/industry/paper-mills/page.tsx
import { createClient } from '@/lib/supabase/server'
import { PaperMillsTable } from './PaperMillsTable'

const PAGE_SIZE = 50

export default async function PaperMillsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; market?: string; tier?: string; page?: string }>
}) {
  const params = await searchParams
  const supabase = await createClient()
  const page = Math.max(1, Number(params.page ?? 1))
  const from = (page - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1

  // 1) Paper Mills fetch (with paper_companies embed via FK)
  let millsQuery = supabase
    .schema('industry' as never)
    .from('paper_mills')
    .select(`
      id,
      mill_name,
      market_code,
      city,
      main_products,
      legacy_id,
      paper_company:paper_company_id (
        id,
        name,
        tier_role
      )
    `, { count: 'exact' })
    .order('id', { ascending: true })

  if (params.q) {
    millsQuery = millsQuery.or(
      `mill_name.ilike.%${params.q}%,city.ilike.%${params.q}%,main_products.ilike.%${params.q}%`
    )
  }
  if (params.market) {
    millsQuery = millsQuery.eq('market_code', params.market)
  }

  const { data: mills, count } = await millsQuery.range(from, to)

  // 2) Markets (filter dropdown)
  const { data: markets } = await supabase
    .schema('industry' as never)
    .from('markets')
    .select('code, name, region')
    .order('name')

  return (
    <PaperMillsTable
      mills={(mills ?? []) as any[]}
      total={count ?? 0}
      markets={(markets ?? []) as any[]}
      currentPage={page}
      pageSize={PAGE_SIZE}
    />
  )
}
```

⚠️ **Supabase embed 주의** — `paper_company:paper_company_id (...)` 형식이 industry schema 안에서 작동하려면 같은 schema 내 FK가 PostgREST에 인식되어야 함. 만약 작동 안 하면 두 쿼리 분리 + 클라이언트 join. fallback 코드는 섹션 9 참조.

### PaperMillsTable.tsx (Client Component)

```tsx
// src/app/(authenticated)/industry/paper-mills/PaperMillsTable.tsx
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
```

---

## 6. Paper Companies Page (정리 결과 시각화의 핵심)

```tsx
// src/app/(authenticated)/industry/paper-companies/page.tsx
import { createClient } from '@/lib/supabase/server'
import { PaperCompaniesTable } from './PaperCompaniesTable'

const PAGE_SIZE = 50

export default async function PaperCompaniesPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; market?: string; tier?: string; page?: string }>
}) {
  const params = await searchParams
  const supabase = await createClient()
  const page = Math.max(1, Number(params.page ?? 1))
  const from = (page - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1

  let q = supabase
    .schema('industry' as never)
    .from('paper_companies')
    .select('id, name, market_code, tier_role, notes', { count: 'exact' })
    .order('id', { ascending: true })

  if (params.q) q = q.ilike('name', `%${params.q}%`)
  if (params.market) q = q.eq('market_code', params.market)
  if (params.tier && params.tier !== 'all') q = q.eq('tier_role', params.tier)

  const { data: companies, count } = await q.range(from, to)

  // mill_count는 별도 query (subquery 대신 클라이언트 join 가벼움)
  const companyIds = (companies ?? []).map((c: any) => c.id)
  const { data: millCounts } = companyIds.length > 0
    ? await supabase
        .schema('industry' as never)
        .from('paper_mills')
        .select('paper_company_id')
        .in('paper_company_id', companyIds)
    : { data: [] as any[] }

  const millCountMap = new Map<number, number>()
  ;(millCounts ?? []).forEach((m: any) => {
    millCountMap.set(m.paper_company_id, (millCountMap.get(m.paper_company_id) ?? 0) + 1)
  })

  const companiesWithMillCount = (companies ?? []).map((c: any) => ({
    ...c,
    mill_count: millCountMap.get(c.id) ?? 0,
  }))

  const { data: markets } = await supabase
    .schema('industry' as never)
    .from('markets')
    .select('code, name')
    .order('name')

  return (
    <PaperCompaniesTable
      companies={companiesWithMillCount as any[]}
      total={count ?? 0}
      markets={(markets ?? []) as any[]}
      currentPage={page}
      pageSize={PAGE_SIZE}
    />
  )
}
```

`PaperCompaniesTable.tsx` 는 PaperMillsTable과 거의 동일 — tier filter 추가, 컬럼 다름:

```tsx
// 핵심 차이만 발췌
// Filters에 tier_role select 추가:
<Select
  value={searchParams.get('tier') ?? 'all'}
  onValueChange={(v) => updateParam('tier', v)}
>
  <SelectTrigger className="w-40">
    <SelectValue placeholder="All tiers" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="all">All tiers</SelectItem>
    <SelectItem value="HQ">HQ</SelectItem>
    <SelectItem value="Regional">Regional</SelectItem>
    <SelectItem value="Country">Country</SelectItem>
    <SelectItem value="Plant">Plant</SelectItem>
  </SelectContent>
</Select>

// TableHead 컬럼:
// ID | Name | Tier | Market | Mills | Notes

// TableRow:
<TableCell>{company.id}</TableCell>
<TableCell className="font-medium">{company.name}</TableCell>
<TableCell><TierRoleBadge tier={company.tier_role} /></TableCell>
<TableCell><code className="text-xs">{company.market_code}</code></TableCell>
<TableCell>
  <Badge variant={company.mill_count > 0 ? 'default' : 'secondary'}>
    {company.mill_count}
  </Badge>
</TableCell>
<TableCell className="text-xs text-muted-foreground max-w-[300px] truncate">
  {company.notes ?? '—'}
</TableCell>
```

---

## 7. Filler Suppliers Page

```tsx
// src/app/(authenticated)/industry/filler-suppliers/page.tsx
import { createClient } from '@/lib/supabase/server'
import { FillerSuppliersTable } from './FillerSuppliersTable'

const PAGE_SIZE = 50

export default async function FillerSuppliersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; market?: string; type?: string; evidence?: string; tier?: string; page?: string }>
}) {
  const params = await searchParams
  const supabase = await createClient()
  const page = Math.max(1, Number(params.page ?? 1))
  const from = (page - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1

  let q = supabase
    .schema('industry' as never)
    .from('filler_suppliers')
    .select(`
      id, name, supplier_type, market_role,
      relevant_filler_types, supply_model,
      evidence_level, market_code, tier_role,
      source_url, notes
    `, { count: 'exact' })
    .order('id', { ascending: true })

  if (params.q) q = q.ilike('name', `%${params.q}%`)
  if (params.market) q = q.eq('market_code', params.market)
  if (params.type) q = q.eq('supplier_type', params.type)
  if (params.evidence) q = q.eq('evidence_level', params.evidence)
  if (params.tier && params.tier !== 'all') q = q.eq('tier_role', params.tier)

  const { data: suppliers, count } = await q.range(from, to)

  const { data: markets } = await supabase
    .schema('industry' as never)
    .from('markets')
    .select('code, name')
    .order('name')

  return (
    <FillerSuppliersTable
      suppliers={(suppliers ?? []) as any[]}
      total={count ?? 0}
      markets={(markets ?? []) as any[]}
      currentPage={page}
      pageSize={PAGE_SIZE}
    />
  )
}
```

`FillerSuppliersTable.tsx`는 같은 패턴, 컬럼 다름:

```tsx
// TableHead: ID | Name | Type | Tier | Evidence | Filler Types | Market | Source

<TableCell>{s.id}</TableCell>
<TableCell className="font-medium">{s.name}</TableCell>
<TableCell className="text-sm">{s.supplier_type ?? '—'}</TableCell>
<TableCell><TierRoleBadge tier={s.tier_role} /></TableCell>
<TableCell><EvidenceBadge level={s.evidence_level} /></TableCell>
<TableCell>
  <div className="flex flex-wrap gap-1">
    {(s.relevant_filler_types ?? []).map((t: string) => (
      <Badge key={t} variant="secondary" className="text-xs">{t}</Badge>
    ))}
  </div>
</TableCell>
<TableCell><code className="text-xs">{s.market_code}</code></TableCell>
<TableCell>
  {s.source_url ? (
    <a href={s.source_url} target="_blank" rel="noopener" className="text-xs text-blue-600 hover:underline truncate block max-w-[150px]">
      🔗 link
    </a>
  ) : '—'}
</TableCell>
```

---

## 8. Sidebar Navigation 통합

기존 sidebar 컴포넌트에 추가:

```tsx
// 예시 — 본인 sidebar 구조에 맞춰 조정
{
  section: 'Industry Data',
  items: [
    { href: '/industry/paper-mills',       label: 'Paper Mills',       icon: FactoryIcon },
    { href: '/industry/paper-companies',   label: 'Paper Companies',   icon: Building2Icon },
    { href: '/industry/filler-suppliers',  label: 'Filler Suppliers',  icon: PackageIcon },
  ],
},
```

count badge 동적으로 표시하려면 sidebar component 자체에서 fetch (server component) 또는 React Query/SWR로 client fetch.

---

## 9. Supabase Embed Fallback

만약 `paper_company:paper_company_id (...)` embed가 작동 안 하면 (PostgREST가 industry schema 내 FK를 못 잡는 경우):

```tsx
// PaperMillsPage에서 embed 빼고 분리 fetch
const { data: mills, count } = await supabase
  .schema('industry' as never)
  .from('paper_mills')
  .select('id, mill_name, market_code, city, main_products, legacy_id, paper_company_id', { count: 'exact' })
  .order('id')
  .range(from, to)

const companyIds = [...new Set((mills ?? []).map((m: any) => m.paper_company_id).filter(Boolean))]
const { data: companies } = companyIds.length > 0
  ? await supabase
      .schema('industry' as never)
      .from('paper_companies')
      .select('id, name, tier_role')
      .in('id', companyIds)
  : { data: [] as any[] }

const companyMap = new Map((companies ?? []).map((c: any) => [c.id, c]))
const millsWithCompany = (mills ?? []).map((m: any) => ({
  ...m,
  paper_company: m.paper_company_id ? companyMap.get(m.paper_company_id) ?? null : null,
}))
```

---

## 10. 적용 순서

```
1. RLS / GRANT 점검 SQL 실행 (섹션 2)
   - 데이터가 화면에 안 보이면 권한 문제
   
2. shared 컴포넌트 2개 생성 (TierRoleBadge, EvidenceBadge)

3. layout.tsx + IndustryTabs.tsx 생성

4. paper-mills/ 페이지 생성 → 작동 확인
   - 가장 큰 데이터 (552 row)라 pagination 검증 중요
   - embed 작동 안 하면 섹션 9 fallback 적용

5. paper-companies/ 페이지 — Sappi 6 row + 다른 family 확인 가능
   - tier_role filter로 정리된 entity 확인
   - mill_count 0인 row가 정리 후보

6. filler-suppliers/ 페이지

7. Sidebar에 'Industry Data' 섹션 추가

8. (옵션) i18n key 추가 — 한국어 label
   - paper-mills.title = '제지 공장' / 'Paper Mills'
   - paper-companies.title = '제지 회사' / 'Paper Companies'
   - filler-suppliers.title = '충전제 공급사' / 'Filler Suppliers'
```

---

## 11. Phase 2 UI 확장 후보 (Phase 1 MVP 작동 확인 후)

- **Row click → detail drawer** — 단일 entity 상세 (linkages, app.parties promotion 상태 등)
- **Bulk action** — 선택 후 DELETE/UPDATE batch
- **Dirty data 시각화** — `Multi-region`, `KwaZulu-Natal x2` 같은 anomaly highlight
- **CSV export** — 정리 결과 외부 공유
- **Sappi-style cleanup wizard** — 다음 family (Mondi 43 등) 정리 가이드 UI
- **Realtime updates** — Supabase realtime으로 정리 작업 중 다른 탭 자동 refresh

---

## 12. 알려진 이슈 / 노트

- **Supabase 타입** — `as never` 캐스팅은 임시. 핸드오프 v5.4 #8: `supabase gen types typescript --schema industry,app` 재실행 필요. 그 후 캐스팅 제거 가능.
- **next/navigation searchParams** — Next 14.2+에서 `searchParams` Promise. `await` 필수.
- **shadcn/ui 가정** — 미사용 시 import path 조정.
- **i18n** — 핸드오프 451 keys i18n. 화면 string 한국어/영어 분리 처리. label `t('industry.paper_mills.title')` 같은 패턴.
- **RLS organization-independent** — industry 데이터는 read-only 마스터로 가정. 추가 권한 분리 필요하면 `created_by_org_id` 등 컬럼 추가.

---

끝. Phase 1 MVP는 7-8개 파일로 구성됨. 적용 후 막히는 부분 알려주시면 디버깅 + 다음 확장.

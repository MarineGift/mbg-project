import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Plus, ExternalLink } from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { requireAuthOrRedirect } from '@/lib/auth';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import type { ModuleType } from '@/types/ai';
import type { PartyTier, PartyStatus } from '@/types/party-detail';

const PHASE_1_MODULES: readonly ModuleType[] = [
  'investor',
  'buyer',
  'partner',
  'customer',
  'filler',
] as const;

const MODULE_LABELS: Record<ModuleType, string> = {
  investor: '투자자',
  buyer: '구매자',
  partner: '파트너',
  customer: '고객',
  crowdfunding: '크라우드펀딩',
  product_launch: '제품 출시',
  sales: '영업',
  filler: '충전제 공급사',
};

const TIER_LABELS: Record<PartyTier, string> = {
  tier_1: 'Tier 1',
  tier_2: 'Tier 2',
  tier_3: 'Tier 3',
  cold: 'Cold',
};

const TIER_COLORS: Record<PartyTier, string> = {
  tier_1: 'bg-emerald-100 text-emerald-700',
  tier_2: 'bg-blue-100 text-blue-700',
  tier_3: 'bg-slate-100 text-slate-700',
  cold: 'bg-gray-100 text-gray-500',
};

const STATUS_LABELS: Record<PartyStatus, string> = {
  active: '활성',
  paused: '일시정지',
  closed_won: '성공',
  closed_lost: '실패',
  archived: '보관',
};

interface PartyRow {
  id: string;
  name: string;
  tier: PartyTier | null;
  status: PartyStatus;
  country_code: string | null;
  city: string | null;
  industry_tags: string[] | null;
  website: string | null;
  created_at: string;
}

interface PageProps {
  params: Promise<{ module: string }>;
  searchParams: Promise<{ include_stubs?: string }>;
}

export default async function PartiesListPage({ params, searchParams }: PageProps) {
  const { module: moduleParam } = await params;
  const { include_stubs } = await searchParams;
  const showStubs = include_stubs === '1';

  if (!(PHASE_1_MODULES as readonly string[]).includes(moduleParam)) {
    notFound();
  }
  const module = moduleParam as ModuleType;

  await requireAuthOrRedirect();
  const supabase = await createSupabaseServerClient();

  let query = supabase
    .schema('app')
    .from('parties' as never)
    .select('id, name, tier, status, country_code, city, industry_tags, website, created_at')
    .eq('module', module)
    .is('deleted_at', null);

  // Stub (Auto-created from industry mills/linkages) 제외 — ?include_stubs=1 로 포함 토글
  if (!showStubs) {
    query = query.or('notes.is.null,notes.not.ilike.Auto-created%');
  }

  const { data, error } = await query;

  // 에러를 silent하게 삼키지 않음 — Next.js error boundary가 잡아서
  // 적절한 에러 화면을 표시. "총 0개"로 잘못 보이는 것보다 명시적 에러가 디버깅에 안전.
  if (error) {
    console.error('[parties-list] fetch error:', error);
    throw error;
  }

  const parties = (data ?? []) as unknown as PartyRow[];

  return (
    <div className="p-6 max-w-6xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">{MODULE_LABELS[module]} 거래처</h1>
          <p className="text-sm text-muted-foreground mt-1">
            총 {parties.length}개의 거래처
          </p>
        </div>
        <Button asChild>
          <Link href={`/${module}/parties/new`}>
            <Plus className="h-4 w-4" />새 거래처
          </Link>
        </Button>
      </div>

      {parties.length === 0 ? (
        <Card>
          <CardContent className="py-16 text-center">
            <p className="text-muted-foreground mb-4">
              아직 등록된 거래처가 없습니다.
            </p>
            <Button asChild>
              <Link href={`/${module}/parties/new`}>
                <Plus className="h-4 w-4" />첫 거래처 추가
              </Link>
            </Button>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b bg-muted/30">
                <tr className="text-left text-xs uppercase tracking-wide text-muted-foreground">
                  <th className="px-4 py-3 font-medium">이름</th>
                  <th className="px-4 py-3 font-medium">Tier</th>
                  <th className="px-4 py-3 font-medium">위치</th>
                  <th className="px-4 py-3 font-medium">태그</th>
                  <th className="px-4 py-3 font-medium">웹사이트</th>
                </tr>
              </thead>
              <tbody>
                {parties.map((p) => {
                  const location = [p.city, p.country_code]
                    .filter(Boolean)
                    .join(', ');
                  const tags = p.industry_tags ?? [];
                  return (
                    <tr
                      key={p.id}
                      className="border-b hover:bg-muted/20 transition"
                    >
                      <td className="px-4 py-3">
                        <Link
                          href={`/${module}/parties/${p.id}`}
                          className="font-medium hover:underline"
                        >
                          {p.name}
                        </Link>
                      </td>
                      <td className="px-4 py-3">
                        {p.tier ? (
                          <span
                            className={`inline-flex px-2 py-0.5 text-xs font-medium rounded-full ${TIER_COLORS[p.tier]}`}
                          >
                            {TIER_LABELS[p.tier]}
                          </span>
                        ) : (
                          <span className="text-sm text-muted-foreground">—</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm">
                        {location || '—'}
                      </td>
                      <td className="px-4 py-3 text-sm">
                        <div className="flex flex-wrap gap-1">
                          {tags.slice(0, 3).map((tag) => (
                            <span
                              key={tag}
                              className="inline-flex px-2 py-0.5 text-xs bg-muted rounded"
                            >
                              {tag}
                            </span>
                          ))}
                          {tags.length > 3 && (
                            <span className="inline-flex px-1 py-0.5 text-xs text-muted-foreground">
                              +{tags.length - 3}
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm">
                        {p.website ? (
                          <a
                            href={p.website}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-primary hover:underline inline-flex items-center gap-1"
                          >
                            링크
                            <ExternalLink className="h-3 w-3" />
                          </a>
                        ) : (
                          '—'
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </div>
  );
}

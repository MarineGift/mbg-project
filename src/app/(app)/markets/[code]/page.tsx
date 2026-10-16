// src/app/(app)/markets/[code]/page.tsx
//
// One country's market page - the same Market view as the mill / filler
// "Market" tab, reachable by country code even when the country has no
// paper mill or filler row in URM (e.g. /markets/TL).

import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { CountryMarketTab } from '@/components/parties/country-market-tab';
import { fetchCountryNames } from '@/lib/queries/countries';

export const dynamic = 'force-dynamic';

export default async function CountryMarketPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code: raw } = await params;
  const code = decodeURIComponent(raw ?? '').trim().toUpperCase();
  const names = await fetchCountryNames();
  const name = names[code] ?? code;

  return (
    <div className="px-4 sm:px-6 py-4 sm:py-6 space-y-4">
      <div className="flex flex-col gap-1">
        <Link href="/markets" className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:underline">
          <ArrowLeft className="h-3 w-3" /> Country Markets
        </Link>
        <h1 className="text-xl sm:text-2xl font-bold">
          {name} <span className="text-base font-normal text-muted-foreground">{code}</span>
        </h1>
        <div className="flex gap-3 text-sm">
          <Link href={`/paper_mill/parties?country=${code}`} className="text-primary hover:underline">제지사 목록</Link>
          <Link href={`/filler_supplier/parties?country=${code}`} className="text-primary hover:underline">충전제사 목록</Link>
        </div>
      </div>
      <CountryMarketTab partyId="" country={code} path={`/markets/${code}`} />
    </div>
  );
}

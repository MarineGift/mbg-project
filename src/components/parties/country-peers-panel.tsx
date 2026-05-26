import { createSupabaseServerClient } from '@/lib/supabase/server';
import { CountryPeersPanelClient } from './country-peers-panel-client';

const COUNTRY_NAMES: Record<string, string> = {
  AR:'Argentina', AT:'Austria', AU:'Australia', BD:'Bangladesh',
  BE:'Belgium', BR:'Brazil', CA:'Canada', CH:'Switzerland',
  CL:'Chile', CN:'China', CO:'Colombia', DE:'Germany',
  DZ:'Algeria', EG:'Egypt', ES:'Spain', FI:'Finland',
  FR:'France', GB:'UK', ID:'Indonesia', IN:'India',
  IT:'Italy', JP:'Japan', KR:'Korea', MA:'Morocco',
  MX:'Mexico', MY:'Malaysia', NO:'Norway', NZ:'New Zealand',
  PH:'Philippines', PL:'Poland', PT:'Portugal', SE:'Sweden',
  SK:'Slovakia', TH:'Thailand', TR:'Turkey', US:'USA',
  VN:'Vietnam', ZA:'South Africa',
};

interface Props {
  partyId: string;
  country: string | null;
  currentModule: string;
}

export async function CountryPeersPanel({ partyId, country, currentModule }: Props) {
  if (!country) return null;

  const supabase = await createSupabaseServerClient();

  const [millsRes, fillersRes] = await Promise.all([
    supabase.schema('app').from('parties' as never)
      .select('id, name, city, tier, party_level')
      .eq('party_type' as never, 'paper_mill')
      .eq('country_code' as never, country)
      .is('deleted_at' as never, null)
      .order('name')
      .limit(20),
    supabase.schema('app').from('parties' as never)
      .select('id, name, city, tier, party_level')
      .eq('party_type' as never, 'filler_supplier')
      .eq('country_code' as never, country)
      .is('deleted_at' as never, null)
      .order('name')
      .limit(20),
  ]);

  const mills   = ((millsRes.data ?? []) as any[]);
  const fillers = ((fillersRes.data ?? []) as any[]);
  const countryName = COUNTRY_NAMES[country] ?? country;

  if (mills.length === 0 && fillers.length === 0) return null;

  return (
    <CountryPeersPanelClient
      partyId={partyId}
      country={country}
      countryName={countryName}
      currentModule={currentModule as never}
      mills={mills}
      fillers={fillers}
    />
  );
}

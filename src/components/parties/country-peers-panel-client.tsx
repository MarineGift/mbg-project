'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Building2, Package, ChevronRight, MapPin } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import type { CountryPeer } from '@/lib/queries/country-peers';

interface Props {
  partyId: string;
  country: string;
  countryName?: string;
  currentModule: 'paper_mill' | 'filler_supplier';
  mills: CountryPeer[];
  fillers: CountryPeer[];
}

const TIER_MAP: Record<string, string> = {
  tier_1: 'Tier 1', tier_2: 'Tier 2', tier_3: 'Tier 3', cold: 'Cold',
  'Tier 1': 'Tier 1', 'Tier 2': 'Tier 2', 'Tier 3': 'Tier 3',
};
const TIER_COLOR: Record<string, string> = {
  'Tier 1': 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
  'Tier 2': 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300',
  'Tier 3': 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300',
};

const MODULE_ROUTE: Record<string, string> = {
  paper_mill: 'paper_mill',
  filler: 'filler_supplier',
};

function PeerRow({ peer }: { peer: CountryPeer }) {
  const route = MODULE_ROUTE[peer.module] ?? peer.module;
  const tierCls = peer.tier ? (TIER_COLOR[TIER_MAP[peer.tier] ?? peer.tier] ?? 'bg-muted text-muted-foreground') : '';
  return (
    <Link
      href={`/${route}/parties/${peer.id}`}
      className="flex items-center gap-3 px-4 py-3 hover:bg-muted/40 transition-colors group border-b last:border-0"
    >
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-0.5">
          <span className="font-medium text-sm truncate group-hover:text-primary transition-colors">
            {peer.name}
          </span>
          {peer.tier && (
            <span className={cn('text-[10px] font-medium px-1.5 py-0.5 rounded-full shrink-0', tierCls)}>
              {TIER_MAP[peer.tier ?? ''] ?? peer.tier}
            </span>
          )}
          {peer.status && peer.status !== 'active' && (
            <Badge variant="outline" className="text-[10px] h-4 px-1 shrink-0">
              {peer.status}
            </Badge>
          )}
        </div>
        {peer.tags && peer.tags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-1">
            {peer.tags.slice(0, 4).map((tag) => (
              <span key={tag} className="text-[10px] text-muted-foreground bg-muted px-1.5 py-0.5 rounded">
                {tag}
              </span>
            ))}
            {peer.tags.length > 4 && (
              <span className="text-[10px] text-muted-foreground">+{peer.tags.length - 4}</span>
            )}
          </div>
        )}
        {peer.description && (
          <p className="text-xs text-muted-foreground line-clamp-1 mt-0.5">{peer.description}</p>
        )}
      </div>
      <ChevronRight className="h-4 w-4 text-muted-foreground shrink-0 group-hover:text-primary transition-colors" />
    </Link>
  );
}

export function CountryPeersPanelClient({ partyId, country, countryName, currentModule, mills, fillers }: Props) {
  // paper_mill page: filler tab first; filler page: mills tab first
  const [activeTab, setActiveTab] = useState<'mills' | 'fillers'>(
    currentModule === 'filler_supplier' ? 'mills' : 'fillers'
  );

  const locationLabel = countryName ?? country;
  const list = activeTab === 'mills' ? mills : fillers;

  return (
    <Card>
      <CardHeader className="pb-0">
        <CardTitle className="text-sm flex items-center gap-2">
          <MapPin className="h-4 w-4 text-muted-foreground" />
          {locationLabel} — Same-country peers
        </CardTitle>
        {/* Tab buttons */}
        <div className="flex gap-0 mt-3 border-b">
          <button
            onClick={() => setActiveTab('mills')}
            className={cn(
              'flex items-center gap-1.5 px-4 py-2 text-xs font-medium border-b-2 transition-colors',
              activeTab === 'mills'
                ? 'border-primary text-foreground'
                : 'border-transparent text-muted-foreground hover:text-foreground'
            )}
          >
            <Building2 className="h-3.5 w-3.5" />
            Paper Mills
            <span className="ml-1 inline-flex items-center justify-center rounded-full bg-muted text-muted-foreground text-[10px] font-medium min-w-[18px] h-4 px-1">
              {mills.length}
            </span>
          </button>
          <button
            onClick={() => setActiveTab('fillers')}
            className={cn(
              'flex items-center gap-1.5 px-4 py-2 text-xs font-medium border-b-2 transition-colors',
              activeTab === 'fillers'
                ? 'border-primary text-foreground'
                : 'border-transparent text-muted-foreground hover:text-foreground'
            )}
          >
            <Package className="h-3.5 w-3.5" />
            Filler Suppliers
            <span className="ml-1 inline-flex items-center justify-center rounded-full bg-muted text-muted-foreground text-[10px] font-medium min-w-[18px] h-4 px-1">
              {fillers.length}
            </span>
          </button>
        </div>
      </CardHeader>
      <CardContent className="p-0 max-h-[400px] overflow-y-auto">
        {list.length === 0 ? (
          <div className="px-4 py-8 text-center text-sm text-muted-foreground italic">
            {activeTab === 'mills' ? 'No paper mills' : 'No filler suppliers'} in this country</div>
        ) : (
          list.map((p) => <PeerRow key={p.id} peer={p} />)
        )}
      </CardContent>
    </Card>
  );
}
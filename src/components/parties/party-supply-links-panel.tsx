'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  Factory, Package, Plus, Trash2,
  TrendingUp, Loader2, X, Search, AlertTriangle
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

interface SupplyLink {
  id: string;
  linked_id: string;
  linked_name: string;
  linked_module: string;
  linked_country: string | null;
  linked_tier: string | null;
  link_type: string;
  product_grade: string | null;
  volume_estimate: number | null;
  notes: string | null;
}

interface SearchParty {
  id: string;
  name: string;
  country_code: string | null;
  tier: string | null;
  module: string;
}

const SUPPLY_TYPES = [
  { value: 'active',     label: 'Active',     color: 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' },
  { value: 'potential',  label: 'Potential',  color: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300' },
  { value: 'pilot',      label: 'Pilot',      color: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300' },
  { value: 'historical', label: 'Historical', color: 'bg-muted text-muted-foreground' },
];

const GRADES = ['PCC', 'GCC', 'PCC+GCC', 'Kaolin', 'Talc', 'TiO2', 'Other'];

function cn(...classes: (string | undefined | false)[]) {
  return classes.filter(Boolean).join(' ');
}

interface Props {
  partyId: string;
  partyModule: 'filler_supplier' | 'paper_mill';
  orgId: string;
}

export function PartySupplyLinksPanel({ partyId, partyModule, orgId }: Props) {
  const isFillerPage = partyModule === 'filler_supplier';
  const linkedModule = isFillerPage ? 'paper_mill' : 'filler_supplier';
  const title  = isFillerPage ? 'Paper Mills supplied' : 'Filler suppliers in use';
  const Icon   = isFillerPage ? Factory : Package;

  const [links, setLinks]     = useState<SupplyLink[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);

  async function loadLinks() {
    setLoading(true);
    try {
      const res = await fetch(`/api/supply-links?partyId=${partyId}&role=${partyModule}`);
      if (res.ok) setLinks(await res.json());
    } finally { setLoading(false); }
  }

  useEffect(() => { loadLinks(); }, [partyId]);

  async function removeLink(linkId: string) {
    if (!confirm('Delete this link?')) return;
    await fetch(`/api/supply-links/${linkId}`, { method: 'DELETE' });
    setLinks(prev => prev.filter(l => l.id !== linkId));
  }

  return (
    <Card>
      <CardHeader className="pb-0">
        <CardTitle className="text-sm flex items-center justify-between">
          <span className="flex items-center gap-2">
            <Icon className="h-4 w-4 text-muted-foreground" />
            {title}
            {!loading && (
              <span className="text-xs font-normal text-muted-foreground ml-1">
                {links.length}
              </span>
            )}
          </span>
          <button
            onClick={() => setShowAdd(true)}
            className="inline-flex items-center gap-1 text-xs text-primary hover:underline"
          >
            <Plus className="h-3.5 w-3.5" /> Add link
          </button>
        </CardTitle>
      </CardHeader>

      <CardContent className="p-0 mt-2">
        {loading ? (
          <div className="flex justify-center py-6">
            <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />
          </div>
        ) : links.length === 0 ? (
          <p className="px-4 py-6 text-center text-sm text-muted-foreground italic">
            {isFillerPage ? 'No paper mills supplied yet.' : 'No filler suppliers in use.'}
          </p>
        ) : (
          <div className="divide-y max-h-[380px] overflow-y-auto">
            {links.map(lk => {
              const route    = lk.linked_module === 'paper_mill' ? 'paper_mill' : 'filler_supplier';
              const typeInfo = SUPPLY_TYPES.find(t => t.value === lk.link_type) ?? SUPPLY_TYPES[0];
              return (
                <div key={lk.id} className="flex items-start gap-2 px-4 py-3 hover:bg-muted/30 group">
                  <Link href={`/${route}/parties/${lk.linked_id}`} className="flex-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-1.5 mb-0.5">
                      <span className="text-sm font-medium group-hover:text-primary truncate">
                        {lk.linked_name}
                      </span>
                      {lk.linked_country && (
                        <span className="text-xs text-muted-foreground shrink-0">{lk.linked_country}</span>
                      )}
                      <span className={cn('text-[10px] font-medium px-1.5 py-0.5 rounded-full shrink-0', typeInfo!.color)}>
                        {typeInfo!.label}
                      </span>
                    </div>
                    <div className="flex flex-wrap gap-3 text-xs text-muted-foreground">
                      {lk.product_grade && (
                        <span className="flex items-center gap-0.5">
                          <Package className="h-3 w-3" />{lk.product_grade}
                        </span>
                      )}
                      {lk.volume_estimate && (
                        <span className="flex items-center gap-0.5">
                          <TrendingUp className="h-3 w-3" />{lk.volume_estimate.toLocaleString()} t/yr
                        </span>
                      )}
                      {lk.notes && <span className="truncate max-w-[180px] italic">{lk.notes}</span>}
                    </div>
                  </Link>
                  <button
                    onClick={() => removeLink(lk.id)}
                    className="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-destructive/10 hover:text-destructive transition-all shrink-0"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </CardContent>

      {showAdd && (
        <AddLinkModal
          partyId={partyId}
          partyModule={partyModule}
          orgId={orgId}
          linkedModule={linkedModule}
          onClose={() => setShowAdd(false)}
          onAdded={() => { setShowAdd(false); loadLinks(); }}
        />
      )}
    </Card>
  );
}

function AddLinkModal({ partyId, partyModule, orgId, linkedModule, onClose, onAdded }: {
  partyId: string; partyModule: string; orgId: string;
  linkedModule: string; onClose: () => void; onAdded: () => void;
}) {
  const [query, setQuery]         = useState('');
  const [results, setResults]     = useState<SearchParty[]>([]);
  const [selected, setSelected]   = useState<SearchParty | null>(null);
  const [supplyType, setSupplyType] = useState('active');
  const [grade, setGrade]         = useState('PCC');
  const [volume, setVolume]       = useState('');
  const [notes, setNotes]         = useState('');
  const [saving, setSaving]       = useState(false);
  const [searching, setSearching] = useState(false);

  useEffect(() => {
    if (query.length < 2) { setResults([]); return; }
    const t = setTimeout(async () => {
      setSearching(true);
      try {
        const res = await fetch(
          `/api/parties/search?q=${encodeURIComponent(query)}&module=${linkedModule}&limit=10`
        );
        if (res.ok) setResults(await res.json());
      } finally { setSearching(false); }
    }, 300);
    return () => clearTimeout(t);
  }, [query, linkedModule]);

  async function save() {
    if (!selected) return;
    setSaving(true);
    try {
      const isFillerPage = partyModule === 'filler_supplier';
      await fetch('/api/supply-links', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          organization_id: orgId,
          filler_party_id: isFillerPage ? partyId : selected.id,
          mill_party_id:   isFillerPage ? selected.id : partyId,
          link_type:     supplyType,
          product_grade:   grade || null,
          volume_estimate:      volume ? parseInt(volume) : null,
          notes:           notes || null,
        }),
      });
      onAdded();
    } finally { setSaving(false); }
  }

  async function saveAsUnregistered() {
    setSaving(true);
    try {
      // Search for placeholder [Unregistered] or legacy [Korean-encoded] party in DB
      const res = await fetch('/api/parties/search?q=%5BUnregistered%5D&module=filler&limit=1');
      let list = res.ok ? await res.json() : [];
      if (list.length === 0) {
        // Fallback: legacy Korean placeholder [誘몃벑濡? (URL-encoded)
        const res2 = await fetch('/api/parties/search?q=%5B%EB%AF%B8%EB%93%B1%EB%A1%9D%5D&module=filler&limit=1');
        list = res2.ok ? await res2.json() : [];
      }
      if (list.length === 0) {
        alert('[Unregistered] Filler Supplier not found in DB. Run Normalize-Clean.sql first.');
        setSaving(false);
        return;
      }
      setSelected(list[0]);
      setSupplyType('potential');
      setNotes('Unregistered supplier - update needed once real supplier is confirmed');
    } finally { setSaving(false); }
  }

  const isFillerPage = partyModule === 'filler_supplier';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-background rounded-xl shadow-xl w-full max-w-md mx-4 overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4 border-b">
          <h3 className="font-semibold text-sm">
            {isFillerPage ? 'Add Paper Mill link' : 'Add Filler supplier link'}
          </h3>
          <button onClick={onClose} className="p-1 hover:bg-muted rounded">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="p-5 space-y-4">
          {!selected ? (
            <div>
              <label className="text-xs font-medium text-muted-foreground mb-1 block">
                {isFillerPage ? 'Search Paper Mills (registered only)' : 'Search Filler suppliers (registered only)'}
              </label>
              <div className="relative">
                <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
                <input
                  autoFocus
                  type="text"
                  value={query}
                  onChange={e => setQuery(e.target.value)}
                  placeholder="Enter name..."
                  className="w-full h-9 pl-8 pr-3 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring"
                />
                {searching && <Loader2 className="absolute right-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 animate-spin" />}
              </div>
              {results.length > 0 && (
                <div className="mt-1 border rounded-md divide-y max-h-48 overflow-y-auto bg-background shadow-sm">
                  {results.map(p => (
                    <button key={p.id} onClick={() => { setSelected(p); setQuery(''); }}
                      className="w-full flex items-center gap-2 px-3 py-2 text-left text-sm hover:bg-muted transition-colors">
                      <div className="flex-1 min-w-0">
                        <div className="font-medium truncate">{p.name}</div>
                        <div className="text-xs text-muted-foreground">
                          {p.country_code} &middot; {p.tier}
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              )}
              <p className="text-xs text-muted-foreground mt-1.5 flex items-center gap-1">
                <AlertTriangle className="h-3 w-3 text-amber-500" />
                If not in DB, use the &quot;Unregistered link&quot; button below
              </p>
            </div>
          ) : (
            <div className="flex items-center gap-2 p-3 rounded-lg bg-primary/5 border border-primary/20">
              <div className="flex-1 min-w-0">
                <p className="font-medium text-sm truncate">{selected.name}</p>
                <p className="text-xs text-muted-foreground">{selected.country_code} &middot; {selected.tier}</p>
              </div>
              <button onClick={() => setSelected(null)} className="p-1 hover:bg-muted rounded">
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          )}

          <div>
            <label className="text-xs font-medium text-muted-foreground mb-1 block">Supply status</label>
            <div className="flex flex-wrap gap-1.5">
              {SUPPLY_TYPES.map(t => (
                <button key={t.value} onClick={() => setSupplyType(t.value)}
                  className={cn('px-2.5 py-1 rounded-full text-xs font-medium transition-colors',
                    supplyType === t.value ? t.color + ' ring-1 ring-current' : 'bg-muted text-muted-foreground hover:bg-muted/80')}>
                  {t.label}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted-foreground mb-1 block">Product grade</label>
              <select value={grade} onChange={e => setGrade(e.target.value)}
                className="w-full h-8 px-2 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring">
                <option value="">Not selected</option>
                {GRADES.map(g => <option key={g} value={g}>{g}</option>)}
              </select>
            </div>
            <div>
              <label className="text-xs font-medium text-muted-foreground mb-1 block">Annual volume (t/yr)</label>
              <input type="number" value={volume} onChange={e => setVolume(e.target.value)}
                placeholder="50000"
                className="w-full h-8 px-2 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring" />
            </div>
          </div>

          <div>
            <label className="text-xs font-medium text-muted-foreground mb-1 block">Notes</label>
            <input type="text" value={notes} onChange={e => setNotes(e.target.value)}
              placeholder="Contract status, special notes, etc..."
              className="w-full h-8 px-3 text-sm rounded-md border border-input bg-background focus:outline-none focus:ring-1 focus:ring-ring" />
          </div>
        </div>

        <div className="flex justify-between gap-2 px-5 py-4 border-t bg-muted/20">
          <button onClick={saveAsUnregistered} disabled={saving}
            className="px-3 py-1.5 text-xs rounded-md border border-amber-300 bg-amber-50 text-amber-700 hover:bg-amber-100 disabled:opacity-40 transition-colors">
            Unregistered link
          </button>
          <div className="flex gap-2">
            <button onClick={onClose}
              className="px-4 py-1.5 text-sm rounded-md border hover:bg-muted transition-colors">
              Cancel
            </button>
            <button onClick={save} disabled={!selected || saving}
              className="px-4 py-1.5 text-sm rounded-md bg-primary text-primary-foreground hover:bg-primary/90 disabled:opacity-40 flex items-center gap-1.5">
              {saving && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
              Save link
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
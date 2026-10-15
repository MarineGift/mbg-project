'use client';

/**
 * components/parties/country-market-links.tsx
 *
 * Source-analysis links for a country market (Market tab). Lists saved links
 * (open in a new tab) and lets the user add a ChatGPT shared-conversation URL
 * or any https link, or remove one.
 */

import { useState, useTransition } from 'react';
import { ExternalLink, Plus, X, Link2 } from 'lucide-react';
import {
  addCountryMarketLink,
  removeCountryMarketLink,
  type ReportLink,
} from '@/lib/actions/country-markets';

interface Props {
  countryCode: string;
  initialLinks: ReportLink[];
  revalidate?: string;
}

export function CountryMarketLinks({ countryCode, initialLinks, revalidate }: Props) {
  const [links, setLinks] = useState<ReportLink[]>(initialLinks ?? []);
  const [adding, setAdding] = useState(false);
  const [label, setLabel] = useState('');
  const [url, setUrl] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [pending, start] = useTransition();

  const onAdd = () => {
    setError(null);
    start(async () => {
      const r = await addCountryMarketLink(countryCode, label, url, revalidate);
      if (!r.ok) { setError(r.error ?? 'Could not save'); return; }
      setLinks(r.links ?? []);
      setLabel(''); setUrl(''); setAdding(false);
    });
  };

  const onRemove = (u: string) => {
    if (!window.confirm('이 링크를 삭제할까요?')) return;
    setError(null);
    start(async () => {
      const r = await removeCountryMarketLink(countryCode, u, revalidate);
      if (!r.ok) { setError(r.error ?? 'Could not remove'); return; }
      setLinks(r.links ?? []);
    });
  };

  return (
    <section className="pt-3">
      <div className="mb-1 flex items-center gap-2">
        <h3 className="flex items-center gap-1.5 text-sm font-semibold">
          <Link2 className="h-4 w-4 text-slate-600" />
          시장 분석 원문 (ChatGPT 등)
        </h3>
        {!adding && (
          <button
            type="button"
            onClick={() => setAdding(true)}
            className="ml-auto inline-flex items-center gap-1 rounded-md border px-2 py-1 text-xs hover:bg-muted"
          >
            <Plus className="h-3.5 w-3.5" /> 링크 추가
          </button>
        )}
      </div>

      {links.length === 0 && !adding && (
        <p className="text-sm text-muted-foreground">
          저장된 분석 링크가 없습니다. ChatGPT 대화에서 공유(Share) → 링크 복사 후 &quot;링크 추가&quot;에 붙여 넣으세요.
        </p>
      )}

      {links.length > 0 && (
        <ul className="space-y-1">
          {links.map((l) => (
            <li key={l.url} className="flex items-center gap-2 text-sm">
              <a
                href={l.url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1 text-primary hover:underline"
              >
                <ExternalLink className="h-3.5 w-3.5" />
                {l.label}
              </a>
              {l.added_at && <span className="text-xs text-muted-foreground">{l.added_at}</span>}
              <button
                type="button"
                onClick={() => onRemove(l.url)}
                disabled={pending}
                className="ml-1 text-muted-foreground hover:text-red-600"
                aria-label="링크 삭제"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </li>
          ))}
        </ul>
      )}

      {adding && (
        <div className="mt-2 grid gap-2 sm:grid-cols-[220px_1fr_auto_auto]">
          <input
            value={label}
            onChange={(e) => setLabel(e.target.value)}
            placeholder="제목 (예: ChatGPT 제지사 분석)"
            className="h-8 rounded-md border bg-background px-2 text-sm"
          />
          <input
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="https://chatgpt.com/share/..."
            className="h-8 rounded-md border bg-background px-2 text-sm"
          />
          <button
            type="button"
            onClick={onAdd}
            disabled={pending || !url.trim()}
            className="h-8 rounded-md bg-blue-600 px-3 text-sm font-medium text-white disabled:opacity-50"
          >
            {pending ? '저장 중…' : '저장'}
          </button>
          <button
            type="button"
            onClick={() => { setAdding(false); setError(null); }}
            className="h-8 rounded-md border px-3 text-sm"
          >
            취소
          </button>
        </div>
      )}
      {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
    </section>
  );
}

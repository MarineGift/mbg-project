'use client';

/**
 * components/parties/country-market-links.tsx
 *
 * Three fixed AI-analysis links for a country market (Market tab):
 * ChatGPT, Claude, Gemini - stored in app.country_markets.chatgpt_url /
 * claude_url / gemini_url. Open in a new tab, enter, change or clear.
 */

import { useState, useTransition } from 'react';
import { ExternalLink, Pencil, X, Link2 } from 'lucide-react';
import { setCountryMarketAiLink, type AiProvider } from '@/lib/actions/country-markets';

interface Props {
  countryCode: string;
  chatgptUrl: string | null;
  claudeUrl: string | null;
  geminiUrl: string | null;
  revalidate?: string;
}

const PROVIDERS: { key: AiProvider; label: string; placeholder: string }[] = [
  { key: 'chatgpt', label: 'ChatGPT', placeholder: 'https://chatgpt.com/share/...' },
  { key: 'claude',  label: 'Claude',  placeholder: 'https://claude.ai/share/...' },
  { key: 'gemini',  label: 'Gemini',  placeholder: 'https://gemini.google.com/share/...' },
];

function LinkRow({
  countryCode, provider, label, placeholder, initial, revalidate,
}: {
  countryCode: string; provider: AiProvider; label: string; placeholder: string;
  initial: string | null; revalidate?: string;
}) {
  const [url, setUrl] = useState<string | null>(initial);
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(initial ?? '');
  const [error, setError] = useState<string | null>(null);
  const [pending, start] = useTransition();

  const save = (value: string | null) => {
    setError(null);
    start(async () => {
      const r = await setCountryMarketAiLink(countryCode, provider, value, revalidate);
      if (!r.ok) { setError(r.error ?? '저장하지 못했습니다'); return; }
      setUrl(r.url ?? null);
      setDraft(r.url ?? '');
      setEditing(false);
    });
  };

  return (
    <div className="grid grid-cols-[90px_1fr] items-center gap-2 py-1.5 border-b border-border/40 last:border-0">
      <span className="text-sm font-medium">{label}</span>
      {editing ? (
        <div className="flex flex-wrap items-center gap-2">
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            placeholder={placeholder}
            className="h-8 min-w-[260px] flex-1 rounded-md border bg-background px-2 text-sm"
          />
          <button
            type="button"
            onClick={() => save(draft)}
            disabled={pending || !draft.trim()}
            className="h-8 rounded-md bg-blue-600 px-3 text-sm font-medium text-white disabled:opacity-50"
          >
            {pending ? '저장 중…' : '저장'}
          </button>
          <button
            type="button"
            onClick={() => { setEditing(false); setDraft(url ?? ''); setError(null); }}
            className="h-8 rounded-md border px-3 text-sm"
          >
            취소
          </button>
        </div>
      ) : (
        <div className="flex min-w-0 items-center gap-2 text-sm">
          {url ? (
            <a
              href={url}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex min-w-0 items-center gap-1 text-primary hover:underline"
            >
              <ExternalLink className="h-3.5 w-3.5 shrink-0" />
              <span className="truncate">{url}</span>
            </a>
          ) : (
            <span className="text-muted-foreground">미입력</span>
          )}
          <button
            type="button"
            onClick={() => setEditing(true)}
            className="ml-auto inline-flex shrink-0 items-center gap-1 rounded-md border px-2 py-1 text-xs hover:bg-muted"
          >
            <Pencil className="h-3 w-3" /> {url ? '변경' : '입력'}
          </button>
          {url && (
            <button
              type="button"
              onClick={() => { if (window.confirm(`${label} 링크를 지울까요?`)) save(null); }}
              disabled={pending}
              className="shrink-0 text-muted-foreground hover:text-red-600"
              aria-label={`${label} 링크 삭제`}
            >
              <X className="h-3.5 w-3.5" />
            </button>
          )}
        </div>
      )}
      {error && <p className="col-start-2 text-xs text-red-600">{error}</p>}
    </div>
  );
}

export function CountryMarketLinks({ countryCode, chatgptUrl, claudeUrl, geminiUrl, revalidate }: Props) {
  const initial: Record<AiProvider, string | null> = { chatgpt: chatgptUrl, claude: claudeUrl, gemini: geminiUrl };
  return (
    <section className="pt-3">
      <h3 className="mb-1 flex items-center gap-1.5 text-sm font-semibold">
        <Link2 className="h-4 w-4 text-slate-600" />
        AI 시장 분석 원문
      </h3>
      <div className="rounded-md border border-border/60 px-3">
        {PROVIDERS.map((p) => (
          <LinkRow
            key={p.key}
            countryCode={countryCode}
            provider={p.key}
            label={p.label}
            placeholder={p.placeholder}
            initial={initial[p.key]}
            revalidate={revalidate}
          />
        ))}
      </div>
      <p className="mt-1 text-xs text-muted-foreground">
        국가별로 저장 — 같은 나라의 모든 제지사·충전제사 Market 탭에 표시됩니다. 각 AI 대화의 공유(Share) 링크를 붙여 넣으세요.
      </p>
    </section>
  );
}

'use client';
import { useRef, useState, useEffect } from 'react';
import { usePathname } from 'next/navigation';
import { Search } from 'lucide-react';

const VALID_MODULES = ['paper_mill', 'filler', 'investor', 'partner', 'customer'];

export function TopbarSearchInput() {
  const [value, setValue] = useState('');
  const pathname = usePathname();
  const ref = useRef<HTMLInputElement>(null);

  // Sync input value with URL search param on mount
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const params = new URLSearchParams(window.location.search);
      const q = params.get('q');
      if (q) setValue(q);
    }
  }, [pathname]);

  function doSearch() {
    const q = value.trim();
    if (!q) return;
    // Detect module from current pathname
    const segments = pathname.split('/').filter(Boolean);
    const mod = VALID_MODULES.includes(segments[0]) ? segments[0] : 'filler';
    const url = '/' + mod + '/parties?q=' + encodeURIComponent(q);
    window.location.href = url;  // hard navigate to ensure page reload with new params
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === 'Enter') doSearch();
    if (e.key === 'Escape') setValue('');
  }

  return (
    <div className="flex items-center gap-1.5 flex-1 max-w-md">
      <div className="relative flex-1">
        <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground pointer-events-none" />
        <input
          ref={ref}
          type="text"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="검색어 입력 후 Enter..."
          className="h-8 w-full rounded-md border border-input bg-background pl-8 pr-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
        />
      </div>
      <button
        onClick={doSearch}
        disabled={!value.trim()}
        className="h-8 px-3 rounded-md bg-primary text-primary-foreground text-xs font-medium hover:bg-primary/90 disabled:opacity-40 disabled:cursor-not-allowed shrink-0"
      >
        검색
      </button>
    </div>
  );
}
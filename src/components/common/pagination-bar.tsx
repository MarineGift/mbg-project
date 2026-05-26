/**
 * components/common/pagination-bar.tsx
 *
 * URL-driven pagination bar. Reads current path + search params and
 * builds prev/next + page size links by mutating `page` / `perPage` query.
 */
'use client';
import Link from 'next/link';
import { useSearchParams, usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';

interface PaginationBarProps {
  totalCount: number;
  pageSize: number;
  currentPage: number;
  pageSizeOptions?: number[];
  className?: string;
}

export function PaginationBar({
  totalCount,
  pageSize,
  currentPage,
  pageSizeOptions = [20, 50, 100],
  className,
}: PaginationBarProps) {
  const pathname = usePathname();
  const sp       = useSearchParams();

  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const canPrev    = currentPage > 1;
  const canNext    = currentPage < totalPages;
  const start      = totalCount === 0 ? 0 : (currentPage - 1) * pageSize + 1;
  const end        = Math.min(currentPage * pageSize, totalCount);

  function buildHref(nextPage: number, nextSize?: number): string {
    const params = new URLSearchParams(sp?.toString() ?? '');
    if (nextPage > 1) params.set('page', String(nextPage));
    else              params.delete('page');
    if (nextSize !== undefined) {
      if (nextSize !== pageSizeOptions[0]) params.set('perPage', String(nextSize));
      else                                  params.delete('perPage');
    }
    const qs = params.toString();
    return qs ? `${pathname}?${qs}` : (pathname ?? '');
  }

  const baseBtn  = 'inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-sm font-medium transition-colors';
  const enabled  = 'bg-white text-gray-700 hover:bg-gray-50 border-gray-300';
  const disabled = 'bg-gray-50 text-gray-400 border-gray-200 cursor-not-allowed pointer-events-none';

  return (
    <nav
      className={cn('flex flex-wrap items-center justify-between gap-3 py-2', className)}
      aria-label="Pagination"
    >
      <div className="text-sm text-gray-500">
        {totalCount === 0
          ? 'No results'
          : <>Showing <span className="font-medium text-gray-700">{start}</span>{'\u2013'}<span className="font-medium text-gray-700">{end}</span> of <span className="font-medium text-gray-700">{totalCount}</span></>}
      </div>

      <div className="flex items-center gap-2">
        {/* Page size selector */}
        <div className="flex items-center gap-1 text-sm text-gray-500">
          <span>Per page:</span>
          {pageSizeOptions.map(opt => (
            <Link
              key={opt}
              href={buildHref(1, opt)}
              className={cn(
                'rounded px-2 py-0.5 text-xs font-medium',
                opt === pageSize
                  ? 'bg-gray-900 text-white'
                  : 'text-gray-600 hover:bg-gray-100',
              )}
            >
              {opt}
            </Link>
          ))}
        </div>

        {/* Prev / Next */}
        <Link
          href={canPrev ? buildHref(currentPage - 1) : '#'}
          className={cn(baseBtn, canPrev ? enabled : disabled)}
          aria-disabled={!canPrev}
        >
          Previous
        </Link>
        <span className="text-sm text-gray-500 whitespace-nowrap">
          Page {currentPage} of {totalPages}
        </span>
        <Link
          href={canNext ? buildHref(currentPage + 1) : '#'}
          className={cn(baseBtn, canNext ? enabled : disabled)}
          aria-disabled={!canNext}
        >
          Next
        </Link>
      </div>
    </nav>
  );
}
'use client';

import { useRouter, usePathname, useSearchParams } from 'next/navigation';
import { useTransition } from 'react';
import { useTranslations } from 'next-intl';
import { ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { PAGE_SIZE_OPTIONS } from '@/types/draft-queue';

interface DraftQueuePaginationProps {
  page: number;
  pageSize: number;
  totalCount: number;
}

export function DraftQueuePagination({
  page,
  pageSize,
  totalCount,
}: DraftQueuePaginationProps) {
  const t = useTranslations('drafts.pagination');
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));

  const goTo = (nextPage: number) => {
    const next = new URLSearchParams(searchParams.toString());
    if (nextPage <= 1) next.delete('page');
    else next.set('page', String(nextPage));
    startTransition(() => {
      router.replace(`${pathname}?${next.toString()}`);
    });
  };

  const changePageSize = (size: string) => {
    const next = new URLSearchParams(searchParams.toString());
    next.set('size', size);
    next.delete('page');
    startTransition(() => {
      router.replace(`${pathname}?${next.toString()}`);
    });
  };

  return (
    <div
      className="flex items-center gap-4 px-4 py-3 border-t text-sm"
      aria-busy={isPending}
    >
      <p className="text-muted-foreground">{t('total', { count: totalCount })}</p>

      <div className="flex items-center gap-2 ml-auto">
        <span className="text-xs text-muted-foreground">{t('rowsPerPage')}</span>
        <Select value={String(pageSize)} onValueChange={changePageSize}>
          <SelectTrigger className="h-8 w-[80px]">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {PAGE_SIZE_OPTIONS.map((size) => (
              <SelectItem key={size} value={String(size)}>
                {size}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <span className="text-xs tabular-nums">
        {t('page')} {page} {t('of')} {totalPages}
      </span>

      <div className="flex items-center gap-1">
        <Button
          variant="outline"
          size="icon"
          className="h-8 w-8"
          onClick={() => goTo(1)}
          disabled={page <= 1}
          aria-label="First page"
        >
          <ChevronsLeft className="h-4 w-4" />
        </Button>
        <Button
          variant="outline"
          size="icon"
          className="h-8 w-8"
          onClick={() => goTo(page - 1)}
          disabled={page <= 1}
          aria-label="Previous page"
        >
          <ChevronLeft className="h-4 w-4" />
        </Button>
        <Button
          variant="outline"
          size="icon"
          className="h-8 w-8"
          onClick={() => goTo(page + 1)}
          disabled={page >= totalPages}
          aria-label="Next page"
        >
          <ChevronRight className="h-4 w-4" />
        </Button>
        <Button
          variant="outline"
          size="icon"
          className="h-8 w-8"
          onClick={() => goTo(totalPages)}
          disabled={page >= totalPages}
          aria-label="Last page"
        >
          <ChevronsRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}

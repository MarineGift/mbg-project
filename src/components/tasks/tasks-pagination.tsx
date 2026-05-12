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
import { TASK_PAGE_SIZE_OPTIONS } from '@/types/task';

interface Props {
  page: number;
  pageSize: number;
  totalCount: number;
}

export function TasksPagination({ page, pageSize, totalCount }: Props) {
  const t = useTranslations('drafts.pagination');
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));

  const goTo = (n: number) => {
    const sp = new URLSearchParams(searchParams.toString());
    if (n <= 1) sp.delete('page');
    else sp.set('page', String(n));
    startTransition(() => router.replace(`${pathname}?${sp.toString()}`));
  };

  const setSize = (size: string) => {
    const sp = new URLSearchParams(searchParams.toString());
    sp.set('size', size);
    sp.delete('page');
    startTransition(() => router.replace(`${pathname}?${sp.toString()}`));
  };

  return (
    <div className="flex items-center gap-4 px-4 py-3 border-t text-sm" aria-busy={isPending}>
      <p className="text-muted-foreground">{t('total', { count: totalCount })}</p>
      <div className="flex items-center gap-2 ml-auto">
        <span className="text-xs text-muted-foreground">{t('rowsPerPage')}</span>
        <Select value={String(pageSize)} onValueChange={setSize}>
          <SelectTrigger className="h-8 w-[80px]">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {TASK_PAGE_SIZE_OPTIONS.map((s) => (
              <SelectItem key={s} value={String(s)}>{s}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <span className="text-xs tabular-nums">
        {t('page')} {page} {t('of')} {totalPages}
      </span>
      <div className="flex items-center gap-1">
        <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => goTo(1)} disabled={page <= 1}><ChevronsLeft className="h-4 w-4" /></Button>
        <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => goTo(page - 1)} disabled={page <= 1}><ChevronLeft className="h-4 w-4" /></Button>
        <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => goTo(page + 1)} disabled={page >= totalPages}><ChevronRight className="h-4 w-4" /></Button>
        <Button variant="outline" size="icon" className="h-8 w-8" onClick={() => goTo(totalPages)} disabled={page >= totalPages}><ChevronsRight className="h-4 w-4" /></Button>
      </div>
    </div>
  );
}

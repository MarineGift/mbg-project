/**
 * app/(app)/drafts/page.tsx
 *
 * AI draft review queue - the core screen of Phase 1.
 *
 * Operates as a Server Component:
 *   - passes URL searchParams to fetchDraftQueue
 *   - passes results to child client components (filters, table, pagination)
 *   - on filter change, the page re-runs automatically (router.replace)
 */

import { getTranslations } from 'next-intl/server';
import { Suspense } from 'react';
import { Skeleton } from '@/components/ui/skeleton';
import { DraftQueueFilters } from '@/components/drafts/draft-queue-filters';
import { DraftQueueTable } from '@/components/drafts/draft-queue-table';
import { DraftQueueBulkActions } from '@/components/drafts/draft-queue-bulk-actions';
import { DraftQueuePagination } from '@/components/drafts/draft-queue-pagination';
import { DraftQueueEmpty } from '@/components/drafts/draft-queue-empty';
import {
  fetchDraftQueue,
  parseFilters,
  parsePagination,
  parseSort,
} from '@/lib/queries/drafts';
import { DEFAULT_FILTERS } from '@/types/draft-queue';

interface DraftQueuePageProps {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}

export default async function DraftQueuePage({
  searchParams,
}: DraftQueuePageProps) {
  const params = await searchParams;
  const filters = parseFilters(params);
  const sort = parseSort(params);
  const pagination = parsePagination(params);
  const t = await getTranslations('drafts');

  const result = await fetchDraftQueue(filters, sort, pagination);

  const isFiltered =
    filters.status !== DEFAULT_FILTERS.status ||
    filters.partyType !== DEFAULT_FILTERS.partyType ||
    filters.category !== DEFAULT_FILTERS.category ||
    filters.minConfidence !== DEFAULT_FILTERS.minConfidence ||
    filters.onlyRisky !== DEFAULT_FILTERS.onlyRisky;

  const visibleIds = result.rows.map((r) => r.id);
  const editingIds = result.rows.filter((r) => r.hasEdits).map((r) => r.id);

  return (
    <div className="flex flex-col h-full">
      <header className="px-6 py-5 border-b bg-background">
        <h1 className="text-xl font-semibold">{t('queueTitle')}</h1>
        <p className="text-sm text-muted-foreground mt-1">
          {t('queueDescription')}
        </p>
      </header>

      <DraftQueueFilters filters={filters} sort={sort} />

      <DraftQueueBulkActions
        allVisibleIds={visibleIds}
        editingIds={editingIds}
      />

      <div className="flex-1 overflow-y-auto">
        {result.rows.length === 0 ? (
          <DraftQueueEmpty isFiltered={isFiltered} />
        ) : (
          <Suspense fallback={<TableSkeleton />}>
            <DraftQueueTable rows={result.rows} />
          </Suspense>
        )}
      </div>

      {result.totalCount > 0 && (
        <DraftQueuePagination
          page={pagination.page}
          pageSize={pagination.pageSize}
          totalCount={result.totalCount}
        />
      )}
    </div>
  );
}

function TableSkeleton() {
  return (
    <div className="p-6 space-y-2">
      {Array.from({ length: 6 }).map((_, i) => (
        <Skeleton key={i} className="h-14 w-full" />
      ))}
    </div>
  );
}

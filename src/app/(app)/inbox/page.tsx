/**
 * app/(app)/inbox/page.tsx
 *
 * 받은 편지함 — 통합 communications 목록.
 * inbound + outbound 모두 표시. 검색·필터·페이지네이션.
 */

import { getTranslations } from 'next-intl/server';
import {
  fetchInbox,
  parseInboxFilters,
  parseInboxPagination,
} from '@/lib/queries/inbox';
import { InboxFiltersBar } from '@/components/inbox/inbox-filters';
import { InboxSearchBar } from '@/components/inbox/inbox-search-bar';
import { InboxTable } from '@/components/inbox/inbox-table';
import { InboxPagination } from '@/components/inbox/inbox-pagination';
import { InboxEmpty } from '@/components/inbox/inbox-empty';
import { DEFAULT_INBOX_FILTERS } from '@/types/inbox';

interface PageProps {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}

export default async function InboxPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const filters = parseInboxFilters(params);
  const pagination = parseInboxPagination(params);
  const t = await getTranslations('inbox');

  const result = await fetchInbox(filters, pagination);

  const isFiltered =
    filters.channel !== DEFAULT_INBOX_FILTERS.channel ||
    filters.direction !== DEFAULT_INBOX_FILTERS.direction ||
    filters.query.length > 0 ||
    filters.hasDraft ||
    filters.partyId !== null;

  return (
    <div className="flex flex-col h-full">
      <header className="px-6 py-5 border-b bg-background">
        <h1 className="text-xl font-semibold">{t('queueTitle')}</h1>
        <p className="text-sm text-muted-foreground mt-1">
          {t('queueDescription')}
        </p>
        <div className="mt-4 max-w-xl">
          <InboxSearchBar initialQuery={filters.query} />
        </div>
      </header>

      <InboxFiltersBar filters={filters} />

      <div className="flex-1 overflow-y-auto">
        {result.rows.length === 0 ? (
          <InboxEmpty isFiltered={isFiltered} />
        ) : (
          <InboxTable rows={result.rows} />
        )}
      </div>

      {result.totalCount > 0 && (
        <InboxPagination
          page={pagination.page}
          pageSize={pagination.pageSize}
          totalCount={result.totalCount}
        />
      )}
    </div>
  );
}

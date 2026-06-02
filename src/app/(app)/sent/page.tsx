import { getTranslations } from 'next-intl/server';
import {
  fetchInbox,
  parseInboxFilters,
  parseInboxPagination,
} from '@/lib/queries/inbox';
import { fetchOpenStatuses } from '@/lib/queries/open-status';
import { fetchCurrentUserProfile } from '@/lib/queries/user-profile';
import { DEFAULT_TIMEZONE } from '@/lib/constants/timezones';
import { InboxFiltersBar } from '@/components/inbox/inbox-filters';
import { InboxSearchBar } from '@/components/inbox/inbox-search-bar';
import { InboxTable } from '@/components/inbox/inbox-table';
import { InboxPagination } from '@/components/inbox/inbox-pagination';
import { InboxEmpty } from '@/components/inbox/inbox-empty';
import { DEFAULT_SENT_FILTERS } from '@/types/inbox';

interface PageProps {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}

export default async function SentPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const filters = parseInboxFilters(params, DEFAULT_SENT_FILTERS);
  const pagination = parseInboxPagination(params);
  const tNav = await getTranslations('nav');

  const result = await fetchInbox(filters, pagination);

  // Read tracking for the visible rows + the viewer's preferred display timezone.
  const [openStatuses, profile] = await Promise.all([
    fetchOpenStatuses(result.rows.map((r) => r.id)),
    fetchCurrentUserProfile(),
  ]);
  const timeZone = profile?.timezone ?? DEFAULT_TIMEZONE;

  const isFiltered =
    filters.channel !== DEFAULT_SENT_FILTERS.channel ||
    filters.direction !== DEFAULT_SENT_FILTERS.direction ||
    filters.query.length > 0 ||
    filters.hasDraft ||
    filters.partyId !== null;

  return (
    <div className="flex flex-col h-full">
      <header className="px-4 py-4 sm:px-6 sm:py-5 border-b bg-background">
        <h1 className="text-lg sm:text-xl font-semibold">{tNav('sent')}</h1>
        <p className="text-sm text-muted-foreground mt-1">
          {/* TODO t7c: dedicated sent.queueDescription i18n key */}
          Messages you have sent.
        </p>
        <div className="mt-4 w-full max-w-xl">
          <InboxSearchBar initialQuery={filters.query} />
        </div>
      </header>

      <InboxFiltersBar filters={filters} />

      <div className="flex-1 overflow-y-auto">
        {result.rows.length === 0 ? (
          <InboxEmpty isFiltered={isFiltered} />
        ) : (
          <InboxTable rows={result.rows} openStatuses={openStatuses} timeZone={timeZone} />
        )}
      </div>

      <InboxPagination
        page={pagination.page}
        pageSize={pagination.pageSize}
        totalCount={result.totalCount}
      />
    </div>
  );
}

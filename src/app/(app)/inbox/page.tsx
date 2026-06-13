/**
 * app/(app)/inbox/page.tsx
 *
 * Inbox list. Defaults to inbound only (DEFAULT_INBOX_FILTERS.direction = 'inbound')
 * so the count matches the sidebar/dashboard unread-inbound indicator. Users can
 * switch direction via the filter dropdown. Search + filter + pagination.
 */

import Link from 'next/link';
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
import { InboxComposeButton } from '@/components/inbox/inbox-compose-button';
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
        <div className="flex items-start justify-between gap-4">
          <div>
            <h1 className="text-xl font-semibold">{t('queueTitle')}</h1>
            <p className="text-sm text-muted-foreground mt-1">
              {t('queueDescription')}
            </p>
          </div>
          <InboxComposeButton />
        </div>
        <div className="mt-4 max-w-xl">
          <InboxSearchBar initialQuery={filters.query} />
        </div>
      </header>

      {/* Inbox sections: Inbound / Outbound / AI Drafts (quick switch) */}
      <InboxTabs direction={filters.direction} hasDraft={filters.hasDraft} />

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

// ---------------------------------------------------------------------------
// Inbox section tabs: Inbound / Outbound / AI Drafts.
// These map onto the existing inbox filters (direction + hasDraft) so the
// table/query are reused. The detailed filter bar below still works.
// ---------------------------------------------------------------------------
function InboxTabs({
  direction,
  hasDraft,
}: {
  direction: 'inbound' | 'outbound' | 'all';
  hasDraft: boolean;
}) {
  const tabs: Array<{ label: string; href: string; active: boolean }> = [
    {
      label: 'Inbound',
      href: '/inbox?direction=inbound',
      active: !hasDraft && direction === 'inbound',
    },
    {
      label: 'Outbound',
      href: '/inbox?direction=outbound',
      active: !hasDraft && direction === 'outbound',
    },
    {
      label: 'AI Drafts',
      href: '/inbox?hasDraft=1',
      active: hasDraft,
    },
  ];

  return (
    <div className="flex gap-1 border-b bg-background px-4">
      {tabs.map((tab) => (
        <Link
          key={tab.label}
          href={tab.href}
          className={
            'relative -mb-px px-3.5 py-2 text-sm font-medium transition-colors ' +
            (tab.active
              ? 'text-foreground'
              : 'text-muted-foreground hover:text-foreground')
          }
          aria-current={tab.active ? 'page' : undefined}
        >
          {tab.label}
          {tab.active && (
            <span className="absolute inset-x-0 -bottom-px h-0.5 rounded-full bg-foreground" />
          )}
        </Link>
      ))}
    </div>
  );
}

import { getTranslations } from 'next-intl/server';
import {
  fetchTasks,
  parseTaskFilters,
  parseTaskPagination,
  parseTaskSort,
} from '@/lib/queries/tasks';
import { TasksFilters } from '@/components/tasks/tasks-filters';
import { TasksTable } from '@/components/tasks/tasks-table';
import { TasksPagination } from '@/components/tasks/tasks-pagination';
import { TasksEmpty } from '@/components/tasks/tasks-empty';
import { DEFAULT_TASK_FILTERS } from '@/types/task';

interface PageProps {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}

export default async function TasksPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const filters = parseTaskFilters(params);
  const sort = parseTaskSort(params);
  const pagination = parseTaskPagination(params);
  const t = await getTranslations('tasks');

  const result = await fetchTasks(filters, sort, pagination);

  const isFiltered =
    filters.status !== DEFAULT_TASK_FILTERS.status ||
    filters.priority !== DEFAULT_TASK_FILTERS.priority ||
    filters.partyType !== DEFAULT_TASK_FILTERS.partyType ||
    filters.overdueOnly ||
    filters.partyId !== null;

  return (
    <div className="flex flex-col h-full">
      <header className="px-6 py-5 border-b bg-background">
        <h1 className="text-xl font-semibold">{t('queueTitle')}</h1>
        <p className="text-sm text-muted-foreground mt-1">
          {t('queueDescription')}
        </p>
      </header>

      <TasksFilters filters={filters} sort={sort} />

      <div className="flex-1 overflow-y-auto">
        {result.rows.length === 0 ? (
          <TasksEmpty isFiltered={isFiltered} />
        ) : (
          <TasksTable rows={result.rows} />
        )}
      </div>

      {result.totalCount > 0 && (
        <TasksPagination
          page={pagination.page}
          pageSize={pagination.pageSize}
          totalCount={result.totalCount}
        />
      )}
    </div>
  );
}

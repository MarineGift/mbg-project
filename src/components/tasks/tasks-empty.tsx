'use client';

import { CheckSquare, Filter } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { EmptyState } from '@/components/common/empty-state';

interface Props {
  isFiltered: boolean;
}

export function TasksEmpty({ isFiltered }: Props) {
  const t = useTranslations(isFiltered ? 'tasks.emptyFiltered' : 'tasks.empty');
  return (
    <EmptyState
      icon={isFiltered ? <Filter className="h-5 w-5" /> : <CheckSquare className="h-5 w-5" />}
      title={t('title')}
      description={t('description')}
    />
  );
}

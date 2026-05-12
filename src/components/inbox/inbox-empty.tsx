'use client';

import { Inbox, Filter } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { EmptyState } from '@/components/common/empty-state';

interface Props {
  isFiltered: boolean;
}

export function InboxEmpty({ isFiltered }: Props) {
  const t = useTranslations(isFiltered ? 'inbox.emptyFiltered' : 'inbox.empty');
  return (
    <EmptyState
      icon={isFiltered ? <Filter className="h-5 w-5" /> : <Inbox className="h-5 w-5" />}
      title={t('title')}
      description={t('description')}
    />
  );
}

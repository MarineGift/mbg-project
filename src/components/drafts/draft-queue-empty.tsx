'use client';

import { useTranslations } from 'next-intl';
import { Sparkles, Filter } from 'lucide-react';
import { EmptyState } from '@/components/common/empty-state';

interface DraftQueueEmptyProps {
  isFiltered: boolean;
}

export function DraftQueueEmpty({ isFiltered }: DraftQueueEmptyProps) {
  const t = useTranslations(isFiltered ? 'drafts.emptyFiltered' : 'drafts.empty');
  return (
    <EmptyState
      icon={isFiltered ? <Filter className="h-5 w-5" /> : <Sparkles className="h-5 w-5" />}
      title={t('title')}
      description={t('description')}
    />
  );
}

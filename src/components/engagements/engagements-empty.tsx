'use client';

import { useTranslations } from 'next-intl';
import { Briefcase, Settings } from 'lucide-react';
import Link from 'next/link';
import { EmptyState } from '@/components/common/empty-state';
import { Button } from '@/components/ui/button';
import type { ModuleType } from '@/types/ai';

interface Props {
  module: ModuleType;
}

export function EngagementsPipelineMissing({ module }: Props) {
  const t = useTranslations('engagements.empty');
  return (
    <EmptyState
      icon={<Briefcase className="h-5 w-5" />}
      title={t('pipelineMissingTitle')}
      description={t('pipelineMissingDescription', { module })}
      action={
        <Button asChild variant="outline">
          <Link href={`/settings/pipelines?module=${module}`}>
            <Settings className="h-4 w-4" />
            {t('configurePipeline')}
          </Link>
        </Button>
      }
    />
  );
}

export function EngagementsEmpty({ module }: Props) {
  const t = useTranslations('engagements.empty');
  return (
    <EmptyState
      icon={<Briefcase className="h-5 w-5" />}
      title={t('noEngagementsTitle')}
      description={t('noEngagementsDescription')}
    />
  );
}

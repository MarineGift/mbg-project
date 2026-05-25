/**
 * app/(app)/[module]/engagements/page.tsx
 *
 * 모듈별 Engagement Kanban 보드.
 */

import { notFound } from 'next/navigation';
import { getTranslations } from 'next-intl/server';
import { fetchKanbanBoard } from '@/lib/queries/engagements';
import { KanbanBoardClient } from '@/components/engagements/kanban-board-client';
import {
  EngagementsPipelineMissing,
  EngagementsEmpty,
} from '@/components/engagements/engagements-empty';
import type { ModuleType } from '@/types/ai';

const PHASE_1_MODULES: readonly ModuleType[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;

interface PageProps {
  params: Promise<{ partyType: string }>;
}

export default async function KanbanPage({ params }: PageProps) {
  const { partyType: urlModule } = await params;
  if (!(PHASE_1_MODULES as readonly string[]).includes(urlModule)) {
    notFound();
  }
  const module = urlModule as ModuleType;

  const board = await fetchKanbanBoard(module);
  const t = await getTranslations('engagements');
  const tModules = await getTranslations('modules');

  return (
    <div className="flex flex-col h-full">
      <header className="px-6 py-5 border-b bg-background">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-semibold">
              {tModules(module)} · {t('queueTitle')}
            </h1>
            <p className="text-sm text-muted-foreground mt-1">
              {board.pipelineName
                ? t('queueDescription', { pipeline: board.pipelineName })
                : t('noPipeline')}
            </p>
          </div>
          <div className="text-right">
            <p className="text-2xl font-semibold tabular-nums">
              {board.totalCount}
            </p>
            <p className="text-xs text-muted-foreground">{t('totalLabel')}</p>
          </div>
        </div>
      </header>

      <div className="flex-1 overflow-hidden">
        {board.pipelineDefinitionId == null ? (
          <EngagementsPipelineMissing module={module} />
        ) : board.totalCount === 0 ? (
          <EngagementsEmpty module={module} />
        ) : (
          <KanbanBoardClient board={board} />
        )}
      </div>
    </div>
  );
}

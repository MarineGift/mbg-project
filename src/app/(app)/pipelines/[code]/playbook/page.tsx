// src/app/(app)/pipelines/[code]/playbook/page.tsx
//
// Stage Playbook editor (Feature B). For the given pipeline, lists every stage
// with its checklist + task templates and provides full CRUD. When a deal
// enters a stage, app.apply_stage_playbook() auto-materialises these templates
// onto the deal as deal_checklists + tasks (see 20260605_stage_playbooks.sql).
//
// Works for ANY pipeline code (investors / paper_mill / filler_suppliers / ...).
// Reached at /pipelines/<code>/playbook.

import { notFound } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { requireAuthOrRedirect } from '@/lib/auth';
import { getPipelinePlaybook } from '@/lib/queries/stage-playbooks';
import { PlaybookClient } from './playbook-client';

interface Props {
  params: { code: string };
}

export default async function PlaybookPage({ params }: Props) {
  await requireAuthOrRedirect();

  const playbook = await getPipelinePlaybook(params.code);
  if (!playbook) notFound();

  return (
    <div className="px-4 sm:px-6 py-4 sm:py-6 space-y-4 max-w-4xl">
      <div className="space-y-1">
        <Link
          href={`/pipelines/${params.code}`}
          className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          Back to board
        </Link>
        <h1 className="text-xl sm:text-2xl font-bold">{playbook.pipelineName} &mdash; Stage Playbook</h1>
        <p className="text-sm text-muted-foreground">
          Checklist items and tasks defined here are added to a deal automatically
          when it enters the stage. Editing a template affects future stage entries,
          not deals already in the stage.
        </p>
      </div>

      <PlaybookClient stages={playbook.stages} />
    </div>
  );
}

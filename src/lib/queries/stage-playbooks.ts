/**
 * lib/queries/stage-playbooks.ts
 *
 * Read API for the Stage Playbook editor (Feature B).
 *
 * Returns, for one pipeline, each stage with its checklist templates and task
 * templates (app.stage_checklist_templates / app.stage_task_templates). Org
 * scoping is handled by RLS, matching the rest of the queries stack.
 *
 * Stage columns are kept to the set proven on the board (id, name, sort_order)
 * to avoid 42703 surprises.
 */
import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export type TemplatePriority = 'low' | 'medium' | 'high';

export interface ChecklistTemplate {
  id: string;
  stageId: string;
  title: string;
  sortOrder: number;
  isActive: boolean;
}

export interface TaskTemplate {
  id: string;
  stageId: string;
  checklistTemplateId: string | null;
  title: string;
  description: string | null;
  defaultPriority: TemplatePriority;
  dueInDays: number;
  sortOrder: number;
  isActive: boolean;
}

export interface PlaybookStage {
  id: string;
  name: string;
  sortOrder: number;
  checklists: ChecklistTemplate[];
  tasks: TaskTemplate[];
}

export interface PipelinePlaybook {
  pipelineId: string;
  pipelineCode: string;
  pipelineName: string;
  stages: PlaybookStage[];
}

interface RawStage { id: string; name: string; sort_order: number }
interface RawChecklist {
  id: string; stage_id: string; title: string; sort_order: number; is_active: boolean;
}
interface RawTask {
  id: string; stage_id: string; checklist_template_id: string | null;
  title: string; description: string | null; default_priority: string;
  due_in_days: number; sort_order: number; is_active: boolean;
}

function priority(v: string | null | undefined): TemplatePriority {
  return v === 'low' || v === 'high' ? v : 'medium';
}

/**
 * Load a pipeline (by code) plus all of its stages and their playbook
 * templates. Returns null if the pipeline isn't found / visible.
 */
export async function getPipelinePlaybook(
  pipelineCode: string,
): Promise<PipelinePlaybook | null> {
  const supabase = await createSupabaseServerClient();

  const { data: pipeRow } = await supabase
    .schema('app')
    .from('pipelines' as never)
    .select('id, code, name')
    .eq('code' as never, pipelineCode)
    .eq('is_active' as never, true)
    .maybeSingle();
  if (!pipeRow) return null;
  const pipeline = pipeRow as unknown as { id: string; code: string; name: string };

  const { data: stageData } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id, name, sort_order')
    .eq('pipeline_id' as never, pipeline.id)
    .order('sort_order', { ascending: true });
  const stages = (stageData ?? []) as unknown as RawStage[];
  if (stages.length === 0) {
    return {
      pipelineId: pipeline.id,
      pipelineCode: pipeline.code,
      pipelineName: pipeline.name,
      stages: [],
    };
  }
  const stageIds = stages.map((s) => s.id);

  const [{ data: clData }, { data: tkData }] = await Promise.all([
    supabase
      .schema('app')
      .from('stage_checklist_templates' as never)
      .select('id, stage_id, title, sort_order, is_active')
      .in('stage_id' as never, stageIds)
      .order('sort_order', { ascending: true }),
    supabase
      .schema('app')
      .from('stage_task_templates' as never)
      .select('id, stage_id, checklist_template_id, title, description, default_priority, due_in_days, sort_order, is_active')
      .in('stage_id' as never, stageIds)
      .order('sort_order', { ascending: true }),
  ]);

  const clByStage = new Map<string, ChecklistTemplate[]>();
  for (const r of (clData ?? []) as unknown as RawChecklist[]) {
    const arr = clByStage.get(r.stage_id) ?? [];
    arr.push({
      id: r.id, stageId: r.stage_id, title: r.title,
      sortOrder: r.sort_order, isActive: r.is_active,
    });
    clByStage.set(r.stage_id, arr);
  }

  const tkByStage = new Map<string, TaskTemplate[]>();
  for (const r of (tkData ?? []) as unknown as RawTask[]) {
    const arr = tkByStage.get(r.stage_id) ?? [];
    arr.push({
      id: r.id, stageId: r.stage_id, checklistTemplateId: r.checklist_template_id,
      title: r.title, description: r.description, defaultPriority: priority(r.default_priority),
      dueInDays: r.due_in_days, sortOrder: r.sort_order, isActive: r.is_active,
    });
    tkByStage.set(r.stage_id, arr);
  }

  return {
    pipelineId: pipeline.id,
    pipelineCode: pipeline.code,
    pipelineName: pipeline.name,
    stages: stages.map((s) => ({
      id: s.id,
      name: s.name,
      sortOrder: s.sort_order,
      checklists: clByStage.get(s.id) ?? [],
      tasks: tkByStage.get(s.id) ?? [],
    })),
  };
}

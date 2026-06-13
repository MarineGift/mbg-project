// src/app/(app)/tasks/[id]/page.tsx
import { notFound } from 'next/navigation';
import { fetchTaskById } from '@/lib/queries/tasks';
import { fetchTaskActivity } from '@/lib/queries/task-activity';
import { TaskDetailClient } from '@/components/tasks/task-detail-client';

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function TaskDetailPage({ params }: PageProps) {
  const { id } = await params;
  const task = await fetchTaskById(id);
  if (!task) notFound();
  const activity = await fetchTaskActivity(id);
  return <TaskDetailClient task={task} activity={activity} />;
}
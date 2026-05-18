// src/app/(app)/tasks/[id]/page.tsx
// Phase 22b: Task detail page (placeholder - redirects to list)
// TODO: build full task detail UI

import { redirect } from "next/navigation";

interface PageProps {
  params: Promise<{ id: string }>;
}

export default async function TaskDetailPage({ params }: PageProps) {
  const { id } = await params;
  // Until task detail UI is built, send users back to the list
  // with the task highlighted in URL query
  redirect(`/tasks?focus=${encodeURIComponent(id)}`);
}
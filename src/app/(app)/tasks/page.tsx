// src/app/(app)/tasks/page.tsx
// Server component: fetches all tasks across deals (RLS auto-scopes to org),
// passes to client for bucketing + filtering.
//
// !! CONFIRM AGAINST REAL REPO:
//   - createSupabaseServerClient import path (assumed '@/lib/supabase/server')
//   - FK hint names in the embeds below (deal_id / pipeline_id / firm_party_id /
//     assigned_to_contact_id). Handoff says "PostgREST follows FK by constraint name";
//     I'm using the column-disambiguation form `relation!fk_column` which PostgREST
//     also accepts. If your constraints are named differently, swap to the name form
//     (e.g. `deals!tasks_deal_id_fkey(...)`).
//   - Handoff "Files to create" said WHERE deleted_at IS NULL, but the verified
//     2026-05-28 app.tasks schema has NO deleted_at column. Omitted to avoid a 500.
//     If the column exists, add `.is('deleted_at', null)` back (see marker below).

import { createSupabaseServerClient } from '@/lib/supabase/server'
import TasksListClient, { type TaskRow } from './tasks-list-client'

export const dynamic = 'force-dynamic'

type SearchParams = {
  status?: string
  filter?: string
}

export default async function TasksPage({
  searchParams,
}: {
  // Next 14.2 App Router = sync params (NOT a Promise)
  searchParams: SearchParams
}) {
  const supabase = await createSupabaseServerClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { data, error } = await supabase
    .schema('app')
    .from('tasks' as never)
    .select(
      `id, title, status, priority, due_at, completed_at, assigned_to_user_id, deal_id,
       deal:deals!deal_id(
         id, deal_name,
         pipeline:pipelines!pipeline_id(code, name)
       ),
       assignee:contacts!assigned_to_contact_id(
         id, full_name, given_name, family_name, title_text,
         firm:parties!party_id(party_name)
       )`
    )
    // .is('deleted_at', null)   // <- re-enable ONLY if app.tasks gains a deleted_at column
    .order('due_at', { ascending: true, nullsFirst: false })

  if (error) {
    // Don't blow up the page on a transient fetch error; render the empty state.
    console.error('[tasks] fetch failed:', error.message)
  }

  const tasks = (data ?? []) as unknown as TaskRow[]

  const status =
    searchParams.status === 'completed' || searchParams.status === 'all'
      ? searchParams.status
      : 'open'
  const mine = searchParams.filter === 'mine'

  return (
    <TasksListClient
      tasks={tasks}
      currentUserId={user?.id ?? null}
      initialStatus={status}
      initialMine={mine}
    />
  )
}

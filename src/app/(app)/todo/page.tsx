// src/app/(app)/todo/page.tsx
// Renders the Todo board (Kanban / Calendar / Gantt). Lives in the (app) route
// group so it inherits the existing sidebar/topbar layout (same as /tasks,
// /inbox, etc.).

import { listBoards, listBoard } from '@/lib/tasks/actions';
import { TaskBoardView } from '@/components/tasks/task-board-view';

export const dynamic = 'force-dynamic'; // always fresh until Realtime is wired

export default async function TodoPage() {
  const boards = await listBoards();
  const todo = boards.find((b) => b.kind === 'todo') ?? boards[0];

  if (!todo) {
    return (
      <div style={{ padding: 24, color: '#5d7681' }}>
        No Todo board found. Run the seed in Supabase SQL Editor first.
      </div>
    );
  }

  const data = await listBoard(todo.id);
  return <TaskBoardView initial={data} />;
}

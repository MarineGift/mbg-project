import { Skeleton } from '@/components/ui/skeleton';

export default function KanbanLoading() {
  return (
    <div className="flex flex-col h-full">
      <div className="px-6 py-5 border-b flex items-center justify-between">
        <div>
          <Skeleton className="h-6 w-48 mb-2" />
          <Skeleton className="h-4 w-72" />
        </div>
        <Skeleton className="h-12 w-16" />
      </div>
      <div className="flex-1 overflow-hidden p-4">
        <div className="flex gap-3 h-full">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="w-72 h-full shrink-0" />
          ))}
        </div>
      </div>
    </div>
  );
}

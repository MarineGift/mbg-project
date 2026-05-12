import { Skeleton } from '@/components/ui/skeleton';

export default function TasksLoading() {
  return (
    <div className="flex flex-col h-full">
      <div className="px-6 py-5 border-b">
        <Skeleton className="h-6 w-24 mb-2" />
        <Skeleton className="h-4 w-72" />
      </div>
      <div className="p-4 space-y-2">
        {Array.from({ length: 10 }).map((_, i) => (
          <Skeleton key={i} className="h-14 w-full" />
        ))}
      </div>
    </div>
  );
}

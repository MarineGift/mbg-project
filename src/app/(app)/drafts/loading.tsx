import { Skeleton } from '@/components/ui/skeleton';

export default function DraftQueueLoading() {
  return (
    <div className="flex flex-col h-full">
      <div className="px-6 py-5 border-b">
        <Skeleton className="h-6 w-40 mb-2" />
        <Skeleton className="h-4 w-72" />
      </div>
      <div className="p-4 border-b bg-muted/30 flex gap-3">
        <Skeleton className="h-10 w-36" />
        <Skeleton className="h-10 w-36" />
        <Skeleton className="h-10 w-36" />
        <Skeleton className="h-10 w-40" />
        <Skeleton className="h-10 w-44" />
      </div>
      <div className="p-6 space-y-2">
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} className="h-14 w-full" />
        ))}
      </div>
    </div>
  );
}

import { Skeleton } from '@/components/ui/skeleton';

export default function InboxLoading() {
  return (
    <div className="flex flex-col h-full">
      <div className="px-6 py-5 border-b">
        <Skeleton className="h-6 w-32 mb-2" />
        <Skeleton className="h-4 w-72 mb-4" />
        <Skeleton className="h-10 w-full max-w-xl" />
      </div>
      <div className="px-4 py-3 border-b bg-muted/30 flex gap-3">
        <Skeleton className="h-10 w-40" />
        <Skeleton className="h-10 w-40" />
        <Skeleton className="h-10 w-32" />
      </div>
      <div className="p-4 space-y-2">
        {Array.from({ length: 8 }).map((_, i) => (
          <Skeleton key={i} className="h-16 w-full" />
        ))}
      </div>
    </div>
  );
}

import { Skeleton } from '@/components/ui/skeleton';

export default function EngagementDetailLoading() {
  return (
    <div className="flex flex-col h-full">
      <div className="border-b bg-background">
        <div className="px-6 py-3 border-b flex items-center gap-3">
          <Skeleton className="h-8 w-8" />
          <Skeleton className="h-6 w-20" />
          <Skeleton className="h-6 w-16" />
        </div>
        <div className="px-6 py-4">
          <Skeleton className="h-8 w-1/2 mb-2" />
          <Skeleton className="h-4 w-1/3" />
        </div>
      </div>
      <div className="flex-1 overflow-y-auto p-6">
        <div className="grid gap-4 lg:grid-cols-[1.4fr_1fr] max-w-7xl mx-auto">
          <div className="space-y-4">
            <Skeleton className="h-72 w-full" />
            <Skeleton className="h-64 w-full" />
          </div>
          <Skeleton className="h-40 w-full" />
        </div>
      </div>
    </div>
  );
}

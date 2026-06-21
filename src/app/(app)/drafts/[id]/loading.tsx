import { Skeleton } from '@/components/ui/skeleton';

export default function DraftDetailLoading() {
  return (
    <div className="flex flex-col h-full">
      <div className="border-b bg-background">
        <div className="px-6 py-3 border-b flex items-center gap-3">
          <Skeleton className="h-8 w-8" />
          <Skeleton className="h-6 w-20" />
          <Skeleton className="h-6 w-16" />
        </div>
        <div className="px-6 py-3">
          <Skeleton className="h-5 w-3/4 mb-2" />
          <Skeleton className="h-4 w-1/3" />
        </div>
      </div>
      <div className="flex-1 overflow-y-auto p-6">
        <div className="grid gap-4 lg:grid-cols-[1fr_1.4fr] max-w-app mx-auto">
          <div className="space-y-4">
            <Skeleton className="h-44 w-full" />
            <Skeleton className="h-36 w-full" />
            <Skeleton className="h-48 w-full" />
            <Skeleton className="h-64 w-full" />
          </div>
          <div className="space-y-4">
            <Skeleton className="h-[500px] w-full" />
          </div>
        </div>
      </div>
    </div>
  );
}

import { Skeleton } from '@/components/ui/skeleton';

export default function CommunicationDetailLoading() {
  return (
    <div className="flex flex-col h-full">
      <div className="border-b bg-background flex items-center gap-3 px-6 py-3">
        <Skeleton className="h-8 w-8" />
        <Skeleton className="h-6 w-2/3" />
      </div>
      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-4xl mx-auto space-y-4">
          <Skeleton className="h-40 w-full" />
          <Skeleton className="h-72 w-full" />
        </div>
      </div>
    </div>
  );
}

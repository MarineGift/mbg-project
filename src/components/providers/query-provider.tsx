/**
 * components/providers/query-provider.tsx
 *
 * TanStack Query Provider - provides the global QueryClient instance.
 *
 * Caching policy (stability first):
 *   - staleTime: 30s - return cache within 30s for re-requests of the same query
 *   - gcTime: 5min - unused cache is GC'd after 5 minutes
 *   - retry: 1 - retry a failed query only once (balancing UX responsiveness vs stability)
 *   - refetchOnWindowFocus: false - avoid overly frequent refetching
 *     (Realtime subscriptions ensure data freshness, so focus refetch is unnecessary)
 */

'use client';

import { useState, type ReactNode } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

interface QueryProviderProps {
  children: ReactNode;
}

export function QueryProvider({ children }: QueryProviderProps) {
  // guarantee the instance via useState - creating a new one each render loses the cache
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30 * 1000,
            gcTime: 5 * 60 * 1000,
            retry: (failureCount, error) => {
              // don't retry 4xx errors (insufficient permission / bad request)
              if (error instanceof Error && /4\d\d/.test(error.message)) {
                return false;
              }
              return failureCount < 1;
            },
            refetchOnWindowFocus: false,
          },
          mutations: {
            retry: 0, // never auto-retry mutations (risk of duplicate execution)
          },
        },
      }),
  );

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
}

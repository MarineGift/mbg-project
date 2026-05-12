/**
 * components/providers/query-provider.tsx
 *
 * TanStack Query Provider — 전역 QueryClient 인스턴스 제공.
 *
 * 캐싱 정책 (안정성 우선):
 *   - staleTime: 30s — 같은 쿼리 재요청 시 30초 내엔 캐시 반환
 *   - gcTime: 5min — 사용되지 않는 캐시는 5분 후 GC
 *   - retry: 1회 — 실패한 쿼리 1회만 재시도 (UX 응답성 vs 안정성 균형)
 *   - refetchOnWindowFocus: false — 너무 잦은 재조회 방지
 *     (Realtime 구독이 데이터 신선도 보장하므로 focus refetch 불필요)
 */

'use client';

import { useState, type ReactNode } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

interface QueryProviderProps {
  children: ReactNode;
}

export function QueryProvider({ children }: QueryProviderProps) {
  // useState로 인스턴스 보장 — 매 렌더마다 새로 만들면 캐시 손실
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30 * 1000,
            gcTime: 5 * 60 * 1000,
            retry: (failureCount, error) => {
              // 4xx 에러는 재시도 안 함 (권한 부족·잘못된 요청)
              if (error instanceof Error && /4\d\d/.test(error.message)) {
                return false;
              }
              return failureCount < 1;
            },
            refetchOnWindowFocus: false,
          },
          mutations: {
            retry: 0, // 변경 작업은 절대 자동 재시도 안 함 (중복 실행 위험)
          },
        },
      }),
  );

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
}

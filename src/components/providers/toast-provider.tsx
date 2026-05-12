/**
 * components/providers/toast-provider.tsx
 *
 * 토스트 컨테이너 — sonner 라이브러리 사용.
 *
 * 사용 패턴:
 *   import { toast } from 'sonner';
 *   toast.success('초안이 승인되었습니다');
 *   toast.error('승인에 실패했습니다', { description: error.message });
 */

'use client';

import { Toaster } from 'sonner';

export function ToastProvider() {
  return (
    <Toaster
      position="top-right"
      richColors
      closeButton
      duration={4500}
      toastOptions={{
        classNames: {
          toast:
            'group toast group-[.toaster]:bg-background group-[.toaster]:text-foreground group-[.toaster]:border-border group-[.toaster]:shadow-lg',
        },
      }}
    />
  );
}
